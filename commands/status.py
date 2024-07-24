import subprocess
import sys

def execute():
    """Gitステータスを表示する"""
    try:
        subprocess.call(
            "git status",
            shell=True,
        )
    except subprocess.CalledProcessError as e:
        print(e.stderr, file=sys.stderr)
