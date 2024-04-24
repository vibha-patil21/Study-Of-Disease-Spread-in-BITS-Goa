# Study-Of-Disease-Spread-in-BITS-Goa
Using agent-based simulations to understand how an infection spreads in a college campus
## Problem Statement
Understanding the spread of an infection will help in planning efficient rules and regulations for managing and preventing outbreak and provide insight into predicting the future of the outbreaks. To that end, the aims of the simulation study are as follows. 
1. Measure the percentage of cummulative infections and active infections over a period of 28 days.
2. Test effectiveness of restrictions like quarantines, classroom and mess batches and hostel zones to see if they can prevent an outbreak by decreasing or delaying surge in infections 
## Methodology and Implementation
### GIS Data
GIS data is collected using Open Street Map and GQIS tools. Vector Polygon datasets are used to represent boundary of the campus and different areas like student hostels, mess and classroom buildings.
### Model
The agents in the model represent student. Students can move within the boundary of the campus, go to different locations and expose or infect other people to disease. Students stay within the vector polygon of their location. The model's environment mimics the everyday lives of students in the campus. Students stay in the hostel. They attend classes according to their timetables and go to mess.
The model uses the S-E-I-R-D Framework (Susceptible - Exposed - Infected - Recovered – Deceased) to demonstrate the disease progression in individual agents. Each student in the simulation has a variable which tracks the stage of disease progression. At the start of the simulation, some individuals are infected, and others are susceptible to the disease. As the individuals move around and come in contact with others, they are exposed to the disease, and after some time, given some infection chances, they are infected with the disease. After a recovery period, the infected individuals either recover or remain infected, depending on the recovery chances. At this point, the chances of death are also checked. If the infected individuals die, they are removed from the simulation. In addition, students can also be quarantined if the feature is enabled.
### Implementation
Different datasets contain details of students and class location. stored as CSV files

ID.csv : List of Students, their hostel, batch and branches.

merged_timetable.csv : Acts as a master timetable. It contains 4 columns: unique_ID, day, hour and location. Used to store details of all lectures according to the day of the week, hour of the day and location of the lecture. Each <day,hour,location> triplet has a unique id which is used to reference the triplet.

Student.csv: It contians 2 columns, student_id and unique_id. This csv contains unique_ids of all lectures for each student in the simulation.

For each day and hour in the simulation, filter rows in merged_timetable.csv containing the current hour and day. The unique ids of these rows represent lectures during that hour.
For each filtered unique id: each unique id represents a particular lecture. We can get location of the lecture using the row of the unique id. Using Student.csv, locations of all students who have the filtered unique_ids mentioned are updated according to the corresponding lecture location. This ensures students attend classes according to their lectures.

Students who don't have a class in the current hour and day go to a default location (eg. hostel). 

(EXPLAIN MESS)
(EXPLAIN BATCHES)
(EXPLAIN ZONES, quarantine)


### Software 
The model is developed using NetLogo 6.2.0 with GIS extension (version 1.1.2). The BehaviorSpace tool in NetLogo is used to run experiments. Each experiment runs multiple simulations and generates CSV files containing results for each simulation. Python (Matplotlib library) is used to analyse data and visualise results.

#### Parameters: 

|parameter|value| 
|----|-------|  
|Distance scale-down para.| 0.02|
|1 tick| 1 hour|
|Duration|28 days|
|Population|630|
|Radius of exposure| 0.04 (~2m)|
|Incubation Period|4 days|
|Illness Period|10 days|
|Chances of Exposure|70%|
|Chances of infection|70%|
|Chances of recovery|80%|
|Chances of death|1%|

### Code Architecture
<img width="760" alt="Diagram" src="https://github.com/vibha-patil21/Study-Of-Disease-Spread-in-BITS-Goa/assets/98578612/9d8133f6-f2ef-4aa6-929a-d0e2e20bd097" >


## Results (plots)
### Percentage of Cumulative Infections 
![cummInfections vs days](https://github.com/vibha-patil21/Study-Of-Disease-Spread-in-BITS-Goa/assets/98578612/7c2aa39c-718d-4209-bead-ee4e62ee07c7)

### Percentage of Active Infections
![currInfections vs days](https://github.com/vibha-patil21/Study-Of-Disease-Spread-in-BITS-Goa/assets/98578612/d6fa29b7-5b07-47d7-a313-3ac52efcaf58)

## Conclusion
(readme will be updated)
