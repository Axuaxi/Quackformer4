#!/bin/sh
echo -ne '\033c\033]0;Quackformer 4\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Quackformer4.x86_64" "$@"
