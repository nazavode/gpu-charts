if (!exists("infile")) infile='performance.hist.dat'
if (!exists("outfile")) outfile='performance.hist.ps'
set term postscript solid color rounded
set output outfile

set nokey
set grid y
set style data histograms
set style fill solid 1.0 border -1
set ytics 1000 nomirror
set yrange [0:3000]
set ylabel "GFLOP/s"
set auto x

plot infile using 2:xtic(1) lc rgb '#0c51c2'