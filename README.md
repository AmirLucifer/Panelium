# Panelium

Panelium is an all-in-one VPN administration panel for OpenVPN, WireGuard, V2Ray/Xray, L2TP/IPsec, and SSTP.

## Install on Ubuntu 26.04 amd64

```sh
curl -fL --retry 3 -O https://github.com/AmirLucifer/Panelium/releases/download/v1.0.0/install.sh -O https://github.com/AmirLucifer/Panelium/releases/download/v1.0.0/panelium && chmod +x install.sh panelium && sudo bash install.sh
```

For offline installation, download `install.sh` and `panelium` on a connected machine and copy them to the same directory on the server. From that directory, run `chmod +x install.sh panelium && sudo ./install.sh install`.

The repository also tracks the binary using Git LFS. The release downloads provide the executable directly.

[Panelium v1.0.0 release](https://github.com/AmirLucifer/Panelium/releases/tag/v1.0.0)
