# custom-scripts

Scripts, configs and systemd user units behind the Sway desktop in
[dotfiles](https://github.com/WalterSmuts/dotfiles): Midway renewal, mail via
DavMail, calendar, and waybar modules. Everything here is symlinked into
`$HOME` by `install.sh`; the layout mirrors the home directory.

## Install (new machine)

```sh
sudo apt install davmail-server isync neomutt khal vdirsyncer zenity pass \
    python3-pexpect brightnessctl cliphist wl-clipboard netcat-openbsd
git clone <this repo> ~/workspace/custom-scripts
~/workspace/custom-scripts/install.sh
```

Then, once:

```sh
mwinit -f                 # Midway web session + SSH cert
pass insert amazon/midway # YubiKey PIN (optional; mwinit-refresh asks otherwise)
davmail-refresh           # writes the O365 refresh token into ~/.davmail.properties
mailsync                  # first mbsync pull
```

`install.sh` is idempotent; re-run it after adding a script or unit.

## What runs

| Unit | Purpose |
|---|---|
| `davmail.service` | DavMail gateway: IMAP 1143, SMTP 1025, CalDAV 1080 to M365 |
| `midway-ssh-agent.service` | Plain ssh-agent holding the Midway-signed cert (gpg-agent drops certs); forwarded to clouddesk |
| `mwinit-refresh.timer` | Every 5 min: prompt to renew Midway when < 30 min left |
| `meeting-remind.timer` | Every minute: notify 5 min before calendar events |
| `cliphist.service` | Clipboard history for `$mod+c` |
| `sway-session.target` | Started by sway's config; anchors graphical-session |

## Auth chain

Midway is the root credential. `mwinit-refresh` (waybar `custom/mwinit`,
click to renew) runs `mwinit -f` with YubiKey lockout safeguards and, on
success, reloads the ssh-agent and pushes `~/.midway/cookie` to the dev
desktop. Lifetimes: web session ~20h, SSH cert 12h, AEA cookie 2h.

Mail auth derives from it. `mailsync` probes DavMail; when the O365 token is
stale (~2h) it runs `davmail-refresh`, which drives the Microsoft -> Federate
-> Midway SSO chain with the Midway cookie (`davmail-get-token`), exchanges
the code for a refresh token, writes it to `~/.davmail.properties` and
restarts DavMail. No key touch needed while the Midway session is alive. All
steps log to `~/.local/state/mwinit-refresh/auth.log` (`mwinit-refresh log`).

Files with secrets stay out of git: `~/.davmail.properties` (refresh tokens,
seeded from `templates/`), `~/.midway/`, `~/.bashrc.local`.

## Scripts

- `mwinit-refresh` — status / renew / reset / aea / push / log
- `mailsync`, `mail-notify` — mbsync wrapper with auto re-auth; waybar mail module
- `davmail-refresh`, `davmail-get-token`, `mcurl` — O365 token chain; curl with Midway cookie
- `calsync`, `waybar-khal`, `meeting-remind` — M365 calendar to khal; waybar clock tooltip; reminders
- `brightness` — perceptual backlight steps (sway keys, waybar scroll)
- `clipboard-history`, `gg` — clipboard log; interactive git grep
