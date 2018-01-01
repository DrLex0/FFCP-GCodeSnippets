;- - - Custom G-code for tool change of FlashForge Creator Pro - - -
;- - - by DrLex; 2016/09. Released under Creative Commons Attribution License. - - -
; We do not need to do any retraction here, slic3r and/or the firmware handles this for us.
G1 F6000; set speed for tool change. The move is not accelerated, therefore keep it reasonable.
; Mind that this is a hack, there is no reliable way to set tool change speed. This only works if the last command before this chunk of code was a G1 move. Sailfish tries to combine the tool change with the next (travel or retract) move in some fishy way.
T[next_extruder]; makes the printer swap the current nozzle with the next one
G4 P0; flush pipeline
;- - - End custom G-code for tool change - - -
