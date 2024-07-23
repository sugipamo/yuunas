#!/bin/bash

# 更新と基本パッケージのインストール
sudo apt update
sudo apt upgrade -y
sudo apt install -y curl gnupg lsb-release

# Dockerのインストール
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
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

# 設定を反映
sudo systemctl restart ssh

# 静的IPの設定
NETPLAN_CONFIG="/etc/netplan/01-netcfg.yaml"

# 現在のネットワークインターフェース名を取得
INTERFACE=$(ip link show | grep -oP '(?<=: )[a-zA-Z0-9_-]+(?=:)' | head -n 1)

if [ -z "$INTERFACE" ]; then
    echo "No network interface found. Please check your network setup."
    exit 1
fi

# 設定ファイルのバックアップ
sudo cp $NETPLAN_CONFIG ${NETPLAN_CONFIG}.bak

# 静的IPアドレスの設定
sudo bash -c "cat > $NETPLAN_CONFIG <<EOF
network:
  version: 2
  ethernets:
    $INTERFACE:
      addresses:
        - 192.168.1.100/24
      gateway4: 192.168.1.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
EOF"

# 設定の適用
sudo netplan apply

# Gitリポジトリのクローン
REPO_URL="https://github.com/sugipamo/yuunas"
CLONE_DIR="~/yuunas_work"

# クローン先ディレクトリが存在しない場合のみクローン
if [ ! -d "$CLONE_DIR" ]; then
    git clone $REPO_URL $CLONE_DIR
else
    echo "Directory $CLONE_DIR already exists. Skipping git clone."
fi

# ディレクトリと設定ファイルの準備（オプション）
mkdir -p ~/yuunas_work/certs
touch ~/yuunas_work/certs/nginx-selfsigned.crt
touch ~/yuunas_work/certs/nginx-selfsigned.key

echo "Setup complete. Please log out and log back in for Docker group changes to take effect."
