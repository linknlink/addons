document.addEventListener('DOMContentLoaded', () => {
    const scanBtn = document.getElementById('scan-btn');
    const wifiListEl = document.getElementById('wifi-list');
    const statusContainer = document.getElementById('status-container');
    const modal = document.getElementById('connect-modal');
    const modalSsid = document.getElementById('modal-ssid');
    const passwordInput = document.getElementById('password');
    const ipMethodSelect = document.getElementById('ip-method');
    const staticIpConfig = document.getElementById('static-ip-config');
    const ipAddressInput = document.getElementById('ip-address');
    const gatewayInput = document.getElementById('gateway');
    const dnsInput = document.getElementById('dns');
    const cancelBtn = document.getElementById('cancel-btn');
    const connectConfirmBtn = document.getElementById('connect-confirm-btn');

    let currentSsid = '';

    // Load initial status
    fetchStatus();

    // Event Listeners
    scanBtn.addEventListener('click', scanWifi);

    cancelBtn.addEventListener('click', () => {
        modal.classList.remove('show');
        passwordInput.value = '';
    });

    connectConfirmBtn.addEventListener('click', connectToWifi);

    ipMethodSelect.addEventListener('change', () => {
        if (ipMethodSelect.value === 'manual') {
            staticIpConfig.style.display = 'block';
        } else {
            staticIpConfig.style.display = 'none';
        }
    });

    // Auto-fill gateway based on IP address input
    ipAddressInput.addEventListener('input', () => {
        const ip = ipAddressInput.value;
        const gateway = gatewayInput.value;

        // Match standard IP format prefix (e.g. 192.168.1)
        const match = ip.match(/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})/);

        if (match) {
            const subnetPrefix = `${match[1]}.${match[2]}.${match[3]}`;
            const suggestedGateway = `${subnetPrefix}.1`;

            // Logic: Fill if empty OR update if the existing gateway looks like a default (.1) 
            // but belongs to a different subnet (stale guess)
            if (!gateway) {
                gatewayInput.value = suggestedGateway;
            } else {
                const parts = gateway.split('.');
                if (parts.length === 4 && parts[3] === '1') {
                    const gatewayPrefix = `${parts[0]}.${parts[1]}.${parts[2]}`;
                    if (gatewayPrefix !== subnetPrefix) {
                        gatewayInput.value = suggestedGateway;
                    }
                }
            }
        }
    });

    function fetchStatus() {
        fetch('/api/status')
            .then(res => res.json())
            .then(data => {
                statusContainer.innerHTML = '';
                if (data.length === 0) {
                    statusContainer.innerHTML = '<div class="status-item">未检测到网络设备</div>';
                    return;
                }
                data.forEach(dev => {
                    const div = document.createElement('div');
                    div.className = 'status-item';

                    let icon = '🔌';
                    if (dev.type === 'wifi') icon = '📶';

                    let statusText = dev.state;
                    if (dev.state === 'connected') {
                        statusText = `<span style="color: green">已连接</span> (${dev.connection})`;
                    } else if (dev.state === 'disconnected') {
                        statusText = '<span style="color: red">未连接</span>';
                    }

                    div.innerHTML = `
                        <div>${icon} <strong>${dev.device}</strong></div>
                        <div>${statusText}</div>
                        <div>${dev.ip || '-'}</div>
                    `;
                    statusContainer.appendChild(div);
                });
            })
            .catch(err => {
                statusContainer.innerText = '获取状态失败: ' + err;
            });
    }

    function scanWifi() {
        wifiListEl.innerHTML = '<div class="loading">正在扫描...</div>';
        fetch('/api/wifi/scan')
            .then(res => res.json())
            .then(data => {
                wifiListEl.innerHTML = '';
                if (data.length === 0) {
                    wifiListEl.innerHTML = '<div class="loading">未发现 WiFi 网络</div>';
                    return;
                }

                // Sort by signal strength (bars) roughly
                // The 'bars' field is like '****' or '__**'
                // But better to rely on order from nmcli or signal

                data.forEach(net => {
                    const item = document.createElement('div');
                    item.className = 'wifi-item';

                    const isSecure = net.security && net.security !== '--';
                    const icon = isSecure ? '<div class="wifi-icon lock-icon"></div>' : '<div class="wifi-icon">🔓</div>';

                    item.innerHTML = `
                        ${icon}
                        <div class="wifi-details">
                            <div class="wifi-ssid">${net.ssid}</div>
                            <div class="wifi-info">信号: ${net.signal}% | 安全: ${net.security}</div>
                        </div>
                        <div class="wifi-action">
                             <button class="btn btn-sm">连接</button>
                        </div>
                    `;

                    item.addEventListener('click', () => {
                        openConnectModal(net.ssid);
                    });

                    wifiListEl.appendChild(item);
                });
            })
            .catch(err => {
                wifiListEl.innerText = '扫描失败: ' + err;
            });
    }

    function openConnectModal(ssid) {
        currentSsid = ssid;
        modalSsid.innerText = ssid;
        passwordInput.value = '';
        ipMethodSelect.value = 'auto'; // Reset to auto
        staticIpConfig.style.display = 'none';
        modal.classList.add('show');
    }

    function connectToWifi() {
        const password = passwordInput.value;
        const method = ipMethodSelect.value;

        const payload = {
            ssid: currentSsid,
            password: password,
            method: method
        };

        if (method === 'manual') {
            payload.ip = ipAddressInput.value;
            payload.gateway = gatewayInput.value;
            payload.dns = dnsInput.value;

            if (!payload.ip || !payload.gateway) {
                alert("请输入 IP 地址和网关");
                return;
            }
        }

        connectConfirmBtn.disabled = true;
        connectConfirmBtn.innerText = '连接中...';

        fetch('/api/wifi/connect', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(payload)
        })
            .then(res => res.json())
            .then(data => {
                if (data.error) {
                    alert('连接失败: ' + data.error);
                } else {
                    alert('连接命令已发送，请等待连接建立...');
                    modal.classList.remove('show');
                    setTimeout(fetchStatus, 5000); // Wait a bit then refresh status
                }
            })
            .catch(err => {
                alert('请求错误: ' + err);
            })
            .finally(() => {
                connectConfirmBtn.disabled = false;
                connectConfirmBtn.innerText = '连接';
            });
    }

    // Initial scan
    scanWifi();
});
