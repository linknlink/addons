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
        output = run_nmcli(['-t', '-f', 'SSID,SIGNAL,SECURITY,BARS', 'device', 'wifi', 'list'])
        if output is None:
             return jsonify({'error': 'Failed to scan WiFi'}), 500
        
        networks = parse_wifi_list(output)
        
        # Filter out currently active connection
        # Get active connection UUID or SSID
        # nmcli -t -f NAME,TYPE,DEVICE,STATE connection show --active
        active_ssid = None
        try:
             active_output = run_nmcli(['-t', '-f', 'NAME,TYPE,DEVICE,STATE', 'connection', 'show', '--active'])
             if active_output:
                for line in active_output.split('\n'):
                    if 'wifi' in line and 'activated' in line:
                         # NAME:TYPE:DEVICE:STATE
                         parts = line.split(':')
                         if len(parts) >= 1:
                              # The connection name is often the SSID for wifi, but not always.
                              # Better to check device status to get the exact SSID being used.
                              pass
        except:
            pass

        # Better way: check device status for the SSID
        # nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status
        # checking device details is more reliable for SSID
        # nmcli -t -f GENERAL.CONNECTION,GENERAL.STATE device show wlan0
        # Actually, let's just get the list of active SSIDs from `nmcli -t -f SSID device wifi list --rescan no | grep '*'` but parsing that is annoying.
        
        # Let's use the IN-USE field from the scan?
        # The scan output we use currently is -f SSID,SIGNAL,SECURITY,BARS
        # If we add IN-USE, we can filter it.
        # IN-USE is '*' for connected.
        
        output_with_inuse = run_nmcli(['-t', '-f', 'IN-USE,SSID,SIGNAL,SECURITY,BARS', 'device', 'wifi', 'list'])
        if output_with_inuse:
             networks = parse_wifi_list_with_inuse(output_with_inuse)
             # Filter out those with in_use=True
             networks = [n for n in networks if not n.get('in_use')]
             return jsonify(networks)
             
        # Fallback if the above fails (e.g. older nmcli?)
        return jsonify(networks)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/wifi/connect', methods=['POST'])
def connect_wifi():
    data = request.json
    ssid = data.get('ssid')
    password = data.get('password')
    method = data.get('method', 'auto') # auto or manual
    
    if not ssid:
        return jsonify({'error': 'SSID is required'}), 400

    cmd = ['device', 'wifi', 'connect', ssid]
    if password:
        cmd.extend(['password', password])
        
    if method == 'manual':
        ip = data.get('ip')
        gateway = data.get('gateway')
        dns = data.get('dns')
        
        if not ip or not gateway:
             return jsonify({'error': 'IP and Gateway are required for manual configuration'}), 400
             
        cmd.extend(['ipv4.method', 'manual'])
        cmd.extend(['ipv4.addresses', ip])
        cmd.extend(['ipv4.gateway', gateway])
        if dns:
            cmd.extend(['ipv4.dns', dns])
    else:
        cmd.extend(['ipv4.method', 'auto'])

    try:
        subprocess.run(['nmcli'] + cmd, check=True, capture_output=True, text=True)
        return jsonify({'status': 'success'})
    except subprocess.CalledProcessError as e:
        return jsonify({'error': f"Failed to connect: {e.stderr}"}), 500

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
