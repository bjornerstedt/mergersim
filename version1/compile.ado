
/***************************

MERGER SIMULATION PACKAGE FOR STATA
Jonas Björnerstedt and Frank Verboven

$Id: compile.ado 233 2015-01-26 12:36:10Z d3687-mb $

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
	
	if "`lib´" != "" {
		mata: mata mlib create lmergersim, dir(PERSONAL) replace
		mata: mata mlib add lmergersim *()
	}
	// touch the file, to ensure Subversion revision update
end

