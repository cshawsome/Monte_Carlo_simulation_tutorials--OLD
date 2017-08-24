/******************************************************************************/
/*** 				Simulation Master File 				  					***/ 
/***	 		Collider stratification bias scenario 						***/

/*"simulate" performs Monte Carlo-type simulations. 
The basic form of the code is: 

"simulate <list_of_scalars_collected_from_each_repetition>, /// 
reps(B) seed(#): do <data_generation_and_analysis_do_file>" 
 
This calls the data generation and analysis file B times to generate and 
analyze B data sets and stores the results from each sample as scalars. 
-Note that the first lines of code call in and assign the value from each 
scalar to a variable with the same name. 
-"reps(B)" specifies the number of iterations of sample generation. 
-"seed(#)" specifies the random number seed. 

Simulate documentation: http://www.stata.com/manuals13/rsimulate.pdf 

The rest of the code summarizes results across the B iterations of sample 
generation and stores the results from the B samples in a data file file 
(one sample = one row in the file).*/ 
/******************************************************************************/

*cd "C:\Users\location_of_collider_bias_data_generation_and_analysis_do_file"


set more off
clear all

capture log close
*log using "C:\Users\emayeda\Dropbox\ERMayeda\CV_Biosketch_ResearchStatements\Job_application_materials\Columbia\teaching demo\collider_bias_log_file", replace
*log using "C:\Users\location_and_name_of_collider_bias_log_file", replace


/*Specify desired number of iterations of sample generation*/
local B = 1000

/*Create local variable for causal/true OR for A on Y specified in data
generation do file*/
local causal_OR_AY = 1.0 


/***Pull in scalars from data generation and analysis file***/
local simlist ""
foreach x in OR_AY_S1 ub_OR_AY_S1 lb_OR_AY_S1 ///
	 OR_AY_all ///
	 mean_U ///
	 mean_U_A1_all mean_U_A0_all ///
	 mean_U_A1_S1 mean_U_A0_S1 ///
	 p_A p_Y p_S ///
	 p_S_A1 p_S_A0  ///
	 p_Y_A0 p_Y_A1 ///
	 p_Y_A0_S1 p_Y_A1_S1 ///
{ 
   local simlist "`simlist' `x'=`x'"
}


/***Run simulation***/
simulate `simlist', ///
reps(`B') seed(67208105): do collider_bias_teaching_example_2017May10 //replace with name of your data generation do file


/*Across all B replications, calculate and store mean value of each variable as a scalar*/ 
foreach b in OR_AY_S1 ///
			 OR_AY_all ///
			 mean_U ///
			 mean_U_A1_all mean_U_A0_all ///
			 mean_U_A1_S1 mean_U_A0_S1 ///
			 p_A p_Y p_S ///
			 p_S_A1 p_S_A0  ///
			 p_Y_A0 p_Y_A1 ///
			 p_Y_A0_S1 p_Y_A1_S1 {
summarize `b', meanonly
scalar mean_`b' = round(r(mean),0.001)
}


/*For each sample, generate indicator variable for whether the 95% CI for 
the estimated OR_AY includes the causal/true OR_AY*/
gen covg_OR_AY_S1 = (lb_OR_AY_S1  < `causal_OR_AY' & ub_OR_AY_S1  > `causal_OR_AY')

/*Across all B replications, calculate and store the proportion of times the
95% CI includes the causal/true OR_AY (95% CI coverage)*/ 
foreach b in covg_OR_AY_S1 covg_OR_AY_S1 {
summarize `b', meanonly
scalar P_`b' = round(r(mean),0.001)
}



/***List results across the B iterations of sample generation***/

*Check proportions of people with: 
	*exposure (A) = 1
	*selection (S) = 1
	*outcome (Y) = 1
	*outcome (Y) = 1 by exposure (A)
scalar list mean_p_A mean_p_S mean_p_Y mean_p_Y_A1 mean_p_Y_A0 mean_mean_U 

*Check proportion of people with outcome (Y) = 1 by exposure (A) among S=1
scalar list mean_p_Y_A1_S1 mean_p_Y_A0_S1

*Check distribution of U by A among S=1
scalar list mean_mean_U_A1_S1 mean_mean_U_A0_S1 

*Check distribution of U by A among full sample
scalar list mean_U_A1_all mean_U_A0_all

*Check ORs in whole population (no bias anticipated)
scalar list mean_OR_AY_all

*Estimate of primary interest: Estimated ORs among S=1
scalar list mean_OR_AY_S1

*Proportion of 95% CIs that include the causal/true OR 95% CI coverage)
scalar list P_covg_OR_AY_S1 					


/*Plot mean U across the B iterations of sample generation by S and overall*/
twoway (histogram mean_U_A1_S1, start(-0.11) width(0.01) color(blue)) ///
       (histogram mean_U_A0_S1, start(-0.11) width(0.01) ///
	   fcolor(cranberry) lcolor(cranberry)), ytitle(, size(huge)) ///
	   ylabel(, labsize(huge)) xlabel(, labsize(huge)) ///
	   xscale(range(-0.1 1.2)) xlabel(-0.2(.2)1.2) ///
	   yscale(range(0 25)) ylabel(0(5)25) ///
	   legend(order(1 "anxiety=1" 2 "anxiety=0" ) size(huge)) title("memory complaints=1",size(huge)) graphregion(color(white))
	   
	   graph save histogram_S1, replace
	   graph export histogram_S1.wmf,replace
	   
	   
twoway (histogram mean_U_A1_all, start(-0.11) width(0.01) fcolor(blue) lcolor(blue)) ///
       (histogram mean_U_A0_all, start(-0.11) width(0.01) ///
	   fcolor(cranberry) lcolor(cranberry)), ytitle(, size(huge)) ///
	   ylabel(, labsize(huge)) xlabel(, labsize(huge)) ///
	   xscale(range(-0.1 1.2)) xlabel(-0.2(.2)1.2) ///
	   yscale(range(0 25)) ylabel(0(5)25) ///
	   legend(order(1 "anxiety=1" 2 "anxiety=0" ) size(huge)) title("whole population",size(huge)) graphregion(color(white))
	   
	   graph save histogram_all, replace
	   graph export histogram_all.wmf,replace
	   
	   
/*Store results. One row=one iteration of sample generation*/	   
save collider_bias_teaching_example_results.dta, replace
