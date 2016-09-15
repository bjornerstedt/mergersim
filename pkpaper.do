/**************************************************************************************************************
Bjornerstedt and Verboven, Does Merger Simulation Work, JAE: Applied
- Descriptive Table 1, 2, 3
- Figure 1, 2
- Nested logit estimation and corresponding merger simulation for Table 5, 6, 7, 8 (bootstrapped CI in matlab code)
***************************************************************************************************************/

version 11
clear all
//compile
// CHOOSE MAIN SETTINGS
local ces 1		// 1 is ces 0 is unit
local cond 0	// 0 no coordination, 0.75 partial coordination

use painkillers
capture drop totQ BL* num* 
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
* PART 2. 	SECOND STAGE ANALYSIS FOR DEMAND AND COST
****************************************************************************

// 2.1 DEMAND ANALYSIS: TABLE 5 IN PAPER (DEMAND PARAMETER ESTIMATES)

* first stage (use product dummies instead of fixed effects)
if `ces'==1 {
mergersim init, nests(form substance) ces price(Ptablets) revenue(PX1) marketsize(BL`ces') firm(firm)
	ivreg2 M_ls $exogvar prod1-prod56 (M_lp M_lsjh M_lshg = num*) if year<2009, noconstant robust
}
if `ces'==0 {
mergersim init, nests(form substance) unit price(Ptablets) quantity(Xtablets) marketsize(BL`ces') firm(firm)
	ivreg2 M_ls $exogvar prod1-prod56 (Ptablets M_lsjh M_lshg = num*) if year<2009, noconstant robust
}
mergersim market if year==2008 & month ==12, conduct(`cond') group(substance) // do this to compute the marginal costs for later
* second stage: Nevo fixed effects on time-invariant characteristics
matlist r(average_elasticities)


asdf




matrix beta=e(b)
matrix delta=beta[1,"prod1".."prod56"]'  
preserve
clear
svmat delta
save temp, replace
restore
preserve
sort product
gsort product -year -month
by product: keep if _n==1
merge 1:1 _n using temp
reg delta ldosage lpacksize form1 substance1 substance2 branded
restore
scalar b_ps= _b[lpacksize]
* new delta after the merger
gen delta_new=M_delta+(log(packsize_new)-lpacksize)*_b[lpacksize]

// 2.2 MARGINAL COSTS AND CHANGE BECAUSE OF PACKAGING: TABLE 12 IN PAPER (COST PARAMETER ESTIMATES)

gen lcost=log(M_costs)

* first stage
reg lcost time month2-month12 prod1-prod56 if year<2009, noconstant robust
* second stage: Nevo fixed effects on time-invariant characteristics
matrix beta=e(b)
matrix lcost_fe=beta[1,"prod1".."prod56"]'
preserve
clear
svmat lcost_fe
save temp, replace
restore
preserve
sort product
gsort product -year -month
by product: keep if _n==1
merge 1:1 _n using temp
reg lcost_fe ldosage lpacksize form1 substance1 substance2
restore
scalar c_ps= _b[lpacksize]
display c_ps
* new marginal cost after the merger
gen costs_new=M_costs*(packsize_new/packsize)^_b[lpacksize]
gen cost_ch=(costs_new-M_costs)/M_costs

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
	xtivreg2 M_ls $exogvar (Ptablets M_lsjh M_lshg = num*) if year<2009,fe robust /*first*/
}
mergersim market if year==2008&month==12, conduct(`cond')  

// 3.1 STANDARD MERGER SIMULATION WITHOUT COST CHANGES: ILLUSTRATION OF NESTED LOGIT PART OF TABLE 6, 7 (FULL RESULTS WITH CI IN MATLAB CODE)

mergersim simulate if year == 2008&month==12, seller(1) buyer(2) sellereff(0) buyereff(0) conduct(`cond')
gen M_lerner=(Ptablets-M_costs)/Ptablets
egen M_tot=sum(M_quantity), by(year month)
egen M_tot2=sum(M_quantity2), by(year month)
gen M_sh=M_quantity/M_tot
gen M_sh2=M_quantity2/M_tot2
gen M_shdif=M_sh2-M_sh
*by substance
table substance if year==2008&month==12 [fw=Xtablets], contents(mean M_price_ch mean M_lerner)
table substance if year==2008&month==12, contents(sum M_shdif)
*by firm*substance
table firmsubst if year==2008&month==12 [fw=Xtablets], contents(mean M_price_ch)
table firmsubst if year==2008&month==12, contents(sum M_shdif)
drop M_lerner M_tot M_tot2 M_sh M_sh2 M_shdif

// 3.2 MERGER SIMULATION WITH COST CHANGES BECAUSE OF PACKAGE SIZE: ILLUSTRATION OF NESTED LOGIT PART OF TABLE 8 OF PAPER (MORE DETAIL IN MATLAB CODE)
mergersim simulate if year == 2008&month==12, seller(1) buyer(2) newcosts(costs_new) conduct(`cond') 
table substance if year==2008&month==12 [fw=Xtablets], contents(mean M_price_ch)
table firmsubst if year==2008&month==12 [fw=Xtablets], contents(mean M_price_ch)
	*in line 16, set cond=0 for "cost increase" and set cond=0.75 for "cost increase + part. coord."

****************************************************************************
* PART 4. DESCRIPTIVES AND EX POST ANALYSIS
****************************************************************************

* SUMSTATS IN TABLE 1, 2 AND 3 OF PAPER
egen tot=sum(PX1),by(year)
gen PX2=PX1/tot
table form substance if year==2008,c(sum PX2) row col // TABLE 1 OF PAPER
table brand substance if year==2008,c(sum PX2) row col // TABLE 2 OF PAPER
sum PX1  Xtablets Xddd Xnormal Ptablets Pddd Pnormal marketing sickwomen sickmen GDPnom popwomen popmen if year<2009 //TABLE 3
sum num numg numhg numf numfg numfgh if year<2009 // TABLE 10 OF PAPER (IN APPENDIX)

	tab firmsubst if firmsubs~=16,gen(firmsubst) //Searle not relevant postmerger
	forvalues i = 1/8 {
		generate mergerf`i' = merger*firmsubst`i'
	}
	forvalues i = 1/3 {
		generate mergersb`i' = merger*substance`i'
	}

// SAVE VARIABLES FOR PRICE AND COST REGRESSIONS
preserve
gen lPtab=log(Ptablets)
keep year month product packsize Ptablets lPtab firmsubst2-firmsubst8 mergerf1-mergerf8 Xtablets short
save expost, replace  // dataset for merger with matlab results
restore

// EX POST MARKET SHARE REGRESSION BY FIRMSUBST, TABLE 4

preserve
drop if firmsubst==16
keep if short==1
*do the collapse and regressions
	collapse (sum) Xtablets (mean) merger ,by(year month firmsubst)
	gen date = ym(year, month)
	format date %tm
	tab firmsubst,gen(firmsubst)
	forvalues i = 1/8 {
		generate mergerf`i' = merger*firmsubst`i'
	}
	egen tX=sum(Xtablets),by(year month)
	gen sX=Xtablets/tX
reg sX firmsubst2-firmsubst8 mergerf1-mergerf8,r
restore

// EX POST REGRESSIONS BY SUBSTANCE

preserve
keep if short
*do the collapse and regressions
	collapse (sum) Xtablets (mean) merger ,by(year month substance)
	gen date = ym(year, month)
	format date %tm
	tab substance,gen(substance)
	forvalues i = 1/3 {
		generate mergers`i' = merger*substance`i'
	}
	egen tX=sum(Xtablets),by(year month)
	gen sX=Xtablets/tX
reg sX substance2-substance3 mergers1-mergers3,r

restore


****************************************************************************
* PART 5. GRAPHS
****************************************************************************

* CREATE VARIABLES

*prices (only tablets for now!)
generate PtabPara = Ptablets if substance ==1
generate PtabIbu = Ptablets if substance ==3
generate PtabAsa = Ptablets if substance ==5
*unit sales
generate XtabPara = Xtablets if substance ==1
generate XtabIbu = Xtablets if substance ==3
generate XtabAsa = Xtablets if substance ==5

* COLLAPSE THE DATA TO SHOW EVOLUTION OF PRICES, MARKET SHARES IN GRAPHS
keep if PX>100000
collapse (mean) PtabPara PtabAsa PtabIbu firm (sum) XtabPara XtabAsa XtabIbu, by(year month)

gen date = ym(year, month)
format date %tm

gen shX_Para=XtabPara/(XtabPara+XtabAsa+XtabIbu)
gen shX_Asa=XtabAsa/(XtabPara+XtabAsa+XtabIbu)
gen shX_Ibu=XtabIbu/(XtabPara+XtabAsa+XtabIbu)

gen short=0
replace short=1 if date>566

*main figures for paper
label variable PtabPara "Paracetamol"
label variable PtabIbu "Ibuprofen"
label variable PtabAsa "ASA"
label variable date "Month"

gen shX_Para1=shX_Para*100
gen shX_Ibu1=shX_Ibu*100
gen shX_Asa1=shX_Asa*100
label variable shX_Para1 "Paracetamol"
label variable shX_Ibu1 "Ibuprofen"
label variable shX_Asa1 "ASA"

* FIGURE 1 IN PAPER (PRICES)
line PtabPara PtabAsa PtabIbu date if short==1, title("Price evolution analgesics (April 2007-April 2011)") ytitle("Price (in Krone)") xline(591) note("Note: vertical line refers to the month of merger (April 2009)") saving(Figure1,replace)
* FIGURE 2 IN PAPER (SHARES)
line shX_Para1 shX_Asa1 shX_Ibu1 date if short==1, title("Market share evolution analgesics (April 2007-April 2011)") ytitle("Market share (in percent)") xline(591) note("Note: vertical line refers to the month of merger (April 2009)") saving(Figure2,replace)

