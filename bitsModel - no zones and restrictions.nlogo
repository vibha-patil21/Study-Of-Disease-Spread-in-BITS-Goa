;NO ZONES ANYWHERE
;NO RESTRICTIONS

extensions [gis csv]

globals[
  students-at-same-location
  count-students-in-class

  boundary-dataset
  classroom-boundary-dataset
  hostel-boundary-dataset
  classroom-dataset
  hostel-dataset
  mess-dataset
  quarantine-loc

  day
  work-day
  hour
  location

  tt-list
  id-list
  student-slot-list
  busy-students

  mess-duration1
  mess-duration2
  mess-duration3

  recovery-time ;minimum time a person will take to recover
  death-chances ;analogous to mortality rate
  recovery-chances ;analogous to recovery rate
  infection-chances ;how probable it is to get infected by an infected person in radius x
  affected-recovery-chances; second infection chances
  exposure-chances ;; chances of contact
  incubation-period ; assuming they are asymtomatic during this period and cant infect others
  isolation-period
  num-susceptible ; susceptible = not infected and not exposed yet
  num-infected ;infected
  num-exposed ;exposed to disease by an infected person, but not infected yet
  num-recovered
  num-deceased
]

breed [students student]
students-own[
  id
  hostel
  mess
  mess-time
  mess-time2
  mess-time3
  class-batch
  is-quarantine
  isolation-time
  curr-location
  prev-location-x
  prev-location-y
]

turtles-own [
  susceptible?
  infected?
  exposed?
  recovered?
  deceased?
  is-quarantine?
  sick-time
  isolation-time
  incubation ;after exposure, how much time has passed in hours
]


to setup-gis
  gis:load-coordinate-system "maps/campus.prj"
  set boundary-dataset gis:load-dataset "maps/campus.shp"
  set classroom-boundary-dataset gis:load-dataset "maps/classrooms_boundary.shp"
  set hostel-boundary-dataset gis:load-dataset "maps/hostel_boundary.shp"
  set mess-dataset gis:load-dataset "maps/mess_boundary.shp"

  gis:set-world-envelope (gis:envelope-union-of
    (gis:envelope-of boundary-dataset)
    (gis:envelope-of classroom-boundary-dataset)
    (gis:envelope-of hostel-boundary-dataset)
    (gis:envelope-of mess-dataset)
    )

  gis:set-drawing-color black
  gis:draw boundary-dataset 1
  gis:set-drawing-color grey
  gis:draw hostel-boundary-dataset 1
  gis:set-drawing-color red
  gis:draw classroom-boundary-dataset 1
  gis:draw mess-dataset 1

  set quarantine-loc  gis:find-one-feature hostel-boundary-dataset "HOSTELNUM" "Quarantine"
end

to setup-constants
  set recovery-time 240
  set death-chances 1
  set incubation-period 96
  set infection-chances 70
  set exposure-chances 70
  set isolation-period 168 ;7 days
  set recovery-chances 80
  set affected-recovery-chances 99
  set num-exposed 0
  set num-infected 0
  set num-recovered 0
  set num-deceased 0
  set mess-duration1 24
  set mess-duration2 6
  set mess-duration3 13
end

to setup
  ca
  random-seed seed
  reset-ticks
  ask patches [set pcolor white]
  ask patches with [(pxcor + pycor) mod 2 = 0][set pcolor 9]
  setup-gis
  setup-constants
  get-timetable
  create-pop
  allot-mess-time
end

to-report extract-elements-by-hour [nested-list time]
  let matching-sublists filter [sublist1 -> item 2 sublist1 = time] nested-list
  let first-elements map [sublist2 -> first sublist2] matching-sublists
  report first-elements
end

