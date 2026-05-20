from flask import Flask, render_template, jsonify
import os
import subprocess
import threading
import time
import re
import docker

app = Flask(__name__)

HA_CONFIG_PATH = os.environ.get('HA_CONFIG_PATH', '/homeassistant')
CUSTOM_COMPONENTS_DIR = os.path.join(HA_CONFIG_PATH, 'custom_components')
HACS_DIR = os.path.join(CUSTOM_COMPONENTS_DIR, 'hacs')

# operation_status: idle, starting, running, success, error
operation_state = {
    'status': 'idle',
    'message': '',
    'operation': None,  # 'Install' or 'Uninstall'
    'detail': '',
    'operation_id': None,
    'started_at': None,
    'finished_at': None,
}

ansi_escape = re.compile(r'\x1B\[[0-?]*[ -/]*[@-~]')
state_lock = threading.Lock()
operation_counter = 0


def clean_output(text):
    if not text:
        return ''
    return ansi_escape.sub('', text).strip()


def humanize_failure(operation_name, detail):
    detail_lower = (detail or '').lower()

    if operation_name == 'Install':
        if 'unable to connect to github' in detail_lower or 'could not resolve host' in detail_lower or 'failed to connect' in detail_lower:
            return 'Install failed: unable to reach GitHub. Please check network or proxy settings.'
        if 'download failed' in detail_lower or 'downloaded file is empty' in detail_lower:
            return 'Install failed: HACS package download did not complete successfully.'
        if 'config directory not found' in detail_lower or 'unable to create or access config directory' in detail_lower:
            return 'Install failed: Home Assistant config path is unavailable. Please check the addon mount path.'
        if 'unzip failed' in detail_lower or 'cannot find or open' in detail_lower:
            return 'Install failed: downloaded package could not be extracted.'

    if operation_name == 'Uninstall':
        if 'config directory not found' in detail_lower:
            return 'Uninstall failed: Home Assistant config path is unavailable.'
        if 'removal failed' in detail_lower or 'permission denied' in detail_lower:
            return 'Uninstall failed: unable to remove HACS files. Please check file permissions.'

    return f'{operation_name} failed'


def update_operation_state(operation_id=None, **kwargs):
    with state_lock:
        if operation_id is not None and operation_state.get('operation_id') != operation_id:
            return False
        operation_state.update(kwargs)
        return True


def get_operation_state():
    with state_lock:
        return dict(operation_state)


def reserve_operation(operation_name, message):
    global operation_counter

    with state_lock:
        if operation_state['status'] in {'starting', 'running'}:
            return None

        operation_counter += 1
        operation_id = operation_counter
        operation_state.update({
            'status': 'starting',
            'message': message,
            'operation': operation_name,
            'detail': '',
            'operation_id': operation_id,
            'started_at': int(time.time()),
            'finished_at': None,
        })
        return operation_id


def check_hacs_installed():
    return os.path.exists(os.path.join(HACS_DIR, '__init__.py'))


def find_ha_container():
    """自动识别 Home Assistant 容器。
    
    查找优先级：
    1. 容器名完全匹配 'homeassistant'
    2. 带有 io.hass.type=homeassistant 标签的容器
    3. 容器名包含 'homeassistant' 的容器
    """
    try:
        client = docker.from_env()
        containers = client.containers.list(all=True)
        
        # 优先级1：容器名完全匹配
        for container in containers:
            if container.name == 'homeassistant':
                return container, None
        
        # 优先级2：通过标签匹配
        for container in containers:
            labels = container.labels or {}
            if labels.get('io.hass.type') == 'homeassistant':
                return container, None
        
        # 优先级3：容器名包含 homeassistant
        for container in containers:
            if 'homeassistant' in container.name.lower():
                return container, None
        
        return None, "找不到包含 homeassistant 名称的容器"
    except Exception as e:
        print(f"查找 HA 容器时出错: {e}")
        return None, str(e)


