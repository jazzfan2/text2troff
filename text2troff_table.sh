#!/bin/bash
# Name  : text2troff_table.sh
# Author: R.J.Toscani
# Date  : 26-10-2023
# Description: 'text2troff_table.sh' is a bash script that uses awk filtering to convert 
# tabulated lines in a flat text-file into TROFF formatted tables by inserting table requests
# and ms macros. All lines not interpreted as table lines are passed on unchanged. The result
# is sent to standard output, and can be processed further with available 'troff' tools with
# 'ms' macro package, preferrably GNU groff_ms(7), to produce typeset PostScript-, PDF-, 
# HTML- or terminal ('nroff') output. As an alternative to processing a text-file, 
# text2troff_table.sh can also read (text) input from a pipe.
#
# (Comment texts are still partly in Dutch - will be translated into English in due course!)
#
######################################################################################
#
# Copyright (C) 2024 Rob Toscani <rob_toscani@yahoo.com>

# text2troff_table,sh is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# text2troff_table.sh is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

#######################################################################################
#
set -o noclobber    # Prevent files to be accidentally overwritten by redirection of standard output


helptext()
# Text printed if -h option (help) or a non-existent option has been given:
{
    while read "line"; do
        echo "$line" >&2         # print to standard error (stderr)
    done << EOF

Usage:
text2troff_table.sh [-ehs] TEXTFILE

   -e     Stretch tables to full text column width ('expand')
   -s     Force tables within text column width("squeeze") if too wide
   -h     Help (this output)

EOF
}


noreturn()
{
	cat "$1" | tr -d '\r' 
}


transcode()
# Stuurt de inhoud van een ISO-8859 tekstfile naar stdout in UTF-8 formaat (om het "grepbaar" te maken):
# https://www.tecmint.com/convert-files-to-utf-8-encoding-in-linux/
# De functie verwerkt een tekstfile die wordt opgegeven als argument, maar kan ook standard output
# verwerken die wordt aangeboden via een pipe.
{
    text="./text$RANDOM"
    cat "$1" >| $text
    if ( command -v file 1>/dev/null && command -v iconv 1>/dev/null ); then 
        file "$text" |
        if grep -q "ISO-8859"; then
#           iconv -f ISO-8859-1 -t UTF-8//TRANSLIT $text
            iconv -f ISO-8859-1 -t UTF-8 $text
        else
            cat $text
        fi
    else
        cat $text
    fi
    \rm $text
}


cleanup()
# Remove temporary files:
{
    [ -f "$textfile" ] && \rm $textfile
    [ -f "$columncount_file" ] && \rm $columncount_file
    exit
}


trap "cleanup; exit" SIGINT

if [[ -d /tmp/ramdisk/ ]]; then
    tmpfiledir="/tmp/ramdisk"
elif [[ -d /dev/shm/ ]]; then
    tmpfiledir="/dev/shm"
else
    tmpfiledir="."
fi

textfile="$tmpfiledir/textfile$RANDOM"
columncount_file="$tmpfiledir/columncount$RANDOM"
textwidth=78      # Iets gesmokkeld t.o.v. werkelijke afstand linker tot rechtermarge in troff bij 10 pts = 74
tabletype="center"
squeeze=0

while getopts "ehs" OPTION; do
    case $OPTION in
        e) tabletype="expand"
           ;;
        h) helptext
           exit 0
           ;;
        s) squeeze=1
           ;;
        *) helptext
           exit 1
           ;;
    esac
done
shift $((OPTIND - 1))

