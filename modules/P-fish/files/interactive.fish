set -gx fish_greeting # Disable greeting
if not set -q NVIM
    fish_vi_key_bindings
end
fzf_configure_bindings --directory=\cf
