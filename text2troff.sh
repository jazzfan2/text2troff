#!/bin/bash
# Name  : text2troff.sh
# Author: R.J.Toscani
# Date  : 12-01-2024
# Description: 'text2troff.sh' is a bash script that uses a combination of awk and sed filters to
# convert a flat text-file into TROFF text format, by inserting TROFF request and ‘ms’ macro
# commands. The result is sent to standard output, and can be processed further with available
# ‘troff’ tools with ‘ms’ macro package, preferrably GNU groff_ms(7), to produce typeset 
# PostScript-, PDF-, HTML- or terminal (‘nroff’) output. As an alternative to processing a 
# text-file, text2troff.sh can also read (text) input from a pipe.
#
# (Comment texts are still partly in Dutch - will be translated into English in due course!)
#
######################################################################################
#
# Copyright (C) 2024 Rob Toscani <rob_toscani@yahoo.com>
#
# text2troff.sh is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# text2troff.sh is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
######################################################################################

set -o noclobber    # Prevent files to be accidentally overwritten by redirection of standard output

####################################### FUNCTIONS START HERE #####################################

options(){
# Specify options:
    while getopts "a:BbcDdmf:hik:nNpesS:tuz:" OPTION; do
        case $OPTION in
            a) if   [[ $OPTARG == g ]]; then escape="gnu"         # Option if utf-8 is not available
               elif [[ $OPTARG == a ]]; then escape="at&t"        # idem, alternative  
               elif [[ $OPTARG == b ]]; then escape="berkeley"    # idem, alternative
               else                          escape="gnu"         # Default
               fi
               ;;
            B) clean_bullets=1   # N.B.: THIS FUNCTION IS NOT FULLY TESTED YET !
               ;;
            b) browser=1
               ;;
            c) console=1
               textwidth=$(tput cols)
               ;;
            D) fixed_date=1
               ;;
            d) columns=".2C"
               colnum=2
               ;;
            m) columnwidth=25
               colnum=3
               ;;
            f) if   [[ $OPTARG == H ]]; then font_family="H"      # Helvetica
               elif [[ $OPTARG == h ]]; then font_family="HN"     # Helvetica Narrow 
               elif [[ $OPTARG == a ]]; then font_family="A"      # Avant Garde  
               elif [[ $OPTARG == b ]]; then font_family="BM"     # Bookman
               elif [[ $OPTARG == c ]]; then font_family="C"      # Courier
               elif [[ $OPTARG == n ]]; then font_family="N"      # New Century Schoolbook
               elif [[ $OPTARG == p ]]; then font_family="P"      # Palatino
               else                          font_family="T"      # Times
               fi
               ;;
            h) helptext
               exit 0
               ;;
            i) keep_paragraph_indents=1
               ;;
            k) if   [[ $OPTARG == a  ]]; then color="aquamarine" && rgbcolor=".defcolor aquamarine rgb #0a5c5c"
               elif [[ $OPTARG == b  ]]; then color="blue"       && rgbcolor=".defcolor blue       rgb #17517e" 
               elif [[ $OPTARG == gn ]]; then color="darkgreen"
               elif [[ $OPTARG == gr ]]; then color="gray"       && rgbcolor=".defcolor gray       rgb #565656" 
               elif [[ $OPTARG == m  ]]; then color="magenta"    && rgbcolor=".defcolor magenta    rgb #8B008B"
               elif [[ $OPTARG == o  ]]; then color="olive"      && rgbcolor=".defcolor olive      rgb #666600"
               elif [[ $OPTARG == r  ]]; then color="red"        && rgbcolor=".defcolor red        rgb #b81414"

               else                      helptext                && exit 1
               fi
               ;;
            n) wrap_newlines=1
               ;;                 # newlinewrap
            N) number_headers=1
               ;;                 # numbered headers
            p) wrap_periods=1
               ;;                 # pointwrap
            e) tabletype="expand"
               ;;
            s) tablesqueeze=1
               ;;
            S) if   [[ $OPTARG == i  ]]; then style="italic"
               elif [[ $OPTARG == b  ]]; then style="bolt"
               elif [[ $OPTARG == bi ]]; then style="boltitalic"
               else                           style="regular"
               fi
               ;;
            t) table_of_contents=1
               ;;
            z) if grep -qE "^[[:digit:]]*\.?[[:digit:]]+$" <<<"$OPTARG"; then
                   size=$OPTARG
               else
                   helptext && exit 1
               fi
               ;;
            u) title_uppercase=1
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
Usage: text2troff.sh [-aBbcDdmfhiknNpesStuz] TEXTFILE

-h   Help (this output)
-B   Clean up "solitary" bullets (not tested yet)
-b   Optimize output for 'browser' (HTML)
-c   Optimize output for 'console' (terminal)
-D   Make document date equal to orginating date of TROFF-file
-d   Double column (2) layout
-m   Multi column (>=3) layout
-i   Have each paragraph start with an indented line

-N   Prefix all chapter headers by incrementing numbers
-n   Have typeset text start on new line if source text does 
-p   Have typeset text start on new line after end-of-sentence period
-e   Stretch tables ('expand') to text margins  
-s   Force tables within text margins ("squeeze") if too wide
-t   Automatically generate and include a Table of Contents
-u   Convert chapter header text from lower case to upper case
-a TYPE 
|    Convert characters with accent marks into escape-sequences: 
|    TYPE  = g   GNU groff_char(7)
|            a   AT&T ms legacy
|            b   Berkeley ms legacy
-f FONT
|    Character-font instead of default Times:
|    FONT  = H   Helvetica
|            h   Helvetica Narrow
|            a   Avant Garde
|            b   Bookman
|            c   Courier
|            n   New Century Schoolbook
|            p   Palatino
-S STYLE
|    Character-style instead of default Regular: 
|    STYLE = i   Italic
|            b   Bolt
|            bi  Bolt Italic
-z SIZE
|    Character size in pts
-k COLOR 
|    Text color instead of default:
|    COLOR = a   Aquamarine 
|            b   Blue
|            gn  Green
|            gr  Grey
|            m   Magenta
|            o   Olive
|            r   Red
EOF
}


opt_execute()
# Voer de [-npi] opties uit indien meegegeven:
{
    # Na eindpunt en/of newline op de volgende regel beginnen:
    if ! (( wrap_periods || wrap_newlines )); then
        tablewrap "$1" | wordwrap -
    else
        if (( wrap_periods )); then
            pointwrap "$1"
        else
            cat "$1"
        fi |
        if (( wrap_newlines )); then
            newlinewrap -
        else
            cat -
        fi
    fi |

    # Inspringingen handhaven aan het begin van een alinea:
    if (( keep_paragraph_indents )); then
        indent_paragraphs -
    else
        cat -
    fi
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


pasta()
# Het paste -d ";" commando als eigen functie omdat TinyCore op Tecra 550 dat commando niet kent:
{
    if command -v paste 1>/dev/null; then
        paste -d ";" "$1" "$2"
    else 
        file1="$1"
        file2="$2"
        awk  '\
        BEGIN {
            i = 0
            while (getline < "'"$file1"'")
                array[i++] = $0
            close("'"$file1"'")
            i = 0
        }
        {
            print array[i++]";"$0
        }' "$file2"
    fi
}


newlinewrap()
# Alle newlines in de brontekst laten terugkomen als breaks (.br) in de TROFF tekst, behalve in een code-blok
# of een tabel:
{
    sed -E $'/^(\.|x><x|x><><x)/!s/$/\\\n\.br/g'
}


pointwrap()
# Na elke punt (of uitroep- of vraagteken) aan het eind van een zin een break (.br) plaatsen in de TROFF tekst
# behalve in een code-blok (^x><x) of een tabel (^x><><x ), of indien er slechts 1 woord erna resteert
# op de regel vanwege het erop volgende wordwrap():
{
    sed -E $'/^(\.|x><x|x><><x)/!s/([^\.][[:alnum:] )"\047](\.|!|\\?){1,})(( {1,}[[:upper:](][^ ]* {1,}[^ ]{1,})|( |\t)*$)/\\1\\\n.br\\\n\\4/g' |
    tablewrap - | wordwrap -
}


tablewrap()
# Regels met daarin één of meer tabs (wat een tabel doet vermoeden) worden onder elkaar gezet, behalve in een code-blok:
{
    sed -E $'/^x><x/!s/(^[^\.][^\t]*\t{1,}.*)/\\1\\\n.br/g'
}


wordwrap()
# Regels bestaande uit 1 string zonder spaties/tabs worden onder elkaar gezet, behalve in een code-blok:
{
    sed -E $'/^x><x/!s/(^[^\.][^ \t]{1,}$)/\\1\\\n.br/g'
}


codetabs2spaces()
# Tabs in een code-blok vervangen door het juiste aantal spaties, conform tabpositie (uitgangspunt tabulatie = 4):
{
    awk 'BEGIN { 
        startcode = "\\[( |\t)*(C|c)(O|o)(D|d)(E|e)( |\t)*(=[^]]*)?\\]"
        endcode   = "\\[( |\t)*/( |\t)*(C|c)(O|o)(D|d)(E|e)( |\t)*\\]"
        codeblock = 0
    }

    $0 ~ startcode  { codeblock = 1 }
    $0 ~ endcode    { codeblock = 0 }

    {
        if (/\t/ && codeblock){
            previouschars = 0
            split($0, chars, "")
            for (i = 1; i <= length($0); i++) {
                if (chars[i] == "\t"){
                    spaces = 4 - (previouschars % 4)
                    printf("%"spaces"s", "")
                    previouschars = 0
                }
                else{
                    printf("%s", chars[i])
                    previouschars++
                }
            }
            printf("%s\n", "")
        }
        else
            print
    }' "$1"
}
# (=> LET OP: functie werkt alleen als code-regels *NIET* zijn voorzien van "code-markers" (x><x).)


