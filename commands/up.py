import subprocess
import sys

def execute():
    """Docker Compose upを実行する"""
    try:
        process = subprocess.Popen(
            ['docker', 'compose', 'up', '-d'],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )

        # リアルタイムで標準出力と標準エラー出力を読み取る
        while True:
            output = process.stdout.readline()
            error = process.stderr.readline()
            if output:
                print(output.strip())
            if error:
                print(error.strip(), file=sys.stderr)
            if output == '' and process.poll() is not None:
                break
        
        return_code = process.poll()
        if return_code != 0:
            raise subprocess.CalledProcessError(return_code, process.args)

    except subprocess.CalledProcessError as e:
        print(f"Error: {e}", file=sys.stderr)

# 実行例
if __name__ == "__main__":
    execute()
