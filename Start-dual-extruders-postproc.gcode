;- - - Custom G-code for dual extruder printing with FlashForge Creator Pro - - -
;- - - FOR USE IN COMBINATION WITH DUALSTRUSION POST-PROCESSING SCRIPT 0.6 OR NEWER ONLY - - -
;- - - Using it without the script will result in the print failing horribly! - - -
;- - - by DrLex; 2016/09-2017/12. Released under Creative Commons Attribution License. - - -
; IMPORTANT: ensure "Use relative E distances" is enabled in Printer settings.
; Do not forget to enable a skirt up to the tallest layer that has two materials, and
;   set minimum skirt extrusion length to have at least 3 loops in the first layer.
; LIMITATION: the first layer must contain something printed with the right extruder (T0).
; NOTE: you should start out with clean nozzles (no oozed filament and no gunk stuck
; to them) to reduce the risk of contamination during the print.
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
;scale = [scale]
;skirt distance = [skirt_distance]mm
;skirt height = [skirt_height]mm
;solid infill below area = [solid_infill_below_area]mm (sq)
;solid infill every n layers = [solid_infill_every_layers]
;top/bottom fill pattern = [external_fill_pattern]
;
;- - - - - - - - - - - - - - - - - - - - - - - - -
;
T0; set primary extruder
; We will not prime the left extruder here, that will happen through the priming tower.
M73 P0; enable show build progress
M140 S[first_layer_bed_temperature]; heat bed up to first layer temperature
M104 S140 T0; preheat right nozzle to 140 degrees, this should not cause oozing
M104 S140 T1; preheat left nozzle to 140 degrees, this should not cause oozing
; T1 will remain at 140 degrees so it does not ooze all across the first layer(s) while T0 is printing.
; Again, the post-processing script will take care of heating it to the full temperature.
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
G1 X-70 Y-82 F8400; move to waiting position (front left corner of print bed
M18 E; disable extruder steppers while heating
M190 S[first_layer_bed_temperature]; Wait for bed to heat up. Leave extruders at 140C, to avoid cooking the filament.
; Set 1st nozzle heater to first layer temperature and wait for it to heat.
; Do not use M116: we do not want to wait for T1 because its temperature is currently irrelevant.
; Do not use M109: older versions of Sailfish treat it the same as M104, again demonstrating the horrible lack of standardisation in G-code.
M104 S[first_layer_temperature_0] T0
M6 T0; This is actually tool change + wait for heating, but we are already at T0.
M17; re-enable all steppers
G1 Z0 F1500
G1 X-70 Y-73 F4000; chop off any ooze on the front of the bed
G1 Z[first_layer_height] F1500; move to first layer height
G1 X121 Y-73 E24 F2000; extrude a line of filament across the front edge of the bed using right extruder
; Note how we extrude a little beyond the bed, this produces a tiny loop that makes it easier to remove the extruded strip.
G1 Y-70 F2000
G1 X108 Y-73 F4000; cross the extruded line to close the loop
G1 X100 F4000; wipe across the line (X direction)
G1 X90 Y-78 F6000; Move back for an additional wipe (Y direction)
;G92 E-0.6; This no longer works with relative E. The purpose was to compensate for the inexplicable but consistent under-extrusion that occurs at the start of the skirt. This compensation must now be done in a post-processing script.
G1 F8400; in case Slic3r would not override this, ensure fast travel to first print move
M73 P1 ;@body (notify GPX body has started)
;- - - End custom G-code for dual extruder printing - - -
