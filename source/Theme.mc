import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Weather;

//! Colour palette for one mode. Light = silver-dominant with black print; dark = black-dominant with silver print.
class Palette {
    public var isDark as Boolean;
    public var face as Number;        // dial base
    public var faceHi as Number;      // brushed ray, lighter
    public var faceLo as Number;      // brushed ray, darker
    public var rim as Number;         // outer chapter-ring band
    public var ink as Number;         // primary print: ticks, numerals, markers
    public var inkSoft as Number;     // minor ticks, scale minor marks
    public var markerHi as Number;    // polished highlight on hour markers
    public var subFace as Number;     // sub-dial ground
    public var subGrooveA as Number;  // concentric grooves
    public var subGrooveB as Number;
    public var subRim as Number;      // sub-dial rim line
    public var winFrame as Number;    // 12 o'clock window frames
    public var winDisc as Number;     // window disc
    public var winText as Number;
    public var handBody as Number;
    public var handEdge as Number;
    public var lume as Number;        // luminous inserts
    public var secondHand as Number;
    public var arbor as Number;
    public var sky as Number;         // moon aperture ground
    public var moon as Number;
    public var moonShade as Number;   // unlit part of the moon
    public var star as Number;

    function initialize(dark as Boolean) {
        isDark = dark;
        if (dark) {
            face = 0x0B0B0C; faceHi = 0x111214; faceLo = 0x070708; rim = 0x111214;
            ink = 0xC8CBD0; inkSoft = 0x6F7379; markerHi = 0xF4F5F7;
            subFace = 0x131518; subGrooveA = 0x17191D; subGrooveB = 0x101113; subRim = 0x8A8E94;
            winFrame = 0xB9BDC2; winDisc = 0x1A1C1F; winText = 0xE3E5E8;
            handBody = 0xD6D9DD; handEdge = 0x6E7278; lume = 0xCFE8B8; secondHand = 0xC8CBD0; arbor = 0xE3E5E8;
            sky = 0x1E2126; moon = 0xE8EAEC; moonShade = 0x4A5058; star = 0xB9BDC2;
        } else {
            face = 0xC7CACF; faceHi = 0xCED1D5; faceLo = 0xC0C3C8; rim = 0xB2B6BB;
            ink = 0x141517; inkSoft = 0x4A4D52; markerHi = 0x63676D;
            subFace = 0xB9BDC2; subGrooveA = 0xBFC3C8; subGrooveB = 0xB3B7BC; subRim = 0x2A2C30;
            winFrame = 0x141517; winDisc = 0xF1F2F3; winText = 0x141517;
            handBody = 0x141517; handEdge = 0x3A3D42; lume = 0xE6EED2; secondHand = 0x141517; arbor = 0x2A2C30;
            sky = 0x2A2E34; moon = 0xE8EAEC; moonShade = 0x5A6069; star = 0xD0D3D7;
        }
    }
}

//! Decides light vs dark. Manual override wins; auto follows sunrise/sunset when the watch knows them,
//! otherwise the configured day window.
module Theme {
    var _sunDayKey as Number = -1;
    var _sunrise as Time.Moment? = null;
    var _sunset as Time.Moment? = null;

    //! True when hour lies inside [start, end), wrapping past midnight when start > end.
    function hourInWindow(hour as Number, start as Number, end as Number) as Boolean {
        if (start == end) {
            return true;
        }
        if (start < end) {
            return hour >= start && hour < end;
        }
        return hour >= start || hour < end;
    }

    function isDark(cfg as Config) as Boolean {
        if (cfg.themeMode == 1) {
            return false;
        }
        if (cfg.themeMode == 2) {
            return true;
        }
        var now = Time.now();
        if (cfg.autoBySun) {
            refreshSun(now);
            var rise = _sunrise;
            var set = _sunset;
            if (rise != null && set != null) {
                var day = now.greaterThan(rise) && now.lessThan(set);
                return !day;
            }
        }
        var ct = System.getClockTime();
        return !hourInWindow(ct.hour, cfg.dayStartHour, cfg.dayEndHour);
    }

    //! Cache today's sunrise/sunset from the weather service (one lookup per day).
    function refreshSun(now as Time.Moment) as Void {
        if (!(Toybox has :Weather) || !(Weather has :getSunrise)) {
            return;
        }
        var key = now.value() / 86400;
        if (key == _sunDayKey) {
            return;
        }
        try {
            var cc = Weather.getCurrentConditions();
            if (cc == null) {
                return;
            }
            var loc = cc.observationLocationPosition;
            if (loc == null) {
                return;
            }
            var rise = Weather.getSunrise(loc, now);
            var set = Weather.getSunset(loc, now);
            if (rise != null && set != null) {
                _sunrise = rise;
                _sunset = set;
                _sunDayKey = key;
            }
        } catch (e) {
            // weather unavailable: fall back to the hour window
        }
    }
}
