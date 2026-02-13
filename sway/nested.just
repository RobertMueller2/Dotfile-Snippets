# provides cloned config which can be used for a nested sway session.

conf := "$HOME/.config/sway/config-nested"
sway := "/usr/local/bin/sway"
wd := "$HOME/tmp/sway-test"

run sway=sway conf=conf:
    cd {{wd}} && _RO_SHELL_QUIET=1 SWAY_EXEC_CON_ID= I3_WINDOW_ID= {{sway}} -c {{conf}}

gdb sway=sway conf=conf:
    cd {{wd}} && _RO_SHELL_QUIET=1 SWAY_EXEC_CON_ID= I3_WINDOW_ID= gdb --args {{sway}} -c {{conf}}

[confirm]
clone:
    cp config config-nested
    tar -cf - config config.d | tar -xvpf - --show-transformed-names --transform=s,^config,config-nested,g
    sed -i -e s,~/.config/sway/config.d,~/.config/sway/config-nested.d,g config-nested
    # until further notice
    sed -i -e 's,^,#,g' config-nested.d/99_autoexec.conf
    # wlogout shuts down the main session
    sed -i -e '/^bindsym .\+ wlogout$/ s,^,#,g' config-nested.d/51_keybindings_basics.conf

[confirm]
clean:
    -rm config-nested
    -rm -rf config-nested.d

