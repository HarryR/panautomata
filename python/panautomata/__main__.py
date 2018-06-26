import click

from .lithium.daemon import daemon

COMMANDS = click.Group()
COMMANDS.add_command(daemon)

if __name__ == "__main__":
    COMMANDS.main()
