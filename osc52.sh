#!/bin/bash
# Valida que se reciba un dispositivo TTY válido como argumento ($1) antes de operar.
# Evita errores I/O si el panel (pane) se cierra repentinamente durante el copiado.
[[ -z "$1" || ! -c "$1" ]] && exit 1

# Pasa la entrada estándar a base64 sin saltos de línea.
b64=$(base64 -w 0)

# 1. Abre passthrough globalmente
tmux set-option -g allow-passthrough on

# 2. Inyecta la secuencia OSC52 hacia el TTY receptor
printf "\033Ptmux;\033\033]52;c;%s\a\033\\" "$b64" > "$1"

# 3. Espera a que Tmux vacíe el buffer del TTY (previene race conditions)
sleep 0.05

# 4. Cierra passthrough por seguridad
tmux set-option -g allow-passthrough off
