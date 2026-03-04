// DeviceHub Manager 前端逻辑

(function () {
    'use strict';

    // DOM 加载后初始化
    document.addEventListener('DOMContentLoaded', init);

    function init() {
        checkAuthAndShow();

        // 绑定登录表单
        var loginForm = document.getElementById('loginForm');
        if (loginForm) {
            loginForm.addEventListener('submit', function (e) {
                e.preventDefault();
                doLogin();
            });
        }

        // 绑定侧边栏导航
        document.querySelectorAll('.nav-item').forEach(function (item) {
            item.addEventListener('click', function (e) {
                if (this.dataset.tab) {
                    e.preventDefault();
                    switchTab(this.dataset.tab);
                }
            });
        });
    }

    // 切换 Tab
    function switchTab(tabName) {
        document.querySelectorAll('.nav-item').forEach(function (el) {
            el.classList.remove('active');
        });
        document.querySelectorAll('.tab-pane').forEach(function (el) {
            el.classList.remove('active');
        });

        var navItem = document.querySelector('[data-tab="' + tabName + '"]');
        var pane = document.getElementById('tab-' + tabName);
        if (navItem) navItem.classList.add('active');
        if (pane) pane.classList.add('active');
    }

    // 检查认证状态
    function checkAuthAndShow() {
        fetch('/manager/account/info')
            .then(function (resp) { return resp.json(); })
            .then(function (data) {
                if (data.error === 0 && data.data) {
                    showMainPage(data.data);
                } else {
                    trySessionAuth();
                }
            })
            .catch(function () {
                trySessionAuth();
            });
    }

    // 尝试 session 认证（haddons 模式）
    function trySessionAuth() {
        fetch('/manager/config/token')
            .then(function (resp) {
                if (resp.status === 401) {
                    showLoginPage();
                    return null;
                }
                return resp.json();
            })
            .then(function (data) {
                if (data) {
                    showMainPage(null);
                    if (data.status === 0 && data.result) {
                        document.getElementById('haToken').value = data.result.haToken || '';
                        updateTokenStatus(data.result.haToken);
                    }
                }
            })
            .catch(function () {
                showLoginPage();
            });
    }

    // 显示登录页
    function showLoginPage() {
        document.getElementById('loginPage').classList.remove('hidden');
        document.getElementById('mainPage').classList.add('hidden');
    }

    // 显示管理页
    function showMainPage(userInfo) {
        document.getElementById('loginPage').classList.add('hidden');
        document.getElementById('mainPage').classList.remove('hidden');

        if (userInfo) {
            var displayName = userInfo.nickname || userInfo.email || userInfo.userid || '用户';
            document.getElementById('userInfo').textContent = displayName;
            document.getElementById('currentUser').textContent = displayName;
            document.getElementById('userAvatar').textContent = displayName.charAt(0).toUpperCase();
        }

        // 从配置加载系统信息（通过 token 接口间接获取）
        loadSystemInfo();
        // 加载 Token
        loadToken();
    }

    // 加载系统信息（authMode、haAddr、haStatus 由 devicehubmanager 自身提供，与 haddons 无关）
    function loadSystemInfo() {
        fetch('/manager/system/info')
            .then(function (r) { return r.json(); })
            .then(function (data) {
                if (data && data.data) {
                    var info = data.data;
                    if (info.authMode) {
                        document.getElementById('authMode').textContent = info.authMode;
                        var sidebarFooter = document.querySelector('.sidebar-footer');
                        if (sidebarFooter) {
                            if (info.authMode === 'haddons') {
                                sidebarFooter.style.display = 'none';
                            } else {
                                sidebarFooter.style.display = '';
                            }
                        }
                    }
                    if (info.haAddr) {
                        document.getElementById('haAddr').textContent = info.haAddr;
                        document.getElementById('haAddrDetail').textContent = info.haAddr;
                    }
                    // 使用后端实时探测的 HA 连接状态
                    if (info.haStatus) {
                        updateConnectionStatus(info.haStatus);
                    } else {
                        updateConnectionStatus('unknown');
                    }
                    // 控制 Debug 页面导航可见性
                    if (info.debugPageEnable) {
                        var debugNav = document.getElementById('nav-debug');
                        if (debugNav) debugNav.classList.remove('hidden');
                    }

                    // 获取并展示激活状态与 License
                    fetchActivationStatus();
                    loadLicenseStatus();
                }
            })
            .catch(function () {
                updateConnectionStatus('unknown');
            });
    }

    // 获取激活状态
    function fetchActivationStatus() {
        fetch('/manager/activation/status')
            .then(function (r) { return r.json(); })
            .then(function (data) {
                if (data.error === 0 && data.data) {
                    renderActivation(data.data);
                }
            })
            .catch(function (e) {
                console.error('获取激活状态失败', e);
            });
    }

    // 手动同步激活状态
    window.syncActivation = function () {
        var btn = document.getElementById('syncActBtn');
        var text = btn.querySelector('.btn-text');
        btn.disabled = true;
        text.textContent = '同步中...';

        fetch('/manager/activation/sync', { method: 'POST' })
            .then(function (r) { return r.json(); })
            .then(function (data) {
                btn.disabled = false;
                text.textContent = '同步';
                if (data.error === 0 && data.data) {
                    renderActivation(data.data);
                }
            })
            .catch(function (e) {
                btn.disabled = false;
                text.textContent = '同步';
            });
    };

    // 重新获取 License
    window.fetchLicense = function () {
        fetch('/manager/license/get', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ mac: document.getElementById('actDid').textContent.substring(20) || '' }) // 粗略提取MAC，正常业务场景会有更好方式
        })
            .then(function (r) { return r.json(); })
            .then(function (data) {
                if (data.error === 0) {
                    loadLicenseStatus();
                    alert('获取成功');
                } else {
                    alert('获取失败: ' + (data.msg || '未知错误'));
                }
            })
            .catch(function (e) {
                alert('获取失败: ' + e.message);
            });
    };

    // 加载 License 状态
    function loadLicenseStatus() {
        var el = document.getElementById('licState');
        if (!el) return;
        fetch('/manager/license/status')
            .then(function (r) { return r.json(); })
            .then(function (data) {
                if (data.error === 0 && data.data && data.data.length > 0) {
                    el.innerHTML = '✅ 已获取';
                } else {
                    el.innerHTML = '❌ 未获取';
                }
            })
            .catch(function () {
                el.innerHTML = '获取失败';
            });
    }

    // 渲染激活信息
    function renderActivation(info) {
        var sumEl = document.getElementById('summaryActInfo');
        var stateEl = document.getElementById('actState');
        var didEl = document.getElementById('actDid');
        var durEl = document.getElementById('actDuration');
        var syncEl = document.getElementById('actSyncTime');

        if (didEl) didEl.textContent = info.devdid || '-';

        var start = info.activate_start ? new Date(info.activate_start * 1000).toLocaleString() : '-';
        var end = info.activate_end ? new Date(info.activate_end * 1000).toLocaleString() : '-';
        if (durEl) durEl.textContent = (info.activate_start || info.activate_end) ? (start + ' ~ ' + end) : '-';

        if (syncEl) syncEl.textContent = info.last_sync_time ? new Date(info.last_sync_time * 1000).toLocaleString() : '-';

        if (info.activated) {
            var days = 0;
            if (info.activate_end) {
                days = Math.floor((info.activate_end - (Date.now() / 1000)) / 86400);
            }
            if (sumEl) sumEl.innerHTML = '<span style="color: #10b981;">✅ 已激活</span> <div style="font-size:12px;color:#6b7280;margin-top:2px;">剩余 ' + Math.max(0, days) + ' 天</div>';
            if (stateEl) {
                stateEl.innerHTML = '<span style="color: #10b981; display:inline-flex; align-items:center; gap:6px;"><span class="conn-dot online"></span>已激活</span>';
            }
        } else {
            if (sumEl) sumEl.innerHTML = '<span style="color: #ef4444;">❌ 未激活</span>';
            if (stateEl) {
                stateEl.innerHTML = '<span style="color: #ef4444; display:inline-flex; align-items:center; gap:6px;"><span class="conn-dot offline"></span>未激活</span>';
            }
        }
    }

    // 更新连接状态
    function updateConnectionStatus(status) {
        var dot = document.getElementById('haDot');
        var badge = document.getElementById('haBadge');
        if (status === 'online') {
            dot.className = 'conn-dot online';
            badge.className = 'conn-badge online';
            badge.textContent = '在线';
        } else if (status === 'offline') {
            dot.className = 'conn-dot offline';
            badge.className = 'conn-badge offline';
            badge.textContent = '离线';
        } else {
            dot.className = 'conn-dot';
            badge.className = 'conn-badge';
            badge.textContent = '未知';
        }
    }

    // 更新 Token 状态显示
    function updateTokenStatus(token) {
        var el = document.getElementById('tokenStatus');
        if (el) {
            if (token && token.length > 10) {
                el.textContent = '已配置';
                el.style.color = '#10b981';
            } else {
                el.textContent = '未配置';
                el.style.color = '#f59e0b';
            }
        }
    }

    // 登录
    window.doLogin = function () {
        var email = document.getElementById('email').value.trim();
        var password = document.getElementById('password').value;
        var clusterEl = document.getElementById('cluster');
        var cluster = clusterEl ? clusterEl.value : 'eu';
        var errorEl = document.getElementById('loginError');
        var btn = document.getElementById('loginBtn');

        if (!email || !password) {
            showAlert(errorEl, '请填写邮箱和密码', 'error');
            return;
        }

        btn.disabled = true;
        btn.querySelector('.btn-text').textContent = '登录中...';
        errorEl.classList.add('hidden');

        fetch('/manager/account/login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email: email, password: password, cluster: cluster })
        })
            .then(function (resp) { return resp.json(); })
            .then(function (data) {
                btn.disabled = false;
                btn.querySelector('.btn-text').textContent = '登录';
                if (data.error === 0) {
                    showMainPage({ userid: data.userid, nickname: data.nickname, email: email });
                } else {
                    showAlert(errorEl, data.msg || '登录失败，请检查邮箱和密码', 'error');
                }
            })
            .catch(function (err) {
                btn.disabled = false;
                btn.querySelector('.btn-text').textContent = '登录';
                showAlert(errorEl, '网络错误: ' + err.message, 'error');
            });
    };

    // 登出
    window.doLogout = function () {
        fetch('/manager/account/logout', { method: 'POST' })
            .then(function () { showLoginPage(); })
            .catch(function () { showLoginPage(); });
    };

    // 加载 Token
    window.loadToken = function () {
        fetch('/manager/config/token')
            .then(function (resp) { return resp.json(); })
            .then(function (data) {
                if (data.status === 0 && data.result) {
                    var token = data.result.haToken || '';
                    document.getElementById('haToken').value = token;
                    updateTokenStatus(token);
                }
            })
            .catch(function () { });
    };

    // 保存 Token
    window.saveToken = function () {
        var token = document.getElementById('haToken').value.trim();
        var msgEl = document.getElementById('tokenMsg');

        if (!token) {
            showAlert(msgEl, '请输入 Token', 'error');
            return;
        }

        fetch('/manager/config/token', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ haToken: token })
        })
            .then(function (resp) { return resp.json(); })
            .then(function (data) {
                if (data.status === 0) {
                    showAlert(msgEl, 'Token 保存成功', 'success');
                    updateTokenStatus(token);
                } else {
                    showAlert(msgEl, data.detail || '保存失败', 'error');
                }
            })
            .catch(function (err) {
                showAlert(msgEl, '网络错误: ' + err.message, 'error');
            });
    };

    // 切换 Token 可见性
    window.toggleTokenVisibility = function () {
        var input = document.getElementById('haToken');
        input.type = input.type === 'password' ? 'text' : 'password';
    };

    // 显示提示信息（带自动消失）
    function showAlert(el, text, type) {
        el.textContent = text;
        el.className = 'alert alert-' + type;
        el.classList.remove('hidden');
        setTimeout(function () {
            el.classList.add('hidden');
        }, 4000);
    }

})();
