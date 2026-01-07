#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "❌ Start dit script met sudo:"
  echo "sudo $0 /dev/sdX"
  exit 1
fi

# Kies de directory naam voor recovery
read -p "📝 Kies de naam voor de recovery directory (bijv. 'mijn_recovery'): " RECOVERY_DIR_NAME

BASE_DIR="/home/$SUDO_USER/Downloads/recovery"
EXTENSIONS="jpg,jpeg,avi,mp4,pdf,doc"

if [ -z "$1" ]; then
    echo "Gebruik: sudo $0 /dev/sdX"
    exit 1
fi

DEVICE="$1"
IMAGE_FILE="/home/$SUDO_USER/Downloads/recovery_image_$(basename $DEVICE).img"

# Foremost installeren indien nodig
if ! command -v foremost &> /dev/null; then
    echo "Foremost niet gevonden — installeren..."
    apt update && apt install -y foremost
fi

# Maak de directory waar we de recovery in gaan opslaan
mkdir -p "$BASE_DIR/$RECOVERY_DIR_NAME"

i=1
while [ -d "${BASE_DIR}/${RECOVERY_DIR_NAME}${i}" ]; do
    i=$((i+1))
done

RECOVERY_DIR="${BASE_DIR}/${RECOVERY_DIR_NAME}${i}"
mkdir -p "$RECOVERY_DIR"

echo "📁 Recovery map: $RECOVERY_DIR"

START_TIME=$(date +%s)

echo "💽 Maak image van $DEVICE..."
dd if="$DEVICE" of="$IMAGE_FILE" bs=4M status=progress conv=sync,noerror

echo "🧠 Start foremost recovery..."
foremost -t $EXTENSIONS -i "$IMAGE_FILE" -o "$RECOVERY_DIR"

echo "🗂️ Bestanden sorteren..."
cd "$RECOVERY_DIR"
for ext in $(echo $EXTENSIONS | tr ',' ' '); do
    if [ -d "$ext" ]; then
        mkdir -p "${ext}_files"
        mv "$ext"/* "${ext}_files/" 2>/dev/null
    fi
done

END_TIME=$(date +%s)
DURATION=$((END_TIME-START_TIME))

echo "✅ Klaar!"
echo "⏱️ Tijd: $DURATION seconden"
echo "📦 Resultaten: $RECOVERY_DIR"
echo "🛡️ Originele schijf is onaangetast"
