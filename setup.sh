#!/bin/bash

# 引数の処理
GATEWAY4=""
GATEWAY6=""

while getopts ":4:6:" opt; do
  case $opt in
    4)
      GATEWAY4=$OPTARG
      ;;
    6)
      GATEWAY6=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

shift $((OPTIND-1))

# インターネット接続が確認できるネットワークインターフェースを取得
INTERFACE=""

for iface in $(ip link show | grep -oP '(?<=: )[a-zA-Z0-9_-]+(?=:)' | head -n 10); do
    if ping -c 1 -I $iface 8.8.8.8 &> /dev/null; then
        INTERFACE=$iface
        break
    fi
done

if [ -z "$INTERFACE" ]; then
    echo "No network interface with internet access found. Please check your network setup."
    exit 1
fi

echo "Using network interface: $INTERFACE"

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

# IPv6のみをリッスンするように設定
echo "AddressFamily inet6" | sudo tee -a $SSHD_CONFIG

# 設定を反映
sudo systemctl restart ssh

# 静的IPの設定
NETPLAN_CONFIG="/etc/netplan/01-netcfg.yaml"

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
        - 2001:db8::100/64
      gateway4: $GATEWAY4
      gateway6: $GATEWAY6
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
          - 2001:4860:4860::8888
          - 2001:4860:4860::8844
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

# UFWの設定
sudo ufw allow OpenSSH
sudo ufw enable

echo "Setup complete. Please log out and log back in for Docker group changes to take effect."
