# Plot Deaths Over Time
# Gabriel Odom
# 2020-07-12

library(tidyverse)
library(lubridate)
library(readxl)



######  Death Data from Roy's "Connections"  ##################################
# ###  OLD DATA SOURCE  ###
# Through some black magic, Roy was able to get the .xlsx file *behind* the PDF
#   report that Trepka sent out. This makes life so much easier. See this slug:
# http://ww11.doh.state.fl.us/comm/_partners/covid19_report_archive/state_linelist_20200902.xlsx
# NOTE: this link no longer works after 9/2.

# deaths_df <- read_excel(
# 	path = "../data/deaths/state_linelist_20200830.xlsx",
# 	sheet = "Deaths",
# 	skip = 4
# ) %>%
# 	# Clean up the dates
# 	mutate(Date = as_date(`Date case counted`)) %>%
# 	select(-`Date case counted`)
# 
# # Newly-added deaths?
# deaths_df %>% 
# 	filter(`Newly identified death` == "Yes") %>% 
# 	filter(County == "Dade") %>% 
# 	arrange(Date) %>% 
# 	View
# # New deaths are added even back a full month. We are getting more and more 
# #   backlogged deaths.
# # On 5 August, they added 51 deaths to Miami-Dade County. Of those, 23 were
# #   added between 16-31 July, and 21 were added between 1-15 July. These counts
# #   cannot be expected as accurate until a full month passes.
# # As of 19 August, we added 40 deaths--22 of which were over 1 month old (before
# #   19 July). 
# 
# deathsbyday_df <-
# 	deaths_df %>%
# 	arrange(County, Date) %>%
# 	# Group deaths by day+county and count how many
# 	group_by(County, Date) %>%
# 	add_tally(name = "Count") %>%
# 	# Remove duplicate rows
# 	select(County, Date, Count) %>%
# 	distinct() %>%
# 	ungroup()


###  NEW DATA SOURCE  ###
# UPDATE: we can get simular data from ArcGIS:
# https://www.arcgis.com/sharing/rest/content/items/4cc62b3a510949c7a8167f6baa3e069d/data
#   The source for this data is this repo:
# https://github.com/mbevand/florida-covid19-line-list-data
#   The data link is defined in 
# <REPO>/blob/master/data_fdoh/download
#   The date-of-death variables are defined in comments in 
# <REPO>/blob/master/gamma.py

# We are missing data files after the 2nd of September from our original slug,
#   so we switched to the ArcGIS slug for 2020-09-08's data.
deaths_df <- 
	read_csv(
		file = "../data/deaths/Case_Data_arcGIS_20210116.csv"
	) %>% 
	# NOTE 2021-01-14: WHAT THE HELL IS "Recent"??? There are 243 "Recent" rows
	#   for the 16th data, but only 95 for the 10th. This must be a new designation
	filter(Died %in% c("Yes", "Recent")) %>% 
	filter(Jurisdiction == "FL resident") %>% 
	rename(CaseDate = Case_)

deaths2_df <- 
	deaths_df %>% 
	mutate(
		CaseDate  = str_remove(CaseDate, pattern = " .*"),
		ChartDate = str_remove(ChartDate, pattern = " .*")
	) %>%
	mutate(
		CaseDate  = as.Date(CaseDate, format = "%m/%d/%Y"),
		ChartDate = as.Date(ChartDate, format = "%m/%d/%Y")
	) %>% 
	mutate(
		CaseDate  = as_date(CaseDate),
		EventDate = as_date(EventDate),
		ChartDate = as_date(ChartDate),
	) %>% 
	select(
		County, Age, Age_group, Gender, EventDate, ChartDate
	)

# deaths2_df %>% 
# 	mutate(diffTime = ChartDate - CaseDate) %>% 
# 	pull(diffTime) %>% 
# 	as.numeric() %>% 
# 	summary()
# # Ok, so CaseDate and ChartDate are identical
# deaths2_df$CaseDate <- NULL

# deaths2_df %>%
# 	mutate(diffTime = ChartDate - EventDate) %>%
# 	pull(diffTime) %>%
# 	as.numeric() %>%
# 	summary()
# deaths2_df %>%
# 	mutate(diffTime = ChartDate - EventDate) %>%
# 	pull(diffTime) %>%
# 	as.numeric() %>%
# 	density() %>%
# 	plot()
# # For most people, the ChartDate is after the EventDate. This corroborates
# #   what we see in Bevand's code (gamma.py). He comments that the EventDate
# #   column is the date of the onset of COVID-19, while the ChartDate column
# #   lists the "date the case was counted". I now assume that means the date
# #   of death.

