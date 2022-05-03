#! /bin/bash

usage () {
    printf "\
Usage: $0 -h
       $0 --help
       $0 [CONFIG] -i <IMAGE> [OPTIONS]
       $0 [CONFIG] -c <CONTAINER> [OPTIONS]

Helper script to start new containers or run commands in existing containers.

Options:
  -i, --image       The docker image to start a new container from.
  -c, --container   The existing running container to run the commands in.
  -w, --workspace   The directory new docker containers will be started in.
  -a, --docker-args Additional docker arguments for 'docker run' and 'docker exec'.
  -t, --task        The task this script is going to start.
                    Interactive shell: bash, shell, sh
                    Jupyter notebook/lab: jupyter, notebook, lab, jupyterlab
                    Set password: set_jupyter_password, set_notebook_password, set_lab_password
                    Tensorboard: tensorboard, tb
  -v, --verbose     SHOW ME MORE!
  -h, --help        Display this usage.

Jupyter options:
  --jupyter-args    Additional arguments for jupyter notebook/lab.
  --jupyter-port    Jupyter notebook/lab port.

Tensorboard options:
  --tb-args         Additional arguments for tensorboard.
  --tb-port         Tensorboard port.
  --tb-logdir       Path to tensorboard logdir on HOST machine.
"
    exit 1
}

success () {
    msg=$(echo $1 | sed 's/%/%%/g')
    printf "\x1B[32m$msg\x1B[0m"
}

warning () {
    msg=$(echo $1 | sed 's/%/%%/g')
    printf "\x1B[33m$msg\x1B[0m"
}

error () {
    msg=$(echo $1 | sed 's/%/%%/g')
    printf "\x1B[31m$msg\x1B[0m"
}

yes_no_prompt () {
    read -p "$1" res
    case ${res,,} in
        y|yes)      return 0 ;;
        *)          return 1 ;;
    esac
}

check_return () {
    ret=$?
    if [[ $ret -ne 0 ]]; then
        if [[ $1 != "" ]]; then
            error "$1\n"
        fi
        exit $ret
    fi
}

check_port () {
    re='^[0-9]+$'
    if ! [[ $1 =~ $re ]] ; then
        error "Invalid port $1\n"
        exit 1
    fi
    if [[ $1 -lt 1 || $1 -gt 65535 ]] ; then
        error "Invalid port $1\n"
        exit 1
    fi
}

load_config () {
    source $1
    check_return "Invalid config file: $1"
    container=$default_container
    image=$default_image
    workspace=$default_workspace
    task=$default_task
    jupyter_port=$default_jupyter_port
    tb_port=$default_tb_port
    tb_logdir=$default_tb_logdir
}

parse_args () {
    if [[ $1 == "-h" || $1 == "--help" ]]; then
        usage
    fi

    if [[ $1 == "-"* ]]; then
        warning "Please specify a config file (default 'run.conf'): "
        read config_file
        if  [[ $config_file == "" ]]; then
            warning "Using 'run.conf'\n"
            config_file="run.conf"
        fi
    else
        config_file=$1
        shift
    fi
    load_config $config_file

    while [[ $# -gt 0 ]]; do
        case $1 in
            -i|--image)         image="$2"          ; shift ;;
            -c|--container)     container="$2"      ; shift ;;
            -w|--workspace)     workspace="$2"      ; shift ;;
            -a|--docker-args)   docker_args="$2"    ; shift ;;
            -t|--task)          task=$2             ; shift ;;
            --jupyter-args)     jupyter_args="$2"   ; shift ;;
            --jupyter-port)     jupyter_port=$2     ; shift ;;
            --tb-args)          tb_args="$2"        ; shift ;;
            --tb-port)          tb_port=$2          ; shift ;;
            --tb-logdir)        tb_logdir="$2"      ; shift ;;
            -v|--verbose)       verbose=0           ;;
            *)
                error "Unknown option $1\n"
                usage
                ;;
        esac
        shift
    done
}

check_args () {
    if [[ $image == "" && $container == "" ]]; then
        error "One of 'image' (-i or --image) or 'container' \
(-c or --container) must be specified.\n"
        usage
    fi

    if [[ $workspace == "" ]]; then
        workspace=.
    fi
    workspace=$(cd "$workspace" && pwd)
    check_return

    check_port $jupyter_port
    check_port $tb_port
}

