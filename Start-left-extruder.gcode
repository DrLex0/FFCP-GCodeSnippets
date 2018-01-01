;- - - Custom G-code for left extruder printing with FlashForge Creator Pro - - -
;- - - by DrLex; 2016/09-2018/01. Released under Creative Commons Attribution License. - - -
; IMPORTANT: ensure "Use relative E distances" is enabled in Printer settings.
;
;SUMMARY
;
;first layer temperature = [first_layer_temperature]C
;temperature = [temperature]C
;first layer bed temperature = [first_layer_bed_temperature]C
;bed temperature = [bed_temperature]C
;
;first layer height = [first_layer_height]mm
;layer height = [layer_height]mm
;z_offset = [z_offset]mm
;perimeters = [perimeters]
;seam position = [seam_position]
;fill density = [fill_density]
;fill pattern = [fill_pattern]
;skirts = [skirts]
;brim width = [brim_width]mm
;raft layers = [raft_layers]
;support material = [support_material]
;support material threshold = [support_material_threshold] degrees
;support material enforced for first n layers = [support_material_enforce_layers]
;support material extruder = [support_material_extruder]
;
;bottom solid layers = [bottom_solid_layers]
;top solid layers = [top_solid_layers]
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
;filament diameter = [filament_diameter]mm
;nozzle diameter = [nozzle_diameter]mm
;bridge flow ratio = [bridge_flow_ratio]
;extrusion axis = [extrusion_axis]
;extrusion multiplier = [extrusion_multiplier]
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
;EVERYTHING ELSE
;
;complete objects = [complete_objects]
;cooling enabled = [cooling]
;default acceleration = [default_acceleration]mm/s/s
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
;infill acceleration = [infill_acceleration]mm/s/s
;infill every n layers = [infill_every_layers]
;infill extruder = [infill_extruder]
;infill first = [infill_first]
;infill only where needed = [infill_only_where_needed]
;minimum skirt length = [min_skirt_length]mm
;only retract when crossing perimeters = [only_retract_when_crossing_perimeters]
;perimeter acceleration = [perimeter_acceleration]mm/s/s
;perimeter extruder = [perimeter_extruder]
;retract before travel = [retract_before_travel]
;retract on layer change = [retract_layer_change]
;retract length = [retract_length]mm
;retract length on tool change = [retract_length_toolchange]mm
;retract lift = [retract_lift]
;retract extra distance on restart = [retract_restart_extra]mm
;retract extra on tool change = [retract_restart_extra_toolchange]mm
;retract speed = [retract_speed]mm/s
;scale = [scale]
;skirt distance = [skirt_distance]mm
;skirt height = [skirt_height]mm
;solid infill below area = [solid_infill_below_area]mm (sq)
;solid infill every n layers = [solid_infill_every_layers]
;top/bottom fill pattern = [external_fill_pattern]
;
;- - - - - - - - - - - - - - - - - - - - - - - - -
;
T0; start with the right extruder. We will switch to T1 after having moved the print head to provide enough space for the nozzle offset.
M73 P0; enable show build progress
M140 S[first_layer_bed_temperature]; heat bed up to first layer temperature
M104 S140 T1; preheat nozzle to 140 degrees, this should not cause oozing
M127; disable fan
G21; set units to mm
M320; acceleration enabled for all commands that follow
G162 X Y F8400; home XY axes maximum
G161 Z F1500; roughly home Z axis minimum
G92 X118 Y72.5 Z0 E0 B0; set (rough) reference point (also set E and B to make GPX happy). This also ensures correct visualisation in some programs.
G1 Z5 F1500; move the bed down again
G4 P0; Wait for command to finish
G161 Z F100; accurately home Z axis minimum
G92 Z0; set accurate Z reference point
M132 X Y Z A B; Recall stored home offsets (accurate reference point)
G90; set positioning to absolute
M83; use relative E coordinates
G1 Z20 F1500; move Z to waiting height
G1 X135 Y75 F1500; do a slow small move because the first move is likely not accelerated
G1 X70 Y-82 F8400; move to waiting position (front right corner of print bed), also makes room for the tool change
; In theory, Sailfish should combine the T1 with the next move. I have tried to make this work many times and I found it extremely unreliable, therefore I force an explicit tool swap as follows.
G1 F4000; set speed for tool change, keep it low because not accelerated.
T1; switch to the left extruder
G4 P0; flush pipeline
M18 A B; disable extruder steppers while heating
M190 S[first_layer_bed_temperature]; Wait for bed to heat up. Leave extruder at 140C, to avoid cooking the filament.
M104 S[first_layer_temperature] T1; set nozzle heater to first layer temperature
M116; wait for everything to reach target temperature
M17 B; re-enable left extruder stepper
G1 Z0 F1000
G1 X70 Y-73 F4000; chop off any ooze on the front of the bed
G1 Z[first_layer_height] F1500; move to first layer height
G1 X-121 Y-73 E24 F2000; extrude a line of filament across the front edge of the bed
; Note how we extrude a little beyond the bed, this produces a tiny loop that makes it easier to remove the extruded strip.
G1 Y-70 F2000
G1 X-108 Y-73 F4000; cross the extruded line to close the loop
G1 X-100 F4000; wipe across the line (X direction)
G1 X-90 Y-78 F6000; Move back for an additional wipe (Y direction)
;G92 E-0.6; This no longer works with relative E. The purpose was to compensate for the inexplicable but consistent under-extrusion that occurs at the start of the skirt. This compensation must now be done in a post-processing script.
G1 F8400; in case Slic3r would not override this, ensure fast travel to first print move
M73 P1 ;@body (notify GPX body has started)
;- - - End custom G-code for left extruder printing - - -