to allot-mess-time-old
  let classes24 extract-elements-by-hour tt-list 24
  let classes1 extract-elements-by-hour tt-list 1
  ;print(classes1)
  let classes2 extract-elements-by-hour tt-list 2
  let classes5 extract-elements-by-hour tt-list 5
  let classes6 extract-elements-by-hour tt-list 6
  let classes7 extract-elements-by-hour tt-list 7
  let classes11 extract-elements-by-hour tt-list 11
  let classes12 extract-elements-by-hour tt-list 12
  let classes13 extract-elements-by-hour tt-list 13

  ask students[
    ;print("student")
    let student-classes filter [sublist1 -> item 0 sublist1 = id] student-slot-list
    ;print(student-classes)
    let classes-uniqueid map [sublist2 -> item 1 sublist2] student-classes
    ;print(classes-uniqueid)


    set mess-time 24
    set mess-time2 6
  ]
  let mean-hour item 1 mess-duration1 ; Middle hour
  let std-dev 0.7 ;
  ask students [
    let dining-hour round(random-normal mean-hour std-dev)
    if dining-hour < item 0 mess-duration1 [set dining-hour item 0 mess-duration1] ; Ensure dining hour is within bounds
    if dining-hour > item 2 mess-duration1 [set dining-hour item 2 mess-duration1] ; Ensure dining hour is within bounds
    set mess-time dining-hour
  ]
  set mean-hour item 1 mess-duration2 ; Middle hour
  set std-dev 0.5 ;
  ask students [
    let dining-hour round(random-normal mean-hour std-dev)
    if dining-hour < item 0 mess-duration2 [set dining-hour item 0 mess-duration2] ; Ensure dining hour is within bounds
    if dining-hour > item 2 mess-duration2 [set dining-hour item 2 mess-duration2] ; Ensure dining hour is within bounds
    set mess-time2 dining-hour
  ]

  ;DINNER
  set mean-hour item 1 mess-duration3 ; Middle hour
  set std-dev 1 ;
  ask students [
    let dining-hour round(random-normal mean-hour std-dev)
    if dining-hour < item 0 mess-duration3 [set dining-hour item 0 mess-duration3] ; Ensure dining hour is within bounds
    if dining-hour > item 2 mess-duration3 [set dining-hour item 2 mess-duration3] ; Ensure dining hour is within bounds
    set mess-time3 dining-hour
  ]
end

to allot-mess-time
  let timings [1 2 3 4]
  ask students[
    set mess-time one-of timings
    ;set mess-time2 one-of timings
    ;set mess-time3 one-of timings
  ]
  if mess-batches [
    ask students with [ class-batch = 0] [
      set mess-time one-of [1 2]
    ]
    ask students with [ class-batch = 1] [
      set mess-time one-of [3 4]
    ]
  ]

end


to move-turtles-within-polygon [polygon_vf]
  ;print("check7")
  let x-cor xcor
  let y-cor ycor
  right random 360 forward (random 5) * 0.02
  while [not gis:contains? polygon_vf student who] [
    set xcor x-cor
    set ycor y-cor
    ;print("check8")
    right random 360 forward (random 5) * 0.02
  ]
end

to hostel-movement
  ask students with [ curr-location = hostel ]
  [
    set prev-location-x  xcor
    set prev-location-y  ycor
    repeat 100 [
     ask self [
        move-turtles-within-polygon hostel
     ]
   ]

 ]
end

to hostel-movement-come-back
  ask students with [ curr-location = hostel ]
  [
    set xcor prev-location-x
    set ycor prev-location-y
    ;repeat 100 [
     ;ask self [
      ;  move-turtles-within-polygon hostel
     ;]
    ;]

 ]
end

to create-pop

  set id-list csv:from-file "ID.csv"
  set id-list remove-item 0 id-list
  let n length id-list
  create-students n
  [
    let current-id item 0 item who id-list
    let current-hostel item 1 item who id-list
    let hostel_vf gis:find-one-feature hostel-boundary-dataset "HOSTELNUM" current-hostel
    let loc gis:location-of gis:centroid-of hostel_vf
    set id current-id
    ifelse id mod 2 = 0 [
      set class-batch 0
    ]
    [
      set class-batch 1
    ]

    set hostel hostel_vf
    set mess gis:find-one-feature mess-dataset "MESS" item 2 item who id-list
    set curr-location hostel_vf
    setxy item 0 loc item 1 loc
    repeat 50 [
      ask self [
        move-turtles-within-polygon hostel_vf
      ]
    ]
    set color gray
    set shape "circle"
    set size 0.3
    set is-quarantine? false
    set susceptible? true
    set exposed? false
    set infected? false
    set recovered? false
    set is-quarantine? false
    set deceased? false
    set sick-time 0
    set isolation-time 0
    set incubation 0
  ]
  set num-susceptible count turtles with [susceptible?]
  ;make initial infected population
  ask n-of initial-infected turtles with [not infected?]
  [
    set susceptible? false

    set infected? true
    set num-infected (num-infected + 1)
    set num-susceptible (num-susceptible - 1)
    set color red
  ]
  print(count students with [class-batch = 0])
  print(count students with [class-batch = 1])
