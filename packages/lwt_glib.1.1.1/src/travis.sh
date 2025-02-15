set -x



# Install system packages.
case $TRAVIS_OS_NAME in
    linux)
        wget https://github.com/ocaml/opam/releases/download/2.0.5/opam-2.0.5-x86_64-linux
        sudo mv opam-2.0.5-x86_64-linux /usr/local/bin/opam
        sudo chmod a+x /usr/local/bin/opam
        sudo apt-get update -qq
        sudo apt-get install -qq libev-dev
        ;;
    osx)
        brew update > /dev/null
        brew install libev gtk+ ocaml opam
        ;;
esac



# Initialize opam.
opam init -y --bare --disable-sandboxing --disable-shell-hook
opam switch create . $COMPILER $REPOSITORIES --no-install
eval `opam config env`
opam --version
ocaml -version



# Install dependencies.
opam install conf-libev
opam pin add -y --no-action lwt_glib .
opam install -y --deps-only lwt_glib



# Build and install Lwt_glib. This is the only inherent test.
opam install -y --verbose lwt_glib
opam lint



# Build our one and only reverse dependency, to make sure all is likely well.
if [ "$COMPILER" != "4.02.3" ]
then
    opam install -y 0install
fi
