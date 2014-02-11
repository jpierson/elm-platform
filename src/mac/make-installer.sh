#!/bin/sh

set -e

# Set version numbers for everything we want to build from source
compiler_version="0.11"

# Clean-up old pkg files
rm -f Elm.pkg

# Create directory structure for new pkgs
installerdir=$(pwd)
helpdir=$installerdir/helper-scripts

tmpdir=$(mktemp -d -t elm)
contentsdir=$tmpdir
scriptsdir=$contentsdir/Scripts
bindir=$contentsdir

mkdir -p $bindir
mkdir -p $scriptsdir

# Build Elm compiler and copy required resources to the correct places
bash $helpdir/build.sh Elm $compiler_version
cp Elm/dist/build/elm/elm $bindir/elm-compiler
datafilesdir=Elm/data

cp $installerdir/postinstall $scriptsdir
cp $helpdir/compiler-wrapper $bindir/elm

# Grab pre-built versions of other executables
# Probably should build these from source as well
for bin in elm-get elm-server elm-repl elm-doc
do
	whichbin=$(which $bin) || echo ""
	if [ "$whichbin" = "" ]; then
		echo "File does not exist: $bin"
		exit 1
	fi
	if [ ! -f $whichbin ]; then
		echo "File does not exist: $bin"
		exit 1
	fi

 	cp $(which $bin) $bindir 
done

pkgbuild --identifier org.elm-lang.share.pkg --install-location /usr/local/share/elm --root $datafilesdir share.pkg
pkgbuild --identifier org.elm-lang.bin.pkg --install-location /usr/local/bin --scripts $scriptsdir --filter 'Scripts.*' --root $tmpdir bin.pkg

productbuild --distribution Distribution.xml --package-path . --resources Resources Elm.pkg

# Clean-up
rm bin.pkg
rm share.pkg
rm -rf $tmpdir
