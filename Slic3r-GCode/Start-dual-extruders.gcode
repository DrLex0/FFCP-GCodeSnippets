;- - - Custom G-code for dual extruder printing with FlashForge Creator Pro - - -
;- - - by DrLex; 2016/09-2019/07. Released under Creative Commons Attribution License. - - -
; IMPORTANT: ensure your home offsets are correctly set. The Y home offset is correct if
;   the initial extrusion performed by this code is at 3mm from the front edge of the bed.
; IMPORTANT: ensure "Use relative E distances" is enabled in Printer settings.
; Tips for better dual extrusion quality:
; 1. Use my dualstrusion-postproc script version 1.0 or newer:
;    https://github.com/DrLex0/DualstrusionPostproc
;    It optimizes the file for much better results on printers like the FFCP.
; 2. Enable a skirt up to the tallest layer that has two materials, and set minimum skirt
;    extrusion length to have at least 3 loops in the first layer.
; 3. Ensure nozzles are clean: no oozed filament and no gunk stuck to them.
;
;SUMMARY
;
;first layer temperature (right) = [first_layer_temperature_0]C
;first layer temperature (left) = [first_layer_temperature_1]C
;temperature (right) = [temperature_0]C
;temperature (left) = [temperature_1]C
;first layer bed temperature = [first_layer_bed_temperature]C
;bed temperature = [bed_temperature]C
;
;bottom solid layers = [bottom_solid_layers]
;top solid layers = [top_solid_layers]
;perimeters = [perimeters]
;seam position = [seam_position]
;
;layer height = [layer_height]mm
;first layer height = [first_layer_height]mm
;z_offset = [z_offset]mm
;fill density = [fill_density]
;fill pattern = [fill_pattern]
;infill only where needed = [infill_only_where_needed]
;
;skirts = [skirts]
;brim width = [brim_width]mm
;raft layers = [raft_layers]
;support material = [support_material]
;support material threshold = [support_material_threshold] degrees
;support material enforced for first n layers = [support_material_enforce_layers]
;support material extruder = [support_material_extruder]
;
;first layer speed = [first_layer_speed]
;perimeter speed = [perimeter_speed]mm/s
;small perimeter speed = [small_perimeter_speed]
;external perimeter speed = [external_perimeter_speed]
;infill speed = [infill_speed]mm/s
;solid infill speed = [solid_infill_speed]
;top solid infill speed = [top_solid_infill_speed]
;support material speed = [support_material_speed]mm/s
;gap fill speed = [gap_fill_speed]mm/s
;travel speed = [travel_speed]mm/s
;bridge speed = [bridge_speed]mm/s
;bridge flow ratio = [bridge_flow_ratio]
;slowdown if layer time is less than = [slowdown_below_layer_time]secs
;minimum print speed = [min_print_speed]mm/s
;
;
;EXTRUSION
;
;filament diameter (right) = [filament_diameter_0]mm
;nozzle diameter (right) = [nozzle_diameter_0]mm
;extrusion multiplier (right) = [extrusion_multiplier_0]
;filament diameter (left) = [filament_diameter_1]mm
;nozzle diameter (left) = [nozzle_diameter_1]mm
;extrusion multiplier (left) = [extrusion_multiplier_1]
;bridge flow ratio = [bridge_flow_ratio]
;extrusion axis = [extrusion_axis]
;extrusion width = [extrusion_width]mm
;first layer extrusion width = [first_layer_extrusion_width]mm
;perimeter extrusion width = [perimeter_extrusion_width]mm
;infill extrusion width = [infill_extrusion_width]mm
;solid infill extrusion width = [solid_infill_extrusion_width]mm
;top infill extrusion width = [top_infill_extrusion_width]mm
;support material extrusion width = [support_material_extrusion_width]mm
;
;
;SUPPORT
;
;raft layers = [raft_layers]
;brim width = [brim_width]mm
;support material = [support_material]
;support material threshold = [support_material_threshold] degrees
;support material enforced for first n layers = [support_material_enforce_layers]
;support material extruder = [support_material_extruder]
;support material extrusion width = [support_material_extrusion_width]mm
;support material interface layers = [support_material_interface_layers]
;support material interface spacing = [support_material_interface_spacing]mm
;support material pattern = [support_material_pattern]
;support material angle = [support_material_angle] degrees
;support material spacing = [support_material_spacing]mm
;support material speed = [support_material_speed]mm/s
;
;
;OTHER (see end of file for all parameters)
;
;complete objects = [complete_objects]
;cooling enabled = [cooling]
;disable fan for first layers = [disable_fan_first_layers]
;duplicate distance = [duplicate_distance]mm
;external perimeters first = [external_perimeters_first]
;extra perimeters = [extra_perimeters]
;extruder clearance height = [extruder_clearance_height]mm
;extruder clearance radius = [extruder_clearance_radius]mm
;extruder offset = [extruder_offset]mm
;fan always on = [fan_always_on]
;fan below layer time = [fan_below_layer_time]secs
;fill angle = [fill_angle] degrees
;gcode comments = [gcode_comments]
;gcode flavor = [gcode_flavor]
;infill every n layers = [infill_every_layers]
;infill extruder = [infill_extruder]
;infill first = [infill_first]
;minimum skirt length = [min_skirt_length]mm
;only retract when crossing perimeters = [only_retract_when_crossing_perimeters]
;perimeter extruder = [perimeter_extruder]
;retract before travel (right) = [retract_before_travel_0]
;retract on layer change (right) = [retract_layer_change_0]
;retract length (right) = [retract_length_0]mm
;retract length on tool change (right) = [retract_length_toolchange_0]mm
;retract lift (right) = [retract_lift_0]
;retract extra distance on restart (right) = [retract_restart_extra_0]mm
;retract extra on tool change (right) = [retract_restart_extra_toolchange_0]mm
;retract speed (right) = [retract_speed_0]mm/s
;retract before travel (left) = [retract_before_travel_1]
;retract on layer change (left) = [retract_layer_change_1]
;retract length (left) = [retract_length_1]mm
;retract length on tool change (left) = [retract_length_toolchange_1]mm
;retract lift (left) = [retract_lift_1]
;retract extra distance on restart (left) = [retract_restart_extra_1]mm
;retract extra on tool change (left) = [retract_restart_extra_toolchange_1]mm
;retract speed (left) = [retract_speed_1]mm/s
;skirt distance = [skirt_distance]mm
;skirt height = [skirt_height] layers
;solid infill below area = [solid_infill_below_area]mm (sq)
;solid infill every n layers = [solid_infill_every_layers]
;
;- - - - - - - - - - - - - - - - - - - - - - - - -

