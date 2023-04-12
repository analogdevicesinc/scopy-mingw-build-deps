#!/usr/bin/bash.exe
#set -ex
source mingw_toolchain.sh $1 $2 $3

init_staging() {
	if [ "$USE_STAGING" == "ON" ]
		then
		rm -rf $STAGING_ENV
		mkdir -p $STAGING_ENV/var/lib/pacman/local
		mkdir -p $STAGING_ENV/var/lib/pacman/sync
		/usr/bin/bash.exe -c "$PACMAN -Syuu bash filesystem mintty pacman"
	fi
}
init_staging
