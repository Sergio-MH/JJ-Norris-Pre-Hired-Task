/*******************************************************************************
  Project:        JJNorris Pre-Hire Task

  Title:          Tasks 1 and 2
  Author:         Sergio Andrés Moreno Huérfano
  Date:           May 22 2022
  Last Modified:  May 24 2022
  Version:        Stata 17
  Resume:         Este dofile trabaja el Pre-Hire Task 
  			
*******************************************************************************/

clear all
set matsize 10000
set scheme plotplain
set scheme plottig, permanently

************************************************
*                1. Directories                *
************************************************

* Choose parent 

di "current user: `c(username)'"

if "`c(username)'" == "sergi"{
	global parentDirectory "\Users\sergi\OneDrive\Escritorio\JJNorris Pre-Hire Task"	// SA Moreno's directory
}
	global rawdata "$parentDirectory/03_raw"
	global dofiles "$parentDirectory/00_code"
	global output "$parentDirectory/02_output"
	global temporary "$parentDirectory/04_temp"
	global logs "$parentDirectory/01_log"	

************************************************
*         2. Administrative Commands           *
************************************************

cap log close
set more off
clear
set memory 6g
pause on
set matsize 3000

cd "$parentDirectory"

log using log/task1.log, replace  // ¿¿¿Qué significa???


******************************
*           TASK 1           *
******************************

************************************************
*           0. Dataset Construction            *
************************************************

* Import sectoral employment share on log GDP per capita

insheet using "$rawdata/employment_city_sector.csv", comma clear

sort geography

rename geography Areaname

save "$temporary/employment_city_sector_sort.csv", replace
describe

* Import GDP data

import excel "$rawdata/gdp_pop_city.xlsx", ///
         sheet(Table 7) cellrange(C2) firstrow clear  // Get the data beginning in cell C2 where the firstrow contain the variable name
		 
sort Areaname, stable

save "$temporary/gdp_pop_city_sort.xlsx", replace
describe

/*foreach v of var * {
    local lbl : var label `v'
    local lbl = strtoname("`lbl'")
    rename `v' `lbl'
} */

* Save final dataset

merge Areaname using "$temporary/employment_city_sector_sort.csv" "$temporary/gdp_pop_city_sort.xlsx"

save "$output/dataset.dta", replace

* Defintion of the sectoral employment share 

global agriculture industryabdeagricultureenergyand
global manufacture industrycmanufacturingeconomicac
global services industrygidistributionhotelsandr industryklmnfinancialrealestatep industryopqpublicadministratione industryrstuothereconomicactivit
// Introduce other asumming there are services related to leisure and cultural activities
// ¿Debería incluir transporte?


************************************************
*           1. Regression Analysis             *
************************************************

use "$output/dataset.dta", clear

*************************************
*           Agriculture             *
*************************************

* OLS

log_gdp_per_capita = ln(Q)

regress $agriculture log_gdp_per_capita
	estimates store a

* Robust standard errors

regress $agriculture log_gdp_per_capita, vce(robust)
	estimates store a2 
	
* Export tables

xml_tab a a2, replace save("$output/Agriculture.xml") /// 
	title("")

*************************************
*           Manufacture             *
*************************************

* OLS

regress $manufacture log_gdp_per_capita
	estimates store m

* Robust standard errors

regress $manufacture log_gdp_per_capita, vce(robust)
	estimates store m2 
	
* Export tables

xml_tab m m2, replace save("$output/Manufacture.xml") /// 
	title("")
	
*************************************
*             Services              *
*************************************

* OLS

regress $services log_gdp_per_capita
	estimates store s

* Robust standard errors

regress $services log_gdp_per_capita, vce(robust)
	estimates store s2	
	
* Export tables

xml_tab s s2, replace save("$output/Services.xml") /// 
	title("")

	
************************************************
*                  5. Graphs                   *
************************************************

* Scatter plot

twoway (scatter $agriculture log_gdp_per_capita) (line ), subtitle(Agriculture)/// 
(scatter $manufacture log_gdp_per_capita ) (line ), subtitle(Manufacturing) /// 
(scatter $services log_gdp_per_capita ) (line ), subtitle(Services) /// 
lwidth(medthick)), ytitle(Share in total employment) xtitle(Log of GDP per capita) title(Employment)
ylabel(0 1) xline(0) legend(off)  graphregion(color(white)) bgcolor(white)

* Save graph in output folder

graph export "$output/ScatterTask.pdf", replace

log close
