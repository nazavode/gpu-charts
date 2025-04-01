if (!exists("outfile")) outfile='roofline-inst.ps'
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
set xlabel "Instruction Intensity (warp instructions per transaction)" 
set x2label "" 
set xrange [1.000000e-02 : 1.500000e+03] noreverse nowriteback
set x2range [ * : * ] noreverse nowriteback
set ylabel "Performance (warp GIPS)"
set y2label "" 
set yrange [1.000000e+00 : 1.000000e+03] noreverse nowriteback
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
peak = 489.6 # GIPS
l1_peak = 437.5 # GTXN/s
l2_peak = 93.6 # GTXN/s
hbm_peak = 25.9 # GTXN/s

# Ceilings
l1_ceiling(x) = peak > (x * l1_peak) ? (x * l1_peak) : peak
l2_ceiling(x) = peak > (x * l2_peak) ? (x * l2_peak) : peak
hbm_ceiling(x) = peak > (x * hbm_peak) ? (x * hbm_peak) : peak
peak_ceiling(x) = peak <= (x * l1_peak) ? peak : 1/0

# Styling
line_width = 2
point_size = 1.5

l1_color = 'red'
l2_color = 'green'
hbm_color = 'blue'

ClassA_point = 5
ClassB_point = 9
ClassC_point = 7

# Ceiling labels
set label 'Theoretical peak: 489.6 warp GIPS' at 2,peak + 90 textcolor rgb 'black' font ",12"
set label sprintf('L1 %.1f GTXN/s', l1_peak) at 0.05,4 + 0.05 * l1_peak  left rotate by 50 textcolor rgb l1_color font ",12"
set label sprintf('L2 %.1f GTXN/s', l2_peak)  at 0.05,0.6 + 0.05 * l2_peak  left rotate by 50 textcolor rgb l2_color font ",12"
set label sprintf('HBM %.1f GTXN/s', hbm_peak) at 0.05,0.2 + 0.05 * hbm_peak left rotate by 50 textcolor rgb hbm_color font ",12"

plot \
	l1_ceiling(x) lw line_width lc rgb l1_color notitle,\
	l2_ceiling(x) lw line_width lc rgb l2_color notitle,\
	hbm_ceiling(x) lw line_width lc rgb hbm_color notitle,\
	peak_ceiling(x) lw line_width lc rgb 'black' notitle,\
	ClassA_warp_instruction_performance dashtype 2 lc rgb 'black' lw 2 notitle,\
	[0:0:1] "+" us (0.012):(ClassA_warp_instruction_performance) \
		with points lc rgb 'black' pt ClassA_point - 1 ps point_size title 'Small',\
	ClassB_warp_instruction_performance dashtype 2 lc rgb 'black' lw 2 notitle,\
	[0:0:1] "+" us (0.012):(ClassB_warp_instruction_performance) \
		with points lc rgb 'black' pt ClassB_point - 1 ps point_size title 'Medium',\
	ClassC_warp_instruction_performance dashtype 2 lc rgb 'black' lw 2 notitle,\
	[0:0:1] "+" us (0.012):(ClassC_warp_instruction_performance) \
		with points lc rgb 'black' pt ClassC_point - 1 ps point_size title 'Large',\
	[0:0:1] "+" us (ClassA_l1_thread_inst_intensity):(ClassA_thread_instruction_performance) with points lc rgb l1_color pt ClassA_point ps point_size title "L1 (tot\\\_inst)",\
	[0:0:1] "+" us (ClassA_l2_thread_inst_intensity):(ClassA_thread_instruction_performance) with points lc rgb l2_color pt ClassA_point ps point_size title "L2 (tot\\\_inst)",\
	[0:0:1] "+" us (ClassA_hbm_thread_inst_intensity):(ClassA_thread_instruction_performance) with points lc rgb hbm_color pt ClassA_point ps point_size title "HBM (tot\\\_inst)",\
	[0:0:1] "+" us (ClassB_l1_thread_inst_intensity):(ClassB_thread_instruction_performance) with points lc rgb l1_color pt ClassB_point ps point_size notitle,\
	[0:0:1] "+" us (ClassB_l2_thread_inst_intensity):(ClassB_thread_instruction_performance) with points lc rgb l2_color pt ClassB_point ps point_size notitle,\
	[0:0:1] "+" us (ClassB_hbm_thread_inst_intensity):(ClassB_thread_instruction_performance) with points lc rgb hbm_color pt ClassB_point ps point_size notitle,\
	[0:0:1] "+" us (ClassC_l1_thread_inst_intensity):(ClassC_thread_instruction_performance) with points lc rgb l1_color pt ClassC_point ps point_size notitle,\
	[0:0:1] "+" us (ClassC_l2_thread_inst_intensity):(ClassC_thread_instruction_performance) with points lc rgb l2_color pt ClassC_point ps point_size notitle,\
	[0:0:1] "+" us (ClassC_hbm_thread_inst_intensity):(ClassC_thread_instruction_performance) with points lc rgb hbm_color pt ClassC_point ps point_size notitle
