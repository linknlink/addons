// 用户配置文件
const USER_CONFIG = {
    // 默认userid
    userid: '10004a1601000000000055c138652925'
};

// 尝试从localStorage获取用户ID（如果存在）
if (typeof localStorage !== 'undefined') {
    const savedUserId = localStorage.getItem('ha2devicehub_userid');
    if (savedUserId) {
        USER_CONFIG.userid = savedUserId;
    }
}

// 尝试从外部文件获取用户ID（如果可以访问）
fetch('/ha2devicehub/frontend/userid.txt')
    .then(response => {
        if (response.ok) {
            return response.text();
        }
        throw new Error('无法获取userid文件');
    })
    .then(userid => {
        // 去除可能的换行符和空格
        const trimmedUserid = userid.trim();
        if (trimmedUserid) {
            USER_CONFIG.userid = trimmedUserid;
            // 同时保存到localStorage
            if (typeof localStorage !== 'undefined') {
                localStorage.setItem('ha2devicehub_userid', trimmedUserid);
            }
        }
    })
    .catch(error => {
        console.log('无法从文件加载userid，使用默认值或localStorage中的值:', error);
    });