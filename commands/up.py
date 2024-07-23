import subprocess
import sys

def execute():
    """Docker Compose upを実行する"""
    try:
        result = subprocess.run(
            ['docker-compose', 'up', '-d'],
            check=True,
            text=True,
            capture_output=True
        )
        print(result.stdout)
    except subprocess.CalledProcessError as e:
        print(e.stderr, file=sys.stderr)
