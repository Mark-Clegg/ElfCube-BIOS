ASMX := asmx

.PHONY: all
all: idiot

idiot: *.asm
	@rm -f BIOS.hex
	$(ASMX) -e -w -l BIOS.lst -i -o BIOS.idiot main.asm || (rm BIOS.idiot; false)

hex:   *.asm
	@rm -f BIOS.idiot
	$(ASMX) -e -w -l BIOS.lst    -o BIOS.hex   main.asm || (rm BIOS.hex; false)

.PHONY: clean
clean:
	rm -f *.lst *.idiot *.hex

.PHONY: install
install:idiot
	screen -X slowpaste 5
	screen -X readreg p "`pwd`/BIOS.idiot"
	screen -X paste p
