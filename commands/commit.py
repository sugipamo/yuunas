import subprocess
import sys

def execute():
    """Gitリポジトリにコミットする"""
    if len(sys.argv) != 3:
        print("Usage: python commands.py commit [message]", file=sys.stderr)
        sys.exit(1)

    message = sys.argv[2]
    try:
        subprocess.call(
            "git commit -m " + message,
            shell=True,
        )
    except subprocess.CalledProcessError as e:
        print(e.stderr, file=sys.stderr)
