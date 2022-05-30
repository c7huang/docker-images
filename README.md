# docker-images

A collection of docker files with a configurable build system.

## Configuring Images
Each docker image is built from a `.ini` configuration file
located in `tags` folder. The config file has the following format:
```
[config]
base = base_tag_name
dockerfile = example.dockerfile
options =

[build_args]
pkg1_version = 1.0
pkg2_version = 2.0
```

The `dockerfile` in config specifies a template docker file located in
`dockerfiles` folder. Additional arguments (e.g., package versions) can be
specified in `[build_args]`.

## Building Images
To build a docker image, use the `build.py` script:
```
python build.py <IMAGE_NAME>:<TAG_NAME>
```
where `<IMAGE_NAME>` should be `<USER>/<REPO>` if the image is intended to be
pushed to dockerhub. The `<TAG_NAME>` should be the name of the config file
`<TAG_NAME>.ini`.
