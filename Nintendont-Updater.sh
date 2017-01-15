#!/usr/bin/env bash

CURRENTVERSION="v1.2.1 Linux (beta)"
URL="https://raw.githubusercontent.com/FIX94/Nintendont/master"
HEADER="	Nintendont-Updater $CURRENTVERSION von WiiDatabase.de"

if [ $(uname -m) == 'x86_64' ]; then
  SFK="sfk-x64"
else
  SFK="sfk-x86"
fi
# OS X: /Volumes/Device (klappt das Skript unter OS X?)
if [ -d "/run/media/$USER" ]; then
  MEDIA="/run/media/$USER"
else
  if [ -d "/media/$USER" ]; then
    MEDIA="/media/$USER"
  else
    MEDIA="/media"
  fi
fi

echo -e '\033]2;'Nintendont-Updater $CURRENTVERSION'\007'
printf '\e[8;20;75t'

download () {
  # Download/Update
  if [[ $NEWINSTALL == "j" ]]; then
    echo "       Nintendont wird installiert..."
  else
    echo "       Deine Version ist veraltet und wird aktualisiert!"
  fi

  if [ -d "/tmp/nintendont" ]; then
    rm -rf "/tmp/nintendont"
  fi
  if [ ! -d "$PFAD/apps/nintendont" ]; then
    mkdir -p "$PFAD/apps/nintendont"
  fi
  if [ ! -d "$PFAD/controllers" ]; then
    mkdir -p "$PFAD/controllers"
  fi

  mkdir /tmp/nintendont
  cd /tmp/nintendont

  echo -e "\n       Downloade Nintendont"
  echo
  wget -t 3 -nv -P "/tmp/nintendont/" "$URL/controllerconfigs/controllers.zip" "$URL/loader/loader.dol" "$URL/nintendont/titles.txt" "$URL/nintendont/meta.xml" "$URL/nintendont/icon.png"
  7za x -y -o"$PFAD/controllers" /tmp/nintendont/controllers.zip
  mv /tmp/nintendont/loader.dol "$PFAD/apps/nintendont/boot.dol"
  mv /tmp/nintendont/icon.png "$PFAD/apps/nintendont/"
  mv /tmp/nintendont/titles.txt "$PFAD/apps/nintendont/"

  echo -e "\n       Update Version in meta.xml..."
  sed "s/<version>.*<\/version>/<version>$AVAILABLEVER<\/version>/"  /tmp/nintendont/meta.xml >/tmp/nintendont/meta-updated.xml
  mv /tmp/nintendont/meta-updated.xml "$PFAD/apps/nintendont/meta.xml"
  rm -rf "/tmp/nintendont"
  echo -e "\n       Nintendont wurde erfolgreich installiert!"
} 

clear
echo "$HEADER"
echo

# Checke nach Supportdateien
if [ -z "$(which 7z)" ]; then
  echo -e "  7z existiert auf diesem System nicht. \n  Bitte installiere es nach (Ubuntu: sudo apt-get install p7zip-full)!\n"
  exit 1
fi
if [ -z "$(which sed)" ]; then
  echo -e "  sed existiert auf diesem System nicht. \n  Bitte installiere es nach (Ubuntu: sudo apt-get install sed)!\n"
  exit 1
fi
if [ -z "$(which wget)" ]; then
  echo -e "  wget existiert auf diesem System nicht. \n  Bitte installiere es nach (Ubuntu: sudo apt-get install wget)!\n"
  exit 1
fi
if [ ! -f "$SFK" ]; then
  echo -e "  sfk existiert auf diesem System nicht. \n  Bitte lade den Nintendont-Updater erneut herunter!"
  exit 1
fi

# Start
while (true); do
  clear
  echo "$HEADER"
  echo
  echo "	Willkommen beim Nintendont-Updater der WiiDatabase!"
  echo "     Gebe bitte die Zahl deiner SD-Karte/deines USB-Gerätes an."
  echo
  select PFAD in $MEDIA/*; do test -n "$PFAD" && break; echo ">>> Das war keine gültige Eingabe"; done
  if [ ! -d "$PFAD/apps/nintendont" ]; then
    echo
    echo -e "  Nintendont existiert auf diesem Gerät nicht.\n  Möchtest du es hierauf installieren? [j/n]"
    read NEWINSTALL
    if [[ $NEWINSTALL == "j" ]]; then
      break;
    fi
  else
    break
  fi
done

# Checkver
clear
echo "$HEADER"
echo
echo "       Checke aktuelle Nintendont-Version..."
if [ -f "NintendontVersion.h" ]; then
  rm NintendontVersion.h
fi
wget -t 3 -q "$URL/common/include/NintendontVersion.h"
if [ ! -f "NintendontVersion.h" ]; then
  echo -e "  Ein Fehler beim Holen der aktuellen Version ist aufgetreten.\n  Bitte überprüfe deine Internetverbindung\!"
  exit 1
fi
MAJORVER=$(./$SFK filter "NintendontVersion.h"  -+"#define NIN_MAJOR_VERSION" -rep ."#define NIN_MAJOR_VERSION			"..)
MINORVER=$(./$SFK filter "NintendontVersion.h"  -+"#define NIN_MINOR_VERSION" -rep ."#define NIN_MINOR_VERSION			"..)
AVAILABLEVER="$MAJORVER.$MINORVER"
rm NintendontVersion.h
if [ ! -f "$PFAD/apps/nintendont/meta.xml" ]; then
  EXISTINGVER="0"
else
  EXISTINGVER=$(./$SFK filter -quiet "$PFAD/apps/nintendont/meta.xml" -+"/version" -rep _"*<version>"__ -rep _"</version*"__)
fi
if [ -z "$EXISTINGVER" ]; then
  EXISTINGVER=0
fi
echo
if [[ $NEWINSTALL != "j" ]]; then
  echo "       Deine Version: $EXISTINGVER"
fi
echo "       Aktuelle Version: $AVAILABLEVER"
echo

if [ "${EXISTINGVER/./}" -eq "${AVAILABLEVER/./}" ]; then
  echo "       Nintendont ist aktuell!"
  exit 0
fi
if [ "${EXISTINGVER/./}" -gt "${AVAILABLEVER/./}" ]; then
  echo -e "       Deine Version ist zu neu!?\n       Downloade Nintendont bitte erneut!"
  exit 0
fi
if [ "${EXISTINGVER/./}" -lt "${AVAILABLEVER/./}" ]; then
  download
  exit 0
fi

exit 0
