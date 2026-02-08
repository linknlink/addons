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

    // Disconnect confirmation modal elements
    const disconnectModal = document.getElementById('disconnect-modal');
    const disconnectDeviceName = document.getElementById('disconnect-device-name');
    const disconnectCancelBtn = document.getElementById('disconnect-cancel-btn');
    const disconnectConfirmBtn = document.getElementById('disconnect-confirm-btn');

    let currentSsid = '';
    let currentDisconnectDevice = ''; // Record device to disconnect

    // Load initial status
    fetchStatus();

    // Event Listeners
    scanBtn.addEventListener('click', scanWifi);

    cancelBtn.addEventListener('click', () => {
        modal.classList.remove('show');
        passwordInput.value = '';
    });

    connectConfirmBtn.addEventListener('click', connectToWifi);

    // Password show/hide toggle
    const togglePasswordBtn = document.getElementById('toggle-password');
    togglePasswordBtn.addEventListener('click', () => {
        const type = passwordInput.getAttribute('type');
        if (type === 'password') {
            passwordInput.setAttribute('type', 'text');
            togglePasswordBtn.setAttribute('aria-label', 'Hide IP');
        } else {
            passwordInput.setAttribute('type', 'password');
            togglePasswordBtn.setAttribute('aria-label', 'Show IP');
        }
    });

    ipMethodSelect.addEventListener('change', () => {
        if (ipMethodSelect.value === 'manual') {
            staticIpConfig.style.display = 'block';
        } else {
            staticIpConfig.style.display = 'none';
        }
    });

    // Disconnect modal event listeners
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

    // ========== Toast Notification System ==========
    const toastContainer = document.getElementById('toast-container');
    let toastIdCounter = 0;

    /**
     * Show Toast notification
     * @param {string} message - Message content
     * @param {string} type - Type: success, error, warning, info
     * @param {number} duration - Duration (ms), default 3000ms
     */
    function showToast(message, type = 'info', duration = 3000) {
        const toastId = `toast-${toastIdCounter++}`;

        // Create Toast element
        const toast = document.createElement('div');
        toast.className = `toast ${type}`;
        toast.id = toastId;

        // Select icon based on type
        const icons = {
            success: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"></polyline></svg>',
            error: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="15" y1="9" x2="9" y2="15"></line><line x1="9" y1="9" x2="15" y2="15"></line></svg>',
            warning: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>',
            info: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>'
        };

        toast.innerHTML = `
            <div class="toast-icon">${icons[type]}</div>
            <div class="toast-content">
                <div class="toast-message">${message}</div>
            </div>
            <button class="toast-close" aria-label="Close">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <line x1="18" y1="6" x2="6" y2="18"></line>
                    <line x1="6" y1="6" x2="18" y2="18"></line>
                </svg>
            </button>
            <div class="toast-progress" style="animation-duration: ${duration}ms;"></div>
        `;

        // Add to container
        toastContainer.appendChild(toast);

        // Close button event
        const closeBtn = toast.querySelector('.toast-close');
        closeBtn.addEventListener('click', () => {
            removeToast(toastId);
        });

        // Auto remove
        setTimeout(() => {
            removeToast(toastId);
        }, duration);

        return toastId;
    }

    /**
     * Remove Toast notification
     * @param {string} toastId - Toast ID
     */
    function removeToast(toastId) {
        const toast = document.getElementById(toastId);
        if (toast && !toast.classList.contains('removing')) {
            toast.classList.add('removing');
            // Wait for animation to end before removing
            setTimeout(() => {
                if (toast.parentNode) {
                    toast.parentNode.removeChild(toast);
                }
            }, 300);
        }
    }

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
                    statusContainer.innerHTML = '<div class="status-item">No network devices detected</div>';
                    return;
                }
                data.forEach(dev => {
                    const div = document.createElement('div');
                    div.className = 'status-item';

                    // Use SVG icons instead of emoji
                    let iconClass = 'device-icon ethernet-icon';
                    if (dev.type === 'wifi') iconClass = 'device-icon wifi-status-icon';

                    let statusText = dev.state;
                    let disconnectBtn = '';

                    if (dev.state === 'connected') {
                        statusText = `<span class="text-success">Connected</span> (${dev.connection})`;
                        // Add disconnect button only for WiFi
                        if (dev.type === 'wifi') {
                            disconnectBtn = `<button class="btn btn-sm btn-disconnect" data-device="${dev.device}">Disconnect</button>`;
                        }
                    } else if (dev.state === 'disconnected') {
                        statusText = '<span class="text-error">Disconnected</span>';
                    }

                    div.innerHTML = `
                        <div><span class="${iconClass}"></span> <strong>${dev.device}</strong></div>
                        <div class="status-info-action">
                            <span>${statusText}</span>
                            ${disconnectBtn}
                        </div>
                        <div>${dev.ip || '-'}</div>
                    `;

                    // Add event listener for disconnect button
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
                statusContainer.innerHTML = '<div class="loading text-error">Failed to get status: ' + err + '</div>';
            });
    }

    function scanWifi() {
        // Show loading state (if list is empty)
        const hasExistingItems = wifiListEl.querySelectorAll('.wifi-item').length > 0;
        if (!hasExistingItems) {
            wifiListEl.innerHTML = '<div class="loading">Scanning...</div>';
        }

        fetch('/api/wifi/scan')
            .then(res => res.json())
            .then(data => {
                // If no WiFi networks
                if (data.length === 0) {
                    wifiListEl.innerHTML = '<div class="loading">No WiFi networks found</div>';
                    return;
                }

                // Sort by signal strength
                data.sort((a, b) => (b.signal || 0) - (a.signal || 0));

                // Differential update: Create Map of existing items
                const existingItems = new Map();
                wifiListEl.querySelectorAll('.wifi-item').forEach(item => {
                    const ssid = item.getAttribute('data-ssid');
                    if (ssid) {
                        existingItems.set(ssid, item);
                    }
                });

                // Track which SSIDs still exist
                const currentSSIDs = new Set(data.map(net => net.ssid));

                // Remove WiFi networks that no longer exist
                existingItems.forEach((item, ssid) => {
                    if (!currentSSIDs.has(ssid)) {
                        item.remove();
                        existingItems.delete(ssid);
                    }
                });

                // Remove loading indicator (if exists)
                const loadingDiv = wifiListEl.querySelector('.loading');
                if (loadingDiv) {
                    loadingDiv.remove();
                }

                // Update or create WiFi items
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
                             <button class="btn btn-sm">Connect</button>
                        </div>
                    `;

                    if (existingItem) {
                        // Update existing item (only when content changes)
                        if (existingItem.innerHTML !== itemHTML) {
                            existingItem.innerHTML = itemHTML;
                        }

                        // Ensure correct position (in sorted order)
                        const currentIndex = Array.from(wifiListEl.children).indexOf(existingItem);
                        if (currentIndex !== index) {
                            if (index >= wifiListEl.children.length) {
                                wifiListEl.appendChild(existingItem);
                            } else {
                                wifiListEl.insertBefore(existingItem, wifiListEl.children[index]);
                            }
                        }
                    } else {
                        // Create new item
                        const item = document.createElement('div');
                        item.className = 'wifi-item';
                        item.setAttribute('data-ssid', net.ssid);
                        item.innerHTML = itemHTML;

                        item.addEventListener('click', () => {
                            openConnectModal(net.ssid);
                        });

                        // Insert at correct position
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
                wifiListEl.innerHTML = '<div class="loading">Scan failed: ' + err + '</div>';
            });
    }

    // Create signal strength visualization bars
    function createSignalBars(signal) {
        const strength = Math.min(100, Math.max(0, signal));
        let color;

        if (strength >= 70) {
            color = '#4caf50'; // Green - Strong
        } else if (strength >= 40) {
            color = '#ff9800'; // Orange - Medium
        } else {
            color = '#f44336'; // Red - Weak
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
                showToast("Please enter IP address and gateway", "warning", 3000);
                return;
            }
        }

        connectConfirmBtn.disabled = true;
        connectConfirmBtn.innerText = 'Connecting...';

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
                    showToast('Connection failed: ' + data.error, 'error', 4000);
                } else {
                    showToast('Connection command sent, waiting for connection...', 'success', 3000);
                    modal.classList.remove('show');
                    setTimeout(fetchStatus, 5000); // Wait a bit then refresh status
                }
            })
            .catch(err => {
                showToast('Request error: ' + err, 'error', 4000);
            })
            .finally(() => {
                connectConfirmBtn.disabled = false;
                connectConfirmBtn.innerText = 'Connect';
            });
    }

    function disconnectWifi(device) {
        // Use custom modal instead of native confirm
        currentDisconnectDevice = device;
        disconnectDeviceName.textContent = device;
        disconnectModal.classList.add('show');
    }

    function performDisconnect(device) {
        // Disable confirm button, show loading state
        disconnectConfirmBtn.disabled = true;
        disconnectConfirmBtn.innerText = 'Disconnecting...';

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
                disconnectConfirmBtn.innerText = 'Confirm';
                currentDisconnectDevice = '';

                if (data.error) {
                    showToast('Disconnect failed: ' + data.error, 'error', 4000);
                } else {
                    // Refresh status and WiFi list
                    fetchStatus();
                    setTimeout(scanWifi, 1000); // Delay 1 second before scanning to ensure status is updated
                }
            })
            .catch(err => {
                disconnectConfirmBtn.disabled = false;
                disconnectConfirmBtn.innerText = 'Confirm';
                alert('Request error: ' + err);
            });
    }

    // Initial scan
    scanWifi();
});
