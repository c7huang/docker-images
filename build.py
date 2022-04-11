import sys
import os
from configparser import ConfigParser, ExtendedInterpolation

def build(repo, tag):
    config = ConfigParser(interpolation=ExtendedInterpolation())
    config.read(f'tags/{tag}.ini')

    # Build base image recursively
    if config.has_option('config', 'base'):
        build(repo, config['config']['base'])
    
    dockerfile = f'dockerfiles/{config["config"]["dockerfile"]}'

    # Construct build command
    cmd = f'docker build -t {repo}:{tag} -f {dockerfile} '

    # Add repo name and base tag name as --build-arg
    cmd += f'--build-arg REPO={repo} '
    if config.has_option('config', 'base'):
        cmd += f'--build-arg BASE={config["config"]["base"]} '

    # Add additional build arguments
    if config.has_section('build_args'):
        for arg_name, arg_value in config['build_args'].items():
            cmd += f'--build-arg {arg_name.upper()}={arg_value} '

    # Add additional build options
    if config.has_option('config', 'options'):
        cmd += f'{config["config"]["options"]} '

    # Build path is current directory
    cmd += '.'

    # Execute build command, exit on error
    print('################################################################################')
    print(f'# Building \'{tag}\'')
    print(f'# Command: {cmd}')
    print('################################################################################')

    ret = os.system(cmd)
    if ret != 0:
        exit(ret)

    print('################################################################################')
    print(f'# Finished \'{tag}\'')
    print('################################################################################')


if __name__ == '__main__':
    name = sys.argv[1].split(':')
    build(name[0], name[1])