get_footnotes()
# Alleen de voetnoten in de tekst worden geprint, elk als een string zonder spaties, tabs of newlines.
# Genoemde karakters worden daartoe tijdelijk omgezet in resp. x><><><x, x><><><><x en x><><><><><x combinaties
# ( = niet gangbaar in tekst), om splitsing van de string tegen te gaan wanneer deze in een array wordt ingelezen.
# (Codeblok-regels zijn niet onderhevig aan deze functie doordat ze zijn voorzien van markers x><x aan het begin.)
{
    awk 'BEGIN { footnote = 0 }
    {
        if (/^( | \t)*\(\*+\)/){               # Bij een (*..*) aan het begin ...
            if (footnote){                     # en indien vorige regel ook reeds een voetvoot was ...
                print string                   # print dan die vorige voetnoot, want die is nu gestopt
            }
            string = ""                        # Maak een lege voetnootstring voor de nieuwe voetnoot aan
            footnote = 1                       # en zet de "footnote" switch aan
        }
        else if (/^(\.LP|\.PP)/ && footnote){  # Zodra (lege) regel met .LP of .PP macro langs komt in een voetnoot ...   
            print string                       # dan is de voetnoot gestopt en kan de voetnootstring geprint worden
            string = ""                        # maak de voetnootstring weer leeg
            footnote = 0                       # en zet de "footnote" switch uit
        }
        if (footnote){                                 # Indien een regel een voetnootregel is ...
            gsub(/^( | \t)*\(\*+\)( | \t)*/, "", $0)   # Verwijder een (*..*) aan het begin van de regel
            gsub(/ /,  "x><><><x", $0)                 # Vervang spaties door tijdelijke vervangers
            gsub(/\t/, "x><><><><x", $0)               # Vervang tabs door tijdelijke vervangers
            string = string""$0"x><><><><><x"  # en voeg huidige regel aan voetnootstring toe met newline vervanger
        }
    }
    END {
        if (footnote){                         # Als de laatste regel nog een voetnoot was ..
            print string                       # print die dan uit
        }
    }' "$1"
}


clean_footnotes()
# De voetnoten worden op de oorspronkelijke plaats in de tekst verwijderd.
# (Codeblok-regels zijn niet onderhevig aan deze functie doordat ze zijn voorzien van markers x><x aan het begin.)
{
    awk 'BEGIN { footnote = 0 }
    {
        if (/^( | \t)*\(\*+\)/){               # De voetnoot begint bij een (*..*) aan het begin
            footnote = 1
        }
        else if (/^(\.LP|\.PP)/){              # De voetnoot eindigt bij een (lege) regel met .LP of .PP macro
            footnote = 0
        }
        if (! footnote){                       # Print alleen de regels die geen voetnoot zijn
            print
        }
    }' "$1"
}


put_footnotes()
# Alle markeringspunten van de vorm <spatie>'*..*') worden vervangen door \** , waarna de regel direct wordt gevolgd
# door een voetnootblok .FS/.FE met daarin de voetnoottekst met corresponderende index vanuit de array "footnotes".
# De tijdelijke combinaties x><><><x, x><><><><x en x><><><><><x worden daarbij weer teruggewijzigd naar resp. spatie, tab en newline.
# Voetnoten kunnen tevens vanuit een bulletlijst of een tabel worden gemarkeerd. Hiertoe wordt op "table markers"
# gecheckt opdat (een)voetnootblok(ken) pas ná de tabel word(t)(en) ingevoegd (om splitsen van de tabel te voorkomen).
# Een voetnoot kan ook zelf een "code"-blok ([code]...[/code]), bullet-lijsten of zelfs een tabel bevatten.
# Bij inlezen van een bash string in awk() d.m.v. de -v optie worden \ tekens in de string geïnterpreteerd, niet gekopieerd.
# Een alteratieve methode waarbij dit probleem niet optreedt is inlezen van de variable in de ENVIRON-array in awk(), zie:
# https://unix.stackexchange.com/questions/542560/prevent-awk-from-removing-backslashes-in-variable
# Dit werkt op alle platforms, GNU/Linux en BSD
# Ook de kleur wordt nogmaals ingesteld omdat de algemene instelling daarvan niet voldoende blijkt voor footnotes
# (evenals bij bullets). 
{
    string="${footnotes[*]}" awk -v color="$color" 'BEGIN { notestack = 0; n = split(ENVIRON["string"], footnotes, " "); i = 1 }
    {
        if (/[^ \t]( |\t)+\*+\)/ && ! /^x><x/){      # Als (een) voetnoot-markeringspunt(en) word(t)(en) gesignaleerd ...
            while (sub(/( |\t)+\*+\)/, "\\**", $0))  # Wijzig elk exemplaar dan achtereenvolgens in: \**
                notestack ++                         # Houd benodigde aantal voetnoten bij, kan > 1 worden indien niet meteen plaats is
            footnote_marker = 1                      # Signaleer met een switch dat deze regel een voetnoot-markeringspunt heeft
            print $0                                 # Print deze regel (dus voorafgaand aan de voetnoot zelf)

        }
        while (notestack && ! /^x><x/ && ! /^x><><x /){   # Blijf voetnoten ophalen zolang de stack niet leeg is, en
                                                          # niet in codeblok (^x><x) of tabel (^x><><x)
            line = ".FS\n\\m["color"]"footnotes[i]".FE"   # Voorzie eerstvolgende voetnoottekst uit de array van macros (en kleur)
            gsub(/x><><><x/, " ",  line)             # Niet-gangbare tijdelijke combinatie x><><><x weer terug vervangen naar spatie
            gsub(/x><><><><x/, "\t", line)           # Idem x><><><><x naar tab
            gsub(/x><><><><><x/, "\n", line)         # Idem x><><><><><x naar newline
            print line                               # Plaats eerst het voetnootblok met macros
            i ++                                     # Indexeer de array;
            notestack --                             # Éen benodigde voetnoot minder ...
        }
        if (footnote_marker){                        # Indien de huidige regel (een) voetnoot-markeringspunt(en) bevatte ..
            footnote_marker = 0                      # zet dan de switch hier dan weer uit
            next                                     # en printen ervan is niet nodig want dat was hierboven al gebeurd
        }
        print                                        # Anders wordt de huidige regel hier geprint
    }' "$1"
}


remove_outer_tabgoups()
# Alle groepen van TABS direct aan het BEGIN en EIND worden overal verwijderd (in codeblocks zitten ze niet meer):
{
    sed $'s/^\t*//g' |
    sed $'s/\t*$//g'
}


add_tablemarker()
# Alle groepen van minimaal twee opeenvolgende regels, met in elk daarvan minimaal twee gescheiden tabs
# (aan begin en eind waren ze al weg), worden voorzien van een tijdelijke "table-marker" vooraan de regel.
# Deze marker is een niet-gangbare karaktercombinatie, nl. x><><x
# (De spatie waarmee de marker eindigt dient om eventuele aanhalingstekens erna correct te laten verwerken.)
{
    awk 'BEGIN { prev_line = ""; table_started = 0 }
    {
        if (/\t+[^\t]+\t+/ && prev_line ~ /\t+[^\t]+\t+/ ) # Huidige en vorige regel minimaal twee gescheiden tabs 
        {
            table_started = 1                              # zet (of houd) dan de tabelschakelaar aan
            gsub(/^/, "x><><x ", prev_line)                # en zet table-marker ^x><><x vooraan de vorige regel
        }
        else if (! /\t+[^\t]+\t+/ && table_started )       # Huidige regel geen tabelregel (meer) maar vorige nog wel
        {
            gsub(/^/, "x><><x ", prev_line)                # zet dan table-marker ^x><><x vooraan de vorige regel
            table_started = 0                              # en zet de tabelschakelaar uit
        }
        print prev_line                                    # Print de vorige regel
        pprev_line = prev_line
        prev_line = $0
    }
    END {
        if (prev_line ~ /\t+[^\t]+\t+/ &&                  # Laatste regel (prev_line) minimaal twee gescheiden tabs
            pprev_line ~ /\t+[^\t]+\t+/ )                  # en voorlaatste (pprev_line) ook
            gsub(/^/, "x><><x ", prev_line)                # zet dan table-marker ^x><><x vooraan de laatste regel
        print prev_line
    }' "$1"
}


remove_outer_tabs_spaces()
# Alle groepen van TABS en/of SPATIES direct aan het BEGIN en EIND worden verwijderd, 
# overal *BEHALVE CODEBLOCKS EN TABELLEN*:
{
    awk  'BEGIN { codeblock = 0 }
    /^(x><x)?\.DS I 3/  { codeblock = 1 }         # Codeblokken zowel gemarkeerd (x><x) als ongemarkeerd,
    /^(x><x)?\.DE$/     { codeblock = 0 }         # ... want deze functie wordt 2x toegepast!
    {
        if (! (codeblock || /^x><><x/)){          # Niet bij code-blok of tabel (table marker = x><><x)
            gsub(/^( |\t)*/, "", $0)
            gsub(/( |\t)*$/, "", $0)
        }
        print
    }' "$1"
}


indent_paragraphs()
# Alinea's laten beginnen met een inspringing, indien aangeroepen met optie -i:
{
    sed 's/^\.LP/.PP/g'
}


remove_tablemarker()
# De aanwezige "table-markers" worden verwijderd (inclusief de eindspatie).
# Geen global replace, maar alléén de eerste in de regel!!
{
    sed 's/^x><><x //'      # ^x><><x is de tijdelijke table-marker, kenmerk van een tabelregel.
}


