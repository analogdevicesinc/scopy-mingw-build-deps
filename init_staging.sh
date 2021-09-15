#!/usr/bin/bash.exe
set -x
source mingw_toolchain.sh

init_staging() {
	rm -rf $STAGING_ENV
	mkdir -p $STAGING_ENV/var/lib/pacman/local
	mkdir -p $STAGING_ENV/var/lib/pacman/sync
	/usr/bin/bash.exe -c "$PACMAN -Syuu bash filesystem mintty pacman"
}
init_staging
