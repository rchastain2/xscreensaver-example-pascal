
PC := fpc
PFLAGS := -Mobjfpc -Sh

ifdef DEBUG
PFLAGS += -ghl
else
PFLAGS += -CX
PFLAGS += -Xs
PFLAGS += -XX
endif

PROGRAMS := $(filter-out vroot.pas,$(wildcard *.pas))

default: $(PROGRAM)

%: %.pas vroot.pas
	$(PC) $(PFLAGS) $<

.PHONY: clean run

clean:
	@rm -v $(PROGRAM)

run: $(PROGRAM)
	./$(PROGRAM) --debug
