import Toybox.Lang;

// Store screenshot build (store-dark.jungle): dial at 92 % so the simulator's bezel image hides none of it.
// Probe values of -1 mean "use the user's setting".
module BuildFlags {
    const FORCE_AOD = false;
    const PROBE_THEME = 2;
    const PROBE_SLOT_LEFT = -1;
    const PROBE_SLOT_RIGHT = -1;
    const PROBE_SLOT_BOTTOM = -1;
    const PROBE_WIN_LEFT = -1;
    const PROBE_WIN_RIGHT = -1;
    const PROBE_SCALE = 0.92;
}
