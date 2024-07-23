import sys
import importlib.util
import logging
import os

# ログの設定
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

HELP_TEXT = {
    "up": "Starts the Docker Compose services.",
    "down": "Stops and removes the Docker Compose services.",
    "generate": "Generates self-signed certificates and DH parameters.",
    "status": "Displays the Git repository status.",
    "commit": "Commits changes to the Git repository with a specified message.",
    "push": "Pushes committed changes to the Git repository."
}

COMMANDS = {
    "up": "commands/up.py",
    "down": "commands/down.py",
    "generate": "commands/generate.py",
    "status": "commands/status.py",
    "commit": "commands/commit.py",
    "push": "commands/push.py"
}

VERSION = "1.0.0"

def load_module_from_file(file_path):
    """指定されたファイルパスからモジュールを読み込む"""
    module_name = os.path.basename(file_path).replace('.py', '')
    spec = importlib.util.spec_from_file_location(module_name, file_path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module

def run_command(command_name, args):
    """指定されたコマンドを実行する"""
    file_path = COMMANDS.get(command_name)
    
    if file_path is None:
        logging.error(f"Invalid command: {command_name}")
        show_help()
        sys.exit(1)

    module = load_module_from_file(file_path)
    if hasattr(module, 'execute'):
        module.execute(*args)
    else:
        logging.error(f"No 'execute' function found in {file_path}")
        sys.exit(1)

def show_help(command_name=None):
    """指定されたコマンドのヘルプを表示する。コマンド名が指定されない場合は全コマンドのヘルプを表示する"""
    if command_name:
        help_text = HELP_TEXT.get(command_name)
        if help_text:
            print(f"{command_name}: {help_text}")
        else:
            logging.error(f"No help available for command: {command_name}")
            show_help()  # Show all available commands if the specific command help is not available
    else:
        print("Available commands:")
        for command, description in HELP_TEXT.items():
            print(f"{command}: {description}")

def show_version():
    """ツールのバージョン情報を表示する"""
    print(f"commands.py version: {VERSION}")

def main():
    if len(sys.argv) < 2:
        print("Usage: python commands.py [command] [args...]", file=sys.stderr)
        show_help()  # Show help if no command is provided
        sys.exit(1)

    command_name = sys.argv[1]
    args = sys.argv[2:]

    if command_name == "help":
        if len(sys.argv) == 3:
            show_help(sys.argv[2])
        else:
            show_help()  # Show help for all commands if no specific command is provided
    elif command_name == "version":
        show_version()
    elif command_name in COMMANDS:
        run_command(command_name, args)
    else:
        logging.error(f"Invalid command: {command_name}")
        show_help()  # Show all available commands if the command is invalid
        sys.exit(1)

if __name__ == "__main__":
    main()
