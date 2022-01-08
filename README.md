# phoenix-quickstart

This Makefile and Dockerfile creates a containerized development environment for
[Elixir](https://elixir-lang.org/) and the [Phoenix
Framework](https://www.phoenixframework.org/).

## Setup

 * You will need a Linux development environment.
 * Install GNU Make. (On Arch Linux, install: `base-devel`. On Debian/Ubuntu,
   install: `build-essential`.)
 * Install [Podman](https://wiki.archlinux.org/title/Podman) or
[Docker](https://wiki.archlinux.org/title/Docker) on your local workstation (you
can use a remote server if you prefer, but then all the files need to reside on
the server filesystem, and be edited remotely).
 * For proper DNS name resolution between podman containers, you will also need
   to install
   [podman-dnsname](https://archlinux.org/packages/community/x86_64/podman-dnsname/)

Configure your own user account so you can run containers successfully (For
podman, see the [Rootless Podman article on the Arch Linux
Wiki](https://wiki.archlinux.org/title/Podman#Rootless_Podman). For Docker, make
sure you add your user to the `docker` group):

```
# Make sure your normal user can run this successfully before proceeding:
# Remember, you can use docker or podman, its up to you. 
podman run hello-world
```

## Install

Create a new directory someplace for your new project. Download `Makefile` and
`Dockerfile` from this repository, and copy them into your new project
directory:

```
curl -L https://raw.githubusercontent.com/EnigmaCurry/phoenix-quickstart/master/Dockerfile -o Dockerfile
curl -L https://raw.githubusercontent.com/EnigmaCurry/phoenix-quickstart/master/Makefile -o Makefile
```

Edit your copy of the `Makefile`. At the top, you will find the variables that
make the default configuration. Change these variables appropriately for your
new project, or leave them as-is and use environment variables to override them
instead.

 * Podman is the default docker implementation. If you are using real Docker,
   make sure to set `DOCKER = docker`.
 
### Using the Makefile

The Makefile can perform all the steps to create and run the development
environment. 

Build and start everything, from scratch: `make all` 
 
Or, run the individual steps in this order:

 * Create the initial Phoenix project: `make init`
 * Build the docker container image: `make build`
 * Create the database: `make database`
 * Start the live reload server: `make serve` (press `Ctrl-C` twice to stop)

Open your web browser to [http://localhost:4000](http://localhost:4000)

(`make init` is idempotent, you can run it many times, and it will only create
the project directory if it does not already exist: eg. `test -d ${APP} ||
${DOCKER} run ...` from the `init` target.)


# Public Domain License

This quickstart template is released to the public domain (CC0-1.0). Use it
however you wish. See [LICENSE.txt](LICENSE.txt)
