if (!exists("infile")) infile='speedup.hist.dat'
if (!exists("outfile")) outfile='speedup.hist.ps'
set term postscript solid color rounded
set output outfile

set nokey
set grid y
set style data histograms
set style fill solid 1.0 border -1
set ytics 1 nomirror
set yrange [-15:2]
set ylabel "Relative speedup"
set auto x

plot infile using 2:xtic(1) lc rgb '#0c51c2'