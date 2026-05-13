# Secure Tmux OSC52 Clipboard

A secure, dynamic-passthrough implementation for OSC52 clipboard integration in Tmux over SSH.

## Key Benefits

* **Massive Payload Support:** Reliably copies huge amounts of text across SSH (tested with 27,000+ lines) without buffer truncation or dropped data.
* **Security-First:** Mitigates pastejacking vulnerabilities by keeping the passthrough gate closed by default.
* **Race-Condition Safe:** Explicit buffer flushing ensures large payloads are transmitted completely before closing the passthrough.

## The Problem: Pastejacking Vulnerability

Many Tmux users rely on the `OSC 52` escape sequence to copy text from remote SSH sessions to their local machine's clipboard. To make this work, Tmux requires `set -g allow-passthrough on`. 

However, enabling global passthrough exposes your local terminal emulator to **Pastejacking** and escape sequence injection attacks. If you `cat` or `tail` a malicious log file, it can silently inject a destructive payload directly into your local clipboard without your knowledge.

## The Solution

This script mitigates the vulnerability by using a **Dynamic Passthrough Toggle**. 
Instead of leaving the door open permanently, the script:
1. Enables `allow-passthrough` globally.
2. Injects the selected text using OSC 52 directly into the specific TTY.
3. Waits for the buffer to flush (preventing race conditions and truncated copies).
4. Disables `allow-passthrough` immediately.

This reduces the attack surface from "always vulnerable" to milliseconds, triggered only by explicit manual user interaction.

## Installation

### 1. The Bash Script (`osc52.sh`)

Download the `osc52.sh` script from this repository, save it as a hidden file in your home directory, and make it executable:

```bash
cp osc52.sh ~/.osc52.sh
chmod +x ~/.osc52.sh
```

*(Ensure the script contains the TTY validation and `sleep` delay to prevent race conditions).*

### 2. Tmux Configuration (`.tmux.conf`)

Remove any existing global `set -g allow-passthrough on` from your `.tmux.conf` and add the following bindings. 

**Crucial:** You must pass `#{pane_tty}` as an argument to the script.

```tmux
# Enable standard clipboard features (Do NOT set allow-passthrough globally)
set -s set-clipboard on
setw -g mode-keys vi

# --- Keyboard Selection ---
bind-key -T copy-mode-vi v send-keys -X begin-selection
bind-key -T copy-mode-vi Space send-keys -X begin-selection

# Keyboard: Send to script and exit copy mode
bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "~/.osc52.sh #{pane_tty}"
bind-key -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "~/.osc52.sh #{pane_tty}"

# Mouse: Send to script, clear selection highlight, but keep copy mode open
bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe "~/.osc52.sh #{pane_tty}" \; send-keys -X clear-selection
```

### 3. Reload Tmux

Apply the changes to your active environment:

```bash
tmux source-file ~/.tmux.conf
```