end

to go
  ;print(gis:feature-list-of hostel-dataset)
  set day 1
  while[ day <= 28 ]
  [
    set hour 1
    while[ hour <= 24 ]
    [
      set work-day (day - 1) mod 7 + 1
      ;print(word "day " work-day " hour " hour)
      if quarantine
      [
        quarantine-infected-students
      ]

      if classroom
      [
        set busy-students []
        go-to-class
        ask students with [not member? who busy-students and curr-location != hostel and not is-quarantine?]
        [
          let locn gis:location-of gis:centroid-of hostel
          set curr-location hostel
          setxy item 0 locn item 1 locn
          repeat 100 [
            ask self [
              move-turtles-within-polygon hostel
            ]
          ]
        ]
      ]
      ; COUNTER 1 TO 4, STUDENTS GO TO MESS ACCD. TO SLOT, EXPOSE STUDENTS ONLY IN MESS FOR EACH COUNTER VALUE
      if mess-switch[
        if hour = mess-duration1 or hour = mess-duration2 or hour = mess-duration3 [
          ;print("going to mess")
          foreach [1 2 3 4] [
            x ->
            ;print(x)
            ask students with [mess-time = x and not is-quarantine?] [
              go-to-mess
            ]
            ask students with [mess-time = x and not is-quarantine?][
              if infected? [expose-people self]
            ]
            go-back-from-mess
          ]
        ]
      ]
     if hour mod 4 = 0
      [
        hostel-movement
      ]
      if hour != mess-duration1 or hour != mess-duration2 or hour != mess-duration3 [
        ask students with [infected?] [expose-people self]
      ]
      if hour mod 4 = 0
      [
        hostel-movement-come-back
      ]
      infect
      recover
      tick
      set hour hour + 1
    ]
    set day day + 1
  ]
  stop
end

to go-to-mess-old
  ;print(count students with [ mess-time = hour or mess-time2 = hour or mess-time3 = hour ])
  ask students with [ (mess-time = hour or mess-time2 = hour or mess-time3 = hour) and not is-quarantine? ]
  [
    ;print("changing loc to mess")
    ;print(who)
    set prev-location-x  xcor
    set prev-location-y  ycor
    ;print("check1")
    set curr-location mess
    ;print("check2")
    let locn gis:location-of gis:centroid-of mess
    ;print("check3")
    setxy item 0 locn item 1 locn
    ;print("check4")
    repeat 100 [
      ask self [
        ;print("check5")
        move-turtles-within-polygon mess
        ;print("check6")
      ]
    ]
  ]
end

to go-to-mess ;[student1]
  ;print(who)
    set curr-location mess
    let locn gis:location-of gis:centroid-of mess
    setxy item 0 locn item 1 locn
    repeat 100 [
      ask self [
        move-turtles-within-polygon mess
      ]
    ]
end

to go-back-from-mess
  ask students with [ curr-location = mess][
    let locn gis:location-of gis:centroid-of hostel
          set curr-location hostel
          setxy item 0 locn item 1 locn
          repeat 100 [
            ask self [
              move-turtles-within-polygon hostel
            ]
          ]
  ]
end


to expose-students [infected-student]
  let infected-location [pxcor] of infected-student

  set students-at-same-location turtles with [ (xcor = [pxcor] of infected-student) and (ycor = [pycor] of infected-student) ]

  let count-nearby-students count(students-at-same-location)
  ;print(students-at-same-location )
  let to-expose count-nearby-students / 3
  if count-nearby-students != 0
  [
    ask n-of to-expose students-at-same-location
    [
        if susceptible? = true
        [
          set exposed? true
          set color yellow
          set susceptible? false
          set num-exposed (num-exposed + 1)
          set num-susceptible (num-susceptible - 1)
        ]
    ]
  ]
end

to expose-people [infected-student]
  let infected-location [curr-location] of infected-student
  if count (students-here with [curr-location = infected-location and not infected? and not recovered?] in-radius 0.04) != 0
  [
     ask (students-here with [ curr-location = infected-location and not infected? and not recovered?] in-radius 0.04)
     [
        if susceptible? = true
        [
          set exposed? true
          set color yellow
          set susceptible? false
          set num-exposed (num-exposed + 1)
          set num-susceptible (num-susceptible - 1)
        ]
      ]
  ]

