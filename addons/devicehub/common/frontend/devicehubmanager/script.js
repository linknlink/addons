// DeviceHub Manager 前端逻辑

(function () {
    'use strict';

    // 页面加载后初始化
    document.addEventListener('DOMContentLoaded', init);

    function init() {
        // 尝试获取用户信息，判断登录状态
        checkAuthAndShow();

        // 绑定登录表单
        var loginForm = document.getElementById('loginForm');
        if (loginForm) {
            loginForm.addEventListener('submit', function (e) {
                e.preventDefault();
                doLogin();
            });
        }
    }

    // 检查认证状态并显示对应页面
    function checkAuthAndShow() {
        fetch('/manager/account/info')
            .then(function (resp) { return resp.json(); })
            .then(function (data) {
                if (data.error === 0 && data.data) {
                    // 已有用户信息，直接显示管理页
                    showMainPage(data.data);
                } else {
                    // 尝试用 session 验证
                    trySessionAuth();
                }
            })
            .catch(function () {
                trySessionAuth();
            });
    }

    // 尝试 session 认证
    function trySessionAuth() {
        // 尝试获取 token，如果能获取说明已认证（haddons 模式）
        fetch('/manager/config/token')
            .then(function (resp) {
                if (resp.status === 401) {
                    // 需要登录
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
            document.getElementById('userInfo').textContent = userInfo.nickname || userInfo.email || userInfo.userid || '';
            document.getElementById('currentUser').textContent = userInfo.nickname || userInfo.email || '-';
        }

        // 加载 Token
        loadToken();
    }

    // 登录
    window.doLogin = function () {
        var email = document.getElementById('email').value.trim();
        var password = document.getElementById('password').value;
        var errorEl = document.getElementById('loginError');
        var btn = document.getElementById('loginBtn');

        if (!email || !password) {
            errorEl.textContent = '请填写邮箱和密码';
            errorEl.classList.remove('hidden');
            return;
        }

        btn.disabled = true;
        btn.textContent = '登录中...';
        errorEl.classList.add('hidden');

        fetch('/manager/account/login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email: email, password: password })
        })
            .then(function (resp) { return resp.json(); })
            .then(function (data) {
                btn.disabled = false;
                btn.textContent = '登录';
                if (data.error === 0) {
                    showMainPage({ userid: data.userid, nickname: data.nickname });
                } else {
                    errorEl.textContent = data.msg || '登录失败';
                    errorEl.classList.remove('hidden');
                }
            })
            .catch(function (err) {
                btn.disabled = false;
                btn.textContent = '登录';
                errorEl.textContent = '网络错误: ' + err.message;
                errorEl.classList.remove('hidden');
            });
    };

    // 登出
    window.doLogout = function () {
        fetch('/manager/account/logout', { method: 'POST' })
            .then(function () {
                showLoginPage();
            })
            .catch(function () {
                showLoginPage();
            });
    };

    // 加载 Token
    window.loadToken = function () {
        fetch('/manager/config/token')
            .then(function (resp) { return resp.json(); })
            .then(function (data) {
                if (data.status === 0 && data.result) {
                    document.getElementById('haToken').value = data.result.haToken || '';
                }
            })
            .catch(function () { });
    };

    // 保存 Token
    window.saveToken = function () {
        var token = document.getElementById('haToken').value.trim();
        var msgEl = document.getElementById('tokenMsg');

        if (!token) {
            showMsg(msgEl, '请输入 Token', 'error');
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
                    showMsg(msgEl, 'Token 保存成功', 'success');
                } else {
                    showMsg(msgEl, data.detail || '保存失败', 'error');
                }
            })
            .catch(function (err) {
                showMsg(msgEl, '网络错误: ' + err.message, 'error');
            });
    };

    // 切换 Token 可见性
    window.toggleTokenVisibility = function () {
        var input = document.getElementById('haToken');
        input.type = input.type === 'password' ? 'text' : 'password';
    };

    // 显示消息
    function showMsg(el, text, type) {
        el.textContent = text;
        el.className = 'msg ' + type;
        el.classList.remove('hidden');
        setTimeout(function () {
            el.classList.add('hidden');
        }, 4000);
    }
})();