def run_script_thread(script_path, operation_name, success_msg, operation_id):
    update_operation_state(
        operation_id=operation_id,
        status='running',
        operation=operation_name,
        message=f'Executing {operation_name}...',
        detail='',
        finished_at=None,
    )

    try:
        process = subprocess.Popen(
            ['/bin/bash', script_path],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        stdout, stderr = process.communicate()

        stdout = clean_output(stdout)
        stderr = clean_output(stderr)
        detail = '\n'.join(part for part in [stdout, stderr] if part).strip()

        if process.returncode == 0:
            update_operation_state(
                operation_id=operation_id,
                status='success',
                message=success_msg,
                detail='',
                finished_at=int(time.time()),
            )
        else:
            error_detail = detail or f'Exit code: {process.returncode}'
            update_operation_state(
                operation_id=operation_id,
                status='error',
                message=humanize_failure(operation_name, error_detail),
                detail=error_detail,
                finished_at=int(time.time()),
            )

    except Exception as e:
        update_operation_state(
            operation_id=operation_id,
            status='error',
            message=f'Error occurred during {operation_name}',
            detail=str(e),
            finished_at=int(time.time()),
        )


@app.route('/')
def index():
    installed = check_hacs_installed()
    
    # 获取宿主机路径用于展示
    host_ha_config_path = os.environ.get('HOST_HA_CONFIG_PATH', '/usr/share/hassio/homeassistant')
    target_path = os.path.join(host_ha_config_path, 'custom_components/hacs')
    
    return render_template('index.html', installed=installed, target_path=target_path)


@app.route('/api/install', methods=['POST'])
def install():
    operation_id = reserve_operation('Install', 'Preparing installation...')
    if operation_id is None:
        return jsonify({'status': 'error', 'message': 'Task already in progress'})

    try:
        thread = threading.Thread(
            target=run_script_thread,
            args=(
                '/app/install-hacs.sh',
                'Install',
                'HACS files installed. Restart Home Assistant, then add the HACS integration in Home Assistant.',
                operation_id,
            ),
            daemon=True,
        )
        thread.start()
    except Exception as e:
        update_operation_state(
            operation_id=operation_id,
            status='error',
            message='Failed to start installation',
            detail=str(e),
            finished_at=int(time.time()),
        )
        return jsonify({'status': 'error', 'message': 'Failed to start installation'})

    return jsonify({
        'status': 'success',
        'message': 'Installation started',
        'operation_id': operation_id,
    })


@app.route('/api/uninstall', methods=['POST'])
def uninstall():
    operation_id = reserve_operation('Uninstall', 'Preparing uninstallation...')
    if operation_id is None:
        return jsonify({'status': 'error', 'message': 'Task already in progress'})

    try:
        thread = threading.Thread(
            target=run_script_thread,
            args=(
                '/app/uninstall-hacs.sh',
                'Uninstall',
                'HACS files removed. Please restart Home Assistant to clear the integration from runtime.',
                operation_id,
            ),
            daemon=True,
        )
        thread.start()
    except Exception as e:
        update_operation_state(
            operation_id=operation_id,
            status='error',
            message='Failed to start uninstallation',
            detail=str(e),
            finished_at=int(time.time()),
        )
        return jsonify({'status': 'error', 'message': 'Failed to start uninstallation'})

    return jsonify({
        'status': 'success',
        'message': 'Uninstallation started',
        'operation_id': operation_id,
    })


@app.route('/api/restart_ha', methods=['POST'])
def restart_ha():
    """重启 Home Assistant 容器"""
    try:
        container, error_msg = find_ha_container()
        if container is None:
            return jsonify({'status': 'error', 'message': f'Unable to find Home Assistant container: {error_msg}'})
        
        container_name = container.name
        container.restart(timeout=30)
        return jsonify({'status': 'success', 'message': f'Home Assistant ({container_name}) is restarting. After it comes back, add HACS from Settings > Devices & services > Add integration.'})
    except Exception as e:
        return jsonify({'status': 'error', 'message': f'Restart failed: {str(e)}'})


@app.route('/api/status')
def status():
    return jsonify(get_operation_state())

if __name__ == '__main__':
    # 端口改为 8202
    app.run(host='0.0.0.0', port=8202)