deathsbyday_df <-
	deaths2_df %>%
	arrange(County, ChartDate) %>%
	# Group deaths by day+county and count how many
	group_by(County, ChartDate) %>%
	add_tally(name = "Count") %>%
	# Remove duplicate rows
	select(County, ChartDate, Count) %>%
	distinct() %>%
	rename(Date = ChartDate) %>% 
	ungroup()
# I compared the first 10 rows (for Alachua County) between the reported deaths
#   we accessed on August 30th (FLDH_COVID19_deathsbyday_bycounty_20200830 in
#   the ~/data/deaths/ directory). They match exactly.

###  Save  ###
write_csv(
	x = deathsbyday_df,
	file = "../data/deaths/FLDH_COVID19_deathsbyday_bycounty_20210116.csv"
)



######  New Deaths Added  #####################################################
# The data in the new format does not mark "newly-added" deaths, so we don't
#   know how delayed the reporting is. In order to estimate this approximately
#   on a weekly basis, we will import the same data from last week, anti-join
#   the sets, and inspect the date distribution for both FL and Miami-Dade
#   county.


# deathsOld_df <- read_excel(
# 	path = "../data/deaths/state_linelist_20200830.xlsx",
# 	sheet = "Deaths",
# 	skip = 4
# ) %>%
# 	# Clean up the dates
# 	mutate(Date = as_date(`Date case counted`)) %>%
# 	select(-`Date case counted`)

deathsOld_df <- 
	read_csv(
		file = "../data/deaths/Case_Data_arcGIS_20210110.csv"
	) %>% 
	filter(Died %in% c("Yes", "Recent")) %>% 
	filter(Jurisdiction == "FL resident") %>% 
	rename(CaseDate = Case_) %>% 
	mutate(
		CaseDate  = str_remove(CaseDate, pattern = " .*"),
		ChartDate = str_remove(ChartDate, pattern = " .*")
	) %>%
	mutate(
		CaseDate  = as.Date(CaseDate, format = "%m/%d/%Y"),
		ChartDate = as.Date(ChartDate, format = "%m/%d/%Y")
	) %>% 
	mutate(
		CaseDate  = as_date(CaseDate),
		EventDate = as_date(EventDate),
		ChartDate = as_date(ChartDate),
	) %>% 
	select(
		County, Age, Age_group, Gender, EventDate, ChartDate
	)

deathsNew_df <- 
	read_csv(
		file = "../data/deaths/Case_Data_arcGIS_20210116.csv"
	) %>% 
	filter(Died %in% c("Yes", "Recent")) %>% 
	filter(Jurisdiction == "FL resident") %>% 
	rename(CaseDate = Case_) %>% 
	mutate(
		CaseDate  = str_remove(CaseDate, pattern = " .*"),
		ChartDate = str_remove(ChartDate, pattern = " .*")
	) %>%
	mutate(
		CaseDate  = as.Date(CaseDate, format = "%m/%d/%Y"),
		ChartDate = as.Date(ChartDate, format = "%m/%d/%Y")
	) %>% 
	mutate(
		CaseDate  = as_date(CaseDate),
		EventDate = as_date(EventDate),
		ChartDate = as_date(ChartDate),
	) %>% 
	select(
		County, Age, Age_group, Gender, EventDate, ChartDate
	)

newlyAddedDeaths_df <- 
	anti_join(
  	deathsNew_df %>% 
  		select(-EventDate, -Age_group) %>% 
  		rename(Date = ChartDate),
  	# Remove this wrangling step for deaths data in old (08-30) format
  	deathsOld_df %>% 
  		select(-EventDate, -Age_group) %>% 
  		rename(Date = ChartDate),
  	by = c("County", "Age", "Gender", "Date")
  )