solitary_bullets()
# Functie die een lijst oplevert met regelnummers waarop zich "solitaire" .IP macro's (bullets) bevinden.
# Deze worden gevonden op basis van statistiek, toegepast op de maximale afstand waarbinnen zich doorgaans
# een volgende bullet in de TROFF tekst bevindt (proefondervindelijk te bepalen).
# De parameter "limit" is hier het maximaal toegestane aantal tussenregels tot de twee naburige bullets in
# de troff-tekst. De waarde daarvan is een wat lastig compromis tussen wat minimaal nodig is voor het
# behouden van alle "juiste bullets" en wat niet te groot is voor het effectief wegvangen van de meeste
# "valse bullets".
{
    awk 'BEGIN {limit = 17 ; pprev = prev = 0}
    /^\.IP/ {
        if(NR - prev > limit && prev - pprev > limit)
            print prev
        pprev = prev
        prev = NR
    }
    END {
        if(prev - pprev > limit)
            print prev
    }' "$1"
}


bullet_clean()
# Functie die onterechte "solitaire" bullets wegfiltert, gebruik makend van de lijst uit solitary_bullets():
# Zie ook https://www.golinuxhub.com/2017/09/sed-perform-search-and-replace-only-on/
# LET OP: DEZE FUNCTIE IS NOG NIET VOLLEDIG GETEST !
{
    if (( $clean_bullets )); then
        regex_string="`solitary_bullets "$1" |
        while read line_nbr; do
            echo "${line_nbr}s/\.IP .(.+).$/\1/g; "
        done`"
        sed -E "$regex_string" "$1"
    else
        cat "$1"
    fi
}


remove_uselessbreaks()
# Verwijderen van een .br request vóór of na een .LP , .PP of .IP regel, en vóór een .FE of .DS regel:
{
	awk 'BEGIN { pprev = ""; prev = ""}
	{
	    if (prev ~ /^\.br$/ &&
 	       (pprev ~ /^(\.LP|\.PP|\.IP)/ || $0 ~ /^(\.LP|\.PP|\.IP|\.FE|\.DS)/) )
 	        ;
 	    else
 	        print prev
 	    pprev = prev
 	    prev = $0
	}
	END { print prev }' "$1"                   # Prev is nu de laatste regel !
}


delete_emptylines()
# Alle lege regels in de TROFF-tekst verwijderen, behalve in een "code"-blok ([code]...[/code]):
{
    awk  'BEGIN { codeblock = 0 }
    /^(x><x)?\.DS I 3/ { codeblock = 1 }
    /^(x><x)?\.DE$/    { codeblock = 0 }
    {
        if (codeblock)
            print
        else{
            if (! /^\t* *\t* *\t*$/)           # Maximale combinatie van tabs en spaties die geen tabel kan betekenen
                print
        }
    }' "$1"
}


uniq_macros()
# Alle zich herhalende TROFF-macro's verwijderen. 
# Tekst in "code"-bloks ([code]...[/code]) wordt ongewijzigd geprint !!
# Alle overige tekstregels beginnend met een punt worden verondersteld reeds te zijn beschermd met een \& escape,
# en codeblok-regels zijn sowieso uitgesloten want daar wil je überhaupt geen dubbele regels weghalen.
{
    awk 'BEGIN  { codeblock = 0; prev = "" }
    /^\.DS I 3/ { codeblock = 1 }
    /^\.DE$/    { codeblock = 0 }
    {
        if (codeblock)
            print
        else
            if (/^\../ && $0 == prev)
                next
            else
                print
        prev = $0
     }' "$1"

}
# (=> LET OP: functie werkt alleen als code-regels *NIET* zijn voorzien van "code-markers" (x><x).)


format_tables()
# De gewenste tabelformatering toepassen:
{
    option=""
    [[ $tabletype    == "expand" ]] && option="$option""e"   # Roep text2troff_table.sh aan met optie -e
    [[ $tablesqueeze == 1        ]] && option="$option""s"   # Roep text2troff_table.sh aan met optie -s

    [[ $option == "" ]] && text2troff_table.sh            "$1" $columnwidth  ||
                           text2troff_table.sh -"$option" "$1" $columnwidth
}


get_common_offsets()
# Per codeblok het grootste gemeenschappelijk aantal beginspaties ("common offset" = kleinste regel-indent) bepalen:
{
    awk 'BEGIN { codeblock = 0; code_on = 0; s_min = 1000 }
    /^\.CW/    { codeblock = 1; next }
    /^\.DE$/   { codeblock = 0 }
    {
        if (codeblock && $0 !~ /^ *$/){        # Lege regels tellen niet mee in de bepaling van de kleinste indent
            code_on = 1
            textline = $0
            gsub(/^ */, "", textline)
            s = length($0) - length(textline)
            if (s < s_min)
                s_min = s
        }
        else if (! codeblock && code_on){
            print s_min
            code_on = 0
            s_min = 1000
        }
    }' "$1"
}


cut_common_offsets()
# Per codeblok het grootste gemeenschappelijk aantal beginspaties ("common offset") verwijderen van de indents:
{
    awk '\
    BEGIN {
        codeblock = 0; i = 1; split("", common_offset)
        while (getline < "'"$offsets"'"){
            common_offset[i++] = $0
        }
        close("'"$offsets"'")
        i = 0
    }
    /^\.CW/  { codeblock = 1; print; code_on = 1; i++; next }
    /^\.DE$/ { codeblock = 0; code_on = 0 }
    {
        if (codeblock && $0 != ""){
            textline = $0
            gsub(/^ */, "", textline)
            indent_length = length($0) - length(textline) - common_offset[i]
            indent = ""
            for (j = 0; j < indent_length; j++)
                indent = indent" "
            print indent""textline
        }
        else
            print
    }' "$1"
}


wrap_codelines()
# Deel lange regels in een "code"- blok ([code]...[/code]) zodanig op dat de tekst past binnen columnwidth (2e argument),
# tenzij geoptimaliseerd wordt voor een HTML-browser, dan wordt het wrappen uitgeschakeld.
# Verder wordt vóór elke backslash een tweede exemplaar geplaatst, en vóór elke punt aan het begin een \& escape,
# nadat eerst de extra beschermings-punt voor de allereerste punt op de regel weer is weggehaald (sub(/\.\./, ".")).
{
    columnwidth=$2

    awk -v columnwidth="$columnwidth" -v browser=$browser -v console=$console -v colnum=$colnum \
    'function max(a, b)
    {
        if (a >= b)
            return a
        else
            return b
    }

    function break_and_print(line, regex)
    {
        split("", array)
        i = 0
#       print length(line), codewidth
        if (! browser){                                      # Function to break the line, except in browser
            while((len = length(line)) > codewidth){         # As long as the line exceeds codewidth
                line2 = line                                 # Define the line-part 2 that must wrap
                sub(regex, "", line2)                        # This breaks after part matching the regex
                if (line2 == line)                           # Only if line cannot break using the regex ..
                    line2 = substr(line, codewidth + 1)      # ..  then force a break at codewidth position!!
                line1 = substr(line, 1, len - length(line2)) # Part 1 before break is short enough ...
                array[i++] = line1                           # .. and is stored into the array
                line = line2                                 # The remaining part 2 is evaluated again
            }
            for (j = 0; j < length(array); j++){             # Loop through earlier line parts in the array
                gsub(/\\/, "\\\\", array[j])                 # Each backslash prefixed by another one
                gsub(/^\./, "\\\\\\&.", array[j])            # any leading "." prefixed by \& escape
                print array[j]                               # ... and print each line part
            }
        }
        gsub(/\\/, "\\\\", line)                        # Each "\" in line 2 escaped by prefixing another one
        gsub(/^\./, "\\\\\\&.", line)                   # any leading "." escaped by prefixing an \& escape
        print line                                      # ... and print line 2
    }


    BEGIN {codeblock = 0; list_indent = 0; right_shift = 0; prev_width = 0; code_indent = 3; 
           if (console)
               horiz_delta = 3                          # De list indent- en shift-waarden in aantal karakters
           else{
               horiz_delta = 2.4                        # Getuned naar 2.4 in geval van troff i.p.v. nroff
               if (colnum == 3)
                   columnwidth = int(columnwidth/1.15)  # Bij 3-koloms in troff minder karakters/kolom dan in nroff!
           }
    }
    /^\.DS I 3/  { codeblock = 1 }
    /^\.DE$/     { codeblock = 0 }
    /^\.IP/      { list_indent =  horiz_delta }  
    /^\.(LP|PP)/ { list_indent =  0; right_shift = 0 }
    /^\.RS/      { right_shift += horiz_delta } 
    /^\.RE/      { right_shift -= horiz_delta }
    {
        if (codeblock && $0 !~ /^\.DS/ && $0 !~ /^\.CW/){
            sub(/\.\./, ".")                             # Punt a/h begin ter bescherming macros in block weg
            codewidth = int(max(columnwidth - code_indent - list_indent - right_shift, 1))
            lowlimit  = int(max(codewidth - 8, 1))
            if (codewidth != prev_width && ! browser){
                regex = "^("
                for (w = lowlimit; w <= codewidth; w++){
                    for (i = 1; i <= w; i++)   # t.b.v. OS X, workaround voor daar niet werkende {} quantifiers
                        regex = regex"."
                    if (w < codewidth)
                        regex = regex"|"
                }
                regex = regex")[:/; ,._=!@#$%&*})>?-]"
            }
            break_and_print($0, regex )        # Break after max. "codewidth", escape and print the line
            prev_width = codewidth
        }
        else
            print
    }' "$1"
}
# (=> LET OP: functie werkt alleen als code-regels *NIET* zijn voorzien van "code-markers" (x><x).)


char_convert()
# Speciale karakter(-combinatie)s converteren voor opmaak, behalve in een "code"-blok ([code] .. [/code]):
{
    awk 'BEGIN  { codeblock = 0 }
    /^\.DS I 3/ { codeblock = 1 }
    /^\.DE$/    { codeblock = 0 }
    {
        if (codeblock)
            print
        else{
            gsub(/(http[^ ]+)/, "\\f2&\\f[P]", $0)    # Urls gecursiveerd weergeven
            gsub("…",     "..."     ) # Drie puntjes in opmaak weergeven
            gsub(/<-+/,   "\\(<-"   ) # Linker pijl in opmaak weergeven
            gsub(/-+>/,   "\\(->"   ) # Rechter pijl in opmaak weergeven
            gsub(/ - /,   " \\(en " ) # Gedachtenstreep; \(em kan eventueel ook, die is iets langer dan \(en
            gsub(/ -$/,   " \\(en"  ) # Idem aan eind van de regel
            gsub(/ij/,    "\\[ij]"  ) # ij tot onbreekbare eenheid maken (zie man groff_char(7))
            gsub(/IJ/,    "\\[IJ]"  ) # Idem met IJ
            gsub(/\+\/-/, "\\(+-"   ) # Plusminus
            gsub(/>=/,    "\\(>="   ) # Groter dan of gelijk aan
            gsub(/<=/,    "\\(<="   ) # Kleiner dan of gelijk aan
            print
        }
    }' "$1"
}
# (=> LET OP: functie werkt alleen als code-regels *NIET* zijn voorzien van "code-markers" (x><x).)


char_escape()
# Checken of de terminal Unicode (UTF-8) kan weergeven. Zo ja de tekst ongewijzigd weergeven, zo nee
# (of in geval van optie -a) de resterende speciale karakters vervangen door escape-sequences:
{
    if ( echo "$LANG" | grep -q UTF-8 && [[ $escape == "none" ]] ); then
        cat "$1"
    else
        # AT&T "native"-TROFF escape sequences van de vorm '\(xy'.
        # Afgeleid van bestand 'text2troff_escapesequences.txt' d.m.v. 
        # awk '{print "s/" $1 "/\\" $2 "/g; "}' text2troff_escapesequences.txt | tr -d '\n'
        sed '
        s/©/\\(co/g; s/®/\\(rg/g; s/—/\\(em/g; s/–/\\(en/g; s/°/\\(de/g; s/•/\\(bu/g; s/¼/\\(14/g;
        s/†/\\(dg/g; s/□/\\(sq/g; s/½/\\(12/g; s/′/\\(fm/g; s/¾/\\(34/g; s/¢/\\(ct/g; s/+/\\(pl/g;
        s/=/\\(eq/g; s/≠/\\(!=/g; s/∼/\\(ap/g; s/→/\\(->/g; s/∫/\\(is/g; s/⊂/\\(sb/g; s/⊆/\\(ib/g;
        s/§/\\(sc/g; s/⎧/\\(lt/g; s/⎩/\\(lb/g; s/⎨/\\(lk/g; s/│/\\(br/g; s/∗/\\(**/g; s/−/\\(mi/g;
        s/≡/\\(==/g; s/±/\\(+-/g; s/≈/\\(~=/g; s/←/\\(<-/g; s/∂/\\(pd/g; s/⊃/\\(sp/g; s/⊇/\\(ip/g;
        s/‡/\\(dd/g; s/⎫/\\(rt/g; s/⎭/\\(rb/g; s/⎬/\\(rk/g; s/|/\\(or/g; s/×/\\(mu/g; s/≥/\\(>=/g;
        s/¬/\\(no/g; s/∝/\\(pt/g; s/↑/\\(ua/g; s/∞/\\(if/g; s/∪/\\(cu/g; s/∈/\\(mo/g; s/○/\\(ci/g;
        s/☜/\\(lh/g; s/⌈/\\(lc/g; s/⌊/\\(lf/g; s/÷/\\(di/g; s/≤/\\(<=/g; s/∇/\\(gr/g; s/↓/\\(da/g;
        s/√/\\(sr/g; s/∩/\\(ca/g; s/∅/\\(es/g; s/☞/\\(rh/g; s/⌉/\\(rc/g; s/⌋/\\(rf/g; s/ς/\\(ts/g;
        s/α/\\(*a/g; s/β/\\(*b/g; s/γ/\\(*g/g; s/δ/\\(*d/g; s/ε/\\(*e/g; s/ζ/\\(*z/g; s/η/\\(*y/g;
        s/θ/\\(*h/g; s/ι/\\(*i/g; s/κ/\\(*k/g; s/λ/\\(*l/g; s/μ/\\(*m/g; s/ν/\\(*n/g; s/ξ/\\(*c/g;
        s/ο/\\(*o/g; s/π/\\(*p/g; s/ρ/\\(*r/g; s/σ/\\(*s/g; s/τ/\\(*t/g; s/υ/\\(*u/g; s/φ/\\(*f/g;
        s/χ/\\(*x/g; s/ψ/\\(*q/g; s/ω/\\(*w/g; s/Α/\\(*A/g; s/Β/\\(*B/g; s/Γ/\\(*G/g; s/∆/\\(*D/g;
        s/Ε/\\(*E/g; s/Ζ/\\(*Z/g; s/Η/\\(*Y/g; s/Θ/\\(*H/g; s/Ι/\\(*I/g; s/Κ/\\(*K/g; s/Λ/\\(*L/g;
        s/Μ/\\(*M/g; s/Ν/\\(*N/g; s/Ξ/\\(*C/g; s/Ο/\\(*O/g; s/Π/\\(*P/g; s/Ρ/\\(*R/g; s/Σ/\\(*S/g;
        s/Τ/\\(*T/g; s/Υ/\\(*U/g; s/Φ/\\(*F/g; s/Χ/\\(*X/g; s/Ψ/\\(*Q/g; s/Ω/\\(*W/g' |

        # Herstel de '+' in de aanwezige auto-increment TROFF requests (is nl. hierboven "verhaspeld"!)
        sed -E "s/(\\\\n)\\\\\\(pl(\[chapt_nr\])/\1+\2/g" |         # '\(pl' weer terug naar '+'
        sed -E "/^\.nr/s/\\\\\\(pl/+/g" |                           # '\(pl' weer terug naar '+'

        if [[ $escape == "at&t" ]]; then
           # AT&T legacy ms escape-sequences van de vorm '\*[^]glyph' (haken mogen weg) t.b.v. accenten:
            # Zie https://www.gnu.org/software/groff/manual/groff.html.node/ms-Legacy-Features.html
            sed "s/ë/\\\*[:]e/g ; s/Ë/\\\*[:]E/g ; s/ü/\\\*[:]u/g ; s/Ü/\\\*[:]U/g ; s/ä/\\\*[:]a/g ;
            s/Ä/\\\*[:]A/g ; s/ö/\\\*[:]o/g ; s/Ö/\\\*[:]O/g ; s/ï/\\\*[:]i/g ; s/Ï/\\\*[:]I/g ;
            s/á/\\\*[']a/g ; s/Á/\\\*[']A/g ; s/é/\\\*[']e/g ; s/É/\\\*[']E/g ;
            s/í/\\\*[']i/g ; s/Í/\\\*[']I/g ; s/ó/\\\*[']o/g ; s/Ó/\\\*[']O/g ;
            s/ú/\\\*[']u/g ; s/Ú/\\\*[']U/g ;
            s/è/\\\*[\\\`]e/g ; s/È/\\\*[\\\`]E/g ; s/à/\\\*[\\\`]a/g ;
            s/À/\\\*[\\\`]A/g ; s/ò/\\\*[\\\`]o/g ; s/Ò/\\\*[\\\`]O/g ;
            s/ê/\\\*[^]e/g ; s/Ê/\\\*[^]E/g ; s/û/\\\*[^]u/g ; s/Û/\\\*[^]U/g ; s/â/\\\*[^]a/g ;
            s/Â/\\\*[^]A/g ; s/ô/\\\*[^]o/g ; s/Ô/\\\*[^]O/g" |
            # Cedille:
            sed "s/ç/\\\*[,]c/g ; s/Ç/\\\*[,]C/g" |
            # Tilde:
            sed "s/ã/\\\*[~]a/g ; s/Ã/\\\*[~]A/g ; s/ñ/\\\*[~]n/g ; s/Ñ/\\\*[~]N/g"

        elif [[ $escape == "berkeley" ]]; then
            # "Berkeley" legacy ms escape-sequences van de vorm 'glyph\*[^]' (haken mogen weg)
            # Zie man groff_ms(7), man groff(7) en:
            # https://www.gnu.org/software/groff/manual/groff.html.node/ms-Legacy-Features.html
            # https://man.freebsd.org/cgi/man.cgi?query=groff&sektion=7&format=html
            # Worden gebruikt in combinatie met .AM macro aan het begin (deze dus inschakelen)
            sed "s/ë/e\\\*[:]/g ; s/Ë/E\\\*[:]/g ; s/ü/u\\\*[:]/g ; s/Ü/U\\\*[:]/g ; s/ä/a\\\*[:]/g ;
            s/Ä/A\\\*[:]/g ; s/ö/o\\\*[:]/g ; s/Ö/O\\\*[:]/g ; s/ï/i\\\*[:]/g ; s/Ï/I\\\*[:]/g ;
            s/á/a\\\*[']/g ; s/Á/A\\\*[']/g ; s/é/e\\\*[']/g ; s/É/E\\\*[']/g ;
            s/í/i\\\*[']/g ; s/Í/I\\\*[']/g ; s/ó/o\\\*[']/g ; s/Ó/O\\\*[']/g ;
            s/ú/u\\\*[']/g ; s/Ú/U\\\*[']/g ;
            s/è/e\\\*[\\\`]/g ; s/È/E\\\*[\\\`]/g ; s/à/a\\\*[\\\`]/g ;
            s/À/A\\\*[\\\`]/g ; s/ò/o\\\*[\\\`]/g ; s/Ò/O\\\*[\\\`]/g ;
            s/ê/e\\\*[^]/g ; s/Ê/E\\\*[^]/g ; s/û/u\\\*[^]/g ; s/Û/U\\\*[^]/g ; s/â/a\\\*[^]/g ;
            s/Â/A\\\*[^]/g ; s/ô/o\\\*[^]/g ; s/Ô/O\\\*[^]/g" |
            # Cedille:
            sed "s/ç/c\\\*[,]/g ; s/Ç/C\\\*[,]/g" |
            # Tilde:
            sed "s/ã/a\\\*[~]/g ; s/Ã/A\\\*[~]/g ; s/ñ/n\\\*[~]/g ; s/Ñ/N\\\*[~]/g" |
            # A-ring:
            sed "s/å/a\\\*[o]/g ; s/Å/A\\\*[o]/g" |
            # O-slash:
            sed "s/Ø/O\\\*[\/]/g ; s/ø/o\\\*[\/]/g" |
            # Ringel-S:
            sed "s/ß/\\\*[8]/g" 

        else
            # GNU groff_char escape-sequences (zie man groff_char(7)):
            sed "s/ë/\\\[:e]/g ; s/Ë/\\\[:E]/g ; s/ü/\\\[:u]/g ; s/Ü/\\\[:U]/g ; s/ä/\\\[:a]/g ;
            s/Ä/\\\[:A]/g ; s/ö/\\\[:o]/g ; s/Ö/\\\[:O]/g ; s/ï/\\\[:i]/g ; s/Ï/\\\[:I]/g ;
            s/á/\\\['a]/g ; s/Á/\\\['A]/g ; s/é/\\\['e]/g ; s/É/\\\['E]/g ;
            s/í/\\\['i]/g ; s/Í/\\\['I]/g ; s/ó/\\\['o]/g ; s/Ó/\\\['O]/g ;
            s/ú/\\\['u]/g ; s/Ú/\\\['U]/g ;
            s/è/\\\[\\\`e]/g ; s/È/\\\[\\\`E]/g ; s/à/\\\[\\\`a]/g ;
            s/À/\\\[\\\`A]/g ; s/ò/\\\[\\\`o]/g ; s/Ò/\\\[\\\`O]/g ;
            s/ê/\\\[^e]/g ; s/Ê/\\\[^E]/g ; s/û/\\\[^u]/g ; s/Û/\\\[^U]/g ; s/â/\\\[^a]/g ;
            s/Â/\\\[^A]/g ; s/ô/\\\[^o]/g ; s/Ô/\\\[^O]/g" |
            # Cedille:
            sed "s/ç/\\\[,c]/g ; s/Ç/\\\[,C]/g" |
            # Tilde:
            sed "s/ã/\\\[~a]/g ; s/Ã/\\\[~A]/g ; s/ñ/\\\[~n]/g ; s/Ñ/\\\[~N]/g" |
            # A-ring:
            sed "s/å/\\\[oa]/g ; s/Å/\\\[oA]/g" |
            # O-slash:
            sed "s/Ø/\\\[\/O]/g ; s/ø/\\\[\/o]/g" |
            # Ringel-S:
            sed "s/ß/\\\[ss]/g"
        fi
    fi
}


clean_codeblock()
# Verwijder overbodige witregels aan begin en einde van een "code"- blok ([code]...[/code]):
{
    tr '\n' '\r'                 |
    sed -E $'s/\r\.CW(\r *)*\r/\r.CW\r/g ; s/(\r *)*\r\.DE/\r.DE/g' |
    tr '\r' '\n'             # Truc met newline -> return en v.v.
}
# (=> LET OP: functie werkt alleen als code-regels *NIET* zijn voorzien van "code-markers" (x><x).)


remove_emptymacros()
# Verwijder een overbodige .LP of .PP of .br macro direct vóór een titelregel, eind van een voetnoot,
# of TOC macros's (.XS, .XE en .TC):
{
    awk '\
    { 
           a[++i] = $0                               # <===== OS X ======
    }
    END {
        for (j = length(a); j >= 1; j--){
            if ( a[j] ~ /^(\.SH|\.$|\.FE|\.XS|\.XE|\.TC)/ ){
                b[++m] = a[j]
                not_before_this = 1
            }
            else if ( a[j] ~ /^(\.LP|\.PP|\.br)/ && not_before_this ){
                not_before_this = 0
            }
            else{
                b[++m] = a[j]
                not_before_this = 0
            }
        }
        for (k = length(b); k >= 1; k--)
            print b[k]
    }'
}


preserve_quote()
# Vervang apostrof of enkele quote aan het begin van een regel door \(cq escape sequence:
{
	sed -E "s/^( |	)*'/\1\\\\(cq/g"
}
# (=> LET OP: functie werkt alleen als code-regels *NIET* zijn voorzien van "code-markers" (x><x).)


# Bij optimalisatie t.b.v. browser (optie -b) de .CW macro's wijzigen naar \f6 requests
# met als doel correcte courier weergave te bereiken in HTML.
courier_in_html()
{
    if (( browser )); then
        sed 's/^\.CW$/\\f6/'
    else
        cat -
    fi
}


opruimen()
# Alle tijdelijke files verwijderen:
{
    [ -f "$tempfile1" ] && \rm $tempfile1
    [ -f "$tempfile2" ] && \rm $tempfile2
    [ -f "$bullets" ] && \rm $bullets
    [ -f "$lines" ] && \rm $lines
    [ -f "$macros" ] && \rm $macros
    [ -f "$offsets" ] && \rm $offsets
}


postpostprocess()
# De laatste handelingen uitvoeren via deze diverse functies omvattende "meta-functie":
{
    # Alle "table-marker"s verwijderen:
    remove_tablemarker - |

    # Aanroepen van het "tabellen-script" voor het verwerken van tab-separated (tabel)regels:
    format_tables - >| "$tempfile2"

    # Per codeblok het grootste gemeenschappelijk aantal beginspaties bepalen:
    get_common_offsets "$tempfile2" >> "$offsets"

    # Per codeblok het grootste gemeenschappelijk aantal beginspaties verwijderen:
    cut_common_offsets "$tempfile2" |

    # Codeblokregels afbreken tot gewenste lengte:
    wrap_codelines - $columnwidth |

    # Special characters handling onder meer d.m.v. vervanging door escape-sequences:
    char_convert -        | char_escape -        |

    # Nogmaals alle lege regels en buitenste spaties en tabs verwijderen:
    delete_emptylines -   | remove_outer_tabs_spaces - |

    # Overbodige witregels aan begin en einde van code-blokken verwijderen, en .LP/.PP macro's vóór o.m. headers:
    clean_codeblock -     | remove_emptymacros - |

    # Apostrof of enkele quote a/h begin van een regel die daardoor anders zou wegvallen in de TROFF output
    # vervangen door \(cq sequence, en het eindresultaat naar stdout sturen:
    preserve_quote - |

    # Bij optimalisatie t.b.v. browser de .CW macro's wijzigen naar \f6 requests:
    courier_in_html -

    # Tijdelijke files verwijderen:
    opruimen
}
# (=> LET OP: functie werkt alleen als code-regels *NIET* zijn voorzien van "code-markers" (x><x).)


################################# MAIN PROGRAM STARTS HERE #####################################


trap "opruimen; exit" SIGINT

if [[ -d /tmp/ramdisk/ ]]; then
    tmpfiledir="/tmp/ramdisk"
elif [[ -d /dev/shm/ ]]; then
    tmpfiledir="/dev/shm"
else
    tmpfiledir="."
fi


tempfile1="$tmpfiledir/temp1_$RANDOM.ms"
tempfile2="$tmpfiledir/temp2_$RANDOM.ms"

bullets="$tmpfiledir/bullets$RANDOM"  # Kan wellicht ook een array of list zijn
lines="$tmpfiledir/lines$RANDOM"
macros="$tmpfiledir/macros$RANDOM"
offsets="$tmpfiledir/offsets$RANDOM"

columns=".1C"
colnum=1
browser=0
console=0
textwidth=74                          # Aantal monospace karakters van linker tot rechtermarge in troff bij 10 pts
clean_bullets=0
keep_paragraph_indents=0
wrap_periods=0
wrap_newlines=0
number_headers=0
tabletype="center"
tablesqueeze=0
font_family=T
style="regular"
size=10
uppercase=0
escape="none"
fixed_date=0
table_of_contents=0


# Voer de opties uit:
options $@
shift $(( OPTIND - 1 ))
touch $offsets


# We beginnen met de toevoeging van wat authentieke AT&T macro's, uit te voeren via de alias "trofform(.sh)":
# text2troff.sh [opties] [tekstfile.txt] | trofform
while read line; do
    echo "$line"
done << EOF
.RP
...TR
...IM
...TM 76-1273-10 39199 39199-11
...MF
...MR
...EG
EOF


# Maak de documentdatum gelijk aan de datum van ontstaan van de TROFF-file (alleen bij optie -D):
if (( fixed_date )); then
   echo ".ND \"$(date +"%d %B, %Y" |
   sed 's/\<j/J/; s/\<f/F/; s/\<m/M/; s/\<a/A/; s/\<s/S/; s/\<o/O/; s/\<n/N/; s/\<d/D/')\""
fi


# Het algemene font wordt ingesteld (default: Times), zie /usr/share/groff/current/font/devpdf:
# Zie /usr/share/groff/current/font/devpdf en
# https://www.gnu.org/software/groff/manual/groff.html.node/Font-Families.html:
echo ".fam $font_family"    


# De algemene font-style wordt ingesteld (default: Regular) volgens de meegegeven -S optie:
case $style in
    italic)     echo ".fp 1 "$font_family"I"     # Wijzig font-positie 1 van Regular (default) naar Italic
                echo ".fp 3 "$font_family"BI"    # Wijzig font-positie 3 van Bolt    (default) naar Bolt Italic
                ;;
    bolt)       echo ".fp 1 "$font_family"B"     # Wijzig font-positie 1 van Regular (default) naar Bolt
                echo ".fp 2 "$font_family"BI"    # Wijzig font-positie 2 van Italic  (default) naar Bolt Italic
                ;;
    boltitalic) echo ".fp 1 "$font_family"BI"    # Wijzig font-positie 1 van Regular (default) naar Bolt Italic
                echo ".fp 2 "$font_family"BI"    # Wijzig font-positie 2 van Italic  (default) naar Bolt Italic
                echo ".fp 3 "$font_family"BI"    # Wijzig font-positie 3 van Bolt    (default) naar Bolt Italic
                ;;
esac


# De algemene character-size (default: 10 pts) wordt ingesteld, behalve in browser en console:
if (( ! console )) && (( ! browser )); then
    echo ".nr PS $size"            
fi

# De algemene tekstkleur wordt ingesteld:
echo "$rgbcolor"
echo "\\m[$color]"                      # Werkt namelijk op Mac OS X niet goed met: .gcolor $color


# Weeskinderen instellen:
echo ".nr HORPHANS 5"
echo ".nr PORPHANS 3"


# User-defined number register voor de hoofdstuk-nummers, (niet gebruikte) beginwaarde 0, increment 1:
echo ".nr chapt_nr 0 1"


# Aantal karaktergrootte-levels instellen v/a standaardtekst t/m max. header-level, en vergroting per level: 
echo ".nr GROWPS 2"
echo ".nr PSINCR 1.5p"


# Bij Berkeley-style ms escape-sequences t.b.v. accenten is de .AM macro nodig:
[[ $escape == "berkeley" ]] && echo ".AM"


# Dit wordt de "TITLE":
textline=${1/.txt/}
titel=${textline/*\//}
echo -e ".TL\n\\\\f3$titel\\\\fP"


# En hier volgen de "AUTHOR" gegevens:
while read line; do
    echo "$line"
done << EOF
.AU "HV BF-124" 2774
R.J. Toscani
.AI
.IH
EOF


# Daarna een default "ABSTRACT" blok:
echo -e ".AB\nDit document heeft als onderwerp \\\\f3\"$titel\"\\\\fP en is het resultaat van een automatische conversie vanuit platte tekst \nnaar het TROFF-formaat, door middel van het script \\\\f3$(basename "$0")\\\\fP, een project van Rob Toscani.\n.AE"


# Nog een grapje met een authentiek AT&T cover sheet, op te roepen bij gebruik van ATT macro's via trofform:
echo "...CS 12 1 13 0 0 10"



# Maatregel om tweekoloms (optie -d) voorrang te geven boven drie- of meerkoloms (optie -m) indien beide gekozen:
if ( [[ $columnwidth == 25 ]] && [[ $columns == ".2C" ]] ); then
    colnum=2
fi


# Altijd één kolom in geval van optimalisatie t.b.v. browser:
if (( browser )); then
    columns=".1C"
    colnum=1
fi


# Instellen van de juiste text- en kolombreedte, afhankelijk van wel/niet console/browser-gebruik,
# aantal kolommen en font-afmeting:
if (( ! console )) && (( ! browser )); then
    textwidth=$(bc <<< "scale=0;$textwidth * 10 / $size")
    if [[ $colnum == 3 ]]; then
        columnwidth=$(bc <<< "scale=0;($columnwidth * 10/$size)")
    fi
fi


if [[ $colnum == 1 ]]; then
    if (( console )); then
        (( columnwidth = textwidth-10 ))                              # In terminal marge rechts van 10 t.o.v. tput cols
    else
        (( columnwidth = textwidth ))
    fi
elif [[ $colnum == 2 ]]; then
    if (( console )); then
        (( columnwidth = ( (textwidth-10) - (7*textwidth/100)) / 2 )) # Min marge min gutter = 0,07*tput-cols, en door 2
    else
        columnwidth=$(bc <<< "scale=0;($textwidth - (40/$size)) / 2") # Min gutter als aantal karakters, en door 2
    fi
else
    columns=".MC "$columnwidth                                        # Dit is het aantal monospace-karakters in nroff
fi


# Printen in het gekozen aantal kolommen:
echo "$columns"


########################### BEGIN VAN DE SED- (EN AWK-) STREAM ###############################


# Returns verwijderen uit de tekstfile en ISO-8859 encoding omzetten naar UTF-8:
noreturn "$1" | transcode - |


# Code-tags ([code] en [/code]) aan het eind van een regel worden op de volgende regel geplaatst:
awk 'BEGIN \
{
    startcode = "( |\t)*\\[( |\t)*(C|c)(O|o)(D|d)(E|e)( |\t)*(=[^]]*)?\\]"  # tag = [code]
    endcode   = "( |\t)*\\[( |\t)*/( |\t)*(C|c)(O|o)(D|d)(E|e)( |\t)*\\]"   # tag = [/code]
}
{
    if ($0 ~ "[^ \t]"startcode"( |\t)*$"){
        gsub(startcode, "")
        print $0
        print "[code]"
    }
    else if ($0 ~ "[^ \t]"endcode"( |\t)*$"){
        gsub(endcode, "")
        print $0
        print "[/code]"
    }
    else
        print
}' |


# Alle tabs in een code-blok worden gewijzigd naar het juiste aantal spaties met behoud van uitlijning:
codetabs2spaces - |
# Let op: de tabs worden *ook* omgezet in de start-tag [code] zelf, maar *niet* in de end-tag [/code] !!


# Codetekst, gemarkeerd met [code] en [/code] tags, wordt een niet-opgemaakt blok in constant-width font,
# door toevoeging van ms macro's.
# Verder wordt vóór een eerste punt op elke regel binnen het code-blok een extra punt geplaatst (dit kan
# overigens ook een ander karakter zijn). Dit ter bescherming van op een macro gelijkende strings, 
# tegen interpretatie als macro in condities verderop in dit programma. (Dit wordt weer ongedaan gemaakt
# in de wrap_codelines() functie, vlak vóór het breken.)
awk 'BEGIN \
{
    startcode = "\\[ *(C|c)(O|o)(D|d)(E|e) *(=[^]]*)?\\]"            # tag = [code],  zonder tabs
    endcode   = "\\[( |\t)*/( |\t)*(C|c)(O|o)(D|d)(E|e)( |\t)*\\]"   # tag = [/code], potentiëel nog met tabs
}
{
    if ($0 ~ "^ *"startcode" *"){
        codeblock = 1
        print ".DS I 3"
        print ".CW"
        sub(/\./, "..")                            # Vóór 1e punt nog één, ter bescherming van macro-strings 
        textline = $0
        gsub("^ *"startcode" *", "", textline)
        qty_spaces = length($0) - length(textline) # Code-tag aan begin vervangen door evenveel spaties
        space = ""
        for (i = 0; i < qty_spaces; i++)
            space = space" "
        print space""textline
    }
    else if ($0 ~ "^( |\t)*"endcode){
        codeblock = 0
        print ".DE"
        gsub("^( |\t)*"endcode"( |\t)*", "")
        if ($0 != "")
            print
    }
    else if (codeblock){
        sub(/\./, "..")                            # Vóór 1e punt nog één, ter bescherming van macro-strings
        print
    }
    else
        print
}' |


# Twee escape-maatregelen (niet in code-blocks):
# 1) Escape "\" t.b.v. letterlijke weergave van een "\" (backslash), en 
# 2) Escape "\&" ter camouflering van letterlijke tekst die identiek is aan een 'code-marker', 'table-marker',
#    of aan andere tijdelijke markers (t.b.v. voetnoottekst, zie aldaar)
# Beide maatregelen *NIET IN CODEBLOCKS*, omdat extra metakarakters daar anders op voorhand een probleem geven 
# bij het bepalen van de correcte regellengte:
# De eerste is daar wel nodig, maar wordt dan pas helemaal a/h eind van de functie wrap_codelines() uitgevoerd,
# De tweede is daar niet nodig want er komt immers een marker vóór die later *ALS ENIGE* weer wordt weggehaald.
awk 'BEGIN         { codeblock = 0 }
    /^\.DS I 3/    { codeblock = 1 }
    /^\.DE$/       { codeblock = 0 }
    {
        if (! codeblock){
            gsub(/\\/, "\\\\")           # Verdubbelen van elke backslash, (nog) niet in code blocks
            gsub(/x></, "x\\\\\\&><")    # \& plaatsen in elk "x><" patroon, niet in code blocks
        }
        print
    }' |


# De code-blokken [code]/[/code] worden nu tijdelijk voorzien van een "code-marker" (x><x) aan het begin
# van elke regel:
awk 'BEGIN         { codeblock = 0; table = 0 }
    /^\.DS I 3/    { codeblock = 1 }
    {
        if (codeblock){
            gsub(/^/, "x><x")        # hiermee wordt het begin van elke code-regel gemarkeerd
        }
        print
    }
    /^x><x\.DE$/   { codeblock = 0 }' |


# Maatregel om te voorkomen dat een punt aan het begin van een string in de brontekst kan worden
# geïnterpreteerd als opmaat tot een TROFF-macro. Daartoe wordt vóór alle strings beginnend
# met een punt (".") een "\&" escape geplaatst, ook als ze halverwege een regel staan, b.v. na 
# een bullet of in een tabel.
# Maar *BEHALVE* nog even in *CODEBLOCKS* (daar gebeurt het pas a/h eind van de functie wrap_codelines()
# omdat extra metakarakters daar anders een probleem geven bij het bepalen van de correcte regellengte.
sed -E $'/^x><x/!s/(^|( |\t))\./\\1\\\\\&./g' |


# Als een regel een lijn vormt zonder overige karakters, dan wordt de regel verwijderd, behalve in een code-blok:
sed -E '/^x><x/!s/(^-{3,}$|^\+{3,}$|^={3,}$|^#{3,}$|^_{3,}$)//g' |


################ LET OP: PAS HIERNÁ TROFF MACRO'S LATEN INVOEGEN IN DE SED-STREAM !! #############


# Alle groepen van TABS direct aan het BEGIN en EIND worden overal verwijderd (in codeblocks waren ze al weg):
remove_outer_tabgoups - |


# Alle groepen van minimaal twee opeenvolgende regels, met in elk daarvan minimaal twee gescheiden TABS
# niet aan begin en eind, worden voorzien van een "table-marker" (x><><x) vooraan de regel. 
add_tablemarker - |


# De tabelregels zijn nu geïsoleerd van de overige tekst.
# Nu worden alle (resterende) groepen van TABS en/of SPATIES direct aan het BEGIN en EIND verwijderd, overal
# *BEHALVE IN (GEMARKEERDE) CODEBLOKS EN TABELLEN*:
remove_outer_tabs_spaces - |


# Platte (' en ") en "opmaak" (‘ en ’ en “ en ”) quotes omzetten naar een formaat dat TROFF kan
# verwerken tot "mooie" opmaak, behalve binnen een "code"-blok ([code] .. [/code]).
# Opmaak enkele open  => 1x platte backtic:
sed '/^x><x/!s/‘/'\`'/g' |
# Opmaak enkele sluit => 1x platte enkele:
sed '/^x><x/!s/’/'\''/g' |
# opmaak dubbele sluit en platte dubbele => 2x platte enkele:
sed -E '/^x><x/!s/('\"'|”)/'\'\''/g' |
# Opmaak dubbele open => 2x platte backtic:
sed '/^x><x/!s/“/'\`\`'/g' |
# 1x platte enkele aan begin van woord => 1x platte backtic:
sed -E $'/^x><x/!s/(^| |\t|\(|\[)(\047)([^ \047.\t,:;\$])/\\1\140\\3/g' |
# 2x platte enkele aan begin van woord => 2x platte backtic:
sed -E $'/^x><x/!s/(^| |\t|\(|\[)(\047\047)([^ .\t,:;\$])/\\1\140\140\\3/g' |


# Afbreken na '/' en diverse andere karakters, behalve in een code-blok, door plaatsing van de '\:' sequence:
sed $'/^x><x/!s/[^ +\t]\//&\\\\:/g' |
sed $'/^x><x/!s/[^ \t][@#%+=_]/&\\\\:/g'  |     # Niet bij te veel karakters, anders raakt de .ms vergeven!
sed $'/^x><x/!s/[^])[:alpha:] !\t?\047"-][!?-]/&\\\\:/g' |   # ?!- daarom alleen in beperkte gevallen.


# Tekst volgend op een lege regel wordt opgevat als een nieuwe alinea, behalve binnen een "code"-blok
# ([code] .. [/code]:
sed -E $'/^x><x/!s/^( |\t)*$/.LP/g' |
# Bij-effect is dat ook een lege regel aan het eind van een voetnoot wordt vervangen door een .LP macro.


# Het interpreteren van titelregels, waarbij de volgende uitgangspunten worden gehanteerd:
# Een titel is een enkele regel die begint met een hoofdletter of cijfer en die (Let op: dit is een
# doorslaggevend criterium en dus conventie!!!) *NIET* eindigt op een punt, d.i. vóór de eerste en enige
# return. De overige criteria zijn dat de enkele regel:
# a) aan het begin van de file staat, of
# b) onder een ".LP" staat, en wordt gevolgd door ".LP" ".PP" of ".IP". (Die laatste is punt van discussie.)
# Andere begrenzende criteria zijn: maximum aantal woorden en bepaalde verplichte of juist uitgesloten
# combinaties (b.v. geen < > * $ ! = in de titel, en verder geen - , aan het eind etc.).
# Titelregels worden als .SH-header geprint, naar keuze in uppercase en/of inclusief een hoofdstuknummer,
# en titelregels die niet aan het begin van de tekst staan worden alleen zo opgevat bij maximaal 90 karakters:
# Ook de font-type wordt nogmaals ingesteld omdat headers anders in geval van italic niet *bolt* italic bljken
# te worden (een nog niet begrepen fenomeen).
awk -v title_uppercase="$title_uppercase"   -v number_headers=$number_headers  -v chapt_nr=$chapt_nr \
    -v table_of_contents=$table_of_contents -v color=$color                    -v browser=$browser '{
    if ($0 ~ /^(\.LP|\.PP|\.IP)/ && prev ~ /^(`|'\'')*[1-9[:upper:]\\][^;<>$=]*[^.,'\'';<>*$!=-]'\''*$/ &&
       (pprev ~ /^\.LP$/ && length(prev) < 95  ||  # Quantifier {0.90} werkt niet op OS X binnen awk
        pprev == "")){
        printf "%s\n%s\n%s\n%s\n%s", ".", ".", ".", ".SH 1", "\\f[3]"   # Begin van de header in font-pos 3
        if (number_headers)
            printf "\\n+[chapt_nr].\\ \\ \\:"   # Auto-incremented chapt.nr, 2 unpaddable spaces + break
        if (title_uppercase)
            print toupper(prev)"\\f[P]"         # Header tekst in upper case, daarna weer vorige font-pos           
        else
            print prev"\\[P]"                   # Header tekst, daarna weer vorige font-pos
        if (table_of_contents && ! browser){    # Indien een TOC geplaatst moet worden, maar niet bij browser..
            print ".XS"                         # Plaats dan de "TOC start" macro
            printf "%s%s%s", "\\m[", color, "]" # Neem juiste kleur in de TOC mee (gaat nl. niet vanzelf!)
            if (number_headers)                 # Indien de titels genummerd moeten worden ..
                printf "\\n[chapt_nr].  "       # Plaats number-register nogmaals a/h begin v/d TOC regel 
            gsub(/\*+\)/, "", prev)             # Voetnootmarkering in titel NIET meenemen in TOC regel!!
            print prev                          # Plaats nu de titelregel nogmaals als TOC regel
            print ".XE"                         # Plaats de "TOC end" macro
        }
    }
    else
        print prev
    pprev = prev
    prev = $0
}
END { 
    print prev
    if (table_of_contents && ! browser)         # Browser-instelling stelt TOC buiten werking !
        print ".TC"
}' > "$tempfile1"


