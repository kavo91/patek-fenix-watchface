import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;

//! Data-slot catalogue, value sources and formatting.
module Fields {
    enum {
        NONE = 0,          // sub-dials: empty
        BODY_BATTERY = 1,
        STEPS = 2,
        BATTERY = 3,
        DATE = 4,
        DIGITAL = 5,
        HEART_RATE = 6,
        CALORIES = 7,
        FLOORS = 8,
        STRESS = 9,
        MOON = 10          // 6 o'clock only: moon phase + 1-31 date track
    }
    // 12 o'clock window contents (each window is its own slot)
    enum {
        WIN_EMPTY = 0,
        WIN_WEEKDAY = 1,
        WIN_MONTH = 2,
        WIN_DAY = 3,
        WIN_DAY_MONTH = 4,
        WIN_MONTH_DAY = 5,
        WIN_BATTERY = 6,
        WIN_BODY_BATTERY = 7,
        WIN_STEPS = 8,
        WIN_HEART_RATE = 9,
        WIN_CALORIES = 10,
        WIN_FLOORS = 11,
        WIN_STRESS = 12,
        WIN_DIGITAL = 13
    }

    const CALORIE_SCALE = 3000;
    const HR_MIN = 40;
    const HR_MAX = 180;

    //! 6540 -> "6,540"
    function fmtThousands(n as Number) as String {
        if (n < 1000) {
            return n.format("%d");
        }
        return (n / 1000).format("%d") + "," + (n % 1000).format("%03d");
    }

    //! Compact form for the 12 o'clock windows: 6540 -> "6540", 12345 -> "12.3k"
    function fmtShort(n as Number) as String {
        if (n < 10000) {
            return n.format("%d");
        }
        return (n / 1000.0).format("%.1f") + "k";
    }

    //! Scale label: 10000 -> "10k", 7500 -> "7.5k", 750 -> "750"
    function fmtK(n as Number) as String {
        if (n < 1000) {
            return n.format("%d");
        }
        if (n % 1000 == 0) {
            return (n / 1000).format("%d") + "k";
        }
        return (n / 1000.0).format("%.1f") + "k";
    }

    //! Text for one 12 o'clock window (at most five characters wide).
    function windowText(kind as Number, ds as DataSource, is24 as Boolean) as String {
        switch (kind) {
            case WIN_WEEKDAY: { return ds.dayName; }
            case WIN_MONTH: { return ds.monthName; }
            case WIN_DAY: { return ds.day.format("%d"); }
            case WIN_DAY_MONTH: { return ds.day.format("%02d") + "/" + ds.monthNum.format("%02d"); }
            case WIN_MONTH_DAY: { return ds.monthNum.format("%02d") + "/" + ds.day.format("%02d"); }
            case WIN_BATTERY: { return ds.battery.format("%d") + "%"; }
            case WIN_BODY_BATTERY: { return (ds.bodyBattery == null) ? "--" : (ds.bodyBattery as Number).format("%d"); }
            case WIN_STEPS: { return fmtShort(ds.steps); }
            case WIN_HEART_RATE: { return (ds.heartRate == null) ? "--" : (ds.heartRate as Number).format("%d"); }
            case WIN_CALORIES: { return fmtShort(ds.calories); }
            case WIN_FLOORS: { return ds.floors.format("%d"); }
            case WIN_STRESS: { return (ds.stress == null) ? "--" : (ds.stress as Number).format("%d"); }
            case WIN_DIGITAL: {
                var h = ds.hour;
                if (!is24) {
                    h = h % 12;
                    if (h == 0) {
                        h = 12;
                    }
                }
                return h.format("%02d") + ":" + ds.minute.format("%02d");
            }
            default: { return ""; }
        }
    }

    function clamp01(v as Float) as Float {
        if (v < 0.0) {
            return 0.0;
        }
        if (v > 1.0) {
            return 1.0;
        }
        return v;
    }

