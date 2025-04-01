if (!exists("infile")) infile='occupancy.hist.dat'
if (!exists("outfile")) outfile='occupancy.hist.ps'
set term postscript solid color rounded
set output outfile

set key invert reverse
set grid y
set style data histograms
set style histogram rowstacked
set style fill solid 1.0 border -1
set ytics 10 nomirror
set yrange [0:50]
set ylabel "Occupancy %"
set auto x

plot infile using 3 t "Sustained", '' using 2:xtic(1) t "Peak"