# Opmerking: eleganter zou zijn een omzetting naar uppercase door invoeging van een macro of troff-request.
# Dit bestaat echter niet in groff versie 1.22 (maar wel in groff versie 1.23 van dec 2020: .stringup).


# Alle alinea's beginnend met één of meer keer een '*' tussen haakjes aan het begin van de 1e regel
# zijn voetnoten, en worden in een array opgeslagen in de vorm van voetnoot-tekststrings:
footnotes=( $(get_footnotes $tempfile1) )


# De zojuist opgeslagen voetnoot-teksten worden vervolgens elk vanuit de array op de eerste (niet-tabel-)regel
# onder het bijbehorende markeringspunt in de tekst ingevoegd, na te zijn verwijderd van de oorspronkelijke
# regels. Dit is nodig omdat groff_ms ervan uit gaat dat het \** markeringspunt in de invoertekst  
# *DIRECT WORDT GEVOLGD* door het .FS/.FE voetnootblok, zie: man groff_ms. (Anders verschijnt de voetnoot later.)
# Resultaat is een automatisch genummerde voetnoot onderaan dezelfde bladzijde als het markeringspunt.
# Ook vanuit een hoofdstuktitel!
clean_footnotes $tempfile1 | put_footnotes - |


# Een passage **<woorden>** (of omringd door een ander aantal sterretjes) ter benadrukking vet cursiveren,
# behalve in een codeblok.
# De accentuering moet per regel compleet zijn, ofwel bij elke openings ** ook een sluitings **.
# Van elke te markeren passage met voetnootmarkeringspunt moet de sluitings ** daaraan voorafgaan.
# Een passage kan zelf geen * \ of tab bevatten.
sed -E $'/^x><x/!s/([^\\]|^)\*+([^* \t][^*\t]*[^* \t\\]|[^* \t\\])\*+/\\1\\\\f[BI]\\2\\\\f[P]/g' |


