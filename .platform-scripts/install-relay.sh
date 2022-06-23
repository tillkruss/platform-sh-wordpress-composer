run() {
	# Run the compilation process.
	cd $PLATFORM_CACHE_DIR || exit 1;

	os_arch=$(uname -m | sed 's/_/-/')
	php_version=$(php -r 'echo substr(PHP_VERSION, 0, 3);')

	relay_build="relay-v${1}-php${php_version}-debian-${os_arch}"

	if [ ! -f "${PLATFORM_CACHE_DIR}/${relay_build}/redis-pkg.so" ]; then
		ensure_dependencies
		ensure_source "$1" "$relay_build"
	fi

	copy_lib "$relay_build"
	enable_lib
}

copy_lib() {
	# Copy the compiled library to the application directory.
	echo "Installing Relay extension."
	cp "${PLATFORM_CACHE_DIR}/${1}/relay-pkg.so" "${PLATFORM_APP_DIR}/relay.so"
}

enable_lib() {
	# Tell PHP to enable the extension.
	echo "Enabling Relay extension."
	echo -e "\nextension=${PLATFORM_APP_DIR}/relay.so" >> "${PLATFORM_APP_DIR}/php.ini"
}

ensure_source() {
	# Download the Relay extension.
	if [ -d $2 ]; then
		cd $2 || exit 1;
	else
		relay_pkg_url="https://cachewerk.s3.amazonaws.com/relay/v$1/$2.tar.gz"
		echo "Downloading: ${relay_pkg_url}"
		curl -s -S -L $relay_pkg_url | tar xz -C $PLATFORM_CACHE_DIR
		cd $2 || exit 1;

		# Inject UUID into Relay extension.
		uuid=$(cat /proc/sys/kernel/random/uuid)
		sed -i "s/BIN:31415926-5358-9793-2384-626433832795/BIN:$uuid/" relay-pkg.so
	fi
}

ensure_dependencies() {
	# Install the dependencies required by Relay.
	echo "Installing Relay dependencies."

	git clone https://github.com/Microsoft/vcpkg.git
	pushd vcpkg || exit 1

	./bootstrap-vcpkg.sh
	./vcpkg integrate install
	./vcpkg install lz4
	./vcpkg install zstd

	popd || exit 1
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
