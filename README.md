# Panelium

Panelium is an all-in-one VPN administration panel for OpenVPN, WireGuard, V2Ray/Xray, L2TP/IPsec, and SSTP.

## Install on Ubuntu 26.04 amd64

```sh
mkdir -p panelium-install
cd panelium-install
base=https://github.com/AmirLucifer/Panelium/releases/download/v1.0.0
curl -fL --retry 3 -O "$base/panelium" -O "$base/install.sh" -O "$base/SHA256SUMS"
sha256sum -c SHA256SUMS && chmod +x panelium install.sh && sudo ./install.sh install
```

For an offline server, run the download commands on a connected machine and copy `panelium`, `install.sh`, and `SHA256SUMS` to the same directory on the server. From that directory, run the checksum and install commands above.

The repository also tracks the binary using Git LFS. The release downloads provide the executable directly.

[Panelium v1.0.0 release](https://github.com/AmirLucifer/Panelium/releases/tag/v1.0.0)
