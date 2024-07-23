import subprocess
import sys

def execute():
    """Docker Compose downを実行する"""
    try:
        result = subprocess.run(
            ['docker-compose', 'down'],
            check=True,
            text=True,
            capture_output=True
        )
        print(result.stdout)
    except subprocess.CalledProcessError as e:
        print(e.stderr, file=sys.stderr)