[[ $# > 1 ]] && textwidth=$2


noreturn "$1" |	transcode - |

# Eerst wordt van alle niet-display regels elke opeenvolging van meer dan 1 tab beperkt tot 1 enkele tab.
# Ook worden eventueel nog aanwezige begin- en eindtabs verwijderd.
# Onderstaande nieuwe uitgangspunten liggen hieraan ten grondslag:
# Elke groep van opeenvolgende tabs in uitgelijnde tabellen betreft per definitie *ÉÉN (1)* kolom, 
# en moet dus eerst expliciet worden genormaliseerd naar 1 tab voor verdere verwerking.
# Dus in de hiervoor aangeleverde tabel gelden twee opeenvolgende tabs *PER DEFINITIE NIET MEER*
# als begrenzing van een daartussen liggende lege kolom !!
# Om een lege kolom te representeren moet als conventie vanaf nu een spatie (of een ander vrij te kiezen 
# karakter voor 'leeg' b.v. '-') worden geplaatst (in de laatste kolom volstaat een spatie in minimaal 1 regel).
# D.i. vóór en/of na altijd van elkaar *GESCHEIDEN* tabs, met inbegrip van de eerste en laatste kolom.
# Begin- en eind-tabs vallen daarmee buiten de definitie van (extra) cel/kolom, zijn daarmee ongeldig en
# worden door het programma verwijderd.
#
# Suggestie voor verbetering:
# Idealiter zou dit alleen moeten gebeuren bij echte tabelregels, niet bij overige regels.
# Dit om de overige tekst ongemoeid te laten.
#
awk 'BEGIN {display_started = 0}
/^\.DS/  { display_started = 1 }
/^\.DE$/ { display_started = 0 }
{
    if (! display_started){
        gsub(/\t+/, "\t")
        gsub(/^\t/, "")
        gsub(/\t$/, "")
    }
    print
}' |


# Vervolgens worden de eventuele .br regels tussen opeenvolgende tabelregels verwijderd (als deze al 
# in een TROFF tekst aanwezig zijn; tabel = twee opeenvolgende regels met minimaal twee *GESCHEIDEN* tabs):
#
awk 'BEGIN {FS = "\t"; prev = ""; pprev = ""}

{
    if ( ! ($0 ~ /\t[^\t]+\t/ && prev ~ /^\.br$/ && pprev ~ /\t[^\t]+\t/)) # "NAND"-conditie!
        print prev
    pprev = prev
    prev = $0
}

END {print prev}' |


# Van elke tabel wordt het grootste aantal cellen bepaald dat in regels van die tabel voorkomt.
# De gevonden waarde zal worden ingesteld als het aantal kolommen voor de tabel in kwestie.
#
awk 'BEGIN {FS = "\t"; tbl = 1; prev_line = ""; display_started = 0; rowcount = 0}
/^\.DS/  { display_started = 1 }
/^\.DE$/ { display_started = 0 }

$0 ~ /\t[^\t]+\t/ && ! display_started \
{
    if (prev_line !~ /\t[^\t]+\t/){       # Eerste regel van potentiële nieuwe tabel
        if(rowcount > 1)                  # Als de vorige tabel rowcount > 2 regels  had, dus een *echte* tabel was ...
            ++tbl                         # .. dan krijgt de nieuwe (potentiële) tabel een *HOGER* nummer (tbl)
        else                              # Anders was de vorige tabel *onecht* en wordt het nummer *HERGEBRUIKT*
            columncount[tbl] = 0          # ...en wordt van de "onechte" tabel de eerder gevulde arraywaarde weer genuld
        rowcount = 1                      # Elke potentiële tabel begint met 1 regel
    }
    else
        ++rowcount                        # Hier heeft de tabel al minimaal 2 regels
    if (NF > columncount[tbl])
        columncount[tbl] = NF             # Max. aantal velden per regel per tabel => dus het aantal tabelkolommen
}

{
    print
    prev_line = $0
}

# Wegschrijven van de 2D-array "columncount" naar een gelijknamige file, die aan het begin van het 
# volgende awk-blok weer zal worden ingelezen naar een vergelijkbare 2D-array:
#
END \
{
    for (tbl = 1; tbl <= length(columncount); tbl++)        # Denk erom: *EXPLICIET IN VOLGORDE* langs de indices in awk!
        print columncount[tbl] >> "'"$columncount_file"'"

}' >| "$textfile"


[[ ! -f "$columncount_file" ]] && cat "$textfile" && cleanup


# Vervolgens worden alle valide tabelregels voorzien van de benodigde macro's en formateringsregels
# om in opmaak te worden weergegeven indien via een pipe aangeboden aan (b.v.) trofms() of nrofms() of een 
# andere TROFF functie met "tbl" optie:
#
awk -v tabletype="$tabletype" -v squeeze="$squeeze" -v "textwidth=$textwidth" '\

    function max(a, b){
        if (a >= b)
            return a
        else
            return b
    }

BEGIN {
    tbl = 0
    while (getline < "'"$columncount_file"'"){     # Max. aantal velden per regel per tabel => dus het aantal tabelkolommen
        ++tbl
        columncount[tbl] = $0
    }
    close("'"$columncount_file"'")

    FS = "\t"
    tbl = 0
    prev_line = ""
    prev_row = ""
    format_on = 0
    table_started = 0
    display_started = 0
    print ".nr table_nr 0"                          # Nieuw number register "table_nr" wordt geïnitialiseerd op 0
    print ".nr ps_decr \\n[.s]*2/10"                # Nieuw number register "ps_decr" wordt op 20% van de point size gesteld
}


/^\.DS/  { display_started = 1 }
/^\.DE$/ { display_started = 0 }

/\t[^\t]+\t/ && ! display_started \
{
    if (prev_line !~ /\t[^\t]*\t/){                 # De huidige regel is de eerste van een *potentiële* tabel
        type = tabletype                            # Maak type gelijk aan de ingestelde tabletype 
        format_string2 = ""
        for (i = 1; i <= columncount[tbl + 1]; i++) # Kijk alvast "vooruit" om de bijbehorende column-count op te halen
            format_string2 = "l "format_string2     # Leg deze vast in een string, die echter nog niet wordt uitgeprint
        format_on = 1                               # 1e regel is nu gesignaleerd, maar "tbl" kan pas omhoog bij 2e regel
        if (squeeze){
            chunk = int(max(textwidth/columncount[tbl+1]-4, 1)) # Kijk alvast "vooruit" om de bijbehorende "chunk" te bepalen
            regex = "("
            for (i = 1; i <= chunk; i++)            # Matchend aantal karakters, niet \:[( om escape-collisions te beperken
                regex = regex"[^:*\\\\\\[\\( ]"     # <============ OS X, hierin werken {} quantifiers niet ===============
            regex = regex")"
        }

    }
    else{
        if (format_on){                             # Dit is dus de 2e tabelregel, teken dat de tabel nu pas "echt" is
            ++tbl                                   # Hier kan dus pas het tabel-nummer omhoog
            print ".LP"                             # Bedoeld tegen table-orphans. Werkt niet want begin tabel = eind alinea
            print ".nr table_nr +1"                 # Hier laten we de waarde van het troff-register "table_nr" verhogen
            print ".ps -\\n[ps_decr]"               # en de point size verminderen met register "ps_decr" = 20% * point size
            print ".TS H"
            maxchunk = max(textwidth/8, 6)
            if (squeeze && chunk < maxchunk)        # Bij "squeeze" en onder een empirisch bepaalde maximale chunkwaarde ...
                type = "expand"                     # ... wijzig dan type (alsnog) van "center" naar "expand"
            print type", allbox;"
            format_string1 = "c"
            for (i = 2; i <= columncount[tbl]; ++i)
                format_string1 = format_string1 " s"
            print format_string1                    # Nu kunnen de format strings (incl de eerder voorbereide) worden geprint
            print format_string2 "."
            print ".ft 3"                           # Bolt font
            print "Tabel \\n[table_nr]"             # Tekst "Tabel" met huidige waarde van register "table_nr"
            print ".P"                              # Previous font
            print "_"
            print ".TH"
            format_on = 0                           # "format_on = 1" was een tussenstadium, dat is nu geëindigd
            table_started = 1                       # Tabel is gestart
        }
    }
    row = ""
    i = 1
    while (length($i)){
        text = $i
        if (squeeze)
            gsub(regex, "&\\:", text)               # Voeg een \: break sequence in na elke "chunk" aan karakters.
        row = row"T{\n"text"\nT}\t"
        i++
    }
}

prev_line !~ /\t[^\t]+\t/ && table_started \
{
    print ".TE"
    print ".LP"
    table_started = 0
}

{
    if (table_started)
        print prev_row
    else
        print prev_line
    prev_line = $0
    prev_row = row
}

END {
    if (prev_line !~ /\t[^\t]*\t/ && table_started){
        print ".TE"
        print ".LP"
        print prev_line
    }
    else if (prev_line ~ /\t[^\t]*\t/ && table_started){
        print row
        print ".TE"
    }
    else
        print prev_line
 }' "$textfile"

cleanup


# ==================== RJT SOFTWARE LABS - FOR MIRACLES IN SYSTEM DEVELOPMENT ====================


