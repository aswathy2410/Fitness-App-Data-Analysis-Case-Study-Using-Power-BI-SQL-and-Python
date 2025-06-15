Create database strava_analysis;
Use strava_analysis;
-- Tables are loaded using Table data import wizard
-- Verifying if the tables are loaded correctly
Select * from dailyactivity_merged,hourlycalories_merged,hourlyintensities_merged,hourlysteps_merged,sleepday_merged,weightloginfo_merged;

/* Data understanding and preprocessing of daily activity table */

Select count(*) from dailyactivity_merged;

Describe dailyactivity_merged;

-- Checking for negative values
Select min(Id), min(ActivityDate), min(TotalSteps),min(TotalDistance), min(TrackerDistance), min(VeryActiveDistance),
 min(ModeratelyActiveDistance), min(LightActiveDistance), min(SedentaryActiveDistance), min(VeryActiveMinutes), 
 min(FairlyActiveMinutes), min(LightlyActiveMinutes), min(SedentaryMinutes), min(Calories) from dailyactivity_merged; 
-- No negative values present 

-- Checking for null values in the columns
Select
  sum(case when TotalSteps is null then 1 else 0 end) as Null_TotalSteps,
  sum(case when TotalDistance is null then 1 else 0 end) as Null_TotalDistance,
  sum(case when TrackerDistance is null then 1 else 0 end) as Null_TrackerDistance,
  sum(case when LoggedActivitiesDistance is null then 1 else 0 end) as Null_LoggedActivitiesDistance,
  sum(case when VeryActiveDistance is null then 1 else 0 end) as Null_VeryActiveDistance,
  sum(case when ModeratelyActiveDistance is null then 1 else 0 end) as Null_ModeratelyActiveDistance,
  sum(case when SedentaryActiveDistance is null then 1 else 0 end) as Null_SedentaryActiveDistance,
  sum(case when VeryActiveMinutes is null then 1 else 0 end) as Null_VeryActiveMinutes,
  sum(case when FairlyActiveMinutes is null then 1 else 0 end) as Null_FairlyActiveMinutes,
  sum(case when LightlyActiveMinutes is null then 1 else 0 end) as Null_LightlyActiveMinutes,
  sum(case when SedentaryMinutes is null then 1 else 0 end) as Null_SedentaryMinutes,
  sum(case WHEN Calories is null then 1 else 0 end) as Null_Calories
from dailyactivity_merged;
-- The query returned 0 for all columns. This means there are no missing values in the columns

-- The date colum has text values. Let's convert it to date format
-- In the excel, we can see different formats of date. Let us update it all to the standard date format first 

Update dailyactivity_merged
set ActivityDate = case
    when ActivityDate like '%/%/%' then STR_TO_DATE(ActivityDate, '%c/%e/%Y')
    when ActivityDate like '%-%-%' then STR_TO_DATE(ActivityDate, '%m-%d-%Y')
    else ActivityDate
end
where ActivityDate like '%/%/%' or ActivityDate like '%-%-%';
-- Verify if all are in the same format
Select distinct ActivityDate from dailyactivity_merged;
-- Alter the datatype to date 
Alter table dailyactivity_merged modify column ActivityDate date;
-- Verify if the datatype has changed
Describe dailyactivity_merged;

-- Most of the values in logged activity is zero.
-- A column can be removed if more than 50% of data is missing or not valuable
Select count(*) from dailyactivity_merged where LoggedActivitiesDistance > 0;
-- As only 32 rows has values, deleting this feature.
Alter table dailyactivity_merged drop column LoggedActivitiesDistance;

/* Statistical analysis on daily activity data */ 
-- Count the total rows
Select count(*) from dailyactivity_merged;

Select count(distinct(Id)) from dailyactivity_merged; -- we have data of 33 users

-- Find the date range
Select min(ActivityDate), max(ActivityDate) from dailyactivity_merged ;
-- Results show min as 12-04-2016 and max as 12-05-2016 which indicates that we have 1 month's data
Select id, min(ActivityDate), max(ActivityDate) from dailyactivity_merged group by id;
Select count(ActivityDate) from dailyactivity_merged group by id; 
-- Howerever, the data is not consistent for all Ids. Some have data for fewer dates
-- most have 30 or 31 days. Some have 18, 19 and even 4 rows of data

-- Checking how active the user is
Select SedentaryMinutes from dailyactivity_merged;
-- If the sedentary minutes is more than 1000, it means the user is inactive most of the day
-- If it is equal to 1440, then they aren't wearing the device
Select count(SedentaryMinutes) from dailyactivity_merged where SedentaryMinutes>1000;
Select count(SedentaryMinutes) from dailyactivity_merged where SedentaryMinutes = 1440;
-- dailyactivity_merged has 930 rows and 515 has more than 1000 sdentary minutes
-- and 79 are not wearing it at all

