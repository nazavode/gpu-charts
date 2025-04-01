if (!exists("outfile")) outfile='roofline-fp.ps'
set term postscript solid color rounded
set output outfile

unset clip points
set clip one
unset clip two
set bar 1.000000
set xdata
set ydata
set zdata
set x2data
set y2data
set boxwidth
set style fill  empty border
set dummy x,y
set format y "10^{%T}"
set format x "10^{%T}"
set format x2 "% g"
set format y2 "% g"
set format z "% g"
set format cb "% g"
set angles radians
set grid nopolar
set grid xtics mxtics ytics mytics noztics nomztics \
 nox2tics nomx2tics noy2tics nomy2tics nocbtics nomcbtics
set grid layerdefault   linetype 0 linewidth 1.000,  linetype 0 linewidth 1.000
set key title ""
# set key off
set key right bottom maxrows 5 font ",10"
unset label
unset arrow
unset style line
unset style arrow
unset logscale
set logscale x 10
set logscale y 10
set offsets 0, 0, 0, 0
set pointsize 1
set encoding default
unset polar
unset parametric
unset decimalsign
set view 60, 30, 1, 1  
set samples 1000, 1000
set isosamples 10, 10
set surface
unset contour
set clabel '%8.3g'
set mapping cartesian
set datafile separator whitespace
unset hidden3d
set cntrparam order 4
set cntrparam linear
set cntrparam levels auto 5
set cntrparam points 5
set size 1,1
set origin 0,0
set style data lines
set style function lines
set xzeroaxis linetype -2 linewidth 1.000
set yzeroaxis linetype -2 linewidth 1.000
set x2zeroaxis linetype -2 linewidth 1.000
set y2zeroaxis linetype -2 linewidth 1.000
set ticslevel 0.5
set mxtics 10
set mytics 10
set mztics default
set mx2tics default
set my2tics default
set mcbtics default
set xtics autofreq
set ytics autofreq
set ztics autofreq
set nox2tics
set noy2tics
set cbtics autofreq
set timestamp bottom 
set timestamp "" 
set rrange [ * : * ] noreverse nowriteback
set trange [ * : * ] noreverse nowriteback
set urange [ * : * ] noreverse nowriteback
set vrange [ * : * ] noreverse nowriteback
set xlabel "Arithmetic Intensity (FLOP/B)"
set x2label "" 
set xrange [1.000000e-02 : 2.00000e+02] noreverse nowriteback
set x2range [ * : * ] noreverse nowriteback
set ylabel "Performance (GFLOP/s)"
set y2label "" 
set yrange [1.000000e+01 : *] noreverse nowriteback
set y2range [ * : * ] noreverse nowriteback
set zlabel "" 
set zrange [ * : * ] noreverse nowriteback
set cblabel "" 
set cbrange [ * : * ] noreverse nowriteback
set zero 1e-08
set lmargin  -1
set bmargin  -1
set rmargin  -1
set tmargin  -1
set locale "C"
set pm3d explicit at s
set pm3d scansautomatic
set palette positive nops_allcF maxcolors 0 gamma 1.5 color model RGB 
set palette rgbformulae 7, 5, 15
set colorbox default
set loadpath 
set fit noerrorvariables

# Device parameters
peak = 6681.6 # GFLOP/s
peak_nofma = peak / 2 # GFLOP/s
l2_peak = 2842.3 # GB/s
hbm_peak = 796.2 # GB/s

peak = 80 * 32 * 2 * 1.53 # GFLOP/s
l1_peak = 437.5 * 32 # GFLOP/s
l2_peak = 93.6 * 32 # GFLOP/s
hbm_peak = 25.9 * 32 # GFLOP/s