end

to infect

  ask turtles with [exposed? = true]
  [
     set incubation (incubation + 1)
     if incubation > incubation-period
     [
       ifelse random 100 < infection-chances
       [
         set infected? true
         set color red
         set exposed? false
         set num-infected (num-infected + 1)
         set num-exposed (num-exposed - 1)
       ]
       [
         set exposed? false
         set color gray
         set susceptible? true
         set num-exposed (num-exposed - 1)
         set num-susceptible (num-susceptible + 1)
       ]
     ]
   ]

end

to quarantine-infected-students
  ask students with [infected?]
  [
    ifelse is-quarantine?
    [
      set isolation-time (isolation-time + 1)
    ]
    [
      if isolation-time <= isolation-period [
        set is-quarantine? true
        ;CHANGE LOCN
        let locn gis:location-of gis:centroid-of quarantine-loc
        set curr-location quarantine-loc
        setxy item 0 locn item 1 locn
        repeat 100 [
          ask self [
            move-turtles-within-polygon quarantine-loc
          ]
        ]
      ]

    ]
    if isolation-time > isolation-period
    [
      set is-quarantine? false
      let locn gis:location-of gis:centroid-of hostel
      set curr-location hostel
      setxy item 0 locn item 1 locn
      repeat 100 [
        ask self [
         move-turtles-within-polygon hostel
        ]
      ]
    ]
  ]
end

to recover

  if count turtles with [infected?] != 0
  [
    ask students with [infected?]
    [
      set sick-time (sick-time + 1)
      if sick-time > recovery-time
      [
        ifelse recovered?
        [
          ifelse random 100 < affected-recovery-chances
          [
            set infected? false
            set recovered? true
            set color lime
            set susceptible? false
            set num-recovered (num-recovered + 1)
            set sick-time 0
          ]
          [
            if random 100 < death-chances
            [
              set num-deceased (num-deceased + 1)
              die
            ]
          ]
        ]
        [
          ifelse random 100 < recovery-chances
          [
            set infected? false
            set recovered? true
            set color lime
            set susceptible? false
            set num-recovered (num-recovered + 1)
            set sick-time 0
          ]
          [
            if random 100 < death-chances
            [
              set num-deceased (num-deceased + 1)
              die
            ]
          ]
        ]
      ]
    ]
  ]

end

to-report extract-elements-by-day-time2 [nested-list]
  let matching-sublists filter [sublist1 -> item 1 sublist1 = work-day and item 2 sublist1 = hour] nested-list
  report matching-sublists
end
to go-to-class

  let matchingSublists extract-elements-by-day-time2 tt-list
  ;print matchingSublists
  ;got all triplets for current day,hour with slot id
  ;now for each triplet-> get unique id, search for students with this unique id, update locations
  foreach matchingSublists [
    x ->
    let slot item 0 x
    let new-location item 3 x
    let class_vf gis:find-one-feature classroom-boundary-dataset "location" new-location
    ;print(class_vf)
    let loc gis:location-of gis:centroid-of class_vf
    foreach student-slot-list[
      y ->
      if slot = item 1 y [
        let student-id item 0 y
        ;print(word "slot: " slot " studentid " student-id)
        ifelse class-batches
        [
          ;ON
          ask students with [id = student-id and class-batch = work-day mod 2] [
            ;print(word "day" day "class-batch" class-batch)
            ;IF NOT QUARANTINED
            if not is-quarantine?
            [
              set busy-students lput who busy-students
              setxy item 0 loc item 1 loc
              set curr-location class_vf
              repeat 50 [
                ask self [
                  move-turtles-within-polygon curr-location
                ]
              ]
            ]
          ]
        ]
        [
          ;OFF
          ask students with [id = student-id] [
            print(word "day" day "class-batch" class-batch)
            ;IF NOT QUARANTINED
            if not is-quarantine?
            [
              set busy-students lput who busy-students
              setxy item 0 loc item 1 loc
              set curr-location class_vf
              repeat 50 [
                ask self [
                  move-turtles-within-polygon curr-location
                ]
              ]
            ]
          ]
        ]
      ]
    ]

  ]
end


to-report extract-elements-by-day-time [nested-list]
  let matching-sublists filter [sublist1 -> item 0 sublist1 = work-day and item 1 sublist1 = hour] nested-list
  report matching-sublists