-- Checking Calories level
Select Id, Calories from dailyactivity_merged;
Select sum(case when Calories > 2500 then 1 else 0 end) as Count_Calories_greater_2500,
  sum(case when Calories between 2000 and 2500 then 1 else 0 end) as Count_Calories_Between_2000_and_2500,
  sum(case when Calories < 2000 then 1 else 0 end) as Count_Calories_LT_2000
from dailyactivity_merged;
-- 234 + 337 meet the minimum requirement of 2000 for women and 2500 for men requirement of calories burned
-- As gender is not provided, we cannot confirm explicitely

-- Min, Max and Average steps
Select Id, min(TotalSteps), max(TotalSteps), avg(TotalSteps) from dailyactivity_merged group by Id;

-- Min, Max and Average calories burned
Select Id, min(Calories), max(Calories), avg(Calories) from dailyactivity_merged group by Id;

-- Min, Max and Average TrackerDistance
Select Id, min(TrackerDistance), max(TrackerDistance), avg(TrackerDistance) from dailyactivity_merged group by Id;

-- Min, Max and Average TotalDistance
Select Id, min(TotalDistance), max(TotalDistance), avg(TotalDistance) from dailyactivity_merged group by Id;
set sql_mode = (select replace(@@sql_mode, 'ONLY_FULL_GROUP_BY', ''));
Select Id, TrackerDistance, TotalDistance  from dailyactivity_merged group by Id;
Select * from dailyactivity_merged where TrackerDistance != TotalDistance;
-- The tracker and total distances are the same or very close indicating a good performance of the tracker

-- Finding the average active minutes for users
Select Id, avg(VeryActiveMinutes + FairlyActiveMinutes + LightlyActiveMinutes) as Avg_Active_Minutes
from dailyactivity_merged group by Id;

-- Finding standard deviation to understand the consistency of users
Select Id, stddev(TotalSteps) as Steps_StdDev from dailyactivity_merged group by Id;
-- Higher deviation indicates inconsistent patterns


-- Total active minutes per user
Select Id, SUM(VeryActiveMinutes + FairlyActiveMinutes + LightlyActiveMinutes) AS Total_Active_Minutes from dailyactivity_merged group by Id;
-- Monthly activity patterns per user
Select Id, month(ActivityDate) as Month, sum(TotalSteps) as Monthly_Steps FROM dailyactivity_merged
group by Id, Month;
-- Weekly activity patterns per user
Select Id, month(ActivityDate) as Month, week(ActivityDate) as Week, SUM(TotalSteps) as WeeklySteps from dailyactivity_merged
group by Id, Month, Week;
-- Total active minutes is inconsistent for users

-- Inorder to analyse this further using visualizations, creating monthly activity table and weekly activity table

Create Table monthly_activity_summary (
    Id bigint,
    Year int,
    Month int,
    TotalActivityMinutes int,
    TotalActivityDistance float,
    AvgActivityMinutes float,
    AvgActivityDistance float,
    StddevActivityMinutes float,
    StddevActivityDistance float
);
 
Create table weekly_activity_summary (
    Id bigint,
    Year int,
    Week int,
    TotalActivityMinutes int,
    TotalActivityDistance float,
    AvgActivityMinutes float,
    AvgActivityDistance float,
    StddevActivityMinutes float,
    StddevActivityDistance float
);

Alter table monthly_activity_summary
add column TotalSteps int,
add column TotalCalories int;

-- For weekly table
Alter table weekly_activity_summary
add column TotalSteps int,
add column TotalCalories int;

Insert into monthly_activity_summary (
    Id, Year, Month, 
    TotalActivityMinutes, TotalActivityDistance, 
    AvgActivityMinutes, AvgActivityDistance,
    StddevActivityMinutes, StddevActivityDistance,
    TotalSteps, TotalCalories
)
Select 
    Id,
    year(ActivityDate) as Year,
    month(ActivityDate) as Month,
    sum(VeryActiveMinutes + FairlyActiveMinutes + LightlyActiveMinutes) AS TotalActivityMinutes,
    sum(VeryActiveDistance + ModeratelyActiveDistance + LightActiveDistance) AS TotalActivityDistance,
    avg(VeryActiveMinutes + FairlyActiveMinutes + LightlyActiveMinutes) AS AvgActivityMinutes,
    avg(VeryActiveDistance + ModeratelyActiveDistance + LightActiveDistance) AS AvgActivityDistance,
    stddev(VeryActiveMinutes + FairlyActiveMinutes + LightlyActiveMinutes) AS StddevActivityMinutes,
    stddev(VeryActiveDistance + ModeratelyActiveDistance + LightActiveDistance) AS StddevActivityDistance,
    sum(TotalSteps) as TotalSteps,
    sum(Calories) as TotalCalories
