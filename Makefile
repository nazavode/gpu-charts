KERNELS         ?=
GNUPLOT         ?= gnuplot
PSTOPDF         ?= ps2pdf
AWK             ?= awk

KERNEL_ARGS := $(patsubst %, --kernel=% , $(KERNELS))

# Remove all NCU output above the actual CSV data
%.csv: %.ncu
	$(AWK) '/^==PROF==/ {last=NR} {lines[NR]=$$0} END {for (i=last+1; i<=NR; i++) print lines[i]}' $< > $@

%.roofline-fp.plt: %.csv roofline-fp.plt.jinja ncu2gnuplot.py
	./ncu2gnuplot.py $(KERNEL_ARGS) --template=./roofline-fp.plt.jinja < $< > $@

%.roofline-inst.plt: %.csv roofline-inst.plt.jinja ncu2gnuplot.py
	./ncu2gnuplot.py $(KERNEL_ARGS) --template=./roofline-inst.plt.jinja < $< > $@

%.roofline-shared.plt: %.csv roofline-shared.plt.jinja ncu2gnuplot.py
	./ncu2gnuplot.py $(KERNEL_ARGS) --template=./roofline-shared.plt.jinja < $< > $@

%.ps: %.plt
	$(GNUPLOT) -e "outfile='$@'" $<

%.pdf: %.ps
	$(PSTOPDF) $< $@

clean:
	@rm -f *.pdf *.plt *.ps *.csv
