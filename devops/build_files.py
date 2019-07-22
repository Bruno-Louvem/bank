#!/usr/bin/env python
import os
import socket
from shutil import copyfile

from datetime import datetime
from os.path import basename, dirname, realpath, join, abspath

__LOCAL__ = 'dev'

PAINT_RED='\033[00;31m'
PAINT_GREEN='\033[01;32m'
PAINT_PURPLE='\033[00;35m'
PAINT_CYAN='\033[01;36m'
PAINT_YELLOW='\033[01;33m'
END_COLOR="\033[00m"
LINE_BREAK='\n'
DEPLOY_JOB_NAME = 'deploy'
"""
Path to base folders (devops and project's root)
"""
DEVOPS_FOLDER_PATH = dirname(realpath(__file__))
PROJECT_ROOT_PATH = abspath(join(DEVOPS_FOLDER_PATH, os.pardir))
devops_directory = lambda dir: join(DEVOPS_FOLDER_PATH, dir)

"""
Path to folder containing base (template) files to be generated
"""
BASE_FILES_PATH = devops_directory('base_files')
DOCKER_COMPOSE_BASE_FILE = join(BASE_FILES_PATH, 'docker-compose.base')
DOCKERFILE_BASE_FILE = join(BASE_FILES_PATH, 'Dockerfile.base')
VERSION_FILE = join(DEVOPS_FOLDER_PATH, 'version.txt')

"""
Path to subfolders inside devops folder to hold config files
based on the the environment name
"""
DEVOPS_LOCAL_PATH = devops_directory(__LOCAL__)

"""
Path to files containing environment variable in the following format
export VAR_NAME=VAR_VALUE
"""
LOCAL_ENV_VARIABLES = join(DEVOPS_FOLDER_PATH, 'env', 'dev.sh')
LOCAL_ENV_VARIABLES_EXAMPLE = join(DEVOPS_FOLDER_PATH, 'env', 'dev.example.sh')
"""
"""
FILENAME_DOCKER_COMPOSE = 'docker-compose.yml'
FILENAME_DOCKERFILE = 'Dockerfile'
FILENAME_DOCKER_ENV_VAR = 'variables.env'

def main():
    print(LINE_BREAK)
    generate_files_local_env()
    print(LINE_BREAK)

def generate_files_local_env():

    generate_environment_variables_file(__LOCAL__)
    generate_docker_compose_file(__LOCAL__)
    generate_dockerfile(__LOCAL__)

def generate_environment_variables_file(env):

    folder_existis(env)
    fp_new_file = create_file(env, FILENAME_DOCKER_ENV_VAR)
    variables_file_exists = os.path.isfile(LOCAL_ENV_VARIABLES)
    if variables_file_exists:
        variables_file = LOCAL_ENV_VARIABLES
        with open(variables_file, 'r') as file:
            export = 'export '
            comment = '#'
            ignore_keys = ['REDIS_', 'DB_']
            for line in file:
                parse_sh_env(line, ignore_keys, env, fp_new_file, comment, export)

        fp_new_file.close()
        print(build_file_generation_message(env, FILENAME_DOCKER_ENV_VAR))
    else:
        ask_if_createfile(LOCAL_ENV_VARIABLES, env)

def folder_existis(env):
    local_folder_path = join(DEVOPS_FOLDER_PATH, env)
    if not os.path.isdir(local_folder_path):
        os.mkdir(local_folder_path)

def ask_if_createfile(file_path, env):
    print('The file: {} was not found.'.format(file_path))
    auto_create = raw_input('Do you want create this file from example? (yes/no)\n')
    if auto_create == 'yes':
        copyfile(LOCAL_ENV_VARIABLES_EXAMPLE, file_path)
        generate_environment_variables_file(env)
    elif auto_create == 'no':
        create_file(env, file_path)
        generate_environment_variables_file(env)
    else:
        ask_if_createfile(file_path, env)

def parse_sh_env(line, ignore_keys, env, fp_new_file, comment, export):
    if env == __LOCAL__:
        if not is_valid_line(ignore_keys, line):
            return

    if line.startswith(export):
        fp_new_file.write(line.replace(export, ''))

    elif line.startswith(comment):
        return

def generate_docker_compose_file(env):

    fp_new_file = create_file(env, FILENAME_DOCKER_COMPOSE)

    with open(DOCKER_COMPOSE_BASE_FILE, 'r') as file:

        key_hostname = '<#HOSTNAME#>'
        key_project_path = '<#PROJECT-PATH#>'
        key_version = '<#VERSION#>'

        for line in file:
            new_line = line

            if key_hostname in line:
                new_line = line.replace(key_hostname, gen_hostname())
            if key_project_path in line:
                new_line = line.replace(key_project_path, PROJECT_ROOT_PATH)
            if key_version in line:
                new_line = line.replace(key_version, get_version())

            fp_new_file.write(new_line)

    fp_new_file.close()
    print(build_file_generation_message(env, FILENAME_DOCKER_COMPOSE))

def generate_dockerfile(env):

    fp_new_file = create_file(env, FILENAME_DOCKERFILE)

    destination = DEVOPS_LOCAL_PATH
    dockerfile = DOCKERFILE_BASE_FILE
    variables_file = join(destination, FILENAME_DOCKER_ENV_VAR)
    ignore_keys = []

    with open(dockerfile, 'r') as file:
        env_block = '<#ENV#>'
        key_version = '<#VERSION#>'


        for line in file:
            new_line = line

            if key_version in line:
                new_line = line.replace(key_version, get_version())

            if line.startswith(env_block):
                docker_formated_variables = []
                with open(variables_file, 'r') as variables:
                    for variable in variables:
                        if not is_valid_line(ignore_keys, variable):
                            continue
                        docker_formated_variables.append('ENV ' + variable)
                new_line = ''.join(docker_formated_variables)

            fp_new_file.write(new_line)

    fp_new_file.close()
    print(build_file_generation_message(env, FILENAME_DOCKERFILE))

def get_version():
    with open(VERSION_FILE, 'r') as file:
        first_line = file.readline()
        return first_line.strip()

def is_valid_line(invalidation_list, line):
    """
    Check string validity against a list of invalid substring
    """
    for invalid_key in invalidation_list:
            if invalid_key in line:
                return False
    return True


def create_file(env, filename):
    """
    Create and return new file based on destination and filename
    """
    destination = DEVOPS_LOCAL_PATH

    new_file = join(destination, filename)
    return open(new_file, 'w')

def build_file_generation_message(env, filename):
    """
    Format message to be used when file a new file is generated.
    """
    return (
        c(PAINT_PURPLE, '---------------------------') +
        LINE_BREAK +
        c(PAINT_CYAN, 'Environment: {} '.format(env)) +
        LINE_BREAK +
        c(PAINT_YELLOW, '{} '.format(filename)) +
        c(PAINT_GREEN, 'was generated successfully')
    )



def gen_hostname():
    """
    Generate random compliant hostname based on user's own hostname
    to avoid hostnames's clash in development environment.
    """
    return '{}-{}'.format(
        datetime.now().microsecond, socket.gethostname())

def c(color, message):

    return color + message + END_COLOR

if __name__ == '__main__':
    main()