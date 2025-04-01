if (!exists("infile")) infile='static.dat'
if (!exists("outfile")) outfile='static.ps'
set term postscript solid color rounded
set output outfile

set yrange [-1:100]
set logscale y 10
set xlabel "Compound size [# atoms]"
set ylabel "Compounds per SM"
set xtics autofreq
set ytics autofreq
set ztics autofreq
set grid xtics mxtics ytics mytics noztics nomztics \
 nox2tics nomx2tics noy2tics nomy2tics nocbtics nomcbtics

plot infile using 2 t 'batch' with linespoints,\
            '' using 3:xtic(1) t 'latency' with linespoints#,\
			# '' using 1:3:3 with labels center notitle