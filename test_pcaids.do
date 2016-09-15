/***************************

MERGER SIMULATION PACKAGE FOR STATA
Jonas Björnerstedt and Frank Verboven

$Id: test_pcaids.do 234 2015-02-09 09:09:39Z d3687-mb $

***************************/
// PCAIDS example of Epstein & Rubinfeld (2001)

version 11.2
clear all
discard
capture compile

// Create example dataset from article
matrix data = (1, 1, 0.2 \ 2, 1, 0.3 \ 3, 1, 0.5 )
mat colnames data = firm p q
svmat data , names(col)

mergersim init , demand(pcaids) elasticities(-1 -3) price(p) quantity(q) firm(firm)
mergersim simulate , buyer(1) seller(2) 

// Corresponds to 13.8% and 10.8% reported by Epstein & Rubinfeld (2001), p895.
