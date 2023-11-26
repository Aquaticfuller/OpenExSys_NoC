CUR_MAKEFILE_PATH:=$(abspath $(lastword $(MAKEFILE_LIST)))
CUR_PATH:=$(patsubst %/,%, $(dir $(CUR_MAKEFILE_PATH)))
SRC_PATH:=$(CUR_PATH)/../rtl

ELFIO_PATH:=$(CUR_PATH)/../../utils/elfio

SIMULATOR_PATH:=$(CUR_PATH)/../../utils/dromajo
SIMULATOR_INC:=$(SIMULATOR_PATH)/include
SIMULATOR_BUILD_PATH:=$(SIMULATOR_PATH)/build

RRVTB_PATH:=$(CUR_PATH)/../../utils/rrvtb

default: mesh

single_router:
	vcs  +vcs+lic+wait +vcs+loopreport -sverilog  -kdb +vc -f flist_single_router.f $(DW_FILES) -top tb_single_router \
	+error+1 \
	+define+SIMULATION \
	+incdir+$(SRC_PATH) \
	+lint=TFIPC-L \
	-CFLAGS "-I$(SIMULATOR_INC) -I$(SIMULATOR_BUILD_PATH) -I$(ELFIO_PATH) -I$(RRVTB_PATH) -g -pthread -O3 -DGOLDMEM_INORDER" \
	-debug_access+all -full64 +vpi

mesh:
	vcs-2020.03-kgf vcs +vcs+lic+wait +vcs+loopreport -sverilog  -kdb +vc -f flist_mesh.f $(DW_FILES) -top tb_mesh \
	+error+1 \
	+define+SIMULATION \
	+incdir+$(SRC_PATH) \
	+lint=TFIPC-L \
	-CFLAGS "-I$(SIMULATOR_INC) -I$(SIMULATOR_BUILD_PATH) -I$(ELFIO_PATH) -I$(RRVTB_PATH) -g -pthread -O3 -DGOLDMEM_INORDER" \
	-debug_access+all -full64 +vpi

run:
	./simv +vcs+loopreport 2>&1 | tee run.log

run_regression:
	time ./simv +vcs+loopreport +dumpon=0 +self_finish=0

clean:
	rm -rf simv* csrc Verdi* novas* ucli.key