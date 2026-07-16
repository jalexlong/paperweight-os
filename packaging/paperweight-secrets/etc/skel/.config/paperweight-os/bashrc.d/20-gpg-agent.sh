# Point gpg-agent's pinentry at the current tty so it can prompt correctly
# even outside the GUI session (e.g. over SSH).
export GPG_TTY=$(tty)
gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1
