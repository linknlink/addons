# HACS Installer User Guide

## Introduction
HACS Installer is a utility tool designed to help you quickly install HACS (Home Assistant Community Store) into your Home Assistant instance.

## Installation Steps

1. **Configure Path**: Before installing this Addon, please ensure your Home Assistant configuration path. The default path is `/usr/share/hassio/homeassistant`. If your Home Assistant is installed in a different location, please modify `HA_CONFIG_PATH` in the configuration.
2. **Start Service**: Install and start HACS Installer.
3. **Access Interface**: Click "Access Service" or visit `http://<Your-IP>:8202` directly.

## Operation Guide

1. **Check Status**: After opening the Web interface, the tool will automatically check if HACS is installed.
2. **Start Installation**: If not installed, click the "Install HACS" button.
   - The tool will automatically download the latest version of HACS from GitHub.
   - Unzip and install it to the `custom_components/hacs` directory.
3. **Complete Installation**: After installation is complete, the interface will prompt success.

## Uninstall HACS

If you need to uninstall HACS, please click the "Uninstall HACS" button on the Web interface.
- The tool will remove the `custom_components/hacs` directory.
- You still need to restart Home Assistant after uninstallation.

## Next Steps

After installation is complete, you need to:
1. **Restart Home Assistant**: You must restart for HACS to take effect.
2. **Add Integration**:
   - Go to Home Assistant -> Settings -> Devices & Services -> Add Integration.
   - Search for "HACS".
   - Follow the prompts to complete GitHub authorization.

## FAQ

**Q: What if installation fails?**
A: Please check:
- Whether the Home Assistant configuration path is mounted correctly.
- Whether the network is normal (needs access to GitHub).

**Q: Cannot find HACS integration after installation?**
A: Please ensure you have restarted Home Assistant and cleared your browser cache.
