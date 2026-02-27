-- LinkNLink Edge 数据库初始化脚本

-- 创建设备表
CREATE TABLE IF NOT EXISTS devices (
    id VARCHAR(36) PRIMARY KEY,
    device_id VARCHAR(36) NOT NULL,
    user_id VARCHAR(255),
    name VARCHAR(255),
    manufacturer VARCHAR(255),
    model VARCHAR(255),
    device_class VARCHAR(100),
    device_type VARCHAR(100),
    capabilities JSON,
    attributes JSON,
    config JSON,
    status VARCHAR(50),
    last_seen TIMESTAMP NULL,
    source VARCHAR(50) DEFAULT 'mqtt',
    ha_device_id VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_device_id (device_id),
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_last_seen (last_seen),
    INDEX idx_source (source),
    INDEX idx_ha_device_id (ha_device_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 创建设备注册表
CREATE TABLE IF NOT EXISTS device_registry (
    id VARCHAR(36) PRIMARY KEY,
    device_id VARCHAR(36) NOT NULL,
    device_class VARCHAR(100),
    last_seen TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (device_id) REFERENCES devices(id) ON DELETE CASCADE,
    INDEX idx_device_id (device_id),
    INDEX idx_device_class (device_class)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 创建实体表
CREATE TABLE IF NOT EXISTS entities (
    id VARCHAR(36) PRIMARY KEY,
    entity_id VARCHAR(255) UNIQUE NOT NULL,
    user_id VARCHAR(255),
    unique_id VARCHAR(255) UNIQUE,
    name VARCHAR(255),
    domain VARCHAR(50) NOT NULL,
    device_class VARCHAR(100),
    capabilities JSON,
    attributes JSON,
    config JSON,
    device_id VARCHAR(36),
    available BOOLEAN DEFAULT TRUE,
    source VARCHAR(50) DEFAULT 'mqtt',
    ha_entity_id VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (device_id) REFERENCES devices(id) ON DELETE CASCADE,
    INDEX idx_entity_id (entity_id),
    INDEX idx_user_id (user_id),
    INDEX idx_unique_id (unique_id),
    INDEX idx_domain (domain),
    INDEX idx_device_id (device_id),
    INDEX idx_device_class (device_class),
    INDEX idx_source (source),
    INDEX idx_ha_entity_id (ha_entity_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 创建当前状态表
CREATE TABLE IF NOT EXISTS current_states (
    entity_id VARCHAR(255) PRIMARY KEY,
    state VARCHAR(255) NOT NULL,
    attributes JSON,
    last_changed TIMESTAMP NOT NULL,
    last_updated TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (entity_id) REFERENCES entities(entity_id) ON DELETE CASCADE,
    INDEX idx_last_changed (last_changed),
    INDEX idx_last_updated (last_updated)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 创建状态历史表
CREATE TABLE IF NOT EXISTS state_history (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    entity_id VARCHAR(255) NOT NULL,
    state VARCHAR(255) NOT NULL,
    attributes JSON,
    last_changed TIMESTAMP NOT NULL,
    last_updated TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (entity_id) REFERENCES entities(entity_id) ON DELETE CASCADE,
    INDEX idx_entity_time (entity_id, last_changed),
    INDEX idx_last_changed (last_changed)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 插入示例数据（可选）
-- INSERT INTO devices (id, device_id, name, manufacturer, model, status, last_seen) VALUES
-- ('device_001', 'device_001', 'Test Device', 'Test Manufacturer', 'Test Model', 'online', NOW());

-- INSERT INTO entities (id, entity_id, name, domain, device_id) VALUES
-- ('entity_001', 'sensor.temperature', 'Temperature Sensor', 'sensor', 'device_001');
