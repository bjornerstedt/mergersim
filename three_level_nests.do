
version 11
clear all
compile
use painkillers

local marketing marketing1

gen atc1 = substance != 5
mergersim init, nests( form atc1 substance ) ces price(Ptablets) revenue(PX1) marketsize(BL) firm(firm) 
* mergersim init, nests( form  substance ) ces price(Ptablets) revenue(PX1) marketsize(BL) firm(firm) 

xtivreg M_ls `marketing' sw sm time month2-month12 (M_lp M_lsji M_lsih M_lshg = num* instrp* instrd*),fe //robust
* xtivreg M_ls `marketing' sw sm time month2-month12 (M_lp M_lsjh  M_lshg = num* instrp* instrd*),fe //robust

mergersim market  , keep

* mergersim simulate if year == 2007 | year == 2008 , seller(1) buyer(2)  
