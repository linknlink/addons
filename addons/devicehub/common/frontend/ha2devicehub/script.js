// 全局变量
let haDevices = [];
let addedDevices = []; // 保留此变量以避免代码错误，但不再使用
let currentToken = '';
let currentSection = 'devices';
let currentUserID = USER_CONFIG.userid; // 从配置文件获取userid

// DOM 元素
const elements = {
    // 导航元素
    navItems: document.querySelectorAll('.nav-item'),
    sections: document.querySelectorAll('.section'),
    sidebarToggle: document.querySelector('.sidebar-toggle'),
    
    // 统计元素
    totalDevices: document.getElementById('totalDevices'),
    addedDevicesCount: document.getElementById('addedDevicesCount'),
    connectionStatus: document.getElementById('connectionStatus'),
    lastActive: document.getElementById('lastActive'),
    connectionStatusDot: document.getElementById('connectionStatusDot'),
    connectionStatusText: document.getElementById('connectionStatusText'),
    
    // 表单元素
    haToken: document.getElementById('haToken'),
    toggleToken: document.getElementById('toggleToken'),
    saveToken: document.getElementById('saveToken'),
    tokenStatus: document.getElementById('tokenStatus'),
    haAddress: document.getElementById('haAddress'),
    connectionStatusBadge: document.getElementById('connectionStatusBadge'),
    
    // 设备管理元素
    refreshDevices: document.getElementById('refreshDevices'),
    refreshStatus: document.getElementById('refreshStatus'),
    deviceSearch: document.getElementById('deviceSearch'),
    deviceList: document.getElementById('deviceList'),
    tabBtns: document.querySelectorAll('.tab-btn'),
    tabPanes: document.querySelectorAll('.tab-pane'),
    
    // 模态框元素
    deviceModal: document.getElementById('deviceModal'),
    modalTitle: document.getElementById('modalTitle'),
    deviceDetails: document.getElementById('deviceDetails'),
    addDevice: document.getElementById('addDevice'),
    cancelAdd: document.getElementById('cancelAdd'),
    closeModal: document.getElementById('closeModal'),
    notification: document.getElementById('notification')
};

// API 基础URL
const API_BASE = '/ha2devicehub';

// 初始化
document.addEventListener('DOMContentLoaded', function() {
    initializeApp();
    bindEvents();
    loadInitialData();
});

// 初始化应用
function initializeApp() {
    console.log('HA2Devicehub 前端应用初始化');
    showNotification('应用已加载', 'info');
}

// 绑定事件
function bindEvents() {
    // 导航事件
    elements.navItems.forEach(item => {
        item.addEventListener('click', function(e) {
            e.preventDefault();
            const section = this.dataset.section;
            switchSection(section);
        });
    });
    
    // 侧边栏切换
    if (elements.sidebarToggle) {
        elements.sidebarToggle.addEventListener('click', toggleSidebar);
    }
    
    // 标签页切换（简化处理）
    // 由于已移除"已添加设备"标签页，这里简化处理逻辑
    elements.tabBtns.forEach(btn => {
        btn.addEventListener('click', function() {
            // 只有一个标签页，所以只需处理激活状态
            elements.tabBtns.forEach(b => b.classList.remove('active'));
            this.classList.add('active');
            
            // 激活对应的面板
            elements.tabPanes.forEach(pane => pane.classList.remove('active'));
            document.getElementById('available-devices').classList.add('active');
        });
    });
    
    // Token 相关事件
    if (elements.toggleToken) {
        elements.toggleToken.addEventListener('click', toggleTokenVisibility);
    }
    if (elements.saveToken) {
        elements.saveToken.addEventListener('click', saveToken);
    }
    
    // 状态刷新事件
    if (elements.refreshStatus) {
        elements.refreshStatus.addEventListener('click', refreshHAStatus);
    }
    if (elements.refreshDevices) {
        // 修复刷新按钮事件绑定，确保正确绑定到所有具有该ID的元素
        document.querySelectorAll('#refreshDevices').forEach(button => {
            button.addEventListener('click', refreshDeviceList);
        });
    }
    
    // 设备搜索事件
    if (elements.deviceSearch) {
        elements.deviceSearch.addEventListener('input', debounce(filterDevices, 300));
    }
    
    // 模态框事件
    if (elements.closeModal) {
        elements.closeModal.addEventListener('click', closeModal);
    }
    if (elements.cancelAdd) {
        elements.cancelAdd.addEventListener('click', closeModal);
    }
    if (elements.addDevice) {
        elements.addDevice.addEventListener('click', addSelectedDevice);
    }
    
    // 点击模态框外部关闭
    if (elements.deviceModal) {
        elements.deviceModal.addEventListener('click', function(e) {
            if (e.target === elements.deviceModal) {
                closeModal();
            }
        });
    }
}

