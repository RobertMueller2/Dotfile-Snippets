# provides cloned config which can be used for a nested sway session.

run sway="/usr/local/bin/sway":
    {{sway}} -c config-nested

[confirm]
clone:
    cp config config-nested
    tar -cf - config config.d | tar -xvpf - --show-transformed-names --transform=s,^config,config-nested,g
    sed -i -e s,~/.config/sway/config.d,~/.config/sway/config-nested.d,g  config-nested
    # until further notice
    sed -i -e 's,^,#,g' config-nested.d/99_autoexec.conf
    
[confirm]
clean:
    -rm config-nested
    -rm -rf config-nested.d

