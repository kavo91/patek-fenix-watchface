import Toybox.Lang;
import Toybox.Math;
import Toybox.Test;

// Run inside the simulator: ./run-tests.sh  (monkeydo <prg> fenix9pro43mm -t)

function near(a as Float, b as Float, eps as Float) as Boolean {
    return (a - b).abs() < eps;
}

(:test)
function moonAnchorIsNew(logger as Logger) as Boolean {
    var p = Moon.phase(Moon.REF_NEW_MOON);
    Test.assertMessage(p < 0.001 || p > 0.999, "anchor phase " + p);
    return true;
}

(:test)
function moonHalfCycleIsFull(logger as Logger) as Boolean {
    var p = Moon.phase(Moon.REF_NEW_MOON + 1275721);   // 14.7653 days
    Test.assertMessage(near(p, 0.5, 0.002), "half cycle phase " + p);
    return true;
}

(:test)
function moonBeforeAnchorWraps(logger as Logger) as Boolean {
    var p = Moon.phase(Moon.REF_NEW_MOON - 7 * 86400);
    Test.assertMessage(near(p, 1.0 - 7.0 / 29.530588853, 0.002), "wrapped phase " + p);
    return true;
}

(:test)
function thousandsFormat(logger as Logger) as Boolean {
    Test.assertEqual("6,540", Fields.fmtThousands(6540));
    Test.assertEqual("999", Fields.fmtThousands(999));
    Test.assertEqual("12,005", Fields.fmtThousands(12005));
    Test.assertEqual("0", Fields.fmtThousands(0));
    return true;
}

(:test)
function shortAndKFormats(logger as Logger) as Boolean {
    Test.assertEqual("9999", Fields.fmtShort(9999));
    Test.assertEqual("12.3k", Fields.fmtShort(12345));
    Test.assertEqual("10k", Fields.fmtK(10000));
    Test.assertEqual("7.5k", Fields.fmtK(7500));
    Test.assertEqual("500", Fields.fmtK(500));
    return true;
}

(:test)
function hourWindowWraps(logger as Logger) as Boolean {
    Test.assertMessage(Theme.hourInWindow(12, 7, 19), "noon is day");
    Test.assertMessage(!Theme.hourInWindow(19, 7, 19), "end hour is night");
    Test.assertMessage(!Theme.hourInWindow(3, 7, 19), "3am is night");
    Test.assertMessage(Theme.hourInWindow(23, 20, 6), "wrapped window covers 23");
    Test.assertMessage(Theme.hourInWindow(2, 20, 6), "wrapped window covers 2");
    Test.assertMessage(!Theme.hourInWindow(12, 20, 6), "wrapped window excludes noon");
    return true;
}

(:test)
function gaugeAndDateAngles(logger as Logger) as Boolean {
    var d2r = Math.PI / 180.0;
    Test.assertMessage(near(Dial.gaugeAngle(0.0), (-135.0 * d2r).toFloat(), 0.0001), "gauge 0");
    Test.assertMessage(near(Dial.gaugeAngle(0.5), 0.0, 0.0001), "gauge mid");
    Test.assertMessage(near(Dial.gaugeAngle(1.0), (135.0 * d2r).toFloat(), 0.0001), "gauge full");
    Test.assertMessage(near(Dial.dateAngle(1), (40.0 * d2r).toFloat(), 0.0001), "day 1");
    Test.assertMessage(near(Dial.dateAngle(16), (180.0 * d2r).toFloat(), 0.0001), "day 16 at 6 o'clock");
    Test.assertMessage(near(Dial.dateAngle(31), (320.0 * d2r).toFloat(), 0.0001), "day 31");
    return true;
}

(:test)
function aodOffsetsMoveEveryMinute(logger as Logger) as Boolean {
    var n = Aod.OFFSETS.size();
    for (var i = 0; i < n; i++) {
        var a = Aod.OFFSETS[i];
        var b = Aod.OFFSETS[(i + 1) % n];
        var shift = (a[0] - b[0]).abs() + (a[1] - b[1]).abs();
        Test.assertMessage(shift >= 3, "consecutive AOD offsets must move at least 3 px");
    }
    return true;
}

(:test)
function readoutSteps(logger as Logger) as Boolean {
    var ds = new DataSource();
    ds.steps = 6540;
    ds.stepGoal = 10000;
    var r = new Readout();
    Fields.fill(r, Fields.STEPS, ds, true);
    Test.assertMessage(r.hasValue && !r.noHand, "steps has a hand");
    Test.assertMessage(near(r.fraction, 0.654, 0.001), "fraction " + r.fraction);
    Test.assertEqual("6,540", r.text);
    Test.assertEqual("5k", r.scale1);
    Test.assertEqual("10k", r.scale2);
    ds.steps = 25000;
    Fields.fill(r, Fields.STEPS, ds, true);
    Test.assertMessage(r.fraction == 1.0, "fraction clamps at goal");
    return true;
}

(:test)
function windowTexts(logger as Logger) as Boolean {
    var ds = new DataSource();
    ds.day = 11;
    ds.monthNum = 9;
    ds.monthName = "SEP";
    ds.dayName = "FRI";
    ds.battery = 85;
    ds.hour = 20;
    ds.minute = 5;
    ds.bodyBattery = null;
    Test.assertEqual("11/09", Fields.windowText(Fields.WIN_DAY_MONTH, ds, true));
    Test.assertEqual("09/11", Fields.windowText(Fields.WIN_MONTH_DAY, ds, true));
    Test.assertEqual("85%", Fields.windowText(Fields.WIN_BATTERY, ds, true));
    Test.assertEqual("FRI", Fields.windowText(Fields.WIN_WEEKDAY, ds, true));
    Test.assertEqual("SEP", Fields.windowText(Fields.WIN_MONTH, ds, true));
    Test.assertEqual("--", Fields.windowText(Fields.WIN_BODY_BATTERY, ds, true));
    Test.assertEqual("20:05", Fields.windowText(Fields.WIN_DIGITAL, ds, true));
    Test.assertEqual("08:05", Fields.windowText(Fields.WIN_DIGITAL, ds, false));
    Test.assertEqual("", Fields.windowText(Fields.WIN_EMPTY, ds, true));
    return true;
}

(:test)
function readoutDigitalAndMissing(logger as Logger) as Boolean {
    var ds = new DataSource();
    ds.hour = 21;
    ds.minute = 5;
    var r = new Readout();
    Fields.fill(r, Fields.DIGITAL, ds, true);
    Test.assertEqual("21:05", r.text);
    Test.assertMessage(r.noHand, "digital has no hand");
    Fields.fill(r, Fields.DIGITAL, ds, false);
    Test.assertEqual("9:05", r.text);
    Test.assertEqual("PM", r.label);
    ds.heartRate = null;
    Fields.fill(r, Fields.HEART_RATE, ds, true);
    Test.assertMessage(!r.hasValue, "missing HR has no value");
    Test.assertEqual("--", r.text);
    ds.heartRate = 110;
    Fields.fill(r, Fields.HEART_RATE, ds, true);
    Test.assertMessage(near(r.fraction, 0.5, 0.001), "110 bpm is mid-scale");
    return true;
}
