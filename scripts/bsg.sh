#! /bin/sh
##
## bsg.sh --
##
##	Script for the go-ball-sim program collection.
##
##	Preparation;
##
##	Install the following packages:
##	Ubuntu
##		sudo apt-get install xorg-dev libgl1-mesa-dev
##
## Commands;
##

prg=$(basename $0)
dir=$(readlink -f $(dirname $0))
top=$(readlink -f $dir/..)
me=$dir/$prg
bins="bounce collision"

die() {
	echo "$(date +"%T") ERROR: $*" >&2
	exit 1
}
log() {
	echo "$(date +"%T") $prg: $*" >&2
}
help() {
	grep '^##' $0 | cut -c3-
	exit 0
}
test -n "$1" || help
echo "$1" | grep -qi "^help\|-h" && help

##	build [--clean] [--tdir=<directory>]
##		Compiles go-ball-sim programs
##
cmd_build() {

	test -n "$__tdir" || __tdir="/tmp"

	if test "$__clean" = "yes";then
		for b in $bins;do
			rm -f $__tdir/$b
		done
	fi

	for b in $bins;do
		go build -o $__tdir/ $top/cmd/$b || die "build failed $__tdir/$b"
		log "build passed $__tdir/$b"
	done

}

##	install
##		Installs go-ball-sim programs
##
cmd_install() {

	for b in $bins;do
		go install $top/cmd/$b || die "install failed $b"
		log "install passed $b"
	done

}

##	test
##		Unit test the go-ball-sim programs
##
cmd_test() {

	go test $top/pkg/... || die "test failed"
	go test $top/internal/pkg/ball/... || die "test failed"
	log "test passed"

}

##	format
##		Lint and format check
##
cmd_format() {

	dirs="cmd pkg internal"
	for d in $dirs;do
		golint -set_exit_status $top/$d/... || die "golint failed in $d"
	done
	log "golint passed"
	fmt=$(gofmt -l $top)
	test -z $fmt || die "gofmt failed $fmt"
	log "gofmt passed"

}

##	smoketest
##		Execute build, test and format
##
cmd_smoketest() {

	cmd_build
	cmd_test
	cmd_format

}

# Get the command
cmd=$1
shift
grep -q "^cmd_$cmd()" $0 || die "Invalid command [$cmd]"

while echo "$1" | grep -q '^--'; do
	if echo $1 | grep -q =; then
		o=$(echo "$1" | cut -d= -f1 | sed -e 's,-,_,g')
		v=$(echo "$1" | cut -d= -f2-)
		eval "$o=\"$v\""
	else
		o=$(echo "$1" | sed -e 's,-,_,g')
		eval "$o=yes"
	fi
	shift
done
unset o v
long_opts=`set | grep '^__' | cut -d= -f1`

# Execute command
trap "die Interrupted" INT TERM
cmd_$cmd "$@"
status=$?
rm -rf $tmp
exit $status
