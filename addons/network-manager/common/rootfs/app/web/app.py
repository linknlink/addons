from flask import Flask, render_template, request, jsonify
import subprocess
import json
import re

app = Flask(__name__)

def run_nmcli(args):
    try:
        result = subprocess.run(['nmcli'] + args, capture_output=True, text=True, check=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        return None

def parse_wifi_list(output):
    lines = output.split('\n')
    networks = []
    if len(lines) < 2:
        return networks
    
    # nmcli -t -f SSID,SIGNAL,SECURITY,BARS device wifi list
    # The output format with -t is colon separated, but fields might contain colons (less likely for these fields but SSID can)
    # Actually using -t is better for parsing.
    # Command: nmcli -t -f SSID,SIGNAL,SECURITY,BARS device wifi list
    
    for line in lines:
        if not line:
            continue
        # We need a robust way to parse. Let's assume -t output:
        # SSID:SIGNAL:SECURITY:BARS
        # Escaping might be an issue, but usually : is escaped as \:
        # For simplicity, we can just split by : if we are careful, or run without -t and parse columns.
        # Let's use the tabular output from nmcli -t
        parts = line.split(':')
        if len(parts) >= 3:
            ssid = parts[0]
            # Skip empty SSIDs
            if not ssid:
                continue
                
            # Handle potential duplicate SSIDs by keeping the one with stronger signal? 
            # Or just return all unique SSIDs.
            
            # Reconstruct if split caused issues (unlikely with selected fields unless SSID has :)
            # A safer way might be to use CSV output if available, but nmcli doesn't standardly output CSV.
            # Let's just join the first N-3 parts as SSID in case SSID has colons.
            ssid = ":".join(parts[:-3])
            signal = parts[-3]
            security = parts[-2]
            bars = parts[-1]
            
            networks.append({
                'ssid': ssid,
                'signal': signal,
                'security': security,
                'bars': bars
            })
            
    # Deduplicate by SSID, keeping strongest signal
    unique_networks = {}
    for net in networks:
        ssid = net['ssid']
        if ssid not in unique_networks:
            unique_networks[ssid] = net
        else:
            if int(net['signal']) > int(unique_networks[ssid]['signal']):
                unique_networks[ssid] = net
    
    return list(unique_networks.values())

def parse_wifi_list_with_inuse(output):
    lines = output.split('\n')
    networks = []
    if len(lines) < 1:
        return networks
    
    # nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY,BARS device wifi list
    # IN-USE is '*' or empty
    
    for line in lines:
        if not line:
            continue
            
        parts = line.split(':')
        # IN-USE:SSID:SIGNAL:SECURITY:BARS
        # But SSID can contain colons.
        # We know IN-USE is first, SIGNAL/SECURITY/BARS are last 3.
        # Everything in between is SSID.
        
        if len(parts) >= 5:
            in_use = parts[0] == '*'
            signal = parts[-3]
            security = parts[-2]
            bars = parts[-1]
            ssid = ":".join(parts[1:-3])
            
            # Skip empty SSIDs
            if not ssid:
                continue
            
            networks.append({
                'ssid': ssid,
                'signal': signal,
                'security': security,
                'bars': bars,
                'in_use': in_use
            })
            
    # Deduplicate by SSID, keeping strongest signal
    # If one is in_use, we should prefer keeping that info? 
    # Actually, we filter out in_use later, so it matters less, 
    # but let's keep the one that is in use if duplicates exist.
    unique_networks = {}
    for net in networks:
        ssid = net['ssid']
        if ssid not in unique_networks:
            unique_networks[ssid] = net
        else:
            # If new one is in use, replace
            if net['in_use']:
                unique_networks[ssid] = net
            # If current is not in use, and new one is stronger, replace
            elif not unique_networks[ssid]['in_use'] and int(net['signal']) > int(unique_networks[ssid]['signal']):
                unique_networks[ssid] = net
                
    return list(unique_networks.values())

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api/wifi/scan')
def scan_wifi():
    # nmcli -t -f SSID,SIGNAL,SECURITY,BARS device wifi list
    # We allow rescan.
    try:
        subprocess.run(['nmcli', 'device', 'wifi', 'rescan'], check=False) # Rescan might fail if too frequent
        
        # 使用 IN-USE 字段来识别已连接的网络
        # IN-USE 字段值为 '*' 表示当前正在使用
        output_with_inuse = run_nmcli(['-t', '-f', 'IN-USE,SSID,SIGNAL,SECURITY,BARS', 'device', 'wifi', 'list'])
        if output_with_inuse:
            networks = parse_wifi_list_with_inuse(output_with_inuse)
            # 过滤掉已连接的网络，并移除 in_use 字段
            filtered_networks = []
            for net in networks:
                if not net.get('in_use', False):
                    # 移除 in_use 字段，前端不需要这个信息
                    filtered_net = {
                        'ssid': net['ssid'],
                        'signal': net['signal'],
                        'security': net['security'],
                        'bars': net['bars']
                    }
                    filtered_networks.append(filtered_net)
            return jsonify(filtered_networks)
              
        # Fallback: 如果 IN-USE 字段不可用（旧版本 nmcli）
        output = run_nmcli(['-t', '-f', 'SSID,SIGNAL,SECURITY,BARS', 'device', 'wifi', 'list'])
        if output is None:
            return jsonify({'error': 'Failed to scan WiFi'}), 500
        
        networks = parse_wifi_list(output)
        return jsonify(networks)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/wifi/connect', methods=['POST'])
def connect_wifi():
    """连接WiFi网络
    
    对于DHCP模式：直接使用 nmcli device wifi connect 命令连接
    对于静态IP模式：采用两步操作来避免参数错误
        1. 先以DHCP模式连接WiFi建立连接
        2. 然后修改连接配置为静态IP
        3. 重新激活连接应用新配置
    """
    data = request.json
    ssid = data.get('ssid')
    password = data.get('password')
    method = data.get('method', 'auto') # auto or manual
    
    if not ssid:
        return jsonify({'error': 'SSID is required'}), 400

    try:
        if method == 'manual':
            # 静态IP模式：两步操作
            ip = data.get('ip')
            gateway = data.get('gateway')
            dns = data.get('dns')
            
            if not ip or not gateway:
                return jsonify({'error': 'IP和网关是静态IP配置的必填项'}), 400
            
            # 步骤1：先以DHCP模式连接WiFi
            cmd_connect = ['nmcli', 'device', 'wifi', 'connect', ssid]
            if password:
                cmd_connect.extend(['password', password])
            
            result = subprocess.run(cmd_connect, capture_output=True, text=True, check=True)
            
            # 步骤2：修改连接配置为静态IP
            # 注意：连接名称通常与SSID相同
            connection_name = ssid
            
            # 修改IP配置方法为manual
            subprocess.run(['nmcli', 'connection', 'modify', connection_name, 
                          'ipv4.method', 'manual'], 
                          check=True, capture_output=True, text=True)
            
            # 设置IP地址
            subprocess.run(['nmcli', 'connection', 'modify', connection_name, 
                          'ipv4.addresses', ip], 
                          check=True, capture_output=True, text=True)
            
            # 设置网关
            subprocess.run(['nmcli', 'connection', 'modify', connection_name, 
                          'ipv4.gateway', gateway], 
                          check=True, capture_output=True, text=True)
            
            # 设置DNS（如果提供）
            if dns:
                # 移除空格并处理逗号分隔的DNS
                dns_clean = dns.replace(' ', '')
                subprocess.run(['nmcli', 'connection', 'modify', connection_name, 
                              'ipv4.dns', dns_clean], 
                              check=True, capture_output=True, text=True)
            
            # 步骤3：重新激活连接以应用新配置
            subprocess.run(['nmcli', 'connection', 'up', connection_name], 
                          check=True, capture_output=True, text=True)
            
            return jsonify({'status': 'success', 'message': '已连接并配置静态IP'})
        else:
            # DHCP模式：直接连接
            cmd = ['nmcli', 'device', 'wifi', 'connect', ssid]
            if password:
                cmd.extend(['password', password])
            
            subprocess.run(cmd, check=True, capture_output=True, text=True)
            return jsonify({'status': 'success', 'message': '已连接'})
            
    except subprocess.CalledProcessError as e:
        error_msg = e.stderr if e.stderr else str(e)
        return jsonify({'error': f"连接失败: {error_msg}"}), 500
    except Exception as e:
        return jsonify({'error': f"未知错误: {str(e)}"}), 500

@app.route('/api/wifi/disconnect', methods=['POST'])
def disconnect_wifi():
    """断开WiFi连接"""
    data = request.json
    device = data.get('device')
    
    if not device:
        return jsonify({'error': 'Device is required'}), 400
    
    try:
        # 使用 nmcli device disconnect 命令断开设备
        subprocess.run(['nmcli', 'device', 'disconnect', device], 
                      check=True, capture_output=True, text=True)
        return jsonify({'status': 'success'})
    except subprocess.CalledProcessError as e:
        return jsonify({'error': f"Failed to disconnect: {e.stderr}"}), 500

@app.route('/api/status')
def get_status():
    # Get device status
    # nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status
    try:
        output = run_nmcli(['-t', '-f', 'DEVICE,TYPE,STATE,CONNECTION,IP4.ADDRESS', 'device', 'status'])
        # Note: IP4.ADDRESS might need device show for more details
        
        # Better: nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device
        dev_output = run_nmcli(['-t', '-f', 'DEVICE,TYPE,STATE,CONNECTION', 'device'])
        
        devices = []
        if dev_output:
             for line in dev_output.split('\n'):
                if not line: continue
                parts = line.split(':')
                if len(parts) >= 4:
                    dev_name = parts[0]
                    dev_type = parts[1]
                    state = parts[2]
                    conn = parts[3]
                    
                    # Filtering logic
                    # 1. Skip if type is explicitly unwanted
                    if dev_type in ['bridge', 'loopback', 'tun', 'veth', 'dummy', 'bond', 'team', 'wifi-p2p']:
                        continue
                        
                    # 2. Skip based on name prefixes commonly used for virtual interfaces
                    if dev_name.startswith(('docker', 'br-', 'veth', 'lo', 'virbr', 'tun', 'tap', 'vnet', 'p2p-dev-')):
                        continue
                        
                    # 3. Explicitly allow wifi, ethernet, gsm, cdma (and maybe others that are physical)
                    # or just rely on the exclusions above. 
                    # Let's be safer: if it's not wifi/ethernet/gsm/cdma, double check.
                    # But for now, the exclusion list is robust for the user's request.
                    
                    # Get IP for this device
                    ip_info = query_ip(dev_name)
                    
                    devices.append({
                        'device': dev_name,
                        'type': dev_type,
                        'state': state,
                        'connection': conn,
                        'ip': ip_info
                    })
        return jsonify(devices)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

def query_ip(interface):
    # nmcli -t -f IP4.ADDRESS device show <interface>
    try:
        out = run_nmcli(['-t', '-f', 'IP4.ADDRESS', 'device', 'show', interface])
        if out:
            # might have multiple lines or multiple IPs
            # Just take the first one
            return out.split('\n')[0].strip()
    except:
        pass
    return ""

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8201)
