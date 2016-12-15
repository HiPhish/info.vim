#!/bin/bash

# This is a mock-version of standalone Info which will simply echo out a
# pre-rendered Info node. It takes the same arguments as the real Info, but it
# uses the 'file' and 'node' options to construct the file name of the mock
# file.

# Default values used by Info as well
FILE='dir'
NODE='Top'

# Printing the version goes first
if [ "$1" = '--version' ] || [ "$1" = '-v' ]; then
	echo '6.0'
	exit 0
fi

# Loop over the arguments and only pick the '--file' and '--node' positional
# keyword parameters
while [ -n "$1" ]; do
	case $1 in
		--file) FILE="$2"; shift; shift;;
		--node) NODE="$2"; shift; shift;;
		*) shift;;
	esac
done

# The $(dirname $0) is save only as long as the script is invoked with its full
# path, which will be true as long as the test cases use 'g:vader_file' to
# construct the path.
TARGET="$(dirname "$0")/mock/$FILE.$NODE.info"
if [ ! -f "$TARGET" ]; then
	# The >&2 means "redirect address of FD 1 to FD 2"
	>&2 echo "info: '$FILE': No such file or directory"
	# If the node was not found: echo "info: Cannot find node '$NODE'."
	exit 1
fi

cat "$TARGET"