// 加载初始数据
async function loadInitialData() {
    await refreshHAStatus();
    await refreshDeviceList();
    updateStats();
}

// 切换区域
function switchSection(sectionName) {
    // 更新导航状态
    elements.navItems.forEach(item => {
        item.classList.remove('active');
        if (item.dataset.section === sectionName) {
            item.classList.add('active');
        }
    });
    
    // 更新内容区域
    elements.sections.forEach(section => {
        section.classList.remove('active');
        if (section.id === `${sectionName}-section`) {
            section.classList.add('active');
        }
    });
    
    currentSection = sectionName;
    
    // 如果切换到设备管理区域，刷新设备列表
    if (sectionName === 'devices') {
        // 确保在切换到设备区域时刷新设备列表
        setTimeout(refreshDeviceList, 100);
    }
}

// 切换标签页
function switchTab(tabName) {
    // 更新标签按钮状态
    elements.tabBtns.forEach(btn => {
        btn.classList.remove('active');
        if (btn.dataset.tab === tabName) {
            btn.classList.add('active');
        }
    });
    
    // 更新标签内容
    elements.tabPanes.forEach(pane => {
        pane.classList.remove('active');
        if (pane.id === `${tabName}-devices`) {
            pane.classList.add('active');
        }
    });
    
    // 当切换到已添加设备标签时，不再执行任何操作
    // 因为根据要求已添加设备列表已被移除
}

// 切换侧边栏
function toggleSidebar() {
    elements.sidebar.classList.toggle('open');
}

// 更新统计信息
function updateStats() {
    if (elements.totalDevices) {
        elements.totalDevices.textContent = haDevices.length;
    }
    // 不再显示已添加设备数量
    if (elements.addedDevicesCount) {
        elements.addedDevicesCount.textContent = '0';
    }
}

// Token 可见性切换
function toggleTokenVisibility() {
    const input = elements.haToken;
    const icon = elements.toggleToken.querySelector('i');
    
    if (input.type === 'password') {
        input.type = 'text';
        icon.className = 'fas fa-eye-slash';
    } else {
        input.type = 'password';
        icon.className = 'fas fa-eye';
    }
}

// 保存 Token
async function saveToken() {
    const token = elements.haToken.value.trim();
    
    if (!token) {
        showStatusMessage('请输入 HA Token', 'error');
        return;
    }
    
    try {
        const response = await fetch(`${API_BASE}/settoken`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'userid': currentUserID
            },
            body: JSON.stringify({ haToken: token })
        });
        
        const result = await response.text();
        const data = JSON.parse(result);
        
        if (data.status === 0) {
            currentToken = token;
            showStatusMessage('Token 保存成功', 'success');
            await refreshHAStatus();
        } else {
            showStatusMessage(`保存失败: ${data.detail}`, 'error');
        }
    } catch (error) {
        console.error('保存 Token 失败:', error);
        showStatusMessage('保存失败: 网络错误', 'error');
    }
}

