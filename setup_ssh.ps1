# 鍵の生成
$keyPath = "$env:USERPROFILE\.ssh\id_rsa"
if (Test-Path $keyPath) {
    Write-Output "SSH鍵はすでに存在します。再生成するには、削除してください。"
} else {
    Write-Output "SSH鍵を生成します..."
    ssh-keygen -t rsa -b 4096 -f $keyPath -N ""
}

# 公開鍵の表示
$publicKeyPath = "$env:USERPROFILE\.ssh\id_rsa.pub"
Write-Output "公開鍵の内容を表示します:"
Get-Content $publicKeyPath

# サーバーの情報を取得
$server = Read-Host "公開鍵を追加するサーバーのアドレス（例: user@server.com）"

# 公開鍵をサーバーにコピー
Write-Output "公開鍵をサーバーにコピーします..."
ssh-copy-id -i $publicKeyPath $server

Write-Output "SSH鍵の設定が完了しました。サーバーに接続して確認してください。"
