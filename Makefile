
PC := fpc
PFLAGS := -Mobjfpc -Sh

ifdef DEBUG
PFLAGS += -ghl
else
PFLAGS += -CX
PFLAGS += -Xs
PFLAGS += -XX
endif

AGGPAS ?= ~/Documents/sources/fpgui/framework/src/main/pascal/corelib/render/software

PROGRAMS := $(patsubst %.pas,%,$(wildcard *.pas))

default: $(PROGRAMS)

demo5 demo6: PFLAGS += -O3 -B -Fu$(AGGPAS) -Fi$(AGGPAS) -FUunits
demo5 demo6: | units

units:
	mkdir -p $@

%: %.pas
	$(PC) $(PFLAGS) $<

.PHONY: clean

clean:
	@rm -fv $(PROGRAMS) *.o
	@rm -rfv units
