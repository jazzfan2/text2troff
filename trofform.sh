#!/bin/bash
# Name  : trofform.sh
# Author: R.J.Toscani
# Date  : 23 december 2023
# Decription: 'trofform.sh' is a bash script that activates a chosen document format (including
# ancient AT&T variants) within a TROFF text and deactivates any alternate document formats.
# It does so by reducing the number of dots prefixed to the ms macro belonging to the 
# chosen format to one (1), and by prefixing two (2) dots to all other document formats
# ms macros. Unaffected text lines are passed on unchanged, and the result is sent to
# standard output. The output can be processed further with available ‘troff’ tools with
# ‘ms’ macro package, preferrably GNU groff_ms(7), to produce typeset PostScript-, PDF-,
# HTML- or terminal (‘nroff’) output. As an alternate to processing a text-file, trofform.sh
# can also read (text) input from a pipe.
#
######################################################################################
#
# Copyright (C) 2024 Rob Toscani <rob_toscani@yahoo.com>

# trofform.sh is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# trofform.sh is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
######################################################################################

set -o noclobber    # Prevent files to be accidentally overwritten by redirection of standard output


options(){
# Specify options:
    while getopts "efhiIrRtT" OPTION; do
        case $OPTION in
            R) format=RP ;;
            T) format=TR ;;
            i) format=IM ;;
            t) format=TM ;;
            f) format=MF ;;
            r) format=MR ;;
            e) format=EG ;;
            I) interactive=1 ;;
            h) helptext
               exit 0
               ;;
            *) helptext
               exit 1
               ;;
        esac
    done
}


helptext()
# Text printed if -h option (help) or a non-existing option has been given:
{
    while read "line"; do
        echo "$line" >&2         # print to standard error (stderr)
    done << EOF
Usage: trofform.sh [-efhiIrRtT] TROFF-FILE

-h   Help (this output)
-R   RP - Released Paper (with cover sheet)
-T   TR - Computing Science Technical Report (AT&T)
-i   IM - Internal Memorandum (AT&T)
-t   TM - Technical Memorandum (AT&T)
-f   MF - Memorandum for File (AT&T)
-r   MR - Memorandum for Record (AT&T)
-e   EG - Engineer's Notes (AT&T)
-I   Interactive mode
EOF
}


policy1()
{
    while true; do
        clear
        cat << EOF
Please choose document format in which to present the output:

1. Non Released Paper  (without cover sheet)
2. RP - Released Paper (with cover sheet)
3. TR - Computing Science Technical Report (AT&T)
4. IM - Internal Memorandum (AT&T)
5. TM - Technical Memorandum (AT&T)
6. MF - Memorandum for File (AT&T)
7. MR - Memorandum for Record (AT&T)
8. EG - Engineer's Notes (AT&T)
9. Close trofform.sh

EOF
        read -n 1 choice
        case $choice in
            1) format=VOID ;;	# VOID is a not existing (=fake-)macro
            2) format=RP ;;
            3) format=TR ;;
            4) format=IM ;;
            5) format=TM ;;
            6) format=MF ;;
            7) format=MR ;;
            8) format=EG ;;
            9) clear; close_off ;;
            *) continue ;;
        esac
        if ! grep -qE "^(\.{1,}|\.*\\\\\"\.)$format" "$file" && [[ $format != VOID ]]; then
            echo -e "\nText doesn't contain $format macro, please make a new choice...\n"
            sleep 1.5
            continue
        fi
        engine "$file"
    done
}


policy2()
{
    while true; do
        clear
        echo -e "Specify command for further troff-processing,\n\
(pipe constructs allowed without argument,\n\
and 'Enter' without input = back):\n"
        read "commando"
        [[ "$commando" == "" ]] && policy1 "$1" || return
    done
}


engine()
{
    # Zie https://stackoverflow.com/questions/7573368/in-place-edits-with-sed-on-os-x
    sed -Ei.bu "s/^\.(RP|TR|IM|TM|MF|MR|EG|CS)/\.\.\.\1/g;
             s/^(\.{2,}|\.*\\\\\"\.)($format)/\.\2/g" "$1"
    [[ $format == "TM" ]] && sed -Ei.bu 's/^(\.{2,}|\.*\\\\\"\.)(CS)/\.\2/g' "$1"  # Cover sheet in case of TM
    if (( interactive )); then
        while true; do
            policy2 "$1"
            bash -c "source "$functions"; ($commando) < '$1'"
        done
    else
        cat "$1"
    fi
}


close_off()
{
    \rm "$file" 2>/dev/null
    exit
}


if [[ -d /tmp/ramdisk/ ]]; then
    tmpfiledir="/tmp/ramdisk"
elif [[ -d /dev/shm/ ]]; then
    tmpfiledir="/dev/shm"
else
    tmpfiledir="."
fi

interactive=0
format=VOID

options $@
shift $(( OPTIND - 1 ))

trap "close_off" SIGINT

file="$tmpfiledir/file$RANDOM$RANDOM"
  functions="$HOME/scripts/functions_troff"

cat "$@" >| "$file"

if (( interactive )) ; then
    # Trick that makes that terminal-input arrives at the read-variable '$choice' 
    # if the program reads (text) input from a pipe:
    policy1 < /dev/tty
else
    engine "$file"
fi

close_off