nrow(deathsNew_df) - nrow(deathsOld_df)
# Between 30 August and 8 September, we added 795 new deaths, but 752 show up
#   as "present in New, but absent in Old". I'm willing to bet that this is
#   dropping repeated rows (i.e., there could be more than one 91 F from Dade
#   that died on the same day; it's unlikely, but possible). I don't know how
#   to fix this, but I can probably estimate the reporting delay without this
#   information.
# Between 8 September and 14 September, we added 727 new deaths, but only 648
#   show up in the anti-join.
# Between 14 September and 21 September, we added 675 new deaths, but only 658
#   show up in the anti-join.
# Between 21 September and 28 September, we added 720 new deaths, but only 691
#   show up in the anti-join.
# Between 28 September and 06 October, we added 730 new deaths, but 822 show up
#   in the anti-join.
# Between 06 October and 15 October, we added 969 new deaths, but 948 show up
#   in the anti-join. (NOTE: this was a 9-day window; that's 737 deaths/week.)
# Between 15 October and 20 October, we added 369 new deaths, but 363 show up
#   in the anti-join. (NOTE: this was a 5-day window; that's 517 deaths/week.)
# Between 20 October and 25 October, we added 324 new deaths, but 329 show up
#   in the anti-join. (NOTE: this was a 5-day window; that's 461 deaths/week.)
# Between 25 October and 1 November, we added 360 new deaths, but 370 show up
#   in the anti-join. 
# Between 1 November and 8 November, we added 332 new deaths, but 346 show up
#   in the anti-join. 
# Between 8 November and 15 November, we added 397 new deaths, but 399 show up
#   in the anti-join. 
# Between 15 November and 22 November, we added 412 new deaths, but 424 show up
#   in the anti-join. 
# Between 22 November and 29 November, we added 570 new deaths, but 552 show up
#   in the anti-join. 
# Between 29 November and 6 December, we added 677 new deaths, but 673 show up
#   in the anti-join. 
# Between 6 December and 13 December, we added 626 new deaths, but 624 show up
#   in the anti-join. 
# Between 13 December and 20 December, we added 686 new deaths, but 695 show up
#   in the anti-join. 
# Between 20 December and 27 December, we added 606 new deaths, but 611 show up
#   in the anti-join. 
# Between 27 December and 3 January, we added 785 new deaths, but 784 show up
#   in the anti-join. 
# Between 3 January and 10 January, we added 937 new deaths, but 949 show up
#   in the anti-join. 
# Between 10 January and 16 January, we added 1092 new deaths, but 1067 show up
#   in the anti-join. (NOTE: this was a 6-day window; that's 1245 deaths/week.)



######  Reporting Delays  #####################################################
# County
newlyAddedDeaths_df %>% 
	filter(County == "Dade") %>% # %in% c("Escambia", "Santa Rosa")
	pull(Date) %>% 
	summary()

# State
newlyAddedDeaths_df %>% 
	pull(Date) %>% 
	summary()


###  Reporting Delay 2020-09-08  ###
# MIAMI-DADE COUNTY:
#         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
# "2020-04-20" "2020-07-13" "2020-07-26" "2020-07-25" "2020-08-10" "2020-09-07" 
# On 8 September, over half of the newly-added deaths in Miami-Dade county were
#   recorded on or before 26 July.
# 
# STATE OF FLORIDA:
#         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
# "2020-04-20" "2020-07-20" "2020-08-06" "2020-08-02" "2020-08-19" "2020-09-07" 
# On 8 September, over half of the newly-added deaths in the State of Florida
#   were recorded on or before 6 August. This means that FL reporting is only
#   a month behind, while MDC is 6 weeks behind.


###  Reporting Delay 2020-09-14  ###
# MIAMI-DADE COUNTY:
#         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
# "2020-03-30" "2020-07-15" "2020-07-29" "2020-07-27" "2020-08-10" "2020-09-10"
# Something is off here. These deaths are supposed to go up to 09-14, but the
#   most recent death we have is from the 10th? Regardless, the median death
#   reporting date for the newly-added deaths is 29 July, almost 7 weeks back.
# Also, we just added a death on 30 March? Holy crap
# 
# STATE OF FLORIDA:
#         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
# "2020-03-30" "2020-07-22" "2020-08-07" "2020-08-05" "2020-08-23" "2020-09-13" 
# The state looks to be in a better position than Miami-Dade County. The deaths
#   are added up until the 13th of September, and median reporting date is only
#   5 weeks back.


###  Reporting Delay 2020-09-21  ###
# MIAMI-DADE COUNTY:
#         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
# "2020-05-02" "2020-07-26" "2020-08-08" "2020-08-06" "2020-08-19" "2020-09-19"
# Something is off here. These deaths are supposed to go up to 09-14, but the
#   most recent death we have is from the 10th? Regardless, the median death
#   reporting date for the newly-added deaths is 29 July, almost 7 weeks back.
# Also, we just added a death on 30 March? Holy crap
# 
# STATE OF FLORIDA:
#         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
# "2020-05-02" "2020-07-29" "2020-08-18" "2020-08-12" "2020-08-28" "2020-09-19" 
# The state looks to be in a better position than Miami-Dade County. The deaths
#   are added up until the 13th of September, and median reporting date is only
#   5 weeks back.


