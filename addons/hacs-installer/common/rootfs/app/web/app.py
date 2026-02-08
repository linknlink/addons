from flask import Flask, render_template, jsonify, request
import os
import subprocess
import threading
import time

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

def run_script_thread(script_path, operation_name, success_msg):
    global operation_state
    operation_state['status'] = 'running'
    operation_state['operation'] = operation_name
    operation_state['message'] = f'正在执行{operation_name}...'
    
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
            operation_state['message'] = f'{operation_name}失败: {stderr}'
            if not stderr and stdout:
                 operation_state['message'] = f'{operation_name}失败: {stdout}'
            
    except Exception as e:
        operation_state['status'] = 'error'
        operation_state['message'] = f'发生错误: {str(e)}'

@app.route('/')
def index():
    installed = check_hacs_installed()
    
    # Get host path for display
    host_ha_config_path = os.environ.get('HOST_HA_CONFIG_PATH', '/usr/share/hassio/homeassistant')
    target_path = os.path.join(host_ha_config_path, 'custom_components/hacs')
    
    return render_template('index.html', installed=installed, target_path=target_path)

@app.route('/api/install', methods=['POST'])
def install():
    global operation_state
    if operation_state['status'] == 'running':
        return jsonify({'status': 'error', 'message': '当前有任务正在进行中'})
    
    thread = threading.Thread(target=run_script_thread, 
                            args=('/app/install-hacs.sh', 'Install', 'HACS 安装成功！请重启 Home Assistant。'))
    thread.start()
    
    return jsonify({'status': 'success', 'message': '开始安装'})

@app.route('/api/uninstall', methods=['POST'])
def uninstall():
    global operation_state
    if operation_state['status'] == 'running':
        return jsonify({'status': 'error', 'message': '当前有任务正在进行中'})

    thread = threading.Thread(target=run_script_thread, 
                            args=('/app/uninstall-hacs.sh', 'Uninstall', 'HACS 卸载成功！请重启 Home Assistant。'))
    thread.start()
    
    return jsonify({'status': 'success', 'message': '开始卸载'})

@app.route('/api/status')
def status():
    return jsonify(operation_state)

if __name__ == '__main__':
    # Port changed to 8202
    app.run(host='0.0.0.0', port=8202)
