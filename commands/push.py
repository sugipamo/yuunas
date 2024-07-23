import subprocess
import sys

def execute():
    """Gitリポジトリにプッシュする"""
    try:
        result = subprocess.run(
            ['git', 'push'],
            check=True,
            text=True,
            capture_output=True
        )
        print(result.stdout)
    except subprocess.CalledProcessError as e:
        print(e.stderr, file=sys.stderr)
