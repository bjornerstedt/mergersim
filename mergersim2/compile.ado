
/***************************

MERGER SIMULATION PACKAGE FOR STATA
Jonas Björnerstedt and Frank Verboven

$Id: compile.ado 235 2015-11-24 17:31:16Z d3687-mb $

* compile.ado is a utility program used in developing the merger simulation package.
* It compiles the Mata code and replace ado files in memory with current versions. 
* Note that running compile is necessary before updating the net install code, as the mlib has to be updated.

***************************/

capture program drop compile
program compile
	args lib
	local adofiles mergersim   ///
	count_instruments  ///
	xtcreatepanel

	discard
	macro drop _all
	clear all
	
	foreach program in `adofiles' {
		capture program drop `program'
		run `program'.ado
	}
	mata: mata clear
	mata: mata set matalnum on
	mata: mata set matastrict on
	version 11.2

	do mergersim.mata
	do pcaids_demand.mata
	do mergersim_equilibrium.mata
	
	mata: mata mlib create lmergersim, replace
	mata: mata mlib add lmergersim *()
end

