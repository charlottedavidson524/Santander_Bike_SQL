# Santander_Bike_SQL

## Profiling

Stations: 793 IDs with 793 names in the old format, and 792 with 792 in the new. Each format is perfectly 1:1, and 786 names match across formats exactly.
7 old names don’t match. One is a spacing issue (Regent's Row , Haggerston ). The other six are probably stations that were closed or renamed by mid-September.
No duplicates within or across formats, and no missing values.
The duration patterns held at full scale: the old format has a 60-second minimum, while the new format has 3,713 journeys under a minute. There are 176 and 495 journeys over 24 hours, 2,010 and 4,507 likely failed hires, and 35 new-format duration mismatches.
The nulls in section 1 for the new format are the SQLTools display quirk again, not the data.

## Cleaning
