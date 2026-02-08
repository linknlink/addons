from flask import Flask, render_template, jsonify, request
import os
import subprocess
import threading
import time

app = Flask(__name__)

HA_CONFIG_PATH = os.environ.get('HA_CONFIG_PATH', '/homeassistant')
CUSTOM_COMPONENTS_DIR = os.path.join(HA_CONFIG_PATH, 'custom_components')
HACS_DIR = os.path.join(CUSTOM_COMPONENTS_DIR, 'hacs')

install_status = {
    'status': 'idle', # idle, installing, success, error
    'message': ''
}

def check_hacs_installed():
    return os.path.exists(os.path.join(HACS_DIR, '__init__.py'))

def install_hacs_thread():
    global install_status
    install_status['status'] = 'installing'
    install_status['message'] = '正在下载 HACS...'
    
    try:
        # 运行安装脚本
        process = subprocess.Popen(['/bin/bash', '/app/install-hacs.sh'], 
                                   stdout=subprocess.PIPE, 
                                   stderr=subprocess.PIPE,
                                   text=True)
        stdout, stderr = process.communicate()
        
        if process.returncode == 0:
            install_status['status'] = 'success'
            install_status['message'] = 'HACS 安装成功！请重启 Home Assistant。'
        else:
            install_status['status'] = 'error'
            install_status['message'] = f'安装失败: {stderr}'
            
    except Exception as e:
        install_status['status'] = 'error'
        install_status['message'] = f'发生错误: {str(e)}'

@app.route('/')
def index():
    installed = check_hacs_installed()
    return render_template('index.html', installed=installed)

@app.route('/api/install', methods=['POST'])
def install():
    global install_status
    if install_status['status'] == 'installing':
        return jsonify({'status': 'error', 'message': '安装正在进行中'})
    
    thread = threading.Thread(target=install_hacs_thread)
    thread.start()
    
    return jsonify({'status': 'success', 'message': '开始安装'})

@app.route('/api/status')
def status():
    return jsonify(install_status)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8099)
