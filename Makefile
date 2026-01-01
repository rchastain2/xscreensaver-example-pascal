
PC := fpc
PFLAGS := -Mobjfpc -Sh
PFLAGS += -ghl

PROGRAM := demo

default: $(PROGRAM)

%: %.pas vroot.pas
	$(PC) $(PFLAGS) $<

.PHONY: clean run

clean:
	@rm -v $(PROGRAM)

run: $(PROGRAM)
	./$(PROGRAM) --debug
