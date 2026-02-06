# Network Manager Usage Guide

This document provides detailed instructions on how to use the Network Manager Addon in production environments. This document will be displayed in the "Documentation" tab of the Haddons Web interface, targeting end users (ToC product users).

## Quick Start

### Installation and Startup

1. Find Network Manager in the Haddons Web interface
2. Click the "Install" button to install the Addon
3. After installation, configure necessary options in the "Configuration" tab (if needed)
4. Click "Save" to save the configuration
5. Click the "Start" button to start the Addon

### Initial Configuration

When using for the first time, it is recommended to set the following options in the "Configuration" tab:

- **initial_wifi_ssid**: WiFi network name (SSID) for initial connection
- **initial_wifi_password**: WiFi password for initial connection
- **default_ip_method**: IP configuration method, `dhcp` (automatic) or `static` (static)
- **wifi_scan_interval**: WiFi scan interval (seconds), default 30 seconds
- **auto_reconnect**: Whether to auto reconnect, default `true`

## Configuration

### Configuration Options

In the "Configuration" tab of the Haddons Web interface, you can configure the following options:

| Option | Type | Description | Default | Required |
|--------|------|-------------|---------|----------|
| `wifi_scan_interval` | int | WiFi scan interval (seconds) | `30` | No |
| `auto_reconnect` | bool | Whether to auto reconnect | `true` | No |
| `default_ip_method` | str | Default IP configuration method (`dhcp` or `static`) | `dhcp` | No |
| `log_level` | str | Log level (`info`, `debug`, etc.) | `info` | No |
| `initial_wifi_ssid` | str | Initial WiFi name (SSID) to connect | - | No |
| `initial_wifi_password` | str | WiFi password | - | No |
| `initial_wifi_ip_address` | str | Static IP address (CIDR format, e.g., `192.168.1.100/24`) | - | No |
| `initial_wifi_gateway` | str | Gateway address (required when using static IP) | - | No |
| `initial_wifi_dns` | str | DNS servers (optional when using static IP, multiple separated by spaces) | - | No |

### Configuration Examples

**Example 1: Basic Configuration (DHCP)**

```json
{
  "initial_wifi_ssid": "MyWiFi",
  "initial_wifi_password": "mypassword",
  "default_ip_method": "dhcp",
  "wifi_scan_interval": 30,
  "auto_reconnect": true,
  "log_level": "info"
}
```

**Example 2: Static IP Configuration**

```json
{
  "initial_wifi_ssid": "MyWiFi",
  "initial_wifi_password": "mypassword",
  "default_ip_method": "static",
  "initial_wifi_ip_address": "192.168.1.100/24",
  "initial_wifi_gateway": "192.168.1.1",
  "initial_wifi_dns": "8.8.8.8 8.8.4.4",
  "wifi_scan_interval": 30,
  "auto_reconnect": true,
  "log_level": "info"
}
```

## Usage Guide

### Basic Operations

#### View Status

In the "Information" tab of the Haddons Web interface, you can view the Addon's running status, version information, etc.

#### View Logs

In the "Logs" tab of the Haddons Web interface, you can view the Addon's running logs in real-time to help troubleshoot issues.

#### Restart Service

If you need to restart the Addon, you can click the "Restart" button in the "Information" tab.

### Common Use Cases

#### Scenario 1: Initial WiFi Connection

1. Set `initial_wifi_ssid` and `initial_wifi_password` in the "Configuration" tab
2. Set `default_ip_method` to `dhcp` (automatic IP) or `static` (static IP)
3. If using static IP, also set `initial_wifi_ip_address`, `initial_wifi_gateway`, and `initial_wifi_dns`
4. Click "Save" to save the configuration
5. Click "Start" to start the Addon, and it will automatically connect to the specified WiFi network

#### Scenario 2: Monitor and Manage WiFi Connections

1. After the Addon starts, it will automatically scan available WiFi networks
2. You can view scan results and connection status through logs
3. If the connection is lost, the Addon will automatically reconnect (if `auto_reconnect` is set to `true`)

## Important Notes

### Pre-use Checklist

- ✅ Ensure the system meets the Addon's requirements (Ubuntu Server, NetworkManager service running)
- ✅ Check if the WiFi device is available and not occupied by other services
- ✅ Confirm network connection is normal (if needed)
- ✅ Ensure the container has sufficient permissions (requires `privileged` mode and `NET_ADMIN`, `SYS_ADMIN` capabilities)

### Important Reminders

- **Permission Requirements**: The container must use `privileged` mode and `host` network mode to access the host's network devices
- **Resource Usage**: The Addon has low resource usage, mainly relying on the NetworkManager service
- **Data Security**: Sensitive information such as WiFi passwords will be stored in the configuration, please keep it secure
- **Network Mode**: Must use `host` network mode, cannot use bridged network

## Troubleshooting

### Common Issues

#### Issue 1: Addon Cannot Start

**Possible Causes**:
- NetworkManager service is not running
- WiFi device is unavailable or occupied
- Insufficient permissions
- Configuration error

**Solutions**:
1. Check if the NetworkManager service is running on the host: `sudo systemctl status NetworkManager`
2. Check if the configuration in the "Configuration" tab is correct
3. View error messages in the "Logs" tab
4. Confirm the container has sufficient permissions (`privileged` mode and `NET_ADMIN`, `SYS_ADMIN` capabilities)

#### Issue 2: Cannot Connect to WiFi

**Possible Causes**:
- Incorrect WiFi password
- Weak WiFi signal
- Incorrect network configuration (static IP configuration error)
- WiFi device issue

**Solutions**:
1. Check if the WiFi password is correct
2. Check WiFi signal strength
3. If using static IP, check if IP address, gateway, and DNS configuration are correct
4. View logs for detailed error information
5. Check if the WiFi device is working properly

#### Issue 3: Frequent Connection Drops

**Possible Causes**:
- Unstable WiFi signal
- Network configuration issues
- Auto reconnect not enabled

**Solutions**:
1. Check WiFi signal strength
2. Ensure `auto_reconnect` is set to `true`
3. Check if network configuration is correct
4. View logs to understand the disconnection reason

### Getting Help

If you encounter issues that cannot be resolved, you can:

1. View the "Logs" tab for detailed error information
2. Check if the configuration is correct
3. Confirm NetworkManager service status
4. Contact technical support

## Updates and Maintenance

### Update Addon

When a new version is available, Haddons will prompt for updates in the "Information" tab. Click the "Update" button to upgrade to the latest version.

### Backup Configuration

It is recommended to regularly backup the configuration information in the "Configuration" tab for quick recovery when needed.

## License

MIT
