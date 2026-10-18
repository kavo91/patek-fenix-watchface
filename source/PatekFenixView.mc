import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;

//! Always-on (AMOLED) rendering constants. The whole low-power drawing shifts through these offsets,
//! one per minute, so no pixel stays lit for more than one update cycle (rule: max three).
module Aod {
    var OFFSETS as Array<Array<Number>> = [[0, 0], [3, 0], [3, 3], [0, 3]];
    const INK = 0x9A9EA4;
    const INK_DIM = 0x6A6E74;
}

class PatekFenixView extends WatchUi.WatchFace {
    private var _cfg as Config;
    private var _pal as Palette;
    private var _ds as DataSource;
    private var _L as Layout?;
    private var _fonts as Fonts?;
    private var _dial as BufferedBitmap?;    // static dial, re-rendered only when theme/slots/goals change
    private var _frame as BufferedBitmap?;   // whole face minus seconds; only on partial-update (MIP) devices
    private var _readL as Readout;
    private var _readR as Readout;
    private var _readB as Readout;
    private var _winL as String = "";
    private var _winR as String = "";
    private var _sleeping as Boolean = false;
    private var _burnIn as Boolean = false;
    private var _partialOk as Boolean = false;
    private var _dialSigA as Number = -1;
    private var _dialSigB as Number = -1;
    private var _hourPts as Array<Array<Numeric>>;
    private var _hourLumePts as Array<Array<Numeric>>;
    private var _minPts as Array<Array<Numeric>>;
    private var _minLumePts as Array<Array<Numeric>>;
    private var _secPts as Array<Array<Numeric>>;
    private var _subPts as Array<Array<Numeric>>;
    private var _lastClip as Array<Number>? = null;

    function initialize() {
        WatchFace.initialize();
        _cfg = new Config();
        _pal = new Palette(false);
        _ds = new DataSource();
        _readL = new Readout();
        _readR = new Readout();
        _readB = new Readout();
        _hourPts = Hands.points(5);
        _hourLumePts = Hands.points(5);
        _minPts = Hands.points(5);
        _minLumePts = Hands.points(5);
        _secPts = Hands.points(4);
        _subPts = Hands.points(5);
        var ds = System.getDeviceSettings();
        _burnIn = (ds has :requiresBurnInProtection) ? ds.requiresBurnInProtection : false;
        _partialOk = (WatchUi.WatchFace has :onPartialUpdate) && !_burnIn;
    }

    function onLayout(dc as Dc) as Void {
        var L = new Layout(dc);
        _L = L;
        _fonts = new Fonts(L.s);
        _dial = null;
        _frame = null;
        if (Graphics has :createBufferedBitmap) {
            _dial = Graphics.createBufferedBitmap({:width => L.w, :height => L.h}).get() as BufferedBitmap;
            if (_partialOk) {
                _frame = Graphics.createBufferedBitmap({:width => L.w, :height => L.h}).get() as BufferedBitmap;
            }
        }
        _dialSigA = -1;
    }

    function reloadSettings() as Void {
        _cfg.load();
        _dialSigA = -1;
        _ds.refresh(true);
    }

    function onEnterSleep() as Void {
        _sleeping = true;
        WatchUi.requestUpdate();
    }

    function onExitSleep() as Void {
        _sleeping = false;
        WatchUi.requestUpdate();
    }

    function turnPartialUpdatesOff() as Void {
        _partialOk = false;
    }

    function onUpdate(dc as Dc) as Void {
        if (_L == null) {
            onLayout(dc);
        }
        var L = _L as Layout;
        var ct = System.getClockTime();
        _ds.refresh(false);

        var dark = Theme.isDark(_cfg);
        if (dark != _pal.isDark) {
            _pal = new Palette(dark);
        }
        dc.clearClip();

        if ((_sleeping && _burnIn) || BuildFlags.FORCE_AOD) {
            drawAod(dc, L, ct);
            return;
        }

        var is24 = System.getDeviceSettings().is24Hour;
        Fields.fill(_readL, _cfg.slotLeft, _ds, is24);
        Fields.fill(_readR, _cfg.slotRight, _ds, is24);
        Fields.fill(_readB, _cfg.slotBottom, _ds, is24);
        _winL = Fields.windowText(_cfg.winLeft, _ds, is24);
        _winR = Fields.windowText(_cfg.winRight, _ds, is24);
        ensureDial();

        var target = dc;
        var frame = _frame;
        if (_partialOk && frame != null) {
            target = frame.getDc();
        }
        drawFace(target, L, ct);
        if (target != dc && frame != null) {
            dc.drawBitmap(0, 0, frame);
        }
        _lastClip = null;
        if (!_sleeping && _cfg.showSeconds) {
            if (dc has :setAntiAlias) {
                dc.setAntiAlias(true);
            }
            drawSeconds(dc, L, ct.sec);
        }
    }