# Het herkennen van bullets en deze in lijstvorm zetten, behalve binnen een "code"-blok ([code] .. [/code]).
# ALLEEN de volgende typen bullets worden erkend:
# 1.  Een string van 1 tot 7 KLEINE Romeinse cijfers i,v,x,l,c (niet d, m), wel/niet voorafgegaan door [ of (
#     en wel gevolgd door ) : . .) .] of ] en SPATIE of TAB.
# 2a. Een * + - # of pijl gevolgd door SPATIE of TAB.
# 2b. Een string van 1 tot 8 cijfer(s) en/of spaties en/of punten, gevolgd door ) : . .) .] of ] en SPATIE of TAB.
# 2c. Één (1) grote of kleine letter gevolgd door ) : . .) .] of ] en SPATIE of TAB.
# 2d. String van 1 tot 4 cijfers gevolgd door 1 grote of kleine letter, gevolgd door ) : . .) .] of ] en SPATIE of TAB.
# 3.  Een (serie) string(s) van niet-tab karakters, gevolgd door TAB en slechts ÉÉN regel aan tekst (in afwijking
#     van alle voorgaande bullets).
# Alle overige combinaties vallen buiten de definitie.
# Deze code is aangepast door herdefinitie van de bullet "zwart bolletje" (nu '*' geworden i.p.v. \&. en eerder 'o').
# Let op: die '\n' na '\t' in de 3e substitutie is essentieel!
# Ook de kleur wordt nogmaals ingesteld omdat de algemene instelling daarvan niet voldoende blijkt voor bullets
# (evenals bij footnotes).
#
sed -E $'/^x><x/!s/^((\[|\(){0,1}[clxvi]{1,7}(\)|:|\.[])]{0,1}|\]))( |\t){1,}([^\t]*)/.IP "\\\m['$color$']\\1" 3\\\n\\5/g ;
/^x><x/!s/^(-|\+|#|→|-{1,}>|\*|(\[|\(){0,1}([. 0-9]{1,8}|[[:alpha:]]|[0-9]{1,4}[[:alpha:]])(\)|:|\.[])]{0,1}|\]))( |\t){1,}([^\t]*)/.IP "\\\m['$color$']\\1" 3\\\n\\6/g ;
/^x><x/!s/^([^\t\\n]{1,})\t{1,}([^\t]*$)/.IP "\\\m['$color$']\\1" 3\\\n\\2\\\n.LP/g' |


# Verwijderen van overbodige en/of ongewenste combinaties van macro's:
# Dubbelingen weg in .LP macros; .LP macro weg vóór b.v. bullet; .IP macro weg vóór header-tekst;
# en tenslotte forceren dat elke header gevolgd blijft door een .LP macro:
awk '{
    if (! (prev ~ /^\.LP$/ && $0 ~ /^(\.LP$|\.IP|\.FE)/) )
        print prev
    pprev = prev
    prev = $0
}
END { print prev }' |