from dailyactivity_merged
group by Id, Year, Month;
Select * from monthly_activity_summary;

Insert into weekly_activity_summary (
    Id, Year, Week, 
    TotalActivityMinutes, TotalActivityDistance, 
    AvgActivityMinutes, AvgActivityDistance,
    StddevActivityMinutes, StddevActivityDistance,
    TotalSteps, TotalCalories
)
SELECT 
    Id,
    year(ActivityDate) as Year,
    week(ActivityDate) as Week,
    sum(VeryActiveMinutes + FairlyActiveMinutes + LightlyActiveMinutes) AS TotalActivityMinutes,
    sum(VeryActiveDistance + ModeratelyActiveDistance + LightActiveDistance) AS TotalActivityDistance,
    avg(VeryActiveMinutes + FairlyActiveMinutes + LightlyActiveMinutes) AS AvgActivityMinutes,
    avg(VeryActiveDistance + ModeratelyActiveDistance + LightActiveDistance) AS AvgActivityDistance,
    stddev(VeryActiveMinutes + FairlyActiveMinutes + LightlyActiveMinutes) AS StddevActivityMinutes,
    stddev(VeryActiveDistance + ModeratelyActiveDistance + LightActiveDistance) AS StddevActivityDistance,
    sum(TotalSteps) as TotalSteps,
    sum(Calories) as TotalCalories
from dailyactivity_merged
group by Id, Year, Week;
Select * from weekly_activity_summary;

/* Data understanding and preprocessing for weightloginfo data */
Select count(*) from weightloginfo_merged; -- only 67 records. Not enough data. Not consistent.
-- As the data is not enough to get deep insights. Not going into further insights.
-- need to prompt user to update it regulhourlycalories_mergedarly

/* Data understanding and preprocessing of Sleep day data */
Describe sleepday_merged;
Select count(*) from sleepday_merged; -- 413 records

-- Check for null values
Select
  sum(case when TotalSleepRecords is null then 1 else 0 end) as Null_TotalSleepRecords,
  sum(case when TotalMinutesAsleep is null then 1 else 0 end) as Null_TotalMinutesAsleep,
  sum(case when TotalTimeInBed is null then 1 else 0 end) as Null_TotalTimeInBed
from sleepday_merged;
-- All returned 0, showing no null values

-- Check for negative values
Select min(Id), min(TotalSleepRecords), min(TotalMinutesAsleep), min(TotalTimeInBed) from sleepday_merged;
-- No negative values found

-- Let's update the date format
Select distinct(SleepDay) from sleepday_merged;
-- trim the time and add the date as text to a new column SleepDate
Alter table sleepday_merged ADD COLUMN SleepDate VARCHAR(20);
Update sleepday_merged set SleepDate = trim(SUBSTRING_INDEX(SleepDay, ' ', 1));
-- Apply string to date to change format
Update sleepday_merged set SleepDate = case
    when SleepDate like '%/%/%' then str_to_date(SleepDate, '%c/%e/%Y')
    when SleepDate like '%-%-%' then str_to_date(SleepDate, '%m-%d-%Y')
    else null
end
where SleepDate like '%/%/%' or SleepDate like '%-%-%';
-- Drop the SleepDay column and retain SleepDate
Alter table sleepday_merged drop column SleepDay;
-- verify it's done right
select * from sleepday_merged;
Describe sleepday_merged;

-- Verifying if every user gets the recommended sleep of 8 hours
Select count(Id) from sleepday_merged where TotalMinutesAsleep >= 480; -- 117
-- verifying if users are getting at least 5 hours of sleep
Select count(Id) from sleepday_merged where TotalMinutesAsleep >= 300; -- 363, most do
-- Checking If people are taking 2 sleeps a day
Select count(Id) from sleepday_merged where TotalSleepRecords > 1; -- 46 very few take extra naps

/* Data understanding and preprocessing for minutesleep data */
Select * from minutesleep_merged;
-- Change the date column to Datetime format
Alter table minutesleep_merged add column SleepDateTime datetime after date;
Update minutesleep_merged set date = trim(date);
Update minutesleep_merged set SleepDateTime = str_to_date(date, '%c/%e/%Y %h:%i:%s %p')
where str_to_date(date, '%c/%e/%Y %h:%i:%s %p') is not null;
Alter table minutesleep_merged modify column SleepDateTime datetime;

-- checking for null values
Select 
  sum(case when SleepDateTime is null then 1 else 0 end) as Null_SleepDateTime,
  sum(case when value is null then 1 else 0 end) as Null_value
