#!/bin/zsh

typeset root=/var/local/boj
typeset dir=/ projdir
typeset out=${TMPDIR:-/tmp}/boj.$$.out
typeset log=/var/log/boj.log
typeset msg=${TMPDIR:-/tmp}/boj.$$.msg
typeset guard
typeset nomail=false alwaysmail=false keepout=false
typeset user=$(print -P %n)
typeset host=$(print -P %m)
typeset HOST=$(print -P %M)
typeset mailfrom=${MAILFROM:-$user} mailto=${MAILTO:-$user} mailsubj=${MAILSUBJ:-'$H: [$r] $c'}
typeset timestamp='%D{%Y%m%dT%H%M%S}'

typeset begin="$(print -P $timestamp)" end
typeset result
typeset cmdline cmd
typeset -a cmdargs

[[ -w $log || -w $log:h ]] || log=~/.bojlog

main() {
    typeset opt
    while getopts :nmkreLd:g:o:l:f:t:s:p:v opt; do
        case $opt in
            (n) nomail=true      ;;
            (m) alwaysmail=true  ;;
            (k) keepout=true     ;;
            (r) keepout=false    ;;
            (L) log=~/.bojlog    ;;
            (d) dir=$OPTARG      ;;
            (g) guard=$OPTARG    ;;
            (o) out=$OPTARG
                keepout=true     ;;
            (l) log=$OPTARG      ;;
            (f) mailfrom=$OPTARG ;;
            (t) mailto=$OPTARG   ;;
            (s) mailsubj=$OPTARG ;;
            (p) projdir=$OPTARG  ;;
            (v) show-version ;;
        esac
    done
    shift $(( OPTIND - 1 ))

    # More setup
    if [[ $1 == @* ]]; then
        # boj @RELDIR
        (( $#argv == 1 )) || usage
        [[ $1 != @/* ]]   || usage
        projdir=${1[2,-1]}; shift
        : ${BOJ_ROOT:=$root}
        cd $BOJ_ROOT/$projdir || fatal "Can\'t chdir $projdir"
        use-projdir -l $BOJ_ROOT/boj.log "$@"
    elif [[ -n $projdir ]]; then
        # boj -p ABSDIR ...
        [[ $projdir == /* ]] || usage
        cd $projdir || fatal "Can\'t chdir $projdir"
        use-projdir "$@"
    else
        (( $#argv > 0 )) || usage
        cd $dir || fatal "Can\'t chdir $dir"
        cmdline="$*"
        cmd=$1; shift
        cmdargs=( "$@" )
    fi

    #  If something fails, we exit -- after calling our exit handler, which
    #  takes care of logging and notification.
    set -e
    trap finish EXIT

    # Make sure all output goes to the designated file
    exec > $out 2>&1

    # Run it (unless the guard file exists)
    integer err
    if [[ -n $guard && -e $guard ]]; then
        result=SKIP
        err=0
    else
        $cmd $@
        err=$?
    fi

    # Everything else happens in finish
    trap - EXIT
    finish $err
}

use-projdir() {
    typeset opt
    mkdir -p tmp
    out=tmp/out
    log=log/boj.log
    msg=tmp/msg
    guard=opt/norun
    [[ ! -e opt/keepout    ]] || keepout=true
    [[ ! -e opt/alwaysmail ]] || alwaysmail=true
    [[ ! -e opt/nomail     ]] || nomail=true
    while getopts :l opt; do
        case $opt in
            (l) log=$OPTARG ;;
            (*) usage ;;
        esac
    done
    shift $(( OPTIND - 1 ))
    # Figure out the command to execute, and what args to give it
    if (( $# == 0 )); then
        # boj -p DIR
        cmd=./run
        cmdline=$projdir/run
    elif [[ $1 == '[' ]]; then
        shift
        if [[ ${argv[-1]} == ']' ]]; then
            # boj -p DIR [ foo bar ] ==> exec foo bar
            (( $# > 1 )) || usage
            argv[-1]=()
            cmdline="$*"
            cmd=$1; shift
        else
            # boj -p DIR [ foo bar ==> exec foo bar DIR/run
            cmd=$1; shift
            set -- $@ ./run
            cmdline="$cmd $*"
        fi
    else
        cmd=./run
        cmdline="$projdir/run $*"
    fi
    cmdargs=( "$@" )
}

finish() {
    integer err=${1:-$?}
    set +e  # Turn off automatic exit on error
    end="$(print -P $timestamp)"
    if [[ -z $result ]]; then
        if (( err == 0 )); then
            result=OK
        else
            result=FAIL
        fi
    fi
    printf '%-4.4s %s %s %s\n' $result $begin $end $cmdline >> $log
    # Send notification
    typeset notify=false
    if (( err != 0 )) || $alwaysmail; then
        notify=true
    elif [[ -s $out ]] && ! $nomail; then
        notify=true
    fi
    ! $notify || send-notification
    $keepout || rm -f $out
}

usage() {
    print 'usage: boj [OPTION]... JOB [ARG]...' >&2
    exit 1
}

send-notification() {
    {
        if [[ -z $projdir ]]; then
            expand-escapes <<EOS
From: $mailfrom
To: $mailto
Subject: $mailsubj

EOS
        else
            if [[ -e mail.$err ]]; then
                cat mail.$err
            elif [[ -e mail.$result ]]; then
                cat mail.$result
            elif [[ -e mail ]]; then
                cat mail
            else
                typeset projname='$j'
                cat <<EOS
From: $mailfrom
To: $mailto
Subject: \$h: [\$r] $projname

Output for job \$J follows...

EOS
            fi | expand-escapes
        fi
        cat $out
    } > $msg
    /usr/sbin/sendmail -oi -t < $msg
    $keepout || rm -f $msg
}

fatal() {
    print -- "$@" >&2
    exit 2
}

show-version() {
    cat <<EOS
boj __VERSION__ by __AUTHOR__
__COPYRIGHT__
Licensed under the terms of the GNU General Public License, version 2.
See LICENSE for details.
EOS
    exit 0
}

expand-escapes() {
    typeset shortres=$(printf '%-4.4s' $result)
    typeset sec=$(print -P '%D{%s}')
    typeset E='\$'
    sed -e "
        s|${E}r|${result}|;     s|${E}?|${err}|;
        s|${E}4r|${shortres}|;  s|${E}R|${RANDOM}|;
        s|${E}j|${projdir:t}|;  s|${E}J|${projdir}|;
        s|${E}u|${user}|;       s|${E}h|${host}|;
        s|${E}b|${begin}|;      s|${E}e|${end}|;
        s|${E}H|${HOST}|;       s|${E}c|${cmdline}|;
        s|${E}${E}|$$|;         s|${E}s|${sec}|;
    "
}

main "$@"

