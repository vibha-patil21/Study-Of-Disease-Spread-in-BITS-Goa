# Study-Of-Disease-Spread-in-BITS-Goa
Using agent-based simulations to understand how an infection spreads on a college campus
## Problem Statement
Understanding the spread of infection will help in planning efficient rules and regulations for managing and preventing outbreaks and provide insight into predicting the future of the outbreaks. To that end, the aims of the simulation study are as follows. 
1. Measure the percentage of cumulative infections and active infections over a period of 28 days.
2. Test the effectiveness of restrictions like quarantines, classroom and mess batches and hostel zones to see if they can prevent an outbreak by decreasing or delaying a surge in infections 
## Methodology and Implementation
### 2.1 GIS Data
GIS data is collected using Open Street Map and GQIS tools. Vector Polygon datasets are used to represent the boundary of the campus and different areas like student hostels, mess and classroom buildings.
### 2.2 Model
The agents in the model represent students. Students can move within the boundaries of the campus, go to different locations, and be exposed to or infect other people with the disease. Students stay within the vector polygon of their location. The model's environment mimics the everyday lives of students on campus. Students stay in the hostel. They attend classes according to their timetables and go to mess.
The model uses the S-E-I-R-D Framework (Susceptible - Exposed - Infected - Recovered – Deceased) to demonstrate the disease progression in individual agents. Each student in the simulation has a variable which tracks the stage of disease progression. At the start of the simulation, some individuals are infected, and others are susceptible to the disease. As individuals move around and come in contact with others, they are exposed to the disease, and after some time, given some chance of infection, they are infected with the disease. After a recovery period, the infected individuals either recover or remain infected, depending on the recovery chances. At this point, the chances of death are also checked. If the infected individuals die, they are removed from the simulation. In addition, students can also be quarantined if the feature is enabled.
### 2.3 Implementation
#### 2.3.1 Datasets
Different datasets contain details of students and class locations stored as CSV files.

ID.csv: List of Students, their hostel, batch and branches.

merged_timetable.csv: Acts as a master timetable. It contains 4 columns: unique_ID, day, hour and location. It is used to store details of all lectures according to the day of the week, hour of the day and location of the lecture. Each <day, hour, location> triplet has a unique ID, which is used to reference the triplet.

Student.csv: It contains 2 columns, student_id and unique_id. This CSV contains unique_ids of all lectures for each student in the simulation.

#### 2.3.2 Creating Different Conditions
The model contains switches called classroom, mess-switch, quarantine, class-batches and mess-batches. These switches are used in combination to simulate different conditions. (e.g., if the classroom switch is on, students go to classrooms according to their timetable; otherwise, they do not.)
1. classroom switch:
For each day and hour in the simulation, filter rows in merged_timetable.csv containing the current hour and day. The unique IDs of these rows represent lectures during that hour.
For each filtered unique id: each unique id represents a particular lecture. We can get the location of the lecture using the row of the unique ID. Using Student.csv, the locations of all students who have the filtered unique_ids mentioned are updated according to the corresponding lecture location. This ensures students attend classes according to their lectures.
Students who don't have a class at the current hour and day go to a default location (e.g. a hostel). 

2. mess-switch: Students go to one of the messes 3 times a day during fixed hours. Each mess hour is divided into 4 slots. Students are allotted one of the slots randomly. For each slot, students with that slot go to mess and take random positions. Infected students expose students to the disease. At the end of their slots, students go back to their hostel.

3. class-batches switch: Students with even IDs are allotted class-batch 0, and those with odd IDs are allotted class-batch 1. When the class-batches switch is on, students with class-batch 0 go to class on even days, and others go on odd days. This reduces the strength of students attending classes to 50%. For each classroom, if the number of students in the classroom per unit area exceeds a limit (more than one), then infected students expose students to the disease.
   
4. mess-batches switch: Students with even IDs are allotted one of the first two slots randomly, and those with odd IDs are one of the other 2 slots randomly. Batches are used to ensure the same students interact with each other.
5. quarantine switch: Students who become infected are quarantined immediately in a different hostel building. Quarantined students do not go to mess or classes. They are under quarantine for an isolation period of 7 days.
   
### 2.4 Software 
The model is developed using NetLogo 6.2.0 with GIS extension (version 1.1.2). The BehaviorSpace tool in NetLogo is used to run experiments. Each experiment runs multiple simulations and generates CSV files containing results for each simulation. Python (Matplotlib library) is used to analyse data and visualise results.

#### 2.4.1 Parameters: 

|parameter|value| 
|----|-------|  
|Distance scale-down para.| 0.02|
|1 tick| 1 hour|
|Duration|28 days|
|Population|630|
|Radius of exposure| 0.04 (~2m)|
|Isolation Period|7 days|
|Incubation Period|4 days|
|Illness Period|10 days|
|Chances of Exposure|70%|
|Chances of infection|70%|
|Chances of recovery|80%|
|Chances of death|1%|

### Code Architecture
<img width="760" alt="Diagram" src="https://github.com/vibha-patil21/Study-Of-Disease-Spread-in-BITS-Goa/assets/98578612/9d8133f6-f2ef-4aa6-929a-d0e2e20bd097" >


## Results
'free' refers to simulations run without any restrictions, quarantine or zones. (classroom, mess-switch -ON, class-batches,mess-batches, quarantine- OFF, no zones in hostel)
'free+Q' refers to simulations run with quarantine without any restrictions or zones. (classroom, mess-switch, quarantine -ON, class-batches,mess-batches- OFF, no zones in hostel)
'restricted' refers to simulations run with restrictions and zones without quarantine. (classroom, mess-switch, class-batches, mess-batches-ON, quarantine- OFF, zones in hostel)
'restricted+Q' refers to simulations run with restrictions, zones, and quarantine. (classroom, mess-switch, class-batches, mess-batches, quarantine-ON, zones in hostel)
### 4.1 Percentage of Cumulative Infections 
![cummInfections vs days](https://github.com/vibha-patil21/Study-Of-Disease-Spread-in-BITS-Goa/assets/98578612/f10fd86f-913a-4726-a342-a728ae75dfa9)

### 4.2 Percentage of Active Infections
![currInfections vs days](https://github.com/vibha-patil21/Study-Of-Disease-Spread-in-BITS-Goa/assets/98578612/ded6645b-ef5e-4d31-acd9-b35af8486c35)

### 4.3 Recoveries
## Conclusion
(readme will be updated)