from minutesleep_merged; 
-- Checking the percentage of sleep modes in users
Select id,
  sum(case when value = 2 then 1 else 0 end) / count(*) as DeepSleepRatio,
  SUM(case when value = 3 then 1 else 0 end) / count(*) as REMSleepRatio
from minutesleep_merged group by id;
Select
  SleepDateTime,
  sum(case when value = 1 then 1 else 0 end) as LightSleepMinutes,
  sum(case when value = 2 then 1 else 0 end) as DeepSleepMinutes,
  sum(case when value = 3 then 1 else 0 end) as REMSleepMinutes
from minutesleep_merged group by SleepDaTeTime, Id order by SleepDateTime;
-- Most of the users have light sleep. Sleep improvement tips can be provided
-- Also not all users are logging sleep values which indicates not all users wear the tracker whiweekly_activity_summaryle asleep

/* Data Understand and preprocessing of Hourly intensities data */
Select * from hourlyintensities_merged;
Describe hourlyintensities_merged;

-- Change Activity hour to Date time format
Alter table hourlyintensities_merged add column ActivityTime datetime after ActivityHour;
Update hourlyintensities_merged set ActivityHour = trim(ActivityHour);
Update hourlyintensities_merged set ActivityTime = str_to_date(ActivityHour, '%c/%e/%Y %h:%i:%s %p')
where str_to_date(ActivityHour, '%c/%e/%Y %h:%i:%s %p') is not null;
Alter table hourlyintensities_merged modify column ActivityTime datetime;
Alter table hourlyintensities_merged drop column ActivityHour;

-- Calculating daily intensities
Select Id, date(ActivityTime) as ActivityDate, sum(TotalIntensity) as TotalDailyIntensity
from  hourlyintensities_merged group by Id, ActivityDate;
select
    a.Id,
    a.ActivityDate,
    a.TotalDailyIntensity,
    case
        when a.TotalDailyIntensity > 300 then 'High'
        else 'Low'
    end as IntensityCategory
from (
    select
        Id,
        date(ActivityTime) as ActivityDate,
        sum(TotalIntensity) as TotalDailyIntensity
    from hourlyintensities_merged
    group by Id, ActivityDate
) a;
-- Sleep the day after high-intensity activity
select s.Id, s.SleepDate, s.TotalMinutesAsleep,
    s.TotalTimeInBed, s.TotalSleepRecords, a.IntensityCategory
from sleepday_merged s
join (
    select a.Id, a.ActivityDate,
        case
            when a.TotalDailyIntensity > 100 then 'High'
            else 'Low'
        end as IntensityCategory
    from (
        select Id, date(ActivityTime) as ActivityDate, sum(TotalIntensity) as TotalDailyIntensity
        from hourlyintensities_merged
        group by Id, ActivityDate
    ) a
) a on s.SleepDate = date_add(a.ActivityDate, interval 1 day)
where a.IntensityCategory in ('High', 'Low');
-- Can't realy notice a direct relationship between the two
-- It depends on a lot of other factors like age, gender, profession, etc which aren't available in the datasets

-- Changing the text to date time format in hourly calories data
Alter table hourlycalories_merged add column ActivityTime datetime after ActivityHour;
Update hourlycalories_merged set ActivityHour = trim(ActivityHour);
Update hourlycalories_merged set ActivityTime = str_to_date(ActivityHour, '%c/%e/%Y %h:%i:%s %p')
where str_to_date(ActivityHour, '%c/%e/%Y %h:%i:%s %p') is not null;
Alter table hourlycalories_merged modify column ActivityTime datetime;
Alter table hourlycalories_merged drop column ActivityHour;
Select * from hourlycalories_merged;

-- Changing the text to date time format in hourly steps data
Alter table hourlysteps_merged add column ActivityTime datetime after ActivityHour;
Update hourlysteps_merged set ActivityHour = trim(ActivityHour);
Update hourlysteps_merged set ActivityTime = str_to_date(ActivityHour, '%c/%e/%Y %h:%i:%s %p')
where str_to_date(ActivityHour, '%c/%e/%Y %h:%i:%s %p') is not null;
Alter table hourlysteps_merged modify column ActivityTime datetime;
Alter table hourlysteps_merged drop column ActivityHour;
Select * from hourlysteps_merged;

-- Updating date to datetime format in daily activities data to maintain the same kind of format
Alter table dailyactivity_merged add column ActivityDateTime datetime after ActivityDate;
Update dailyactivity_merged set  ActivityDateTime = concat(ActivityDate, ' 00:00:00');
Alter table dailyactivity_merged modify column ActivityDateTime datetime;
Alter table dailyactivity_merged drop column ActivityDate;
Describe dailyactivity_merged;

/* Further analysis will be done in python
The minute and seconds data were not loading properly due to it's large size.
They will be analysed in the python notebook file */