    //! Once-a-second seconds hand on MIP devices: restore the frame under the old hand, draw the new one.
    function onPartialUpdate(dc as Dc) as Void {
        var frame = _frame;
        var L = _L;
        if (!_partialOk || frame == null || L == null || !_cfg.showSeconds) {
            return;
        }
        var ct = System.getClockTime();
        var a = Dial.rad(ct.sec * 6.0);
        Hands.transform(Hands.SECOND, _secPts, L.cx, L.cy, a, L.s);
        var box = boundingBox(_secPts, L.px(8));
        var last = _lastClip;
        if (last != null) {
            var x0 = (last[0] < box[0]) ? last[0] : box[0];
            var y0 = (last[1] < box[1]) ? last[1] : box[1];
            var x1 = ((last[0] + last[2]) > (box[0] + box[2])) ? (last[0] + last[2]) : (box[0] + box[2]);
            var y1 = ((last[1] + last[3]) > (box[1] + box[3])) ? (last[1] + last[3]) : (box[1] + box[3]);
            box = [x0, y0, x1 - x0, y1 - y0];
        }
        dc.setClip(box[0], box[1], box[2], box[3]);
        dc.drawBitmap(0, 0, frame);
        drawSeconds(dc, L, ct.sec);
        _lastClip = box;
    }

    private function boundingBox(pts as Array<Array<Numeric>>, pad as Number) as Array<Number> {
        var minX = 99999.0;
        var minY = 99999.0;
        var maxX = -99999.0;
        var maxY = -99999.0;
        for (var i = 0; i < pts.size(); i++) {
            var p = pts[i];
            if (p[0] < minX) { minX = p[0]; }
            if (p[1] < minY) { minY = p[1]; }
            if (p[0] > maxX) { maxX = p[0]; }
            if (p[1] > maxY) { maxY = p[1]; }
        }
        var x = (minX - pad).toNumber();
        var y = (minY - pad).toNumber();
        return [x, y, (maxX + pad).toNumber() - x + 1, (maxY + pad).toNumber() - y + 1];
    }

    //! Re-render the static dial when anything it depends on changed.
    private function ensureDial() as Void {
        var sigA = (_pal.isDark ? 1 : 0) + (_cfg.slotLeft * 2) + (_cfg.slotRight * 64) + (_cfg.slotBottom * 2048);
        var sigB = _ds.stepGoal * 100 + _ds.floorGoal;
        var dial = _dial;
        if (dial == null) {
            return;
        }
        if (sigA == _dialSigA && sigB == _dialSigB) {
            return;
        }
        Dial.render(dial.getDc(), _L as Layout, _pal, _fonts as Fonts, _readL, _readR, _readB);
        _dialSigA = sigA;
        _dialSigB = sigB;
    }

