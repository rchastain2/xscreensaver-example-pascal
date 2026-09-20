
PC := fpc
PFLAGS := -Mobjfpc -Sh

ifdef DEBUG
PFLAGS += -ghl
else
PFLAGS += -CX
PFLAGS += -Xs
PFLAGS += -XX
endif

PROGRAMS := $(patsubst %.pas,%,$(filter-out vroot.pas,$(wildcard *.pas)))

default: $(PROGRAMS)

%: %.pas vroot.pas
	$(PC) $(PFLAGS) $<

.PHONY: clean

clean:
	@rm -fv $(PROGRAMS) *.o
