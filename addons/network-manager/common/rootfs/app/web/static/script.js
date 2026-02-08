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

    // 断开确认弹窗元素
    const disconnectModal = document.getElementById('disconnect-modal');
    const disconnectDeviceName = document.getElementById('disconnect-device-name');
    const disconnectCancelBtn = document.getElementById('disconnect-cancel-btn');
    const disconnectConfirmBtn = document.getElementById('disconnect-confirm-btn');

    let currentSsid = '';
    let currentDisconnectDevice = ''; // 记录要断开的设备

    // Load initial status
    fetchStatus();

    // Event Listeners
    scanBtn.addEventListener('click', scanWifi);

    cancelBtn.addEventListener('click', () => {
        modal.classList.remove('show');
        passwordInput.value = '';
    });

    connectConfirmBtn.addEventListener('click', connectToWifi);

    // 密码显示/隐藏切换
    const togglePasswordBtn = document.getElementById('toggle-password');
    togglePasswordBtn.addEventListener('click', () => {
        const type = passwordInput.getAttribute('type');
        if (type === 'password') {
            passwordInput.setAttribute('type', 'text');
            togglePasswordBtn.setAttribute('aria-label', '隐藏密码');
        } else {
            passwordInput.setAttribute('type', 'password');
            togglePasswordBtn.setAttribute('aria-label', '显示密码');
        }
    });

    ipMethodSelect.addEventListener('change', () => {
        if (ipMethodSelect.value === 'manual') {
            staticIpConfig.style.display = 'block';
        } else {
            staticIpConfig.style.display = 'none';
        }
    });

    // 断开确认弹窗事件监听
    disconnectCancelBtn.addEventListener('click', () => {
        disconnectModal.classList.remove('show');
        currentDisconnectDevice = '';
    });

    disconnectConfirmBtn.addEventListener('click', () => {
        if (currentDisconnectDevice) {
            performDisconnect(currentDisconnectDevice);
            disconnectModal.classList.remove('show');
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

                    // 使用SVG图标替代emoji
                    let iconClass = 'device-icon ethernet-icon';
                    if (dev.type === 'wifi') iconClass = 'device-icon wifi-status-icon';

                    let statusText = dev.state;
                    let disconnectBtn = '';

                    if (dev.state === 'connected') {
                        statusText = `<span class="text-success">已连接</span> (${dev.connection})`;
                        // 仅为WiFi连接添加断开按钮
                        if (dev.type === 'wifi') {
                            disconnectBtn = `<button class="btn btn-sm btn-disconnect" data-device="${dev.device}">断开</button>`;
                        }
                    } else if (dev.state === 'disconnected') {
                        statusText = '<span class="text-error">未连接</span>';
                    }

                    div.innerHTML = `
                        <div><span class="${iconClass}"></span> <strong>${dev.device}</strong></div>
                        <div class="status-info-action">
                            <span>${statusText}</span>
                            ${disconnectBtn}
                        </div>
                        <div>${dev.ip || '-'}</div>
                    `;

                    // 为断开按钮添加事件监听
                    const btnDisconnect = div.querySelector('.btn-disconnect');
                    if (btnDisconnect) {
                        btnDisconnect.addEventListener('click', (e) => {
                            e.stopPropagation();
                            disconnectWifi(dev.device);
                        });
                    }

                    statusContainer.appendChild(div);
                });
            })
            .catch(err => {
                statusContainer.innerHTML = '<div class="loading text-error">获取状态失败: ' + err + '</div>';
            });
    }

    function scanWifi() {
        // 显示加载状态（如果列表为空）
        const hasExistingItems = wifiListEl.querySelectorAll('.wifi-item').length > 0;
        if (!hasExistingItems) {
            wifiListEl.innerHTML = '<div class="loading">正在扫描...</div>';
        }

        fetch('/api/wifi/scan')
            .then(res => res.json())
            .then(data => {
                // 如果没有WiFi网络
                if (data.length === 0) {
                    wifiListEl.innerHTML = '<div class="loading">未发现 WiFi 网络</div>';
                    return;
                }

                // 按信号强度排序
                data.sort((a, b) => (b.signal || 0) - (a.signal || 0));

                // 差异化更新：创建现有项的Map
                const existingItems = new Map();
                wifiListEl.querySelectorAll('.wifi-item').forEach(item => {
                    const ssid = item.getAttribute('data-ssid');
                    if (ssid) {
                        existingItems.set(ssid, item);
                    }
                });

                // 跟踪哪些SSID仍然存在
                const currentSSIDs = new Set(data.map(net => net.ssid));

                // 移除不再存在的WiFi网络
                existingItems.forEach((item, ssid) => {
                    if (!currentSSIDs.has(ssid)) {
                        item.remove();
                        existingItems.delete(ssid);
                    }
                });

                // 移除加载提示（如果存在）
                const loadingDiv = wifiListEl.querySelector('.loading');
                if (loadingDiv) {
                    loadingDiv.remove();
                }

                // 更新或创建WiFi项
                data.forEach((net, index) => {
                    const existingItem = existingItems.get(net.ssid);

                    const isSecure = net.security && net.security !== '--';
                    const iconClass = isSecure ? 'wifi-icon wifi-signal secured' : 'wifi-icon wifi-signal unsecured';
                    const icon = `<div class="${iconClass}"></div>`;
                    const signalBars = createSignalBars(net.signal || 0);

                    const itemHTML = `
                        ${icon}
                        <div class="wifi-details">
                            <div class="wifi-ssid">${net.ssid}</div>
                            <div class="wifi-info">
                                ${signalBars}
                                <span>${net.signal}%</span>
                                <span>•</span>
                                <span>${net.security}</span>
                            </div>
                        </div>
                        <div class="wifi-action">
                             <button class="btn btn-sm">连接</button>
                        </div>
                    `;

                    if (existingItem) {
                        // 更新现有项（仅当内容变化时）
                        if (existingItem.innerHTML !== itemHTML) {
                            existingItem.innerHTML = itemHTML;
                        }

                        // 确保位置正确（按排序后的顺序）
                        const currentIndex = Array.from(wifiListEl.children).indexOf(existingItem);
                        if (currentIndex !== index) {
                            if (index >= wifiListEl.children.length) {
                                wifiListEl.appendChild(existingItem);
                            } else {
                                wifiListEl.insertBefore(existingItem, wifiListEl.children[index]);
                            }
                        }
                    } else {
                        // 创建新项
                        const item = document.createElement('div');
                        item.className = 'wifi-item';
                        item.setAttribute('data-ssid', net.ssid);
                        item.innerHTML = itemHTML;

                        item.addEventListener('click', () => {
                            openConnectModal(net.ssid);
                        });

                        // 插入到正确位置
                        if (index >= wifiListEl.children.length) {
                            wifiListEl.appendChild(item);
                        } else {
                            wifiListEl.insertBefore(item, wifiListEl.children[index]);
                        }

                        existingItems.set(net.ssid, item);
                    }
                });
            })
            .catch(err => {
                wifiListEl.innerHTML = '<div class="loading">扫描失败: ' + err + '</div>';
            });
    }

    // 创建信号强度可视化条
    function createSignalBars(signal) {
        const strength = Math.min(100, Math.max(0, signal));
        let color;

        if (strength >= 70) {
            color = '#4caf50'; // 绿色 - 强
        } else if (strength >= 40) {
            color = '#ff9800'; // 橙色 - 中
        } else {
            color = '#f44336'; // 红色 - 弱
        }

        const bars = [];
        for (let i = 0; i < 4; i++) {
            const threshold = (i + 1) * 25;
            const opacity = strength >= threshold ? 1 : 0.2;
            bars.push(`<div class="signal-bar" style="background-color: ${color}; opacity: ${opacity};"></div>`);
        }

        return `<div class="signal-bars">${bars.join('')}</div>`;
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

    function disconnectWifi(device) {
        // 使用自定义弹窗而非原生confirm
        currentDisconnectDevice = device;
        disconnectDeviceName.textContent = device;
        disconnectModal.classList.add('show');
    }

    function performDisconnect(device) {
        // 禁用确认按钮，显示加载状态
        disconnectConfirmBtn.disabled = true;
        disconnectConfirmBtn.innerText = '断开中...';

        fetch('/api/wifi/disconnect', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ device: device })
        })
            .then(res => res.json())
            .then(data => {
                disconnectConfirmBtn.disabled = false;
                disconnectConfirmBtn.innerText = '确认断开';
                currentDisconnectDevice = '';

                if (data.error) {
                    alert('断开失败: ' + data.error);
                } else {
                    // 刷新状态和WiFi列表
                    fetchStatus();
                    setTimeout(scanWifi, 1000); // 延迟1秒后扫描，确保状态已更新
                }
            })
            .catch(err => {
                disconnectConfirmBtn.disabled = false;
                disconnectConfirmBtn.innerText = '确认断开';
                alert('请求错误: ' + err);
            });
    }

    // Initial scan
    scanWifi();
});
