#!/bin/bash

# 更新と基本パッケージのインストール
sudo apt update
sudo apt upgrade -y

# Gitのインストール
sudo apt install -y git

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
      addresses: [192.168.1.70/24]
      nameservers:
        addresses: [192.168.1.1, 8.8.8.8, 8.8.4.4]
EOF"

chmod 600 $NETPLAN_CONFIG

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

# UFWの設定
sudo ufw allow OpenSSH
sudo ufw enable