#!/bin/sh

# make sure we're in the repository root.
cd $(dirname $0)
cd ..

# create host specific anacron directories for a user anacron
ANACRON=anacron/anacron.$(uname -n)

mkdir -p "${ANACRON}/spool"
mkdir -p "${ANACRON}/etc"

if [ ! -f "${ANACRON}/etc/anacrontab" ];then
    cat > ${ANACRON}/etc/anacrontab <<EOF
# /etc/anacrontab: configuration file for anacron
#
# # See anacron(8) and anacrontab(5) for details.

SHELL=/bin/sh
PATH=/usr/local/bin:/bin:/usr/bin

# period  delay  job-identifier  command
# generates a summary of forgotten files once per day from .cache data which is then mailed
1         20     watch-home      $HOME/Progs/bin/watch-homedir.sh

# find out if any of the reports are suspended
30        60     watch-suspends  find $HOME/.config -mindepth 1 -maxdepth 1 -type f -a -iname '*suspend'

EOF

fi

cd
if [ ! -e .anacron ]; then
    ln -s $(pwd)/${ANACRON} .anacron
fi

if ! crontab -l | grep -q /usr/sbin/anacron ; then
    # avoid globbing, so * in the crontab doesn't get expanded
    set -f
    echo "$(crontab -l; echo '@hourly /usr/sbin/anacron -s -t $HOME/.anacron/etc/anacrontab -S $HOME/.anacron/spool';)" | crontab -
    set +f
fi

