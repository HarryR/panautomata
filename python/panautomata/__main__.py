import click

from .lithium.daemon import daemon
from .example.swap import COMMANDS as swap_commands


COMMANDS = click.Group()
COMMANDS.add_command(daemon)
COMMANDS.add_command(swap_commands)


if __name__ == "__main__":
    COMMANDS.main()