    //! Fill readout r for the given field from ds. Mutates in place; no allocation beyond the strings.
    function fill(r as Readout, field as Number, ds as DataSource, is24 as Boolean) as Void {
        r.field = field;
        r.hasValue = false;
        r.noHand = false;
        r.fraction = 0.0;
        r.label = "";
        r.text = "--";
        r.scale0 = "";
        r.scale1 = "";
        r.scale2 = "";

        switch (field) {
            case BODY_BATTERY: {
                r.label = "BODY";
                r.scale0 = "0"; r.scale1 = "50"; r.scale2 = "100";
                var v = ds.bodyBattery;
                if (v != null) {
                    r.hasValue = true;
                    r.fraction = clamp01(v / 100.0);
                    r.text = v.format("%d");
                }
                break;
            }
            case STEPS: {
                r.label = "STEPS";
                r.scale0 = "0"; r.scale1 = fmtK(ds.stepGoal / 2); r.scale2 = fmtK(ds.stepGoal);
                r.hasValue = true;
                r.fraction = clamp01(ds.steps.toFloat() / ds.stepGoal);
                r.text = fmtThousands(ds.steps);
                break;
            }
            case BATTERY: {
                r.label = "BATT";
                r.scale0 = "0"; r.scale1 = "50"; r.scale2 = "100";
                r.hasValue = true;
                r.fraction = clamp01(ds.battery / 100.0);
                r.text = ds.battery.format("%d") + "%";
                break;
            }
            case DATE: {
                r.label = ds.dayName;
                r.scale0 = "1"; r.scale1 = "16"; r.scale2 = "31";
                r.hasValue = true;
                r.fraction = clamp01((ds.day - 1) / 30.0);
                r.text = ds.day.format("%d");
                break;
            }
            case DIGITAL: {
                r.noHand = true;
                r.hasValue = true;
                var h = ds.hour;
                if (!is24) {
                    h = h % 12;
                    if (h == 0) {
                        h = 12;
                    }
                    r.label = (ds.hour < 12) ? "AM" : "PM";
                }
                r.text = h.format(is24 ? "%02d" : "%d") + ":" + ds.minute.format("%02d");
                break;
            }
            case HEART_RATE: {
                r.label = "BPM";
                r.scale0 = HR_MIN.format("%d"); r.scale1 = ((HR_MIN + HR_MAX) / 2).format("%d"); r.scale2 = HR_MAX.format("%d");
                var hr = ds.heartRate;
                if (hr != null) {
                    r.hasValue = true;
                    r.fraction = clamp01((hr - HR_MIN).toFloat() / (HR_MAX - HR_MIN));
                    r.text = hr.format("%d");
                }
                break;
            }
            case CALORIES: {
                r.label = "KCAL";
                r.scale0 = "0"; r.scale1 = fmtK(CALORIE_SCALE / 2); r.scale2 = fmtK(CALORIE_SCALE);
                r.hasValue = true;
                r.fraction = clamp01(ds.calories.toFloat() / CALORIE_SCALE);
                r.text = fmtThousands(ds.calories);
                break;
            }
            case FLOORS: {
                r.label = "FLOORS";
                r.scale0 = "0"; r.scale1 = (ds.floorGoal / 2).format("%d"); r.scale2 = ds.floorGoal.format("%d");
                r.hasValue = true;
                r.fraction = clamp01(ds.floors.toFloat() / ds.floorGoal);
                r.text = ds.floors.format("%d");
                break;
            }
            case STRESS: {
                r.label = "STRESS";
                r.scale0 = "0"; r.scale1 = "50"; r.scale2 = "100";
                var s = ds.stress;
                if (s != null && s >= 0) {
                    r.hasValue = true;
                    r.fraction = clamp01(s / 100.0);
                    r.text = s.format("%d");
                }
                break;
            }
            case MOON: {
                r.noHand = true;
                r.hasValue = true;
                break;
            }
            default: {
                r.noHand = true;
                break;
            }
        }
    }
}

//! One slot's displayable state. Reused every update.
class Readout {
    public var field as Number = Fields.NONE;
    public var hasValue as Boolean = false;
    public var noHand as Boolean = true;
    public var fraction as Float = 0.0;   // gauge position 0..1
    public var text as String = "--";
    public var label as String = "";
    public var scale0 as String = "";
    public var scale1 as String = "";
    public var scale2 as String = "";

    function initialize() {
    }
}

//! Cached sensor and clock values." comment to end of file) with:

//! Cached sensor and clock values. Slow sources refresh once a minute, heart rate every call.
//! Health values come from the system complications first (the number the native glance shows,
//! documented "or null" when there is no reading), then SensorHistory, then ActivityMonitor.
class DataSource {
    public var steps as Number = 0;
    public var stepGoal as Number = 10000;
    public var calories as Number = 0;
    public var floors as Number = 0;
    public var floorGoal as Number = 10;
    public var stress as Number? = null;
    public var bodyBattery as Number? = null;
    public var heartRate as Number? = null;
    public var battery as Number = 0;
    public var day as Number = 1;
    public var dayName as String = "MON";
    public var monthName as String = "JAN";
    public var monthNum as Number = 1;
    public var hour as Number = 0;
    public var minute as Number = 0;
    private var _minuteKey as Number = -1;
    private var _complicationAnswered as Boolean = false;

    function initialize() {
    }

