# Dotfile-Snippets

## What is this?

This repository contains extracted examples from my dotfiles for reference purposes.

Many people make their whole dotfiles repository public. Personally, I don't feel comfortable with that. Some things are WIP, some might even never get finished. Some things in my dotfiles might be outright embarassing. :P It's also easy to share security relevant info by accident.

I do think though that some parts of my dotfiles ARE worth sharing. So instead of sharing everything, I extract relevant parts of my dotfiles and place them in this repository. (The extraction magic is in the example-extraction directory.)

This is a WIP and the repository should grow in the future. Not all examples will be complete, so they might not immediately work alone. This is intended. However, the examples should make sense or there is no point in sharing them, so if you stumble across anything that makes no sense without the missing bits, feel free to open an issue. This is a spare time activity so responding to those might take time, especially if I need to clean up the missing bits first.

## Some remarks regarding the shared parts

### Powershell

Powershell profile working for both Windows and Linux.

#### CoreUtils module

Adds alias for commands available from [CoreUtils](https://github.com/uutils/coreutils) with a few exceptions.

#### MOTD

Module to display MOTD files for a powershell session. My basic idea was to have a local machine specific MOTD that contains things that are noteworthy or weird on that system, and a user specific MOTD that is cloud synced to all my devices.

#### OneIM

Powershell module to support [OneIM](https://www.oneidentity.com/products/identity-manager/) lab installations with functions for
- extraction of docs (chms, guides, release notes) from new versions' installsets - I use [recoll](https://www.recoll.org/) to search through these
- installation of frontend and jobservice directories for all modules via InstallManager.cli.exe
- start of frontends of a specific version
- start of jobservice of a specific version
- various functions that start containers from [OneIM docker images](https://hub.docker.com/u/oneidentity/)
  - these are mostly for Linux images, but some functions exist for Windows images
  - both Linux and Windows containers can run side by side, but
    - I don't remember the details, but on my lab computer Windows Firewall prevented communication of Windows containers with a database running in a Linux container. I had to add an exception specifically for this.
    - the module assumes that docker contexts "Linux" and "Windows" are available:
``` 
λ 'C:\Program Files\Docker\Docker\DockerCli.exe' -SwitchWindowsEngine
λ docker context create windows --description "Windows containers" --default-stack-orchestrator=swarm --docker "host=npipe:////./pipe/dockerDesktopWindowsEngine"

λ & 'C:\Program Files\Docker\Docker\DockerCli.exe' -SwitchLinuxEngine
λ docker context create linux --description "Linux containers" --default-stack-orchestrator=swarm --docker "host=npipe:////./pipe/dockerDesktopLinuxEngine"

```
### Sway

The config makes use of wayland-helper.sh, sway-helper.sh and swayhelper, none of those are public yet but will be later.
