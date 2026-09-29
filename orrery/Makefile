PC := fpc
PFLAGS := -Mobjfpc -Sh -O3 -B

ifdef DEBUG
PFLAGS += -ghl
else
PFLAGS += -CX
PFLAGS += -Xs
PFLAGS += -XX
endif

AGGPAS ?= ~/Documents/sources/fpgui/framework/src/main/pascal/corelib/render/software

PFLAGS += -Fu$(AGGPAS) -Fi$(AGGPAS) -FUunits

PROGRAM := orrery

default: $(PROGRAM)

$(PROGRAM): $(PROGRAM).pas | units
	$(PC) $(PFLAGS) $<

units:
	mkdir $@

.PHONY: clean run

clean:
	@rm -fv $(PROGRAM) *.o
	@rm -rfv units

run: $(PROGRAM)
	./$(PROGRAM)
