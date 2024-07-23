import subprocess
import sys

def execute():
    """Gitステータスを表示する"""
    try:
        result = subprocess.run(
            ['git', 'status'],
            check=True,
            text=True,
            capture_output=True
        )
        print(result.stdout)
    except subprocess.CalledProcessError as e:
        print(e.stderr, file=sys.stderr)