// 刷新 HA 状态
async function refreshHAStatus() {
    try {
        const response = await fetch(`${API_BASE}/hainfo`, {
            headers: {
                'userid': currentUserID
            }
        });
        const result = await response.text();
        const data = JSON.parse(result);
        
        if (data.status === 0) {
            const info = data.data;
            
            // 更新连接状态
            const isOnline = info.active;
            if (elements.connectionStatus) {
                elements.connectionStatus.textContent = isOnline ? '在线' : '离线';
            }
            if (elements.connectionStatusText) {
                elements.connectionStatusText.textContent = isOnline ? '在线' : '离线';
            }
            if (elements.connectionStatusDot) {
                elements.connectionStatusDot.className = `status-dot ${isOnline ? 'online' : 'offline'}`;
            }
            
            // 更新 HA 地址
            if (elements.haAddress) {
                elements.haAddress.textContent = info.ipaddr || '-';
            }
            
            // 更新最后活跃时间
            if (elements.lastActive) {
                if (info.last_active_time) {
                    const lastActive = new Date(info.last_active_time * 1000);
                    elements.lastActive.textContent = lastActive.toLocaleString();
                } else {
                    elements.lastActive.textContent = '-';
                }
            }
            
            // 如果状态信息中有 token，填充到输入框
            if (info.token && elements.haToken && !elements.haToken.value) {
                elements.haToken.value = info.token;
                currentToken = info.token;
            }
            
            // 更新统计信息
            updateStats();
        } else {
            showStatusMessage(`获取状态失败: ${data.detail}`, 'error');
        }
    } catch (error) {
        console.error('获取 HA 状态失败:', error);
        showStatusMessage('获取状态失败: 网络错误', 'error');
    }
}

// 刷新设备列表
async function refreshDeviceList() {
    if (elements.deviceList) {
        elements.deviceList.innerHTML = '<div class="loading"><i class="fas fa-spinner fa-spin"></i> 加载中...</div>';
    }
    
    try {
        const response = await fetch(`${API_BASE}/gethaentity`, {
            headers: {
                'userid': currentUserID
            }
        });
        const result = await response.text();
        const data = JSON.parse(result);
        
        if (data.status === 0) {
            haDevices = data.data || [];
            renderDeviceList();
            updateStats();
        } else {
            if (elements.deviceList) {
                elements.deviceList.innerHTML = `<div class="empty-state"><i class="fas fa-exclamation-triangle"></i><p>获取设备列表失败: ${data.detail}</p></div>`;
            }
        }
    } catch (error) {
        console.error('获取设备列表失败:', error);
        if (elements.deviceList) {
            elements.deviceList.innerHTML = '<div class="empty-state"><i class="fas fa-exclamation-triangle"></i><p>获取设备列表失败: 网络错误</p></div>';
        }
    }
}

// 渲染设备列表
function renderDeviceList() {
    if (!elements.deviceList) return;
    
    if (haDevices.length === 0) {
        elements.deviceList.innerHTML = '<div class="empty-state"><i class="fas fa-inbox"></i><p>暂无可用设备</p></div>';
        return;
    }
    
    const searchTerm = elements.deviceSearch ? elements.deviceSearch.value.toLowerCase() : '';
    const filteredDevices = haDevices.filter(device => {
        const entityId = device.entity_id || '';
        const name = device.name || entityId;
        return name.toLowerCase().includes(searchTerm) || entityId.toLowerCase().includes(searchTerm);
    });
    
    elements.deviceList.innerHTML = filteredDevices.map(device => {
        const entityId = device.entity_id || '';
        const name = device.name || entityId;
        // 根据新的数据格式获取设备类型
        const deviceType = device.entitytag || entityId.split('.')[0] || 'unknown';
        
        // 不再检查是否已添加，所有设备都显示为可添加状态
        const isAdded = false;
        
        return `
            <div class="device-item ${isAdded ? 'selected' : ''}" data-entity-id="${entityId}">
                <div class="device-header">
                    <div class="device-name">${name}</div>
                    <div class="device-type">${deviceType}</div>
                </div>
                <div class="device-info">
                    <div><strong>实体ID:</strong> ${entityId}</div>
                    <!-- 根据新的数据格式调整显示字段 -->
                    <div><strong>设备ID:</strong> ${device.device_id || '-'}</div>
                    <div><strong>平台:</strong> ${device.platform || '-'}</div>
                </div>
                <div class="device-actions">
                    <button class="btn-primary btn-small" onclick="showDeviceDetails('${entityId}')">
                        <i class="fas fa-info-circle"></i> 详情
                    </button>
                    ${isAdded ? 
                        '<button class="btn-secondary btn-small" disabled><i class="fas fa-check"></i> 已添加</button>' :
                        `<button class="btn-primary btn-small" onclick="addDevice('${entityId}')">
                            <i class="fas fa-plus"></i> 添加
                        </button>`
                    }
                </div>
            </div>
        `;
    }).join('');
}

// 过滤设备
function filterDevices() {
    renderDeviceList();
}

