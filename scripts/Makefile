COMMA		:= ,
SANS		:= undefined address pointer-compare pointer-subtract
SANS_COMMA_LIST	:= $(subst $() ,${COMMA},$(SANS))

CXXFLAGS	:= -Wall -fstack-protector $(addprefix -fsanitize=, ${SANS_COMMA_LIST})

CMAKE_EX_FLAGS	:= -DCMAKE_CXX_FLAGS="${CXXFLAGS}"

SYSCONF		:=./config/sample.cfg
SSDCONF		:= ./simplessd/config/sample.cfg

VALGRIND_CMD	:= valgrind --suppressions=valgrind.supp -s --track-origins=yes

OUTPUT_DIR	?= .
ODIR		= $(shell realpath ${OUTPUT_DIR})

run:
	./simplessd-standalone ${SYSCONF} ${SSDCONF} ${ODIR}

debug:
	gdb -q --args ./simplessd-standalone ${SYSCONF} ${SSDCONF} ${ODIR}

vrun:
	${VALGRIND_CMD} ./simplessd-standalone ${SYSCONF} ${SSDCONF} ${ODIR}

rebuild: clean build

build:
	cmake ${CMAKE_EX_FLAGS} -DDEBUG_BUILD=on -B .
	cmake --build . -j8

SLET_ID		:= 1
KEYS		:= ""
VALUES		:= ""
RES_LBAS	:= 1
test-slet:
	./scripts/test-slet.sh ${SLET_ID} "${KEYS}" "${VALUES}" "${RES_LBAS}"

clean:
	rm -rf CMakeCache.txt CMakeFiles