    private function drawFace(dc as Dc, L as Layout, ct as System.ClockTime) as Void {
        var dial = _dial;
        if (dial != null) {
            dc.drawBitmap(0, 0, dial);
        } else {
            Dial.render(dc, L, _pal, _fonts as Fonts, _readL, _readR, _readB);
        }
        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }
        drawWindows(dc, L);
        drawSubdial(dc, L, L.subLX, L.subY, L.subR, _readL);
        drawSubdial(dc, L, L.subRX, L.subY, L.subR, _readR);
        if (_readB.field == Fields.MOON) {
            drawMoonAndDate(dc, L);
        } else {
            drawSubdial(dc, L, L.botX, L.botY, L.botR, _readB);
        }
        drawMainHands(dc, L, ct);
    }

    private function drawWindows(dc as Dc, L as Layout) as Void {
        var f = _fonts as Fonts;
        dc.setColor(_pal.winText, Graphics.COLOR_TRANSPARENT);
        var j = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        dc.drawText(L.cx - L.winDX, L.winY, f.win, _winL, j);
        dc.drawText(L.cx + L.winDX, L.winY, f.win, _winR, j);
    }

    private function drawSubdial(dc as Dc, L as Layout, x as Number, y as Number, r as Number, ro as Readout) as Void {
        if (ro.field == Fields.NONE) {
            return;
        }
        var f = _fonts as Fonts;
        var pal = _pal;
        var j = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        dc.setColor(pal.ink, Graphics.COLOR_TRANSPARENT);
        if (ro.field == Fields.DIGITAL) {
            dc.drawText(x, y - L.px(3), f.digital, ro.text, j);
            if (!ro.label.equals("")) {
                dc.drawText(x, y + L.px(16), f.lbl, ro.label, j);
            }
            return;
        }
        // value in the bottom gap of the sweep, its name printed under it (the needle never enters that
        // quadrant, and the min/max scale labels sit a clear row above the value)
        dc.drawText(x, y + (r * 0.60).toNumber(), f.val, ro.text, j);
        dc.drawText(x, y + (r * 0.80).toNumber(), f.lbl, ro.label, j);

        var a = Dial.gaugeAngle(ro.fraction);
        Hands.transform(Hands.SUB, _subPts, x, y, a, r / 58.0);
        drawSmallHand(dc, L, x, y);
    }

    private function drawSmallHand(dc as Dc, L as Layout, x as Number, y as Number) as Void {
        var pal = _pal;
        dc.setColor(pal.handBody, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(_subPts as Array<Point2D>);
        dc.setPenWidth(1);
        dc.setColor(pal.handEdge, Graphics.COLOR_TRANSPARENT);
        Hands.outline(dc, _subPts);
        dc.setColor(pal.handBody, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, L.px(3));
        dc.setColor(pal.lume, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, 1);
    }

    private function drawMoonAndDate(dc as Dc, L as Layout) as Void {
        var x = L.botX;
        var y = L.botY;
        var p = Moon.phase(Time.now().value());
        Moon.draw(dc, x, y - L.px(9), L.px(16), p, _cfg.moonSouth, _pal.moon, _pal.moonShade);
        // the day as a numeral too, so the date reads at a glance without following the pointer
        dc.setColor(_pal.ink, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y + L.px(38), (_fonts as Fonts).val, _ds.day.format("%d"),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        var a = Dial.dateAngle(_ds.day);
        Hands.transform(Hands.DATE, _subPts, x, y, a, L.botR / 54.0);
        drawSmallHand(dc, L, x, y);
    }

    private function drawMainHands(dc as Dc, L as Layout, ct as System.ClockTime) as Void {
        var pal = _pal;
        var hourA = Dial.rad((ct.hour % 12) * 30.0 + ct.min * 0.5);
        var minA = Dial.rad(ct.min * 6.0 + ct.sec * 0.1);
        Hands.transform(Hands.HOUR, _hourPts, L.cx, L.cy, hourA, L.s);
        Hands.transform(Hands.HOUR_LUME, _hourLumePts, L.cx, L.cy, hourA, L.s);
        Hands.transform(Hands.MINUTE, _minPts, L.cx, L.cy, minA, L.s);
        Hands.transform(Hands.MINUTE_LUME, _minLumePts, L.cx, L.cy, minA, L.s);
        Hands.drawLumed(dc, _hourPts, _hourLumePts, pal);
        Hands.drawLumed(dc, _minPts, _minLumePts, pal);
        // arbor
        dc.setColor(pal.handBody, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(L.cx, L.cy, L.px(7));
        dc.setPenWidth(1);
        dc.setColor(pal.handEdge, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(L.cx, L.cy, L.px(7));
        dc.setColor(pal.lume, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(L.cx, L.cy, L.px(2));
    }

    private function drawSeconds(dc as Dc, L as Layout, sec as Number) as Void {
        var pal = _pal;
        var a = Dial.rad(sec * 6.0);
        Hands.transform(Hands.SECOND, _secPts, L.cx, L.cy, a, L.s);
        dc.setColor(pal.secondHand, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(_secPts as Array<Point2D>);
        // counterweight on the tail
        var tail = L.px(30);
        dc.fillCircle(L.cx - tail * Math.sin(a), L.cy + tail * Math.cos(a), L.px(5));
        dc.fillCircle(L.cx, L.cy, L.px(3));
    }

    //! Always-on display: black ground, thin outline hands, twelve pin-point markers.
    private function drawAod(dc as Dc, L as Layout, ct as System.ClockTime) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        if (dc has :setAntiAlias) {
            dc.setAntiAlias(false);
        }
        var off = Aod.OFFSETS[ct.min % 4];
        var ox = L.cx + off[0];
        var oy = L.cy + off[1];

        dc.setColor(Aod.INK_DIM, Graphics.COLOR_TRANSPARENT);
        for (var hh = 0; hh < 12; hh++) {
            var a = hh * Math.PI / 6.0;
            dc.fillRectangle((ox + L.markerR * Math.sin(a) - 1).toNumber(), (oy - L.markerR * Math.cos(a) - 1).toNumber(), 2, 2);
        }

        var hourA = Dial.rad((ct.hour % 12) * 30.0 + ct.min * 0.5);
        var minA = Dial.rad(ct.min * 6.0);
        Hands.transform(Hands.HOUR, _hourPts, ox, oy, hourA, L.s);
        Hands.transform(Hands.MINUTE, _minPts, ox, oy, minA, L.s);
        dc.setPenWidth(2);
        dc.setColor(Aod.INK, Graphics.COLOR_TRANSPARENT);
        Hands.outline(dc, _hourPts);
        Hands.outline(dc, _minPts);
        dc.setPenWidth(1);
        dc.drawCircle(ox, oy, L.px(5));
    }
}

//! Receives the power-budget callback for partial updates.
class PatekFenixDelegate extends WatchUi.WatchFaceDelegate {
    private var _view as PatekFenixView;

    function initialize(view as PatekFenixView) {
        WatchFaceDelegate.initialize();
        _view = view;
    }

    function onPowerBudgetExceeded(powerInfo as WatchUi.WatchFacePowerInfo) as Void {
        _view.turnPartialUpdatesOff();
    }
}
