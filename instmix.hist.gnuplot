if (!exists("infile")) infile='instmix.dat'
if (!exists("outfile")) outfile='instmix.ps'
set term postscript solid color rounded
set output outfile

set key invert reverse left outside
# set key autotitle columnheader
# set key maxrows 1
# set nokey
set grid y
set style data histograms
set style histogram rowstacked
set style fill solid 1.0 border -1
set ytics 10 nomirror
set yrange [:100]
set ylabel "% of overall instructions"
set ytics 10
set auto x
# unset xtics
# set xtics nomirror rotate by -45 scale 0

plot infile \
    using 2 t "misc",\
    '' using 3 t "comm",\
    '' using 4 t "cf",\
    '' using 5 t "mem",\
    '' using 6 t "int",\
    '' using 7:xtic(1) t "fp"
    
    
    
