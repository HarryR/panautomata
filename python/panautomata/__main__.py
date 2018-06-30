import click

from .lithium.cli import daemon as lithium_daemon
from .example.swap import COMMANDS as swap_commands


COMMANDS = click.Group()
COMMANDS.add_command(lithium_daemon)
COMMANDS.add_command(swap_commands)


if __name__ == "__main__":
    COMMANDS.main()
