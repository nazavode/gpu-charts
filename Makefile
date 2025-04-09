KERNELS         ?=
GNUPLOT         ?= gnuplot
PSTOPDF         ?= ps2pdf
AWK             ?= awk

KERNEL_ARGS := $(patsubst %, --kernel=% , $(KERNELS))

# Remove all NCU output above the actual CSV data
%.csv: %.ncu
	$(AWK) '/^==PROF==/ {last=NR} {lines[NR]=$$0} END {for (i=last+1; i<=NR; i++) print lines[i]}' $< > $@

define PLOT_RULE
%.$(1).plt: %.csv $(1).plt.jinja ncu2jinja.py
	./ncu2jinja.py $(KERNEL_ARGS) --template=./$(1).plt.jinja < $$< > $$@
endef

$(eval $(call PLOT_RULE,roofline-fp))
$(eval $(call PLOT_RULE,roofline-inst))
$(eval $(call PLOT_RULE,roofline-shared))
$(eval $(call PLOT_RULE,hist-occupancy))
$(eval $(call PLOT_RULE,hist-instmix))
$(eval $(call PLOT_RULE,hist-predication))

%.ps: %.plt
	$(GNUPLOT) -e "outfile='$@'" $<

%.pdf: %.ps
	$(PSTOPDF) $< $@

clean:
	@rm -f *.pdf *.plt *.ps *.csv
