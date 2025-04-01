LIGEN_LATENCY   ?= ligen-dock
LIGEN_BATCH     ?= ligen-dock-batch
POCKET_KEYSITES ?= 3CL_6A.pocket_keysites.pdb
POCKET_ATOMS    ?= 3CL_6A.pocket_atoms.txt
LIGENFLAGS      ?= --cuda --keysite=$(POCKET_KEYSITES) --atoms=$(POCKET_ATOMS)
CLASSFILE       ?= CLASSES
METRICSFILE     ?= METRICS
NCU             ?= ncu
GNUPLOT         ?= gnuplot
PSTOPDF         ?= ps2pdf

CLASSES = $(shell awk '!/\#/{print $$1}' $(CLASSFILE))
METRICS = $(shell cut -f1 -d\# $(METRICSFILE) | xargs | tr ' ' ',')

# Expected files:
# pdf plots
PLOTS =
PLOTS += roofline-fp.batch.pdf
PLOTS += roofline-inst.batch.pdf
PLOTS += roofline-shared.batch.pdf
PLOTS += roofline-fp.latency.pdf
PLOTS += roofline-inst.latency.pdf
PLOTS += roofline-shared.latency.pdf
# ps plots
PS_FILES = $(patsubst %.pdf, %.ps, $(PLOTS))
# gnuplot data files
BATCH_DAT_FILES = $(patsubst %, %.batch.dat, $(CLASSES))
LATENCY_DAT_FILES = $(patsubst %, %.latency.dat, $(CLASSES))
DAT_FILES = $(BATCH_DAT_FILES) $(LATENCY_DAT_FILES)
# nsight raw output
NCU_FILES =
NCU_FILES += $(patsubst %, %.batch.ncu, $(CLASSES))
NCU_FILES += $(patsubst %, %.latency.ncu, $(CLASSES))
# csv from cleaned up nsight output files
CSV_FILES =
CSV_FILES += $(patsubst %, %.batch.csv, $(CLASSES))
CSV_FILES += $(patsubst %, %.latency.csv, $(CLASSES))
# test input molecules
INPUT_FILES =
INPUT_FILES += $(patsubst %, %.batch.test, $(CLASSES))
INPUT_FILES += $(patsubst %, %.latency.test, $(CLASSES))

.PRECIOUS: $(NCU_FILES)

all: $(PLOTS)
dat: $(DAT_FILES)
csv: $(CSV_FILES)

%.batch.test: CLASS = $(basename $(basename $@))
%.batch.test: SIZE = $(shell awk '/$(CLASS)/{print $$4}' $(CLASSFILE))
%.batch.test: RANGE = $(shell seq 1 $(SIZE))
%.batch.test: %.mol2 $(CLASSFILE)
	@for _ in $(RANGE) ; do \
		cat $< >> $@ ; \
	done

%.latency.test: CLASS = $(basename $(basename $@))
%.latency.test: SIZE = 10
%.latency.test: RANGE = $(shell seq 1 $(SIZE))
%.latency.test: %.mol2
	@for _ in $(RANGE) ; do \
		cat $< >> $@ ; \
	done

%.latency.ncu: CLASS = $(basename $(basename $@))
%.latency.ncu: %.latency.test
	$(NCU) --csv --metrics=$(METRICS) $(LIGEN_LATENCY) $(LIGENFLAGS) < $< > $@

%.batch.ncu: CLASS = $(basename $(basename $@))
%.batch.ncu: SIZE = $(shell awk '/$(CLASS)/{print $$4}' $(CLASSFILE))
%.batch.ncu: %.batch.test
	$(NCU) --csv --metrics=$(METRICS) $(LIGEN_BATCH) $(LIGENFLAGS) --batch_size=$(SIZE) < $< > $@

%.csv: %.ncu
	sed -e '/==PROF==/,/==PROF==/d' $< > $@

%.dat: CLASS = $(basename $(basename $@))
%.dat: %.csv
	./ncu2gnuplot --template=$(CLASS).gnuplot.template < $< > $@

%.batch.ps: %.gnuplot $(BATCH_DAT_FILES)
	$(GNUPLOT) -e "outfile='$@'" $(BATCH_DAT_FILES) $<

%.latency.ps: %.gnuplot $(LATENCY_DAT_FILES)
	$(GNUPLOT) -e "outfile='$@'" $(LATENCY_DAT_FILES) $<

%.pdf: %.ps
	$(PSTOPDF) $< $@

clean:
	@rm -f \
		$(PLOTS) \
		$(PS_FILES) \
		$(DAT_FILES) \
		$(NCU_FILES) \
		$(CSV_FILES) \
		$(INPUT_FILES)
