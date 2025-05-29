# Dotfile-Snippets

## What is this?

This repository contains extracted examples from my dotfiles for reference purposes.

Many people make their whole dotfiles repository public. Personally, I don't feel comfortable with that. Some things are WIP, some might even never get finished. Some things in my dotfiles might be outright embarassing. :P It's also easy to share security relevant info by accident.

I do think though that some parts of my dotfiles ARE worth sharing. So instead of sharing everything, I extract relevant parts and place them in this repository.

This is a WIP and the repository should grow in the future. Not all examples will be complete, so they might not immediately work alone. This is intended. However, the examples should make sense or there is no point in sharing them, so if you stumble across anything that makes no sense without the missing bits, feel free to open an issue. This is a spare time activity so responding to those might take time, especially if I need to clean up the missing bits first.

If I feel like there's been enough commits, I'll replace the history with a squash commit. Since everything is generated, there really isn't any benefit to a history.

## Some remarks regarding the shared parts

### example-extraction

This is the magic that extracts shareable stuff from my Dotfiles repo.

p.S.: It'd be rude not to use [just](https://github.com/casey/just)'s interpreter feature for this, but there's a downside: Github does not recognize inline language of the recipes. So let me state that here, the heavy lifting is done by a perl script.

### Powershell

Powershell profile working for both Windows and Linux.

#### Adm

Provides checks and helpers:

- git repositories with uncommitted changes, no remotes or commits not on remote
- home dir check that lists files in folders that are neither cloud synced nor belong to a git repo
  - the paths are controlled in `$HOME\homewatch.ini`, there's an example in Windows-Basics.
  - I run this on a 15 mins schedule together with a VBScript helper (see Windows Basics)
- create desktop icon for firefox that starts the profile manager. In the past, firefox upgrades have sometimes removed my icon and it annoyed me so much I had to script
- `Set-NextWallpaper` to switch wallpapers from `$env:USERPROFILE\Cloud\Sync\Wallpaper-Rotation`, with optional passing of a static image. This changes the wallpaper for all Virtual Desktops, but the only way to do this in Win 11 seemed to be to deal with each desktop's registry entry as well and restart explorer. It's a bit hacky and takes a a while so the function adds a lockfile. Can be bound to a hotkey, e.g. with Autohotkey (not provided).
- copy OneIM installers and documentation to my nas. This had better gone into the OneIM module, but now it's here. Tough.

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
  - in the long run, I'll replace these with compose files at [OneIM-Docker-Scripts](https://github.com/RobertMueller2/OneIM-Docker-Scripts)
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
### Rainmeter

- image-frame to display random images (slideshow) from a cloud folder
- docker-info for running containers in contexts "linux" or "windows"
- screenshot inside (TODO: link)

### Scripts

#### sh

Various shell scripts, see comments inside. Some extra remarks:

- Scripts can be sharp tools, use with caution.
- `sh-helper.inc.sh` enables command style scripts to have annotations for their commands that are automatically extracted by `_usage` and a git commit hook also turns that into markdown cheatsheets and man pages (script not shared yet)

##### Bootstrap

Some initialization for a new machine:

- copy template files (btpl) in the dotfiles repository to the real thing. This is for files that are .gitignored because they contain strictly local information but need to be initialized
  - I clearly have to rethink this with *this* repository in mind
- create user anacrontab

This could do more, e.g. set some basics, but I don't need this very often. I have a machine-config git repository (maybe I can share the makefile in the future) which covers most machine level stuff.

##### Backup

- my NAS backs up files to rotating offsite disks using [btrbk](https://github.com/digint/btrbk) as well as an "emergency NAS" USB disk. The latter was added to the concept following a RAM failure in the NAS machine
- my NAS also backs up all volumes using [bup](https://github.com/bup/bup) (onsite backup)
- my Laptop backs up all volumes with bup, including nested lv volumes (KVM) with dd (not included here yet)
  - everything important on my laptop is already either in a git repo or in a cloud synced path. Scripts (see parent section) ensure that nothing is lingering outside of these locations and that git repositories are properly synced. For a personal env, this already feels quite solid. But in a HW failure scenario, backup might still be easier to use: that way I don't have to remember where everything was in a moment of probably huge pressure

### Sway

The config makes use of wayland-helper.sh, sway-helper.sh and swayhelper, none of those are public yet but will be later after a clean up. Please do note that `--matched-container-id` in `exec`s depends on [PR 8671](https://github.com/swaywm/sway/pull/8671)

A few highlights, from top of my head:

- help/cheatsheet for the focused window. if it's foot, a menu is offered to select help for command line tools
- help annotation in sway config, shift+win+F1 opens a terminal that shows keybindings and modes (using sway-helper.sh)
  - I'm not that happy with how it's presented, the long term goal would be something more similar to awesomewm's help popup
- win+c allows to enter arbitrary swaymsg commands
- "Quake" drop down terminal (still has minor timing issues on first start)
- digital image frame
- passthrough mode to access nested wayland sessions

### Waybar

Various stuff, but nothing spectacular. Worth noting might be the custom wayeyes module which indicates whether the focused node is `xdg_shell`, `xwayland` or something else, as well as the modules that watch homedir and git repositories for files that are not in the cloud, `_volatile` subdir or added to git. Note to self: write cffi module for wayeyes use case.

Uses sway-helper.sh (not public yet), waybar-wayland-helper.sh and [waybar-helper](https://github.com/RobertMueller2/waybar-helper).

Some things depend on unmerged PRs, I've tried to point that out in comments.

Sway directory has a screenshot that also includes my Waybar config.

### Windows Basics

- `rtc-is-utc.ps1`: Windows's default is to assume that hardware clock is local time, whereas Debian normally assumes that it is UTC. (I honestly couldn't tell if Debian asked me last time I installed it. I don't need reinstalls, so the last time is quite a while ago.) Another reason why dual booting sucks, but I really can't afford two gaming laptops. Fortunately, both Windows and Debian allow changing this. Since I only use my Windows installation to update it, the installed software and of course the laptop firmware, Debian wins.
- homecheck scripts (see Adm module): one to register the home check as a schedule, one vbs script to avoid a flickering powershell window, and one to invoke the checks provided by the Adm module
