import Toybox.Application;
import Toybox.Lang;

//! Snapshot of the user settings (resources/settings/properties.xml). Re-read on onSettingsChanged.
class Config {
    public var themeMode as Number = 0;        // 0 auto, 1 light, 2 dark
    public var autoBySun as Boolean = true;
    public var dayStartHour as Number = 7;
    public var dayEndHour as Number = 19;
    public var slotLeft as Number = Fields.STEPS;
    public var slotRight as Number = Fields.BODY_BATTERY;
    public var slotBottom as Number = Fields.MOON;
    public var winLeft as Number = Fields.WIN_DAY_MONTH;
    public var winRight as Number = Fields.WIN_BATTERY;
    public var moonSouth as Boolean = true;
    public var showSeconds as Boolean = true;

    function initialize() {
        load();
    }

    function load() as Void {
        themeMode = readNum("themeMode", 0, 0, 2);
        autoBySun = readBool("autoBySun", true);
        dayStartHour = readNum("dayStartHour", 7, 0, 23);
        dayEndHour = readNum("dayEndHour", 19, 0, 23);
        slotLeft = readNum("slotLeft", Fields.STEPS, 0, Fields.STRESS);
        slotRight = readNum("slotRight", Fields.BODY_BATTERY, 0, Fields.STRESS);
        slotBottom = readNum("slotBottom", Fields.MOON, 0, Fields.MOON);
        winLeft = readNum("winLeft", Fields.WIN_DAY_MONTH, 0, Fields.WIN_DIGITAL);
        winRight = readNum("winRight", Fields.WIN_BATTERY, 0, Fields.WIN_DIGITAL);
        moonSouth = readBool("moonSouth", true);
        showSeconds = readBool("showSeconds", true);
        // probe builds pin values so each mode can be screenshotted without touching device settings
        if (BuildFlags.PROBE_THEME >= 0) { themeMode = BuildFlags.PROBE_THEME; }
        if (BuildFlags.PROBE_SLOT_LEFT >= 0) { slotLeft = BuildFlags.PROBE_SLOT_LEFT; }
        if (BuildFlags.PROBE_SLOT_RIGHT >= 0) { slotRight = BuildFlags.PROBE_SLOT_RIGHT; }
        if (BuildFlags.PROBE_SLOT_BOTTOM >= 0) { slotBottom = BuildFlags.PROBE_SLOT_BOTTOM; }
        if (BuildFlags.PROBE_WIN_LEFT >= 0) { winLeft = BuildFlags.PROBE_WIN_LEFT; }
        if (BuildFlags.PROBE_WIN_RIGHT >= 0) { winRight = BuildFlags.PROBE_WIN_RIGHT; }
    }

    private function readRaw(key as String) as Object? {
        try {
            return Application.Properties.getValue(key);
        } catch (e) {
            return null;
        }
    }

    private function readNum(key as String, def as Number, lo as Number, hi as Number) as Number {
        var v = readRaw(key);
        var n = def;
        if (v instanceof Number) {
            n = v;
        } else if (v instanceof Float) {
            n = v.toNumber();
        } else if (v instanceof String) {
            var parsed = v.toNumber();
            if (parsed != null) {
                n = parsed;
            }
        }
        if (n < lo) {
            n = lo;
        }
        if (n > hi) {
            n = hi;
        }
        return n;
    }

    private function readBool(key as String, def as Boolean) as Boolean {
        var v = readRaw(key);
        if (v instanceof Boolean) {
            return v;
        }
        if (v instanceof Number) {
            return v != 0;
        }
        return def;
    }
}