// 显示设备详情
function showDeviceDetails(entityId) {
    const device = haDevices.find(d => (d.entity_id || '') === entityId);
    if (!device) return;
    
    elements.modalTitle.textContent = device.name || device.entity_id || entityId;
    
    const details = `
        <div class="device-detail">
            <h4>基本信息</h4>
            <div class="detail-item">
                <strong>实体ID:</strong> ${device.entity_id || '-'}
            </div>
            <div class="detail-item">
                <strong>设备名称:</strong> ${device.name || '-'}
            </div>
            <div class="detail-item">
                <strong>设备标签:</strong> ${device.entitytag || '-'}
            </div>
            <div class="detail-item">
                <strong>设备ID:</strong> ${device.device_id || '-'}
            </div>
            <div class="detail-item">
                <strong>平台:</strong> ${device.platform || '-'}
            </div>
            <div class="detail-item">
                <strong>设备类型:</strong> ${device.entitytag || (device.entity_id || '').split('.')[0] || '-'}
            </div>
            
            <h4>详细信息</h4>
            <div class="attributes-list">
                ${Object.entries(device).map(([key, value]) => 
                    `<div class="detail-item"><strong>${key}:</strong> ${JSON.stringify(value)}</div>`
                ).join('')}
            </div>
        </div>
    `;
    
    elements.deviceDetails.innerHTML = details;
    elements.deviceModal.dataset.entityId = entityId;
    elements.deviceModal.style.display = 'block';
}

// 转发到HA的处理函数
async function forwardToHA(domain, service, serviceData) {
    try {
        const response = await fetch(`${API_BASE}/api/services/${domain}/${service}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'userid': currentUserID
            },
            body: JSON.stringify(serviceData)
        });
        
        const result = await response.text();
        const data = JSON.parse(result);
        
        if (data.status === 0) {
            showNotification('命令执行成功', 'success');
        } else {
            showNotification(`执行失败: ${data.detail}`, 'error');
        }
        
        return data;
    } catch (error) {
        console.error('转发到HA失败:', error);
        showNotification('执行失败: 网络错误', 'error');
    }
}

// 添加设备
async function addDevice(entityId) {
    const device = haDevices.find(d => (d.entity_id || '') === entityId);
    if (!device) return;
    
    try {
        const response = await fetch(`${API_BASE}/addhaentity`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'userid': currentUserID
            },
            body: JSON.stringify([entityId])
        });
        
        const result = await response.text();
        const data = JSON.parse(result);
        
        if (data.status === 0) {
            // 不再将设备添加到addedDevices数组
            showNotification('设备添加成功', 'success');
            // 直接刷新设备列表而不是重新渲染
            await refreshDeviceList();
        } else {
            showNotification(`添加失败: ${data.detail}`, 'error');
        }
    } catch (error) {
        console.error('添加设备失败:', error);
        showNotification('添加失败: 网络错误', 'error');
    }
}

// 添加选中的设备（从模态框）
function addSelectedDevice() {
    const entityId = elements.deviceModal.dataset.entityId;
    if (entityId) {
        addDevice(entityId);
        closeModal();
    }
}

// 关闭模态框
function closeModal() {
    elements.deviceModal.style.display = 'none';
    delete elements.deviceModal.dataset.entityId;
}

// 渲染已添加设备
function renderAddedDevices() {
    // 根据要求，移除已添加设备的显示
    return;
}

// 移除设备
function removeDevice(entityId) {
    // 根据要求，移除设备功能不再需要
    return;
}

// 显示状态消息
function showStatusMessage(message, type) {
    if (elements.tokenStatus) {
        elements.tokenStatus.textContent = message;
        elements.tokenStatus.className = `status-message ${type}`;
        elements.tokenStatus.style.display = 'block';
        
        setTimeout(() => {
            elements.tokenStatus.style.display = 'none';
        }, 3000);
    }
}

// 显示通知
function showNotification(message, type = 'info') {
    if (elements.notification) {
        elements.notification.textContent = message;
        elements.notification.className = `notification ${type} show`;
        
        setTimeout(() => {
            elements.notification.classList.remove('show');
        }, 3000);
    }
}

// 工具函数：格式化时间
function formatTime(timestamp) {
    return new Date(timestamp * 1000).toLocaleString();
}

// 工具函数：防抖
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}
