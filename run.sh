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
    printf "\x1B[32m$1\x1B[0m\n"
}

warning () {
    printf "\x1B[33m$1\x1B[0m\n"
}

error () {
    printf "\x1B[31m$1\x1B[0m\n"
}

check_return () {
    ret=$?
    if [[ $ret -ne 0 ]]; then
        if [[ $1 != "" ]]; then
            error "$1"
        fi
        exit $ret
    fi
}

check_port () {
    re='^[0-9]+$'
    if ! [[ $1 =~ $re ]] ; then
        error "Invalid port $1"
        exit 1
    fi
    if [[ $1 -lt 1 || $1 -gt 65535 ]] ; then
        error "Invalid port $1"
        exit 1
    fi
}

load_config () {
    source $1
    check_return "Invalid config file: $1"
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
        warning "You did not specify a config file. Enter it here OR skip to use the default 'run.conf'."
        read -p "> " config_file
        if  [[ $config_file == "" ]]; then
            warning "Using 'run.conf'"
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
                error "Unknown option $1"
                usage
                ;;
        esac
        shift
    done
}

check_args () {
    if [[ $image == "" && $container == "" ]]; then
        error "One of 'image' (-i or --image) or 'container' \
(-c or --container) must be specified."
        usage
    fi

    workspace=$(cd "$workspace" && pwd)
    check_return

    tb_logdir=$(cd "$tb_logdir" && pwd)
    check_return

    check_port $jupyter_port
    check_port $tb_port
}

inject_variables () {
    str=$1
    str=${str/\%image/$image}
    str=${str/\%container/$container}
    str=${str/\%workspace/$workspace}
    str=${str/\%task/$task}
    str=${str/\%jupyter_port/$jupyter_port}
    str=${str/\%tb_port/$tb_port}
    str=${str/\%tb_logdir/$tb_logdir}
    echo $str
}

set_interactive () {
    if [[ $docker_args != *" -i"* &&  \
          $docker_args != *" --interactive"* && \
          $docker_args != *" -d"* && \
          $docker_args != *" --detach"* ]]; then
        docker_args="$docker_args $1"
    fi
}

set_docker_cmd_and_args () {
    if [[ $container != "" ]]; then
        # Run command from an existing docker container
        default_docker_exec_args=$(inject_variables "$default_docker_exec_args")
        docker_args="$default_docker_exec_args $docker_args"
        docker_cmd="docker exec"
        docker_target=$container
    elif [[ $image != "" ]]; then
        # Start a new docker container from specified image
        default_docker_run_args=$(inject_variables "$default_docker_run_args")
        docker_args="$default_docker_run_args $docker_args"
        docker_cmd="docker run"
        docker_target=$image
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
        warning "$docker_cmd"
    fi
    $docker_cmd
    check_return "Docker command: $docker_cmd"
}

main "$@"