###  Reporting Delay 2020-09-28  ###
# MIAMI-DADE COUNTY:
#         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
# "2020-04-03" "2020-07-21" "2020-08-02" "2020-07-29" "2020-08-13" "2020-09-11" 
# 10-week delay for 75th percentile; 8-week delay for 50th percentile
#  
# STATE OF FLORIDA:
#         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
# "2020-04-03" "2020-07-23" "2020-08-07" "2020-08-07" "2020-08-27" "2020-09-27" 
# The state looks to be in a better position than Miami-Dade County for recent
#   deaths, but the quantiles are still being dragged back.
# 9.5-week delay for 75th percentile; 7-week delay for 50th percentile


###  Reporting Delay 2020-10-06  ###
# MIAMI-DADE COUNTY:
#         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
# "2020-04-11" "2020-07-16" "2020-08-04" "2020-08-05" "2020-08-27" "2020-10-05" 
# 12-week delay for 75th percentile; 9-week delay for 50th percentile
#  
# STATE OF FLORIDA:
#         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
# "2020-04-11" "2020-07-21" "2020-08-12" "2020-08-11" "2020-09-05" "2020-10-05"  
# The state looks to be in a better position than Miami-Dade County for recent
#   deaths, but the quantiles are still being dragged back.
# 11-week delay for 75th percentile; 8-week delay for 50th percentile


###  Reporting Delay 2020-10-15  ###
# MIAMI-DADE COUNTY:
#         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
# "2020-04-17" "2020-07-24" "2020-08-10" "2020-08-12" "2020-09-10" "2020-10-06" 
# 12-week delay for 75th percentile; 9-week delay for 50th percentile
#  
# STATE OF FLORIDA:
#         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
# "2020-04-15" "2020-07-24" "2020-08-13" "2020-08-16" "2020-09-13" "2020-10-14"  
# 12-week delay for 75th percentile; 9-week delay for 50th percentile


###  Reporting Delay 2020-10-20  ###
# MIAMI-DADE COUNTY:
#         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
# "2020-05-10" "2020-07-29" "2020-09-01" "2020-08-28" "2020-09-29" "2020-10-19"  
# 12-week delay for 75th percentile; 7-week delay for 50th percentile
#  
# STATE OF FLORIDA:
#         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
# "2020-04-19" "2020-08-05" "2020-09-03" "2020-08-29" "2020-09-25" "2020-10-19"  
# 11-week delay for 75th percentile; 7-week delay for 50th percentile


###  Reporting Delay 2020-10-25  ###
# MIAMI-DADE COUNTY:
#         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
# "2020-04-23" "2020-08-23" "2020-09-11" "2020-09-03" "2020-09-29" "2020-10-22"  
# 9-week delay for 75th percentile; 6-week delay for 50th percentile
#  
# STATE OF FLORIDA:
#         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
# "2020-03-26" "2020-08-30" "2020-09-19" "2020-09-09" "2020-10-03" "2020-10-23"  
# 8-week delay for 75th percentile; 5-week delay for 50th percentile


###  Reporting Delay 2020-11-01  ###
# MIAMI-DADE COUNTY:
#         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
# "2020-03-26" "2020-07-30" "2020-09-18" "2020-08-30" "2020-10-04" "2020-10-27"
# 13-week delay for 75th percentile; 6-week delay for 50th percentile. Something
#   wild happened here: our 75th percentile delay jumped by 5 weeks. I guess we
#   are getting caught up on deaths from the second wave?
#  
# STATE OF FLORIDA:
#         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
# "2020-03-26" "2020-09-13" "2020-09-28" "2020-09-20" "2020-10-10" "2020-10-29"
# 7-week delay for 75th percentile; 5-week delay for 50th percentile


###  Reporting Delay 2020-11-08  ###
# MIAMI-DADE COUNTY:
#         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
# "2020-05-26" "2020-09-15" "2020-10-01" "2020-09-26" "2020-10-18" "2020-11-04" 
# 8-week delay for 75th percentile; 5-week delay for 50th percentile. 
#  
# STATE OF FLORIDA:
#         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
# "2020-04-20" "2020-09-22" "2020-10-07" "2020-09-30" "2020-10-19" "2020-11-06"
# 7-week delay for 75th percentile; 5-week delay for 50th percentile


