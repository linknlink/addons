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
        
        # Use IN-USE field to identify connected networks
        # IN-USE field value '*' indicates currently in use
        output_with_inuse = run_nmcli(['-t', '-f', 'IN-USE,SSID,SIGNAL,SECURITY,BARS', 'device', 'wifi', 'list'])
        if output_with_inuse:
            networks = parse_wifi_list_with_inuse(output_with_inuse)
            # Filter out connected networks and remove in_use field
            filtered_networks = []
            for net in networks:
                if not net.get('in_use', False):
                    # Remove in_use field, frontend doesn't need this info
                    filtered_net = {
                        'ssid': net['ssid'],
                        'signal': net['signal'],
                        'security': net['security'],
                        'bars': net['bars']
                    }
                    filtered_networks.append(filtered_net)
            return jsonify(filtered_networks)
              
        # Fallback: if IN-USE field is unavailable (older nmcli versions)
        output = run_nmcli(['-t', '-f', 'SSID,SIGNAL,SECURITY,BARS', 'device', 'wifi', 'list'])
        if output is None:
            return jsonify({'error': 'Failed to scan WiFi'}), 500
        
        networks = parse_wifi_list(output)
        return jsonify(networks)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/wifi/connect', methods=['POST'])
def connect_wifi():
    """Connect to WiFi network
    
    For DHCP mode: use nmcli device wifi connect directly
    For Static IP mode: use two-step operation to avoid parameter errors
        1. Connect with DHCP first to establish connection
        2. Modify connection configuration to static IP
        3. Reactivate connection to apply new config
    """
    data = request.json
    ssid = data.get('ssid')
    password = data.get('password')
    method = data.get('method', 'auto') # auto or manual
    
    if not ssid:
        return jsonify({'error': 'SSID is required'}), 400

    try:
        if method == 'manual':
            # Static IP mode: two-step operation
            ip = data.get('ip')
            gateway = data.get('gateway')
            dns = data.get('dns')
            
            if not ip or not gateway:
                return jsonify({'error': 'IP and Gateway are required for static IP configuration'}), 400
            
            # Step 1: Connect with DHCP first
            cmd_connect = ['nmcli', 'device', 'wifi', 'connect', ssid]
            if password:
                cmd_connect.extend(['password', password])
            
            result = subprocess.run(cmd_connect, capture_output=True, text=True, check=True)
            
            # Step 2: Modify connection to static IP
            # Note: connection name is usually the SSID
            connection_name = ssid
            
            # Modify IP method to manual
            subprocess.run(['nmcli', 'connection', 'modify', connection_name, 
                          'ipv4.method', 'manual'], 
                          check=True, capture_output=True, text=True)
            
            # Set IP address
            subprocess.run(['nmcli', 'connection', 'modify', connection_name, 
                          'ipv4.addresses', ip], 
                          check=True, capture_output=True, text=True)
            
            # Set Gateway
            subprocess.run(['nmcli', 'connection', 'modify', connection_name, 
                          'ipv4.gateway', gateway], 
                          check=True, capture_output=True, text=True)
            
            # Set DNS (if provided)
            if dns:
                # Remove spaces and handle comma separated DNS
                dns_clean = dns.replace(' ', '')
                subprocess.run(['nmcli', 'connection', 'modify', connection_name, 
                              'ipv4.dns', dns_clean], 
                              check=True, capture_output=True, text=True)
            
            # Step 3: Reactivate connection to apply new config
            subprocess.run(['nmcli', 'connection', 'up', connection_name], 
                          check=True, capture_output=True, text=True)
            
            return jsonify({'status': 'success', 'message': 'Connected and configured with static IP'})
        else:
            # DHCP mode: connect directly
            cmd = ['nmcli', 'device', 'wifi', 'connect', ssid]
            if password:
                cmd.extend(['password', password])
            
            subprocess.run(cmd, check=True, capture_output=True, text=True)
            return jsonify({'status': 'success', 'message': 'Connected'})
            
    except subprocess.CalledProcessError as e:
        error_msg = e.stderr if e.stderr else str(e)
        return jsonify({'error': f"Connection failed: {error_msg}"}), 500
    except Exception as e:
        return jsonify({'error': f"Unknown error: {str(e)}"}), 500

@app.route('/api/wifi/disconnect', methods=['POST'])
def disconnect_wifi():
    """Disconnect WiFi connection"""
    data = request.json
    device = data.get('device')
    
    if not device:
        return jsonify({'error': 'Device is required'}), 400
    
    try:
        # Use nmcli device disconnect command
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