awk 'BEGIN { FS = "\"" }
{
    if (pprev ~ /^\.SH/ && prev ~ /^\.IP/)
        printf "%s ", prev_bullet
    else
        print prev
    pprev = prev
    prev = $0
    prev_bullet = $2
}
END { print prev }' |


awk 'BEGIN { FS = "\"" }
{
    if (pprev ~ /^\.SH/)
        printf "%s\n%s\n", prev, ".LP"
    else
        print prev
    pprev = prev
    prev = $0
}
END { print prev }' |


# De (overige) gekozen optie(s) word(t)(en) uitgevoerd:
opt_execute - > $tempfile2


# De functies solitary_bullets() en bullet_clean() blijven een zinvolle aanvulling en zijn niet vervallen.
# De onterechte "solitaire" bullets worden weggefilterd:
bullet_clean $tempfile2 |
# (Geen idee waarom hier opeens een tempfile nodig is i.p.v. een dash via een pipe?) <=== MAAR DIT LUKT WEL OP OS X!!!


# En hier worden de "code-markers" (x><x) weer verwijderd (geen global replace, maar alléén de eerste in de regel!!):
sed 's/^x><x//' |


################# LET OP: VANAF HIER ZIJN DE CODE-BLOKKEN *NIET MEER* VOORZIEN VAN *MARKERS* !! #################


