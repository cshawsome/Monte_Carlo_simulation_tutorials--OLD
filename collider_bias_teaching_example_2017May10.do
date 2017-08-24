/******************************************************************************/
/*											    							  */
/*			Data generation and analysis code				  				  */
/*	 		Collider-stratification bias scenario 			  				  */
/*																			  */
/******************************************************************************/

set more off
clear
*set seed 67208105

/*******************************************************/
/********	Step 1. Create blank data set		********/
/*******************************************************/

set obs 5000 //creates blank dataset with XXXXX observations
gen id = _n


/*******************************************************/
/********	Step 2. Set parameters				********/
/*******************************************************/

*Specify prevalence of A (exposure)
local P_A = 0.2	 

*Parameters for odds of S (selection)
local g0 = ln(0.10/(1-0.10)) //log odds of S for ref group (A=0 and U=0) 
local g1 = ln(5.0)	//log OR for effect of A on log odds of selection (OR=5.0)	
local g2 = ln(5.0)	//log OR for effect of U on log odds of selection (OR=5.0)
local g3 = ln(1.0)	//log OR for interaction between A and U on  (OR=1.0)


*Parameters for odds of Y (outcome)
local b0 = ln(0.05/(1-0.05)) //log odds of Y for ref group (A=0, U=0, and S=0)
local b1 = ln(1.0)	//log OR for effect of A on log odds of Y (OR=1.0) 
local b2 = ln(5.0)	//log OR for effect of U on log odds of Y (OR=5.0)


/*******************************************************/
/********	Step 3. Generate data				********/
/*******************************************************/

*Generate A
gen A = 0
replace A = runiform()<`P_A'


*Generate U, where U~N(0,1)
gen U = rnormal() 

*Generate S
gen P_Selection = exp(`g0' + `g1'*A + `g2'*U + `g3'*U*A)/(1 + exp(`g0' + `g1'*A + `g2'*U + `g3'*U*A))			
gen S = runiform()<P_Selection

*Generate Y 
gen P_Y = exp(`b0' + `b1'*A + `b2'*U)/(1 + exp(`b0' + `b1'*A + `b2'*U))		
gen Y = runiform()<P_Y

/*******************************************************/
/******** 	End data generation steps			********/
/*******************************************************/


/*******************************************************/
/********	Step 4. Look at data 				********/
/*******************************************************/

/********Check distributions of variables and store results********/

*Check proportions of people with: 
	*exposure (A) = 1
	*selection (S) = 1
	*outcome (Y) = 1
*Check mean U
foreach x in A U S Y {
summarize `x', meanonly
	scalar p_`x' = round(r(mean),0.001)
}
scalar mean_U = p_U
	scalar drop p_U

*Check proportion of people with selection (S) = 1 by exposure (A)
summarize S if A==0, meanonly
	scalar p_S_A0 = round(r(mean),0.001)
summarize S if A==1, meanonly
	scalar p_S_A1 = round(r(mean),0.001)

*Check proportion of people with outcome (Y) = 1 by exposure (A)
summarize Y if A==1, meanonly
	scalar p_Y_A1 = round(r(mean),0.001)
summarize Y if A==0, meanonly
	scalar p_Y_A0 = round(r(mean),0.001)
	
*Check proportion of people with outcome (Y) = 1 by exposure (A) among S=1
summarize Y if (A==1 & S==1), meanonly
	scalar p_Y_A1_S1 = round(r(mean),0.001)
summarize Y if (A==0 & S==1), meanonly
	scalar p_Y_A0_S1 = round(r(mean),0.001)

*Look at mean U by A
sum U if (A==0), meanonly
	scalar mean_U_A0_all = r(mean)
sum U if (A==1), meanonly
	scalar mean_U_A1_all = r(mean)
	
*Look at mean U by A among S=1
sum U if (A==0 & S==1), meanonly
	scalar mean_U_A0_S1 = r(mean)
sum U if (A==1 & S==1), meanonly
	scalar mean_U_A1_S1 = r(mean)


/********Look at associations and store results********/

*Check ORs for A and Y (whole population). No bias anticipated
logistic Y A
	matrix list r(table)
	matrix matrix2 = r(table)
	scalar OR_AY_all = matrix2[1,1]
	
*Estimates of primary interest: Estimated ORs for A and Y among S=1 (store ORs and 95% CI limits)
logistic Y A if (S==1)
	matrix list r(table)
	matrix matrix3 = r(table)
	scalar OR_AY_S1 = matrix3[1,1]
	scalar lb_OR_AY_S1 = matrix3[5,1]
	scalar ub_OR_AY_S1 = matrix3[6,1]
 
