import subprocess
import sys

def execute():
    """Docker Compose upを実行する"""
    try:
        subprocess.call(
            ['docker', 'compose', 'up', '-d'],
            shell=True,
        )
    except subprocess.CalledProcessError as e:
        print(e.stderr, file=sys.stderr)
