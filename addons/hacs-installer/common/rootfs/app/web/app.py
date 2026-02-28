from flask import Flask, render_template, jsonify, request
import os
import subprocess
import threading
import time
import docker

app = Flask(__name__)

HA_CONFIG_PATH = os.environ.get('HA_CONFIG_PATH', '/homeassistant')
CUSTOM_COMPONENTS_DIR = os.path.join(HA_CONFIG_PATH, 'custom_components')
HACS_DIR = os.path.join(CUSTOM_COMPONENTS_DIR, 'hacs')

# operation_status: idle, installing, uninstalling, success, error
operation_state = {
    'status': 'idle', 
    'message': '',
    'operation': None # 'install' or 'uninstall'
}

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
                return container
        
        # 优先级2：通过标签匹配
        for container in containers:
            labels = container.labels or {}
            if labels.get('io.hass.type') == 'homeassistant':
                return container
        
        # 优先级3：容器名包含 homeassistant
        for container in containers:
            if 'homeassistant' in container.name.lower():
                return container
        
        return None, "找不到包含 homeassistant 名称的容器"
    except Exception as e:
        print(f"查找 HA 容器时出错: {e}")
        return None, str(e)

def run_script_thread(script_path, operation_name, success_msg):
    global operation_state
    operation_state['status'] = 'running'
    operation_state['operation'] = operation_name
    operation_state['message'] = f'Executing {operation_name}...'
    
    try:
        # 运行脚本
        process = subprocess.Popen(['/bin/bash', script_path], 
                                   stdout=subprocess.PIPE, 
                                   stderr=subprocess.PIPE,
                                   text=True)
        stdout, stderr = process.communicate()
        
        if process.returncode == 0:
            operation_state['status'] = 'success'
            operation_state['message'] = success_msg
        else:
            operation_state['status'] = 'error'
            operation_state['message'] = f'{operation_name} failed: {stderr}'
            if not stderr and stdout:
                 operation_state['message'] = f'{operation_name} failed: {stdout}'
            
    except Exception as e:
        operation_state['status'] = 'error'
        operation_state['message'] = f'Error occurred: {str(e)}'

@app.route('/')
def index():
    installed = check_hacs_installed()
    
    # 获取宿主机路径用于展示
    host_ha_config_path = os.environ.get('HOST_HA_CONFIG_PATH', '/usr/share/hassio/homeassistant')
    target_path = os.path.join(host_ha_config_path, 'custom_components/hacs')
    
    return render_template('index.html', installed=installed, target_path=target_path)

@app.route('/api/install', methods=['POST'])
def install():
    global operation_state
    if operation_state['status'] == 'running':
        return jsonify({'status': 'error', 'message': 'Task already in progress'})
    
    thread = threading.Thread(target=run_script_thread, 
                            args=('/app/install-hacs.sh', 'Install', 'HACS installed successfully! Please restart Home Assistant.'))
    thread.start()
    
    return jsonify({'status': 'success', 'message': 'Installation started'})

@app.route('/api/uninstall', methods=['POST'])
def uninstall():
    global operation_state
    if operation_state['status'] == 'running':
        return jsonify({'status': 'error', 'message': 'Task already in progress'})

    thread = threading.Thread(target=run_script_thread, 
                            args=('/app/uninstall-hacs.sh', 'Uninstall', 'HACS uninstalled successfully! Please restart Home Assistant.'))
    thread.start()
    
    return jsonify({'status': 'success', 'message': 'Uninstallation started'})

@app.route('/api/restart_ha', methods=['POST'])
def restart_ha():
    """重启 Home Assistant 容器"""
    try:
        container, error_msg = find_ha_container()
        if container is None:
            return jsonify({'status': 'error', 'message': f'Unable to find Home Assistant container: {error_msg}'})
        
        container_name = container.name
        container.restart(timeout=30)
        return jsonify({'status': 'success', 'message': f'Home Assistant ({container_name}) is restarting...'})
    except Exception as e:
        return jsonify({'status': 'error', 'message': f'Restart failed: {str(e)}'})

@app.route('/api/status')
def status():
    return jsonify(operation_state)

if __name__ == '__main__':
    # 端口改为 8202
    app.run(host='0.0.0.0', port=8202)