# Verwijderen van een .br macro vóór of na een .LP of .IP regel:
remove_uselessbreaks - |


# Eventuele resterende lege regels worden weggefilterd:
delete_emptylines - |


# Verwijderen van zich herhalende TROFF-macro's:
uniq_macros - |


# Nogmaals verwijderen van een.br macro vóór of na een .LP of .IP regel, mocht deze combinatie opnieuw zijn ontstaan:
remove_uselessbreaks - >| "$tempfile1"


################## HIER BEGINT DE >>"BULLET_INDENT"<< - POST-PROCESSOR ###############
#
# Zie: text2troff_bullet_indent_algoritme.pdf
#
# Stappen 1 en 2: Twee aparte lijsten: één met bullets en één met corresponderende regelnummers:
# FS = "\"" wordt hier en elders toegepast om een bullet(-"field") in een .IP macro te isoleren van zijn quotes!!
#
awk -v lines="$lines" -v bullets="$bullets" \
'BEGIN { FS = "\"" ; prev = "was_no_bullet" }
/^(\.IP|\.LP|\.PP|\.SH)/ {
    if ($0 ~ /\.IP/){                        # Als de huidige regel een bullet is ...
        print NR >> lines                    # Schrijf het regelnummer naar "lines"
        gsub(/\\m\[[[:alpha:]]*\]/, "", $2)  # Kleurinformatie eerst van de bullet weghalen !
        print "_" $2 >> bullets              # Unquoted bullet (tijdelijke _ voorkomt "optie" als bullet)
        prev = "was_bullet"
    }
    else if (prev == "was_bullet"){          # Als huidige regel geen bullet is en alleen als vorige wel ...
        print NR >> lines                    # Schrijf het regelnummer naar "lines"
        print "-----" >> bullets             # Dit is het signaal voor resetten van de "visited"-array
        prev = "was_no_bullet"
    }
}' "$tempfile1"