# Ceilings
l1_ceiling(x) = peak > (x * l1_peak) ? (x * l1_peak) : peak
l2_ceiling(x) = peak > (x * l2_peak) ? (x * l2_peak) : peak
hbm_ceiling(x) = peak > (x * hbm_peak) ? (x * hbm_peak) : peak
peak_ceiling(x) = peak <= (x * l1_peak) ? peak : 1/0
peak_nofma_ceiling(x) = peak_nofma <= (x * l1_peak) ? peak_nofma : 1/0

# Styling
line_width = 2
point_size = 1.5

hbm_color = '#74460b'
l1_color = '#eaa800'
l2_color = '#14967c'

ClassA_point = 5
ClassB_point = 9
ClassC_point = 7

# Ceiling labels
set label sprintf('Theoretical peak \@ FP64: %.1f GFLOP/s', peak) at 2,peak+1000 textcolor rgb 'black' font ",12"
set label 'FMA' at 180,peak_nofma+500 right textcolor rgb 'black' font ",12"
set label sprintf('L1 %.1f GB/s', l1_peak) at 0.05,100 + 0.05 * l1_peak left rotate by 45 textcolor rgb l1_color font ",12"
set label sprintf('L2 %.1f GB/s', l2_peak) at 0.05,20 + 0.05 * l2_peak left rotate by 45 textcolor rgb l2_color font ",12"
set label sprintf('HBM %.1f GB/s', hbm_peak)  at 0.05,5 + 0.05 * hbm_peak left rotate by 45 textcolor rgb hbm_color font ",12"

plot \
	l1_ceiling(x) lw line_width lc rgb l1_color notitle,\
	l2_ceiling(x) lw line_width lc rgb l2_color notitle,\
	hbm_ceiling(x) lw line_width lc rgb hbm_color notitle,\
	peak_ceiling(x) lw line_width lc rgb 'black' notitle,\
	peak_nofma_ceiling(x) lw line_width lc rgb 'black' dashtype 2 notitle,\
	[0:0:1] "+" us (-10):(-10) \
		with points lc rgb "black" pt ClassA_point - 1 ps point_size title 'Small',\
	[0:0:1] "+" us (-10):(-10) \
		with points lc rgb 'black' pt ClassB_point - 1 ps point_size title 'Medium',\
	[0:0:1] "+" us (-10):(-10) \
		with points lc rgb 'black' pt ClassC_point - 1 ps point_size title 'Large',\
	[0:0:1] "+" us (ClassA_l1_thread_fp_intensity):(ClassA_thread_fp_performance) with points lc rgb l1_color pt ClassA_point ps point_size title "L1",\
	[0:0:1] "+" us (ClassA_l2_thread_fp_intensity):(ClassA_thread_fp_performance) with points lc rgb l2_color pt ClassA_point ps point_size title "L2",\
	[0:0:1] "+" us (ClassA_hbm_thread_fp_intensity):(ClassA_thread_fp_performance) with points lc rgb hbm_color pt ClassA_point ps point_size title "HBM",\
	[0:0:1] "+" us (ClassB_l1_thread_fp_intensity):(ClassB_thread_fp_performance) with points lc rgb l1_color pt ClassB_point ps point_size notitle,\
	[0:0:1] "+" us (ClassB_l2_thread_fp_intensity):(ClassB_thread_fp_performance) with points lc rgb l2_color pt ClassB_point ps point_size notitle,\
	[0:0:1] "+" us (ClassB_hbm_thread_fp_intensity):(ClassB_thread_fp_performance) with points lc rgb hbm_color pt ClassB_point ps point_size notitle,\
	[0:0:1] "+" us (ClassC_l1_thread_fp_intensity):(ClassC_thread_fp_performance) with points lc rgb l1_color pt ClassC_point ps point_size notitle,\
	[0:0:1] "+" us (ClassC_l2_thread_fp_intensity):(ClassC_thread_fp_performance) with points lc rgb l2_color pt ClassC_point ps point_size notitle,\
	[0:0:1] "+" us (ClassC_hbm_thread_fp_intensity):(ClassC_thread_fp_performance) with points lc rgb hbm_color pt ClassC_point ps point_size notitle
