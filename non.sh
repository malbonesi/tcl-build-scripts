#!/bin/sh
#Build NON on TinyCore
#If no project is given then all of them will be built, except ntk

project= source_dir=

while getopts ":p:d:" opt; do
	case $opt in
	p)
        echo $OPTARG | grep -Eq 'timeline|mixer|sequencer|session-manager|ntk' || { echo "Unknown project: $OPTARG" >&2; exit 1; }
		project=$OPTARG
		;;
	d)
        [ -d $OPTARG ] || { echo "Source dir, '$OPTARG', does not exist" >&2; exit 1; }
        source_dir=$OPTARG
		;;
    '?')
        echo "$0: invalid option -$OPTARG" >&2
		echo "Usage: $0 [-p timeline|mixer|sequencer|session-manager|ntk] -d DIRECTORY"
        exit 1
		;;
	esac
done

TMP_DIR="/tmp/non-$project"
WAF_CMD='./waf configure --prefix=/usr/local'

if [ $project ]; then
	$WAF_CMD+=" --project=$project"
fi

#Set compiler flags
export CFLAGS='-march=i486 -mtune=i686 -Os -pipe'
export CXXFLAGS='-march=i486 -mtune=i686 -Os -pipe'
export LDFLAGS='-Wl,-O1'

#Load all dependencies
tce-load -i compiletc python liblo-dev lrdf-dev ntk-dev jack-dev cairo-dev libGL-dev libsndfile-dev libsigc++-dev raptor-dev

cd $source_dir || exit 1

$WAF_CMD

[ $? == 0 ] || { echo 'Configure failed' >&2; exit 1; }

./waf

[ $? == 0 ] || { echo 'Build failed' >&2; exit 1; }

./waf install --destdir=$TMP_DIR

[ $? == 0 ] || { echo 'Install failed' >&2; exit 1; }

#Use /tmp as working dir
cd $TMP_DIR || exit 1

#Strip everything
find . | xargs file | grep "executable" | grep ELF | grep "not stripped" | cut -f 1 -d : | xargs strip --strip-unneeded 2> /dev/null
find . | xargs file | grep "shared object" | grep ELF | grep "not stripped" | cut -f 1 -d : | xargs strip -g 2> /dev/null


exit 0