# Als er geen bullets zijn kan het programma hier al worden afgesloten:
#
if [[ ! -f "$bullets" ]]; then
    cat "$tempfile1" |
    postpostprocess -
    exit
fi

# Anders gaan we hier eerst nog verder met de bullets:
#
# Stap 3: "Normalisatie" van de bullets tot een beperkt aantal representatieve "types":
#
sed -E "s/(\\\\\[->\]|-{1,}>|→)/%/g" $bullets |         # Right arrow krijgt type "%"
sed -E 's/(\||!|\$|:|;|<|>|\/| |_|=|\[|\(|\)|\]|\\|\&|,)//g' |    
#                                                       # Deze tekens mogen niet onderscheidend zijn
tr -d '`' | tr -d "\\'" | tr -d "\"" |                  # Aanhalingstekens zijn ook niet onderscheidend
sed '/[^#]/s/#//g' |                                    # Evenals de hash, indien samen met andere karakters
sed -E 's/-*([^-]{1,})-*/\1/g' |                        # Evenals '-' aan begin en/of aan eind van string
sed -E 's/^([0-9\.]{1,})\.$/\1/g ; /[^0-9\.]/s/\.//g' | # Evenals punten, behalve *TUSSEN* cijfers
sed -E 's/[[:alpha:]]{1,}/a/g ; s/[0-9]{1,}/1/g'  |     # Reeks letters wordt "a", reeks cijfers "1"
sed -E 's/.*[[:alpha:]]{1,}.*([0-9]|-){1,}.*/a/g' |     # String met cijfer(s) of '-' na letter wordt "a"
# Waarom moeten nog steeds classes opgegeven worden nadat die reeds daarvoor zijn genormaliseerd?!


# Stappen 4 t/m 9: Bullet-types opzoeken/opslaan in de "visited"-array en daarbij de index i in volgorde
# van binnenkomst opslaan als "indent_level" (initiële waarde i = 0).
# Vervolgens worden stappen i en ii als functie (binnen awk!) aangeroepen, waarbij de indent_levels via
# delta's worden omgezet in strings bestaande uit .RS of .RE substrings:
#
awk -v macros="$macros" \
'function level2macros(indent_level)
{
    delta = indent_level - prev
    macro = ""
    for(i = delta; i > 0; i--) macro = ".RS" macro
    for(i = delta; i < 0; i++) macro = ".RE" macro
    print macro >> macros
    prev = indent_level
}

BEGIN { split("", visited) }

{
    if ($1 == "-----"){        # Als type niet een bullet is, volgt een reset van "visited"-array
        split("", visited)     # split("", visited) geeft een lege "visited"-array, en daarmee een reset
        level2macros(0)        # Indent_level "0" aanbieden aan de level2macros functie
        next                   # Haal volgende type op
    }
    n = length(visited)
    for (i = 0; i < n; i++){   # Bullet-type opzoeken in "visited"-array, hoogste i als *LAATSTE*!
        if ($1 == visited[i]){ # Indien het type (=$1) daarin wordt gevonden ...
            level2macros(i)    # Bijbehorende index i als indent_level aanbieden aan level2macros functie
            next               # Haal volgende type op
        }
    }                          # Het bullet-type is niet gevonden, dus nieuwe geïncrementeerde index i = n
    visited[n] = $1            # De nieuwe type-waarde toevoegen aan "visited" op deze indexpositie n
    level2macros(n)            # De index-waarde n als indent_level aanbieden aan de level2macros functie
}'


# Stap 10: Het opbouwen van de semicolon-separated regex-string met per regelnummer de te plaatsen
# n*.RS of n*.RE string:
#
regex_string="`pasta "$lines" "$macros" | grep "\(\.RS\|\.RE\)" |
while read line; do
    line_nbr=${line/;*/}
    macro=${line/*;/}
    echo "${line_nbr}s/\(.*\)/$macro\1/g; "
done`"


# Stap 11 en iii: Het bestand voorzien van de n*.RS of n*.RE strings, en daarna elke individuele .RS en .RE
# macro op een aparte regel plaatsen, resulterend in een .ms stream met (geneste) indents:
#
sed "$regex_string" "$tempfile1" | sed -E $'/^(\.RS|\.RE)/s/(\.RS|\.RE)/\\1\\\n/g' | 
# https://unix.stackexchange.com/questions/337250/how-do-i-replace-characters-only-on-certain-lines
#
###################### EINDE VAN DE "BULLET_INDENT" - POST-PROCESSOR ###################


# Dan volgt hierna de definitieve afsluiting:
#
# Bullets met '*' wijzigen in een zwart bolletje, en '-' in een langere dash ('en'):
sed -E 's/(^\.IP \".*)\*(\")/\1\\[bu]\2/g'   |
sed -E 's/(^\.IP \".*)-(\")/\1\\(en\2/g'     |  postpostprocess -


# ==================== RJT SOFTWARE LABS - FOR MIRACLES IN SYSTEM DEVELOPMENT ====================


