#!/bin/bash

# 更新と基本パッケージのインストール
sudo apt update
sudo apt upgrade -y

# Gitのインストール
sudo apt install -y git

# Gitリポジトリのクローン
REPO_URL="https://github.com/sugipamo/yuunas"
CLONE_DIR="$HOME/yuunas_work"

# クローン先ディレクトリが存在しない場合のみクローン
if [ ! -d "$CLONE_DIR" ]; then
    git clone $REPO_URL $CLONE_DIR
else
    echo "Directory $CLONE_DIR already exists. Skipping git clone."
fi

# OpenSSHサーバーのインストール
sudo apt install -y openssh-server
sudo systemctl start ssh
sudo systemctl enable ssh

# インターネット接続が確認できるネットワークインターフェースを取得
INTERFACE="enp0s3"

# 静的IPの設定
NETPLAN_CONFIG="/etc/netplan/99_config.yaml"

# 設定ファイルのバックアップ
sudo cp $NETPLAN_CONFIG ${NETPLAN_CONFIG}.bak

# 静的IPアドレスの設定
sudo bash -c "cat > $NETPLAN_CONFIG <<EOF
network:
  version: 2
  ethernets:
    $INTERFACE:
      dhcp4: false
      addresses:
        - 192.168.0.100/24
      nameservers:
        addresses:
          - 192.168.0.1
          - 8.8.8.8
          - 8.8.4.4
EOF"

chmod 600 $NETPLAN_CONFIG

# 設定の適用
sudo netplan apply

# sshdの設定変更
SSHD_CONFIG="/etc/ssh/sshd_config"

# 設定のバックアップ
sudo cp $SSHD_CONFIG ${SSHD_CONFIG}.bak

# IPv6のみSSHを受け付けるように設定
sudo bash -c "cat >> $SSHD_CONFIG <<EOF
Port 2458
ListenAddress ::

PermitRootLogin no
PasswordAuthentication yes
PermitEmptyPasswords no
ChallengeResponseAuthentication no
EOF"

# 設定を反映
sudo systemctl restart ssh

# UFWの設定
sudo ufw allow 2458/tcp
sudo ufw enable

echo "Setup complete. Please log out and log back in for Docker group changes to take effect."
