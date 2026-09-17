#!/bin/bash
# Symlink scripts, configs and systemd units from this repo into $HOME and
# enable the units. Idempotent: re-run after adding a file to the repo.
set -euo pipefail

REPO=$(cd "$(dirname "$0")" && pwd)

link() { # link <repo-relative path>  -> $HOME/<same path>
    local target="$HOME/$1"
    mkdir -p "$(dirname "$target")"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        echo "skip $target: exists and is not a symlink (move it away or delete it)" >&2
        return
    fi
    ln -sfn "$REPO/$1" "$target"
}

for f in "$REPO"/.local/bin/*; do link ".local/bin/$(basename "$f")"; done
for f in "$REPO"/.config/systemd/user/*; do link ".config/systemd/user/$(basename "$f")"; done
link .mbsyncrc
link .config/vdirsyncer/config

# DavMail keeps its refresh tokens in this file, so it is copied, not linked.
if [ ! -e "$HOME/.davmail.properties" ]; then
    sed "s|__HOME__|$HOME|g" "$REPO/templates/davmail.properties" > "$HOME/.davmail.properties"
    echo "wrote ~/.davmail.properties; run 'mwinit -f && davmail-refresh' to add the token"
fi

mkdir -p "$HOME/.local/share/mail/amazon" "$HOME/.local/share/calendars/amazon/calendar"

systemctl --user daemon-reload
systemctl --user enable --now davmail.service cliphist.service midway-ssh-agent.service \
    mwinit-refresh.timer meeting-remind.timer
# mako is replaced by swaync (apt: sway-notification-center); make sure it can never start.
systemctl --user mask mako.service 2>/dev/null || true
