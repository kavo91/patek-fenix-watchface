import Toybox.Lang;

// Dark probe (dark.jungle): forces the dark palette with default slots.
// Probe values of -1 mean "use the user's setting".
module BuildFlags {
    const FORCE_AOD = false;
    const PROBE_THEME = 2;
    const PROBE_SLOT_LEFT = -1;
    const PROBE_SLOT_RIGHT = -1;
    const PROBE_SLOT_BOTTOM = -1;
    const PROBE_WIN_LEFT = -1;
    const PROBE_WIN_RIGHT = -1;
    const PROBE_SCALE = 1.0;      // dial scale; store screenshot builds shrink the dial so the simulator bezel hides nothing
}
