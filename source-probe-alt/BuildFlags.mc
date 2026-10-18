import Toybox.Lang;

// Alt probe (alt.jungle): light palette, heart rate / battery / digital time / date windows.
// Probe values of -1 mean "use the user's setting".
module BuildFlags {
    const FORCE_AOD = false;
    const PROBE_THEME = 1;
    const PROBE_SLOT_LEFT = 6;
    const PROBE_SLOT_RIGHT = 3;
    const PROBE_SLOT_BOTTOM = 5;
    const PROBE_WIN_LEFT = 3;
    const PROBE_WIN_RIGHT = 2;
    const PROBE_SCALE = 1.0;      // dial scale; store screenshot builds shrink the dial so the simulator bezel hides nothing
}
