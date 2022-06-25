import click

from omniimager import imager
from omniimager import editor


@click.command()
@click.argument('build-type')
@click.option('--config-file', help='Configuration file for the software.')
@click.option('--package-list', help='The list of packages that you want to put into your image.')
@click.option('--repo-files', help='The list of repo files that you want to use, the program will consolidate them.')
@click.option('--product', help='Product Name.')
@click.option('--version', help='Version Identifier.')
@click.option('--release', help='Release.')
@click.option('--variant', help='Variant.')
@click.option('--output-file', default='openEuler-image.iso', help='The output image file name.')
def build(build_type, config_file, package_list, repo_files, product, version, release, variant, output_file):
    imager.build(build_type, config_file, package_list, repo_files, product, version, release, variant, output_file)


@click.command()
@click.argument('resource-type')
@click.option('--config-file', help='Configuration file for the software.')
@click.option('--iso', help='The source iso you want to edit.')
@click.option('--ks', help='The kickstart config file you want to added to the ISO.')
@click.option('--output-file', help='The output image file name.')
@click.option('--loop-device', default='auto', help='Custom loop device path')
def edit(resource_type, config_file, iso, ks, output_file, loop_device):
    editor.edit(resource_type, config_file, iso, ks, output_file, loop_device)


@click.command()
@click.argument('resource-type')
@click.option('--config-file', help='Configuration file for the software.')
@click.option('--iso', help='The source iso you want to edit.')
@click.option('--output-file', default='ks.cfg', help='The output file name.')
@click.option('--loop-device', default='auto', help='Custom loop device path')
def load(resource_type, config_file, iso, output_file, loop_device):
    editor.load(resource_type, config_file, iso, output_file, loop_device)


@click.group()
def cli():
    pass


def main():
    cli.add_command(build)
    cli.add_command(edit)
    cli.add_command(load)
    cli()
