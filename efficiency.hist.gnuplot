if (!exists("infile")) infile='efficiency.hist.dat'
if (!exists("outfile")) outfile='efficiency.hist.ps'
set term postscript solid color rounded
set output outfile

set nokey
set grid y
set style data histograms
set style fill solid 1.0 border -1
set ytics 10 nomirror
set yrange [0:100]
set ylabel "Resource utilization %"
set auto x

plot infile using 2:xtic(1) lc rgb '#0c51c2'