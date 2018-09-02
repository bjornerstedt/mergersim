/***************************

MERGER SIMULATION PACKAGE FOR STATA
Jonas Björnerstedt and Frank Verboven

$Id: pcaids_demand.mata 234 2015-02-09 09:09:39Z d3687-mb $

***************************/
version 11.2

mata:

class PcaidsDemand extends Demand {
	real scalar e
	real scalar e11

	real matrix a
	real matrix b
	real scalar mk

	string price
	string quantity
	
	string estimate // Name of vector of estimates
	string variance

	real scalar valueshares // To indicate that shares are in value terms rather than quantity. 
public:
	virtual void elasticities()
	virtual real matrix demand(), quantity() // Transform to and from shares
	virtual real matrix shares(), group_shares()
	virtual real matrix share_jacobian()
	virtual void get_data()
	virtual void init(), get_shares()
	virtual void parameters()
private:
	void new() 
	real matrix elas()
}

// *******************************************


void PcaidsDemand::new()
{
}

/********************************************************************************/
// PcaidsDemand class

// Pass revenues to function for valueshares, otherwise quantity
real matrix PcaidsDemand::demand(real matrix Q, real matrix P)
{
	real matrix S
	real matrix D
	D = P :* Q
	S = Q :/ mk
	return( S )
}

real matrix PcaidsDemand::quantity(real matrix S, real matrix P)
{
	real matrix Q
	Q = S :* mk
	return( Q )
}

real matrix PcaidsDemand::shares(real matrix p)
{
	return( a + b*log(p) )
}

real matrix PcaidsDemand::elas(real matrix s)
{
	real scalar len
	len = rows(b)
	return( b*diag(1:/s) + J(len, len, 1)*diag(s)*(1+e) - I(len) )
}

real matrix PcaidsDemand::share_jacobian(real matrix s, real matrix p)
{
	return(elas(s)*diag(s:/p))
}

void PcaidsDemand::get_data(string scalar touse)
{
	real matrix p
	real matrix q
	real matrix s
	st_view(p, ., price, touse)
	st_view(q, ., quantity, touse)
	mk = sum(q) // Set marketsize
	
	s = demand(q, p)
	real scalar b11
	real matrix bii, t
	b11 = s[1]*(e11 + 1 -s[1]*(e + 1) ) 
	bii = (s :* (1 :- s)) /(s[1]*(1 - s[1]) ) * b11
	t = -s *( 1 :/ (1 :- s) )' + diag(s :/(1 :- s) )
	
	b =  t * diag(bii) + diag(bii)
	a = s - b*log(p)	
}

void PcaidsDemand::init()
{
	check_variable(price, "price")	
	check_variable(quantity, "quantity")
}

void PcaidsDemand::parameters()
{
	st_global("r(price)", price)
	st_global("r(quantity)", quantity)
	st_numscalar("r(e)", e)
	st_numscalar("r(e11)", e11)
}

end