T0; set primary extruder
; Although we will first initialise the left extruder, do not do a tool change until everything is ready to avoid all kinds of quirks.
M73 P0; enable show build progress
M140 S[first_layer_bed_temperature]; heat bed up to first layer temperature
M104 S140 T0; preheat right nozzle to 140 degrees, this should not cause oozing
M104 S140 T1; preheat left nozzle to 140 degrees, this should not cause oozing
M127; disable fan
G21; set units to mm
M320; acceleration enabled for all commands that follow
G162 X Y F8400; home XY axes maximum
G161 Z F1500; roughly home Z axis minimum
G92 X118 Y72.5 Z0 E0 B0; set (rough) reference point (also set E and B to make GPX happy). This will be overridden by the M132 below but ensures correct visualisation in some programs.
G1 Z5 F1500; move the bed down again
G4 P0; Wait for command to finish
G161 Z F100; accurately home Z axis minimum
M132 X Y Z A B; Recall stored home offsets (accurate reference point which you can configure in the printer's LCD menu).
G90; set positioning to absolute
M83; use relative E coordinates
G1 Z20 F1500; move Z to waiting height
G1 X140 Y65 F1500; do a slow small move to allow acceleration to be gently initialised
G1 X70 Y-83 F8400; move to waiting position (front right corner of print bed), also makes room for the tool change
; In theory, Sailfish should combine the T1 with the next move. I have tried to make this work many times and I found it extremely unreliable, therefore I force an explicit tool swap as follows.
G1 F4000; set speed for tool change, keep it low because not accelerated.
T1; initialise the left extruder first, this minimises tool changes, assuming the print will start with the right extruder.
G4 P0; flush pipeline
M18 A B; disable extruder steppers while heating
M190 S[first_layer_bed_temperature]; Wait for bed to heat up. Leave extruders at 140C, to avoid cooking the filament.
M104 S[first_layer_temperature_0] T0; set 1st nozzle heater to first layer temperature
M104 S[first_layer_temperature_1] T1; set 2nd nozzle heater to first layer temperature
M116; wait for everything to reach target temperature (do not use M6 Tx, it is a combined tool change + wait).
M17; re-enable all steppers
G1 Z0 F1000
G1 X70 Y-74 F4000; chop off any ooze on the front of the bed
G1 Z[first_layer_height] F1500; move to first layer height
G1 X-121 E24 F2000; extrude a line of filament across the front edge of the bed using left extruder
; Note how we extrude a little beyond the bed, this produces a tiny loop that makes it easier to remove the extruded strip.
G1 Y-71 F2000
G1 X-108 Y-74 F4000; cross the extruded line to close the loop
G1 X-100 F4000; wipe across the line (X direction)
; I have tried to do a proper tool change retract on the nozzle, but this consistently resulted in unacceptable
; extrusion lag afterwards, maybe because the firmware performs an additional retraction.
; The 'G92 E-0.6' trick no longer works with relative E, so a post-processing script should add some extra E when T1 is unretracted.
G1 F4000; set speed for tool change, keep it low because not accelerated.
T0; switch back to right extruder.
G4 P0; flush pipeline
G1 X-70 Y-72 F8400; move to front left corner of bed
G1 X121 E24 F2000; extrude a line of filament across the front edge of the bed using right extruder
; Again extrude a little beyond the bed.
G1 Y-69 F2000
G1 X108 Y-72 F4000; cross the extruded line to close the loop
G1 X100 F4000; wipe across the line (X direction)
G1 X90 Y-77 F6000; Move back for an additional wipe (Y direction)
;G92 E-0.6; This no longer works with relative E. The purpose was to compensate for the inexplicable but consistent under-extrusion that occurs at the start of the skirt. This compensation must now be done in a post-processing script.
G1 F8400; in case Slic3r would not override this, ensure fast travel to first print move
M73 P1 ;@body (notify GPX body has started)
;- - - End custom G-code for dual extruder printing - - -