inject_variables () {
    str=$1
    str=${str//\%image/$image}
    str=${str//\%container/$container}
    str=${str//\%workspace/$workspace}
    str=${str//\%task/$task}
    str=${str//\%jupyter_port/$jupyter_port}
    str=${str//\%tb_port/$tb_port}
    str=${str//\%tb_logdir/$tb_logdir}
    echo "$str"
}


set_docker_run_cmd_and_args () {
    # Start a new docker container from specified image
    default_docker_run_args=$(echo "$default_docker_run_args " | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/ /g')

    # To avoid double mounting, create a symlink of $HOME to $TMP_HOME
    if [[ $workspace == $HOME ]]; then
        warning "It's not recommended to set home directory ($HOME) as workspace. Proceed anyway? (Yes/[No]) "
        yes_no_prompt
        if [[ $? -eq 0 ]]; then
            reg_home=$(echo $HOME | sed 's/\//\\\//g')
            reg="s/\(-v\|--volume\)\(\s\+\|=\)\+\(\([^:[:space:]]\+\)\|\([\"'].\+[\"']\)\):[\"']\?$reg_home\/\?[\"']\?\(\(:[a-zA-Z]\+\)\|\)\s//g"
            default_docker_run_args=$(echo "$default_docker_run_args" | sed -e $reg)
        else
            error "Abort!\n"
            exit 1
        fi
    fi

    default_docker_run_args=$(inject_variables "$default_docker_run_args")
    docker_args="$default_docker_run_args $docker_args"
    docker_cmd="docker run"
    docker_target=$image
}

set_docker_exec_cmd_and_args () {
    # Run command from an existing docker container
    default_docker_exec_args=$(inject_variables "$default_docker_exec_args")
    docker_args="$default_docker_exec_args $docker_args"
    docker_cmd="docker exec"
    docker_target=$container
}

set_docker_cmd_and_args () {
    if [[ $container != "" ]]; then
        docker container inspect $container > /dev/null 2>&1
        if [[ $? -ne 0 ]]; then
            warning "Container '$container' does not exist, \
start a new one with config '$config_file'? (Yes/[No]) "
            yes_no_prompt
            if [[ $? -eq 0 ]]; then
                set_docker_run_cmd_and_args
            else
                error "Abort!\n"
                exit 1
            fi
        else
            docker container inspect $container | grep "\"Running\": true" > /dev/null 2>&1
            if [[ $? -ne 0 ]]; then
                warning "Container '$container' is not running, \
start the container using 'docker start'? (Yes/[No]) "
                yes_no_prompt
                if [[ $? -eq 0 ]]; then
                    docker start $container
                    check_return "Fail to start container '$container'"
                else
                    error "Abort!\n"
                    exit 1
                fi
            fi
            set_docker_exec_cmd_and_args
        fi
    elif [[ $image != "" ]]; then
        set_docker_run_cmd_and_args
    fi
}

set_interactive () {
    if [[ $docker_args != *" -i"* &&  \
          $docker_args != *" --interactive"* && \
          $docker_args != *" -d"* && \
          $docker_args != *" --detach"* ]]; then
        docker_args="$docker_args $1"
    fi
}

set_task_cmd_and_args () {
    case $task in
        bash|shell|sh)
            set_interactive -it
            task_cmd="bash"
            ;;
        jupyter|notebook|lab|jupyterlab)
            set_interactive -d
            if [[ $task == *"lab"* ]]; then
                task_cmd="jupyter lab"
            else
                task_cmd="jupyter notebook"
            fi
            default_jupyter_args=$(inject_variables "$default_jupyter_args")
            jupyter_args="$jupyter_args $default_jupyter_args"
            task_cmd="$task_cmd $jupyter_args"
            ;;
        set_jupyter_password|set_notebook_password)
            set_interactive -it
            task_cmd="jupyter notebook password"
            ;;
        set_lab_password)
            set_interactive -it
            task_cmd="jupyter lab password"
            ;;
        tensorboard|tb)
            set_interactive -d
            default_tb_args=$(inject_variables "$default_tb_args")
            tb_args="$tb_args $default_tb_args"
            task_cmd="tensorboard $tb_args"
            ;;
        *)
            task_cmd=$task
    esac
}

main () {
    parse_args "$@"
    check_args
    set_docker_cmd_and_args
    set_task_cmd_and_args
    docker_cmd="$docker_cmd $docker_args $docker_target $task_cmd"
    if [[ $verbose ]]; then
        warning "$docker_cmd\n"
    fi
    $docker_cmd
    check_return "Docker command: $docker_cmd"
}

main "$@"
