# Add user configurations here
# For HyDE to not touch your beloved configurations,
# we added 2 files to the project structure:
# 1. ~/.hyde.zshrc - for customizing the shell related hyde configurations
# 2. ~/.zshenv - for updating the zsh environment variables handled by HyDE // this will be modified across updates

# NOTE:to use transient prompt for starship in zsh, un comment the following lines
#eval "$(starship init zsh)"
#set-long-prompt() { PROMPT=$(starship prompt) }
#precmd_functions=(set-long-prompt)
#set-short-prompt() {
#  if [[ $PROMPT != '%# ' ]]; then
#      PROMPT=$(starship module character)
#    zle .reset-prompt
#  fi
#}
#zle-line-finish() { set-short-prompt }
#zle -N zle-line-finish
#trap 'set-short-prompt; return 130' INT
# NOTE:checkout 'https://starship.rs/advanced-config/' for other shells

# you can choose between different presets by exporting the config file:
# export STARSHIP_CONFIG=~/.config/starship.toml
# default presets are :starship.toml brackets.toml  heavy-right.toml  lualine.toml  powerline.toml
# eg: uncomment the following line to set the lualine preset on startup
# export STARSHIP_CONFIG=~/.config/starship/lualine.toml
#also you can costumize the prompt by editing
# ~/.config/starship/starship.toml
# or add your own configuration under ~/.config/starship/yourconf.toml and export it


#  Plugins 
# oh-my-zsh plugins are loaded  in ~/.hyde.zshrc file, see the file for more information

#  Aliases 
# Add aliases here

#  This is your file 
# Add your configurations here
