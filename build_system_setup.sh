if [ -z "$HOME" ] || [ "$HOME"=="/" ]; then
    export HOME=/home/docker
fi
export STAGING_PREFIX=$HOME/staging