###  Reporting Delay 2020-11-15  ###
# MIAMI-DADE COUNTY:
#         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
# "2020-04-03" "2020-08-04" "2020-10-01" "2020-09-06" "2020-10-17" "2020-11-04"
# 15-week delay for 75th percentile; 6-week delay for 50th percentile. 
#  
# STATE OF FLORIDA:
#         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
# "2020-04-03" "2020-09-17" "2020-10-12" "2020-09-29" "2020-10-26" "2020-11-14"
# 8-week delay for 75th percentile; 5-week delay for 50th percentile


###  Reporting Delay 2020-11-22  ###
# MIAMI-DADE COUNTY:
#         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
# "2020-07-13" "2020-08-13" "2020-10-08" "2020-09-24" "2020-10-29" "2020-11-19"
# 14-week delay for 75th percentile; 6-week delay for 50th percentile. 
#  
# STATE OF FLORIDA:
#         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
# "2020-04-27" "2020-10-04" "2020-10-25" "2020-10-12" "2020-11-04" "2020-11-20" 
# 7-week delay for 75th percentile; 4-week delay for 50th percentile


###  Reporting Delay 2020-11-29  ###
# MIAMI-DADE COUNTY:
#         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
# "2020-07-07" "2020-10-14" "2020-10-29" "2020-10-17" "2020-11-11" "2020-11-27"
# 7-week delay for 75th percentile; 4-week delay for 50th percentile. 
# THIS IS THE SHORTEST REPORTING DELAY WE'VE SEEN IN MIAMI-DADE SINCE SEPTEMBER.
#  
# STATE OF FLORIDA:
#         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
# "2020-04-02" "2020-08-31" "2020-10-22" "2020-10-03" "2020-11-07" "2020-11-27"
# 13-week delay for 75th percentile; 5-week delay for 50th percentile


###  Reporting Delay 2020-12-06  ###
# MIAMI-DADE COUNTY:
#         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
# "2020-06-01" "2020-10-31" "2020-11-08" "2020-10-30" "2020-11-16" "2020-12-04" 
# 5-week delay for 75th percentile; 4-week delay for 50th percentile. 
# THIS IS THE SHORTEST REPORTING DELAY WE'VE SEEN IN MIAMI-DADE SINCE SEPTEMBER.
#   Last week was the shortest reporting delay, and now this week is even
#   shorter. Perhaps the current infrastructure is more capable of keeping pace
#   with the new deaths?
#  
# STATE OF FLORIDA:
#         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
# "2020-05-08" "2020-10-24" "2020-11-07" "2020-10-25" "2020-11-18" "2020-12-05" 
# 6-week delay for 75th percentile; 4-week delay for 50th percentile


###  Reporting Certification Delay 2020-12-13  ###
# I met with DoH (Sarah Suarez and Dr. Villalta) this past week. They explained
#   that this delay we see isn't a "reporting" delay anymore (it hasn't been a
#   reporting delay since some time in August or September when a policy change
#   allowed physicians to mark COVID-19 as a cause of death; this removed the
#   medical examiner bottleneck that horribly delayed reporting over the second
#   wave). This delay is a "certification" and/or "quality assurance" delay:
#   the State offices in Tallahassee take extra time verifying that these deaths
#   are indeed COVID-19 deaths. The individual counties usually have all the
#   deaths data from nursing homes, EMS, long-term care, hospice, hospitals, and
#   the medical examiners office within 2 weeks. Then that data is sent to the
#   state office for QA (which can add quite a bit of delay).
# MIAMI-DADE COUNTY:
#         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
# "2020-05-05" "2020-11-02" "2020-11-13" "2020-11-07" "2020-11-24" "2020-12-05" 
# 6-week delay for 75th percentile; 4-week delay for 50th percentile.
#  
# STATE OF FLORIDA:
#         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
# "2020-04-22" "2020-10-28" "2020-11-14" "2020-10-29" "2020-11-24" "2020-12-10"  
# 7-week delay for 75th percentile; 4-week delay for 50th percentile


###  Reporting Certification Delay 2020-12-20  ###
# MIAMI-DADE COUNTY:
#         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
# "2020-07-09" "2020-11-12" "2020-11-22" "2020-11-12" "2020-11-30" "2020-12-17" 
# 5-week delay for 75th percentile; 4-week delay for 50th percentile. 
#  
# STATE OF FLORIDA:
#         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
# "2020-04-10" "2020-11-10" "2020-11-22" "2020-11-09" "2020-12-02" "2020-12-18" 
# 6-week delay for 75th percentile; 4-week delay for 50th percentile


