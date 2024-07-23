#!/bin/bash

set -e  # スクリプトのエラーチェックを有効にする

# 更新と基本パッケージのインストール
sudo apt update
sudo apt upgrade -y
sudo apt install -y curl gnupg lsb-release

# Dockerのインストール
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER

# Docker Composeのインストール
sudo curl -L "https://github.com/docker/compose/releases/download/2.18.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Gitのインストール
sudo apt install -y git

# OpenSSHサーバーのインストール
sudo apt install -y openssh-server
sudo systemctl start ssh
sudo systemctl enable ssh

# sshdの設定変更
SSHD_CONFIG="/etc/ssh/sshd_config"

# 設定のバックアップ
sudo cp $SSHD_CONFIG ${SSHD_CONFIG}.bak

# 設定の変更
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' $SSHD_CONFIG
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' $SSHD_CONFIG
sudo sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords no/' $SSHD_CONFIG
sudo sed -i 's/#ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/' $SSHD_CONFIG

# IPv6のみをリッスンするように設定
echo "AddressFamily inet6" | sudo tee -a $SSHD_CONFIG

# 設定を反映
sudo systemctl restart ssh

# Gitリポジトリのクローン
REPO_URL="https://github.com/sugipamo/yuunas"
CLONE_DIR="$HOME/yuunas_work"

# クローン先ディレクトリが存在しない場合のみクローン
if [ ! -d "$CLONE_DIR" ]; then
    git clone $REPO_URL $CLONE_DIR
else
    echo "Directory $CLONE_DIR already exists. Skipping git clone."
fi

# ディレクトリと設定ファイルの準備（オプション）
mkdir -p $HOME/yuunas_work/certs
touch $HOME/yuunas_work/certs/nginx-selfsigned.crt
touch $HOME/yuunas_work/certs/nginx-selfsigned.key

# UFWの設定
sudo ufw allow OpenSSH

# ネットワーク設定のバックアップと変更
NETPLAN_CONFIG="/etc/netplan/01-netcfg.yaml"
NM_CONFIG="/etc/NetworkManager/NetworkManager.conf"

# ネットワーク設定ファイルのバックアップ
if [ -f "$NETPLAN_CONFIG" ]; then
    sudo cp $NETPLAN_CONFIG ${NETPLAN_CONFIG}.bak
fi
if [ -f "$NM_CONFIG" ]; then
    sudo cp $NM_CONFIG ${NM_CONFIG}.bak
fi

# 現在のネットワークインターフェース名を取得
INTERFACE=$(ip link show | grep -oP '(?<=: )[a-zA-Z0-9_-]+(?=:)' | head -n 1)

if [ -z "$INTERFACE" ]; then
    echo "No network interface found. Please check your network setup."
    exit 1
fi

# 静的IPアドレスの設定
sudo bash -c "cat > $NETPLAN_CONFIG <<EOF
network:
  version: 2
  ethernets:
    $INTERFACE:
      addresses:
        - 192.168.1.100/24
        - 2001:db8::100/64
      gateway4: 192.168.1.1
      gateway6: 2001:db8::1
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
          - 2001:4860:4860::8888
          - 2001:4860:4860::8844
EOF"

# NetworkManagerの設定（オプション）
echo -e "[main]\nplugins=ifupdown,keyfile\n[ifupdown]\nmanaged=false" | sudo tee $NM_CONFIG

# ネットワーク設定の適用
sudo netplan apply
sudo systemctl restart NetworkManager

# UFWを有効にする
sudo ufw enable

echo "Setup complete. Please log out and log back in for Docker group changes to take effect."
