/**************************************************************************************************************
Bjornerstedt and Verboven, Does Merger Simulation Work, JAE: Applied
- Descriptive Table 1, 2, 3
- Figure 1, 2
- Nested logit estimation and corresponding merger simulation for Table 5, 6, 7, 8 (bootstrapped CI in matlab code)
***************************************************************************************************************/

version 11
clear all
compile

// CHOOSE MAIN SETTINGS
local ces 0		// 1 is ces 0 is unit
local cond 0	// 0 no coordination, 0.75 partial coordination

use J_painkillers_old

****************************************************************************
* PART 1. DATA MANAGEMENT
****************************************************************************

// CREATE OUTSIDE GOOD AND PRICE/QUANTITIES
if `ces'==1 {
	sum GDPnom if time==503, meanonly 			// income in median period time=503
	local medincome = r(mean)
	egen totQ = sum(PX1), by(time)
	sum totQ if year<2009, meanonly
	gen BL`ces' = 2*r(mean)*(GDPnom/`medincome'	)
	egen tX=sum(Xtablets),by(time)
	drop totQ
}
if `ces'==0 {
	replace Ptablets=Ptablets/(cpi/100)
	replace PX=PX/(cpi/100)
	egen totQ = sum(X) , by(time) 
	sum totQ , meanonly 		
	gen BL`ces' = 2*r(mean)
}

// PRODUCT DUMMIES AND TIME-INVARIANT CHARACTERISTICS
	replace product=200 if product==71 	// avoids gap in number (easier to produce product fixed effects in second stage regression
	quietly{
	tab product,gen(prod)
	}
	tab form,gen(form)
	tab substance,gen(substance)
	gen lpacksize=log(packsize)
	gen ldosage=log(dosage)
	tab brand,gen(brand)
	gen branded=(brand==1|brand==15|brand==22) // Alvedon, Ipren, Treo

// CREATE INSTRUMENTS
	egen num = count(product), by(time)
	egen numg = count(product), by(time form)
	egen numf = count(product), by(time firm)
	egen numfg = count(product), by(time firm form)
	egen numhg = count(product), by(time substance form)
	egen numfgh = count(product), by(time firm substance form)
	gen con=1

	global exogvar marketing1 sw sm time month2-month12 // used for nested logit


****************************************************************************
* PART 3. MERGER SIMULATION - BASE AND EXTENDED SCENARIOS
****************************************************************************

* must repeat the above demand analysis first to get the parameters again
if `ces'==1 {
mergersim init, nests(form substance) ces price(Ptablets) revenue(PX1) marketsize(BL`ces') firm(firm)
	xtivreg2 M_ls $exogvar (M_lp M_lsjh M_lshg = num*) if year<2009,fe robust /*first*/
}
if `ces'==0 {
mergersim init, nests(form substance) unit price(Ptablets) quantity(Xtablets) marketsize(BL`ces') firm(firm)
	xtivreg2 M_ls $exogvar (Ptablets M_lsjh M_lshg = num*) if year<2009, fe robust gmm
}
mergersim market if year==2008&month==12, conduct(`cond')  


