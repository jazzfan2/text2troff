# Name: text2troff

text2troff is the major part of a suite of programs consisting of:
- text2troff - converts a flat text-file to TROFF text format by inserting requests and 'ms' macro commands.
- text2troff_table - converts tabulated lines in a flat text-file into TROFF formatted tables by inserting table requests. Is called by text2troff but can also be used stand-alone.
- trofform - activates a chosen TROFF document format and deactivates any alternate document formats. Can process output from text2troff.

# Description:

## text2troff
text2troff is a bash script that uses a combination of awk and sed filters
to convert a flat text-file into TROFF text format, by inserting TROFF request and 'ms' macro commands.
The result is sent to standard output,
and can be processed further with available 'troff' tools with 'ms' macro package, preferrably GNU groff_ms(7),
to produce typeset PostScript-, PDF-, HTML- or terminal ('nroff') output.
As an alternative to processing a text-file, text2troff can also read (text) input from a pipe.

The functionality includes interpretation of
chapter headers,
paragraphs,
emphasized text,
bullet item lists (whether or not nested),
tables,
footnotes and
'code blocks' (definition see below).
It offers various options to set general text font family, style, size and color,
the number of text columns per page, representation of chapter headers, paragraphs and tables,
as well as end-of-sentence behavior.
An option to automatically generate and include a Table of Contents (TOC) is present as well.

text2troff offers an alternative to pandoc(1) for producing TROFF text output,
by attempting to minimize as much as possible the degree of formatting required in the input text,
yet enabling still highly acceptable text typesetting based on a very limited set of simple conventions.
These are used by text2troff as criteria by which to 'best-guess' the intended layout of the text.

The output produced by this program shouldn't be considered as more than an approximation of any full-blown end result.
Further polishing can be done by any additional manual placement of TROFF-requests and/or ms macros if chosen for. 
Main intent for developing this program was the wish to be able to turn a quick-and-dirty piece of flat
text into a decently sophisticated document 'at the push of a button',
with enough options to vary its appearance.

## text2troff_table
text2troff_table is a bash script that uses awk filtering to convert tabulated lines
in a flat text-file into TROFF formatted tables by inserting table requests and ms macros.
All lines not interpreted as table lines are passed on unchanged.
The result is sent to standard output,
and can be processed further with available 'troff' tools with 'ms' macro package, preferrably GNU groff_ms(7),
to produce typeset PostScript-, PDF-, HTML- or terminal ('nroff') output.
As an alternative to processing a text-file, text2troff_table can also read (text) input from a pipe. 

## trofform
trofform is a bash script that activates a chosen document format (including ancient AT&T variants) within a TROFF text
and deactivates any alternate document formats.
It does so by reducing the number of dots prefixed to the ms macro belonging to the chosen format to one (1),
and by prefixing two (2) dots to all other document formats ms macros.
Unaffected text lines are passed on unchanged, and the result is sent to standard output.

The output can be processed further with available 'troff' tools with 'ms' macro package, preferrably GNU groff_ms(7),
to produce typeset PostScript-, PDF-, HTML- or terminal ('nroff') output.
As an alternate to processing a text-file, trofform can also read (text) input from a pipe.

Prerequisite for evoking any of the ancient/authentic AT&T document formats is the presence on the system of the original AT&T 'tmac.s' file
with special macros.
This special 'tmac.s' macro-file is in the public domain,
can be found on the web,
and should preferrably be renamed differently as to avoid collisions with the natively installed ms-macro files.
In order to process the output correctly,
groff must be given option -M with the path to the directory where the AT&T macro-file resides.

trofform can be called both interactively (by options -I and -h) and non-interactively (by specifying no or any of the other options).

# How to use text2troff, text2troff_table and trofform:
See the manual pages text2troff.1, text2troff_table.1 and trofform.1, included in this repository, for full description and options.

# Author:
Written by Rob Toscani (rob_toscani@yahoo.com).