    function refresh(force as Boolean) as Void {
        var ct = System.getClockTime();
        hour = ct.hour;
        minute = ct.min;

        heartRate = readHeartRate();

        var key = hour * 60 + minute;
        if (!force && key == _minuteKey) {
            return;
        }
        _minuteKey = key;

        var info = ActivityMonitor.getInfo();
        steps = nz(info.steps);
        stepGoal = nzd(info.stepGoal, 10000);
        calories = nz(info.calories);
        floors = nz(info.floorsClimbed);
        floorGoal = nzd(info.floorsClimbedGoal, 10);
        stress = readStress(info);
        bodyBattery = readBodyBattery();

        battery = (System.getSystemStats().battery + 0.5).toNumber();

        var g = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        day = g.day;
        dayName = (g.day_of_week as String).toUpper();
        monthName = (g.month as String).toUpper();
        monthNum = Gregorian.info(Time.now(), Time.FORMAT_SHORT).month as Number;
    }

    private function nz(v as Number?) as Number {
        return (v == null) ? 0 : v;
    }

    private function nzd(v as Number?, def as Number) as Number {
        return (v == null || v <= 0) ? def : v;
    }

    //! Body Battery 0-100, or null when the watch has no reading. A 0 is "no reading":
    //! the newest history slot can hold 0 before the firmware has filled it.
    private function readBodyBattery() as Number? {
        var v = complicationValue(Complications.COMPLICATION_TYPE_BODY_BATTERY);
        if (v == null && !_complicationAnswered
            && (Toybox has :SensorHistory) && (SensorHistory has :getBodyBatteryHistory)) {
            try {
                v = newestSample(SensorHistory.getBodyBatteryHistory({:period => 10, :order => SensorHistory.ORDER_NEWEST_FIRST}));
            } catch (e) {
                v = null;
            }
        }
        return (v == null || v <= 0) ? null : v;
    }

    //! Stress 0-100, or null when the watch has no reading.
    private function readStress(info as ActivityMonitor.Info) as Number? {
        var v = complicationValue(Complications.COMPLICATION_TYPE_STRESS);
        if (_complicationAnswered) {
            return v;
        }
        if ((Toybox has :SensorHistory) && (SensorHistory has :getStressHistory)) {
            try {
                v = newestSample(SensorHistory.getStressHistory({:period => 10, :order => SensorHistory.ORDER_NEWEST_FIRST}));
            } catch (e) {
                v = null;
            }
        }
        if (v == null && (info has :stressScore)) {
            v = info.stressScore;
        }
        return v;
    }

    //! Heart rate in bpm, or null when the watch has no reading. 0 bpm is not a reading.
    private function readHeartRate() as Number? {
        var hr = complicationValue(Complications.COMPLICATION_TYPE_HEART_RATE);
        if (hr == null) {
            var ai = Activity.getActivityInfo();
            if (ai != null) {
                hr = ai.currentHeartRate;
            }
        }
        if (hr == null && !_complicationAnswered
            && (Toybox has :SensorHistory) && (SensorHistory has :getHeartRateHistory)) {
            try {
                hr = newestSample(SensorHistory.getHeartRateHistory({:period => 5, :order => SensorHistory.ORDER_NEWEST_FIRST}));
            } catch (e) {
                hr = null;
            }
        }
        return (hr == null || hr <= 0) ? null : hr;
    }

    //! Current value of a system complication as a Number, or null when the watch has no reading.
    //! Sets _complicationAnswered when the system answered at all: an answer of null is final
    //! (the native glance shows "--") and must not be overridden by a stale history slot.
    //! Throws ComplicationNotFoundException where the type is not offered -> not answered.
    private function complicationValue(type as Complications.Type) as Number? {
        _complicationAnswered = false;
        if (!(Toybox has :Complications)) {
            return null;
        }
        try {
            var c = Complications.getComplication(new Complications.Id(type));
            _complicationAnswered = true;
            var v = c.value;
            if (v instanceof Number) {
                return v as Number;
            }
            if (v instanceof Float) {
                return ((v as Float) + 0.5).toNumber();
            }
            if (v instanceof Long) {
                return (v as Long).toNumber();
            }
            if (v instanceof Double) {
                return ((v as Double) + 0.5).toNumber();
            }
        } catch (e) {
            // ComplicationNotFoundException or any other failure: fall through to the next source
        }
        return null;
    }

    //! Newest non-null sample of one SensorHistory series, or null.
    //! :period is a count of entries (not seconds); newest first, empty slots skipped.
    private function newestSample(it as SensorHistory.SensorHistoryIterator?) as Number? {
        if (it == null) {
            return null;
        }
        var s = it.next();
        while (s != null) {
            var d = s.data;
            if (d != null) {
                return (d instanceof Float) ? ((d as Float) + 0.5).toNumber() : (d as Number);
            }
            s = it.next();
        }
        return null;
    }
}
