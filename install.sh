#!/bin/sh
# Клипер для Arch Linux — установка и обновление одной командой:
#   curl -fsSL https://raw.githubusercontent.com/Flenstick/kliper-releases/main/install.sh | sh
# Скачивает пакет последнего релиза и ставит его через pacman (зависимости pacman докачает сам).
set -eu

REPO="${KLIPER_REPO:-Flenstick/kliper-releases}"
API="${KLIPER_API:-https://api.github.com/repos/$REPO/releases/latest}"

if ! command -v pacman >/dev/null 2>&1; then
  echo "Этот установщик — для Arch Linux и его производных (нужен pacman)." >&2
  exit 1
fi

echo ":: Ищу последнюю версию Клипера…"
URL=$(curl -fsSL "$API" | grep -o '"browser_download_url": *"[^"]*-any\.pkg\.tar\.zst"' | head -n1 | sed 's/.*"\(http[^"]*\)"$/\1/')
if [ -z "$URL" ]; then
  echo "Не нашёл пакет для Arch в последнем релизе $REPO." >&2
  exit 1
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
FILE="$TMP/$(basename "$URL")"
echo ":: Скачиваю $(basename "$URL")…"
curl -fL --progress-bar -o "$FILE" "$URL"

echo ":: Устанавливаю (pacman спросит пароль)…"
SUDO=""
[ "$(id -u)" -eq 0 ] || SUDO="sudo"
YES=""
[ -n "${KLIPER_NOCONFIRM:-}" ] && YES="--noconfirm"
# скрипт читается из curl через stdin — вопросы pacman и пароль sudo берём с терминала
if [ -z "$YES" ] && (: </dev/tty) 2>/dev/null; then
  $SUDO pacman -U --needed "$FILE" </dev/tty
else
  $SUDO pacman -U --needed --noconfirm "$FILE"
fi

echo ":: Готово! Открой «Клипер» в меню приложений — служба запустится и дальше будет стартовать со входом в систему."
