FROM nginx:alpine

# 必要なパッケージをインストール
RUN apk add --no-cache gettext

# テンプレートファイルをコピー
COPY nginx.conf.template /etc/nginx/nginx.conf.template

# 環境変数を使って設定ファイルを生成
RUN envsubst '${DOMAIN}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# 設定ファイルに適切な権限を設定
RUN chmod 644 /etc/nginx/nginx.conf

# その他の必要な設定
# COPY --from=build /app /usr/share/nginx/html
# EXPOSE 80

# デフォルトのコマンドを指定
CMD ["nginx", "-g", "daemon off;"]
