## prefered path: proj_root/syn/dc/


export TIMESTAMP=$(shell date +%Y%m%d%H%M%S)
export DESIGN_NAME=rvh_noc
# T12/GF22
export SYN_PDK=T12
# SINGLE_ROUTER/MESH
export SYN_TOP=SINGLE_ROUTER

all:
	export TIMESTAMP=$(shell date +%Y%m%d%H%M%S)
	export DESIGN_NAME=rvh_noc
	export SYN_PDK=T12
	export SYN_TOP=SINGLE_ROUTER

	mkdir ./$(TIMESTAMP)_$(SYN_PDK)_$(SYN_TOP)_run && cd ./$(TIMESTAMP)_$(SYN_PDK)_$(SYN_TOP)_run && mkdir rpt && mkdir output

	/opt/cad/synopsys/installs/syn/Q-2019.12-SP5-1/bin/dc_shell-t -checkout DesignWare -f tcl_scripts/synth.tcl | tee $(TIMESTAMP)_$(SYN_PDK)_$(SYN_TOP)_run/$(SYN_PDK)_$(SYN_TOP).log

PHONY:
clean:
	rm -rf *_run
	rm *.log


# -topographical_mode means using physical constraints on your design, this will allow you to 
# accurately predict post-layout timing, area, and power during synthesis without the need for 
# timing approximations based on wire load models. It uses placement and optimization 
# technologies to drive accurate timing prediction within synthesis and automatically performs 
# leakage power optimization, ensuring better correlation with the final physical design.

  
