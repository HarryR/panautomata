import click


# TODO: setup logger here, must setup logger before modules are imported

from .lithium.cli import daemon as lithium_daemon


COMMANDS = click.Group()
COMMANDS.add_command(lithium_daemon, name="lithium")


if __name__ == "__main__":
    COMMANDS.main()
