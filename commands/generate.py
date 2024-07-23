import subprocess
import os
import sys

def execute():
    """証明書と鍵を生成する"""
    certs_dir = 'certs'
    
    # certsディレクトリが存在しない場合は作成
    if not os.path.exists(certs_dir):
        os.makedirs(certs_dir)

    try:
        # 秘密鍵と証明書の生成
        subprocess.run(
            ['docker', 'run', '--rm', '-v', f'{os.getcwd()}/{certs_dir}:/certs', '-e', 'SUBJ=/C=US/ST=State/L=City/O=Organization/OU=Department/CN=localhost', 'alpine/openssl', 'req', '-x509', '-nodes', '-days', '365', '-newkey', 'rsa:2048', '-keyout', '/certs/nginx-selfsigned.key', '-out', '/certs/nginx-selfsigned.crt', '-subj', '/C=US/ST=State/L=City/O=Organization/OU=Department/CN=localhost'],
            check=True,
            text=True,
            capture_output=True
        )
        subprocess.run(
            ['docker', 'run', '--rm', '-v', f'{os.getcwd()}/{certs_dir}:/certs', 'alpine/openssl', 'dhparam', '-out', '/certs/dhparam.pem', '2048'],
            check=True,
            text=True,
            capture_output=True
        )
        print("Certificates and keys have been generated.")
    except subprocess.CalledProcessError as e:
        print(e.stderr, file=sys.stderr)
