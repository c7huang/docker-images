import sys
import os
from configparser import ConfigParser, ExtendedInterpolation

def build(repo_name, tag_name):
    config = ConfigParser(interpolation=ExtendedInterpolation())
    config.read(f'tags/{tag_name}.ini')
    if config.has_option('config', 'requires'):
        build(repo_name, config['config']['requires'])
    
    dockerfile = f'dockerfiles/{config["config"]["dockerfile"]}'
    cmd = f'docker build -t {repo_name}:{tag_name} -f {dockerfile} --build-arg REPO_NAME={repo_name} '
    if config.has_section('build_args'):
        for arg_name, arg_value in config['build_args'].items():
            cmd += f'--build-arg {arg_name.upper()}={arg_value} '
    cmd += '.'
    ret = os.system(cmd)
    if ret != 0:
        exit(ret)


if __name__ == '__main__':
    name = sys.argv[1].split(':')
    build(name[0], name[1])
