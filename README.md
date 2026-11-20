# Panelium

Panelium All-In-One VPN Panel release artifacts.

## Download

Current installer for Ubuntu 26.04 amd64: **v0.1.0-rc.20261120.2**

- [install.sh](https://github.com/AmirLucifer/Panelium/releases/download/v0.1.0-rc.20261120.2/install.sh)
- [panelium](https://github.com/AmirLucifer/Panelium/releases/download/v0.1.0-rc.20261120.2/panelium)
- [Release notes](https://github.com/AmirLucifer/Panelium/releases/tag/v0.1.0-rc.20261120.2)

Save both files in the same directory on the server, then run:

```sh
chmod +x install.sh panelium
sudo ./install.sh
```

Choose **1** in the installer menu. The binary includes the offline installation payload.

The repository also tracks the binary using Git LFS. If you clone the repository, run `git lfs pull` if your checkout shows a small pointer. The download links above provide the actual files directly.