end
to go-to-class-without-slot-id
  ;let myNestedList [[1 1 "A" "X"] [1 1 "B" "Y"] [1 2 "B" "Y"] [1 4 "C" "Z"]]

  let matchingSublists extract-elements-by-day-time tt-list
  ;print matchingSublists
  foreach matchingSublists [
    x ->
    let student-id item 3 x
    let new-location item 2 x
    ;print(word "id " student-id " loc " new-location)
    ask students with [id = student-id] [
      set busy-students lput who busy-students
      let class_vf gis:find-one-feature classroom-boundary-dataset "location" new-location
      ;print(class_vf)
      let loc gis:location-of gis:centroid-of class_vf
      setxy item 0 loc item 1 loc
      set curr-location class_vf
    ]
  ]
end

to go-to-class-direct-index
  ask students
  [

    let tt-index ((day - 1) * 4 + hour) - 1
    ;print(tt-index)
    let class_loc item 2 item tt-index tt-list
    ;print(class_loc)
    let class_vf gis:find-one-feature classroom-boundary-dataset "location" class_loc
    ;print(class_vf)
    let loc gis:location-of gis:centroid-of class_vf
    setxy item 0 loc item 1 loc
    set curr-location class_vf
  ]
end


to get-timetable
  set tt-list csv:from-file "timetables/merged_timetable22.csv"
  set tt-list remove-item 0 tt-list
  ;print( tt-list)
  set student-slot-list csv:from-file "timetables/Student.csv"
  set student-slot-list remove-item 0 student-slot-list
  ;print( student-slot-list)
end

to draw-circle  ;just to visualise how big or small the radius of exposure is
  ask turtles with [color = red] [
    let x xcor
    let y ycor
    set heading 90
    let radius 0.6
    let num-points 360 ; Number of points to draw the circle

    repeat num-points [
      ; Draw the circle
      fd radius * sin 1
      lt 1
    ]
    pen-up
    set xcor x
    set ycor y
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
647
448
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
66
82
129
115
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
135
82
198
115
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
721
224
786
269
work-day
work-day
0
1
11

MONITOR
791
225
848
270
hour
hour
17
1
11

MONITOR
660
224
717
269
day
day
17
1
11

SLIDER
652
11
824
44
initial-infected
initial-infected
0
20
5.0
1
1
NIL
HORIZONTAL

INPUTBOX
69
12
179
72
seed
42.0
1
0
Number

PLOT
657
52
1001
218
total cases
ticks
num. of cases
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"curr infected" 1.0 0 -2674135 true "" "plot count turtles with [infected?]"
"cum. infections" 1.0 0 -13345367 true "" "plot num-infected"
"deceased" 1.0 0 -7500403 true "" "plot num-deceased"
"recovered" 1.0 0 -15040220 true "" "plot num-recovered"

MONITOR
660
278
737
323
susceptible
count turtles with [susceptible?]
17
1
11

MONITOR
742
278
802
323
exposed
count turtles with [exposed?]
17
1
11

MONITOR
808
277
866
322
infected
count turtles with [infected?]
17
1
11

MONITOR
873
278
943
323
recovered
count turtles with [recovered?]
17
1
11

MONITOR
947
276
1043
321
NIL
num-deceased
17
1
11

MONITOR
853
225
962
270
num. of students
count students
17
1
11

MONITOR
661
334
771
379
cumm. infections
num-infected
17
1
11

SWITCH
79
122
191
155
classroom
classroom
0
1
-1000

SWITCH
78
164
204
197
mess-switch
mess-switch
0
1
-1000

SWITCH
75
208
191
241
quarantine
quarantine
0
1
-1000

SWITCH
75
252
207
285
class-batches
class-batches
1
1
-1000

SWITCH
71
292
205
325
mess-batches
mess-batches
1
1
-1000

MONITOR
779
334
888
379
students in class
length busy-students
17
1
11

PLOT
1012
49
1212
199
plot 1
ticks
no. students
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"check" 1.0 0 -16777216 true "" "plot length busy-students"

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>export-plot "total cases" (word seed "nozones_nobatches_q.csv")</final>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="initial-infected">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="classroom">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="class-batches">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mess-batches">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mess-switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seed">
      <value value="0"/>
      <value value="7"/>
      <value value="42"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="quarantine">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
