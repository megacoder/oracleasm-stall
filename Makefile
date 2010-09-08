TARGETS	=all clean check distclean clobber install uninstall
TARGET	=all

.PHONY: ${TARGETS}

${TARGETS}::

all::	asm-stall.bash

check::	asm-stall.bash
	./asm-stall.bash ${ARGS}

distclean clobber:: clean

install:: asm-stall.bash
	install -D -m 0555 asm-stall.bash ${BINDIR}/asm-stall

uninstall::
	${RM} ${BINDIR}/asm-stall
