run() {
    # Run the compilation process.
    cd $PLATFORM_CACHE_DIR || exit 1;

    if [ ! -f "${PLATFORM_CACHE_DIR}/phpredis/modules/redis.so" ]; then
        ensure_source
        inject_uuid
    fi

    copy_lib
    enable_lib
}

copy_lib() {
    # Copy the compiled library to the application directory.
    echo "Installing Relay extension."
	php_version=$(php -r 'echo substr(PHP_VERSION, 0, 3);')
    cp $PLATFORM_CACHE_DIR/relay-v$1-php$php_version-debian-x86-64/relay-pkg.so $PLATFORM_APP_DIR/relay.so
}

enable_lib() {
    # Tell PHP to enable the extension.
    echo "Enabling Relay extension."
    echo -e "\nextension=${PLATFORM_APP_DIR}/relay.so" >> $PLATFORM_APP_DIR/php.ini
}

ensure_source() {
    # Download the Relay extension.
	php_version=$(php -r 'echo substr(PHP_VERSION, 0, 3);')
	relay_version="v$1"
	relay_build="relay-$relay_version-php$php_version-debian-x86-64"

    if [ -d $relay_build ]; then
        cd $relay_build || exit 1;
    else
        curl -L "https://cachewerk.s3.amazonaws.com/relay/$relay_version/$relay_build.tar.gz" | tar xz -C $PLATFORM_CACHE_DIR
        cd $relay_build || exit 1;
    fi
}

inject_uuid() {
	# Inject UUID into Relay extension.
	uuid=$(cat /proc/sys/kernel/random/uuid)
	sed -i "s/BIN:31415926-5358-9793-2384-626433832795/BIN:$uuid/" relay-pkg.so
}

ensure_environment() {
    # If not running in a Platform.sh build environment, do nothing.
    if [ -z "${PLATFORM_CACHE_DIR}" ]; then
        echo "Not running in a Platform.sh build environment.  Aborting Relay installation."
        exit 0;
    fi
}

ensure_arguments() {
    # If no version was specified, don't try to guess.
    if [ -z $1 ]; then
        echo "No version of the Relay extension specified.  You must specify a tagged version on the command line."
        exit 1;
    fi
}

ensure_environment
ensure_arguments "$1"
run "$1"