###  Reporting Certification Delay 2020-12-27  ###
# MIAMI-DADE COUNTY:
#         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
# "2020-05-25" "2020-11-17" "2020-11-26" "2020-11-19" "2020-12-08" "2020-12-21"
# 6-week delay for 75th percentile; 4-week delay for 50th percentile. 
#  
# STATE OF FLORIDA:
#         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
# "2020-04-07" "2020-11-15" "2020-11-28" "2020-11-19" "2020-12-08" "2020-12-24"
# 6-week delay for 75th percentile; 4-week delay for 50th percentile


###  Reporting Certification Delay 2021-01-03  ###
# happy new year...
# MIAMI-DADE COUNTY:
#         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
# "2020-07-13" "2020-11-25" "2020-12-06" "2020-11-30" "2020-12-14" "2020-12-28"
# 6-week delay for 75th percentile; 4-week delay for 50th percentile. 
#  
# STATE OF FLORIDA:
#         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
# "2020-04-17" "2020-11-23" "2020-12-06" "2020-11-25" "2020-12-15" "2020-12-31"
# 6-week delay for 75th percentile; 4-week delay for 50th percentile


###  Reporting Certification Delay 2021-01-10  ###
# MIAMI-DADE COUNTY:
#         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
# "2020-05-16" "2020-11-25" "2020-12-10" "2020-11-27" "2020-12-17" "2021-01-06"
# 7-week delay for 75th percentile; 5-week delay for 50th percentile. 
#  
# STATE OF FLORIDA:
#         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
# "2020-04-17" "2020-12-04" "2020-12-14" "2020-12-05" "2020-12-23" "2021-01-07"
# 5-week delay for 75th percentile; 4-week delay for 50th percentile


###  Reporting Certification Delay 2021-01-16  ###
# MIAMI-DADE COUNTY:
#         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
# "2020-05-19" "2020-12-06" "2020-12-14" "2020-12-02" "2020-12-21" "2021-01-12"
# 6-week delay for 75th percentile; 5-week delay for 50th percentile. 
#  
# STATE OF FLORIDA:
#         Min.      1st Qu.       Median         Mean      3rd Qu.         Max. 
# "2020-04-16" "2020-12-10" "2020-12-21" "2020-12-12" "2020-12-30" "2021-01-15"
# 5-week delay for 75th percentile; 4-week delay for 50th percentile



######  Plots of Deaths  ######################################################
###  Import Cleaned Deaths Data  ###
deathsbyday_df <- read_csv(
	"../data/deaths/FLDH_COVID19_deathsbyday_bycounty_20210116.csv"
)

# deathsbyday_df %>% 
# 	filter(County == "Dade")
# # The first 10 rows for Miami-Dade County also match exactly. I think I'm
# #   willing to put out this data.


###  Plot County Deaths over Time  ###
whichCounty <- "Dade" # "Palm Beach" # "Broward"

ggplot(
	deathsbyday_df %>% 
		filter(County == whichCounty) %>% # %in% c("Escambia", "Santa Rosa")
		# Only 25% of newly added deaths are on or before this date. See comments
		#   on newly-added deaths in previous section
		filter(Date <= "2020-12-06")
) +
	
	theme_bw() +
	theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
	aes(x = Date, y = Count) +
	# scale_y_log10() +
	scale_x_date(
		date_breaks = "1 week",
		date_minor_breaks = "1 day",
		labels = scales::date_format("%d-%b")
	) +
	labs(
		title = paste("Deaths by Day for", whichCounty, "County")
	) +
	
	geom_point() +
	stat_smooth(method = "gam")


###  Plot State Deaths over Time  ###
ggplot(
	deathsbyday_df %>% 
		group_by(Date) %>% 
		summarise(Count = sum(Count)) %>% 
	  # See comments on newly-added deaths in previous section
	  filter(Date <= "2020-12-10")
) +
	
	theme_bw() +
	theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
	aes(x = Date, y = Count) +
	scale_x_date(
		date_breaks = "1 week",
		date_minor_breaks = "1 day",
		labels = scales::date_format("%d-%b")
	) +
	labs(
		title = "Deaths by Day for the State of Florida"
	) +
	
	geom_point() +
	stat_smooth(method = "gam")


