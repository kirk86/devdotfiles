set-environment -g SGE_ROOT "/resource/software/sge/8.1.9.si/bin/lx-amd64"
set -g default-terminal "screen-256color"
set-option -g update-environment "DISPLAY XAUTHORITY"
set-option -g history-limit 1000000


 # List of plugins
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'

set -g @plugin 'tmux-plugins/tmux-resurrect'
# Enable capturing pane contents
set -g @resurrect-capture-pane-contents 'on'

# tmux-continuum plugin (optional for auto-save/restore)
set -g @plugin 'tmux-plugins/tmux-continuum'
# Automatic restore of sessions
set -g @continuum-restore 'on'

# Other examples:
# set -g @plugin 'github_username/plugin_name'
# set -g @plugin 'github_username/plugin_name#branch'
# set -g @plugin 'git@github.com:user/plugin'
# set -g @plugin 'git@bitbucket.com:user/plugin'

# Initialize TMUX plugin manager (keep this line at the very bottom of tmux.conf)
run '~/.config/tmux/plugins/tpm/tpm'
