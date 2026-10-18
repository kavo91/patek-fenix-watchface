import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! Screen geometry, derived once from the device context (416 px reference, scaled).
class Layout {
    public var w as Number;
    public var h as Number;
    public var cx as Number;
    public var cy as Number;
    public var R as Number;
    public var s as Float;
    public var subR as Number;     // 3 / 9 o'clock sub-dial radius
    public var subLX as Number;
    public var subRX as Number;
    public var subY as Number;
    public var botR as Number;     // 6 o'clock sub-dial radius
    public var botX as Number;
    public var botY as Number;
    public var ringR as Number;    // 1-31 date track radius (about the 6 o'clock centre)
    public var winW as Number;
    public var winH as Number;
    public var winY as Number;
    public var winDX as Number;
    public var markerR as Number;
    public var numeralR as Number;

    function initialize(dc as Dc) {
        w = dc.getWidth();
        h = dc.getHeight();
        cx = w / 2;
        cy = h / 2;
        s = (w / 416.0) * BuildFlags.PROBE_SCALE;          // PROBE_SCALE is 1.0 in every real build
        R = (((w < h) ? w : h) / 2 * BuildFlags.PROBE_SCALE + 0.5).toNumber();
        subR = px(58);
        subLX = cx - px(97);
        subRX = cx + px(97);
        subY = cy;
        botR = px(54);
        botX = cx;
        botY = cy + px(94);
        ringR = px(66);
        winW = px(46);
        winH = px(24);
        winY = cy - px(116);
        winDX = px(27);
        markerR = px(166);
        numeralR = px(182);
    }

    function px(v as Number) as Number {
        return (v * s + 0.5).toNumber();
    }
}

//! Vector fonts sized for the layout, with system-font fallbacks.
class Fonts {
    public var track as FontType;
    public var win as FontType;
    public var lbl as FontType;
    public var val as FontType;
    public var digital as FontType;
    public var logo as FontType;
    public var mark as FontType;      // the initial inside the lozenge
    public var ring as VectorFont?;   // radial text needs a vector font

    function initialize(s as Float) {
        // Vector-font :size is the line box, not the cap height: caps ~= 0.607 x size (measured on the device).
        track = vf("RobotoCondensedBold", 16.0 * s, Graphics.FONT_XTINY);      // 10 px caps: minute numerals
        win = vf("RobotoCondensedBold", 19.0 * s, Graphics.FONT_TINY);         // 11.5 px caps: calendar windows
        lbl = vf("RobotoCondensedRegular", 15.0 * s, Graphics.FONT_XTINY);     // 9 px caps: gauge scale + labels
        val = vf("RobotoCondensedBold", 18.0 * s, Graphics.FONT_XTINY);        // 11 px caps: gauge value
        digital = vf("RobotoCondensedBold", 25.0 * s, Graphics.FONT_SMALL);    // 15 px caps: digital time
        logo = vf("RobotoMedium", 23.0 * s, Graphics.FONT_XTINY);              // 14 px caps: maker's mark
        mark = vf("RobotoMedium", 17.0 * s, Graphics.FONT_XTINY);              // 10 px caps: initial in the lozenge
        ring = null;
        if (Graphics has :getVectorFont) {
            ring = Graphics.getVectorFont({:face => ["RobotoCondensedBold"], :size => (18.0 * s).toNumber()});  // 11 px caps: date track
        }
    }

    private function vf(face as String, size as Float, fallback as FontDefinition) as FontType {
        if (Graphics has :getVectorFont) {
            var f = Graphics.getVectorFont({:face => [face], :size => size.toNumber()});
            if (f != null) {
                return f;
            }
        }
        return fallback;
    }
}

//! Everything that does not move: brushed dial, chapter ring, markers, sub-dial faces and scales,
//! window frames, moon aperture and date track. Rendered once into the offscreen buffer.
module Dial {
    const SWEEP = 270.0;        // gauge sweep in degrees, centred on 12
    const DATE_START = 40.0;    // day 1 sits 40 degrees clockwise of 12 on the 6 o'clock track
    const DATE_SPAN = 280.0;    // day 31 sits at 320 degrees

    function rad(degFrom12 as Float) as Float {
        return (degFrom12 * Math.PI / 180.0).toFloat();
    }

    function gaugeAngle(fraction as Float) as Float {
        return rad(-SWEEP / 2.0 + fraction * SWEEP);
    }

    function dateAngle(day as Number) as Float {
        return rad(DATE_START + (day - 1) * (DATE_SPAN / 30.0));
    }

    function render(dc as Dc, L as Layout, pal as Palette, fonts as Fonts,
                    left as Readout, right as Readout, bottom as Readout) as Void {
        var cx = L.cx;
        var cy = L.cy;
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }

        // brushed sunburst: base fill, then 360 fine rays in two close shades
        dc.setColor(pal.face, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, L.R + 1);
        dc.setPenWidth(1);
        var rayR = L.R + 2;
        for (var i = 0; i < 360; i++) {
            var m = (i * 7) % 5;
            if (m == 0 || m == 3) {
                continue;
            }
            dc.setColor((m == 2) ? pal.faceHi : pal.faceLo, Graphics.COLOR_TRANSPARENT);
            var a = i * Math.PI / 180.0;
            dc.drawLine(cx, cy, cx + rayR * Math.sin(a), cy - rayR * Math.cos(a));
        }

        // chapter ring band
        var band = L.px(14);
        dc.setPenWidth(band);
        dc.setColor(pal.rim, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(cx, cy, L.R - band / 2);
        dc.setPenWidth(1);
        dc.setColor(pal.inkSoft, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(cx, cy, L.R - band);

        // minute ticks (tall every 5) and quarter-minute ticks
        var rOut = L.R - 1;
        for (var q = 0; q < 240; q++) {
            var a = q * Math.PI / 120.0;
            var sn = Math.sin(a);
            var cs = Math.cos(a);
            var rIn;
            if (q % 20 == 0) {
                rIn = L.R - band;
                dc.setPenWidth(2);
                dc.setColor(pal.ink, Graphics.COLOR_TRANSPARENT);
            } else if (q % 4 == 0) {
                rIn = L.R - L.px(9);
                dc.setPenWidth(1);
                dc.setColor(pal.ink, Graphics.COLOR_TRANSPARENT);
            } else {
                rIn = L.R - L.px(5);
                dc.setPenWidth(1);
                dc.setColor(pal.inkSoft, Graphics.COLOR_TRANSPARENT);
            }
            dc.drawLine(cx + rIn * sn, cy - rIn * cs, cx + rOut * sn, cy - rOut * cs);
        }

        // minute numerals 5..60
        dc.setColor(pal.ink, Graphics.COLOR_TRANSPARENT);
        for (var n = 1; n <= 12; n++) {
            var a = n * Math.PI / 6.0;
            dc.drawText(cx + L.numeralR * Math.sin(a), cy - L.numeralR * Math.cos(a), fonts.track,
                        (n * 5).format("%d"), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        // hour markers: polished dots, double baton at 12, none at 6 (date track lives there)
        var dotR = L.px(5);
        var hiR = L.px(2);
        for (var hh = 1; hh <= 11; hh++) {
            if (hh == 6) {
                continue;
            }
            var a = hh * Math.PI / 6.0;
            var mx = cx + L.markerR * Math.sin(a);
            var my = cy - L.markerR * Math.cos(a);
            dc.setColor(pal.ink, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(mx, my, dotR);
            dc.setColor(pal.markerHi, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(mx - L.px(1), my - L.px(1), hiR);
        }
        var batW = L.px(3);
        var batTop = cy - L.markerR - L.px(5);
        var batH = L.px(18);
        dc.setColor(pal.ink, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(cx - L.px(5) - batW / 2, batTop, batW, batH);
        dc.fillRectangle(cx + L.px(5) - batW / 2, batTop, batW, batH);
        dc.setColor(pal.markerHi, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(cx - L.px(5) - batW / 2, batTop, 1, batH);
        dc.fillRectangle(cx + L.px(5) - batW / 2, batTop, 1, batH);

        // sub-dials
        subdialFace(dc, L, pal, fonts, L.subLX, L.subY, L.subR, left);
        subdialFace(dc, L, pal, fonts, L.subRX, L.subY, L.subR, right);
        subdialFace(dc, L, pal, fonts, L.botX, L.botY, L.botR, bottom);
        if (bottom.field == Fields.MOON) {
            moonAperture(dc, L, pal);
            dateTrack(dc, L, pal, fonts);
        }

        // 12 o'clock windows
        windowFrame(dc, L, pal, cx - L.winDX);
        windowFrame(dc, L, pal, cx + L.winDX);

        // maker's mark
        logo(dc, L, pal, fonts);
    }

    function subdialFace(dc as Dc, L as Layout, pal as Palette, fonts as Fonts,
                         x as Number, y as Number, r as Number, ro as Readout) as Void {
        dc.setColor(pal.subFace, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, r);
        // concentric grooves (azurage)
        dc.setPenWidth(1);
        var step = L.px(3);
        var k = 0;
        for (var rr = L.px(5); rr <= r - L.px(5); rr += step) {
            dc.setColor((k % 2 == 0) ? pal.subGrooveA : pal.subGrooveB, Graphics.COLOR_TRANSPARENT);
            dc.drawCircle(x, y, rr);
            k++;
        }
        // rim: fine line plus an inner shadow
        dc.setColor(pal.faceLo, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(x, y, r - 1);
        dc.setColor(pal.subRim, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(x, y, r);

        if (ro.noHand) {
            return;
        }
        // gauge scale: 10 divisions over 270 degrees, minor ticks between
        var majOut = r - L.px(5);
        var majIn = r - L.px(13);
        var minIn = r - L.px(9);
        for (var t = 0; t <= 30; t++) {
            var a = rad(-SWEEP / 2.0 + t * (SWEEP / 30.0));
            var sn = Math.sin(a);
            var cs = Math.cos(a);
            if (t % 3 == 0) {
                dc.setPenWidth(2);
                dc.setColor(pal.ink, Graphics.COLOR_TRANSPARENT);
                dc.drawLine(x + majIn * sn, y - majIn * cs, x + majOut * sn, y - majOut * cs);
            } else {
                dc.setPenWidth(1);
                dc.setColor(pal.inkSoft, Graphics.COLOR_TRANSPARENT);
                dc.drawLine(x + minIn * sn, y - minIn * cs, x + majOut * sn, y - majOut * cs);
            }
        }
        // min / max labels sit 15 degrees inside the scale ends so the terminal ticks never touch them
        var lr = r - L.px(22);
        dc.setColor(pal.ink, Graphics.COLOR_TRANSPARENT);
        scaleLabel(dc, x, y, lr, -SWEEP / 2.0 + 15.0, fonts.lbl, ro.scale0);
        scaleLabel(dc, x, y, lr, 0.0, fonts.lbl, ro.scale1);
        scaleLabel(dc, x, y, lr, SWEEP / 2.0 - 15.0, fonts.lbl, ro.scale2);
    }

    function scaleLabel(dc as Dc, x as Number, y as Number, r as Number, deg as Float, font as FontType, text as String) as Void {
        var a = rad(deg);
        dc.drawText(x + r * Math.sin(a), y - r * Math.cos(a), font, text,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    //! Classic double-hump moon aperture in the upper half of the 6 o'clock sub-dial.
    function moonAperture(dc as Dc, L as Layout, pal as Palette) as Void {
        var x = L.botX;
        var y = L.botY;
        var ar = L.botR - L.px(12);       // aperture radius
        var chord = L.px(14);             // flat edge sits this far below the centre
        var edgeDeg = (Math.asin(chord.toFloat() / ar) * 180.0 / Math.PI).toNumber();
        var halfChord = (ar * Math.cos(edgeDeg * Math.PI / 180.0)).toNumber();
        var hillR = L.px(16);
        var hillDX = L.px(18);
        var hillY = y + L.px(22);
        // everything below the chord stays untouched azurage: the clip holds for the sky, the hills and their edges
        dc.setClip(x - ar - 1, y - ar - 1, 2 * ar + 3, ar + chord + 1);
        dc.setColor(pal.sky, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, ar);
        dc.setPenWidth(1);
        dc.setColor(pal.subRim, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(x - halfChord, y + chord, x + halfChord, y + chord);
        // the two hills carve up into the sky
        dc.setColor(pal.subFace, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x - hillDX, hillY, hillR);
        dc.fillCircle(x + hillDX, hillY, hillR);
        dc.setColor(pal.subRim, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(x - hillDX, hillY, hillR, Graphics.ARC_COUNTER_CLOCKWISE, 20, 160);
        dc.drawArc(x + hillDX, hillY, hillR, Graphics.ARC_COUNTER_CLOCKWISE, 20, 160);
        dc.clearClip();
        // aperture edge
        dc.drawArc(x, y, ar, Graphics.ARC_COUNTER_CLOCKWISE, -edgeDeg, 180 + edgeDeg);
        // fixed stars
        dc.setColor(pal.star, Graphics.COLOR_TRANSPARENT);
        var sr = L.px(1);
        dc.fillCircle(x - L.px(24), y - L.px(12), sr);
        dc.fillCircle(x - L.px(17), y - L.px(26), sr);
        dc.fillCircle(x + L.px(22), y - L.px(24), sr);
        dc.fillCircle(x + L.px(27), y - L.px(8), sr);
        dc.fillCircle(x + L.px(8), y - L.px(31), sr);
    }

    //! 1-31 around the 6 o'clock sub-dial: odd numerals (upright), dots for even days.
    function dateTrack(dc as Dc, L as Layout, pal as Palette, fonts as Fonts) as Void {
        var x = L.botX;
        var y = L.botY;
        var r = L.ringR;
        dc.setColor(pal.ink, Graphics.COLOR_TRANSPARENT);
        var dotR = L.px(2);
        for (var d = 1; d <= 31; d++) {
            var deg = DATE_START + (d - 1) * (DATE_SPAN / 30.0);
            if (d % 2 == 0) {
                var a = rad(deg);
                dc.fillCircle(x + r * Math.sin(a), y - r * Math.cos(a), dotR);
                continue;
            }
            // upright to the wearer: radial text flips its orientation at 3 and 9 and neighbours then read as
            // different digits (a flipped 7 is an L, a flipped 9 a 6)
            var a = rad(deg);
            var ring = fonts.ring;
            dc.drawText(x + r * Math.sin(a), y - r * Math.cos(a), (ring != null) ? ring : fonts.lbl, d.format("%d"),
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    //! Maker's mark: a poincon. Silver carries its maker's mark struck inside a lozenge, so the initial
    //! sits in a hairline lozenge over a letter-spaced FENIX. Everything hangs off the dial's own grid:
    //! the lozenge is exactly one calendar window wide, its tip sits in the notch between the two
    //! windows, and the wordmark is centred under it with a 7 px track (it would be justified to the
    //! windows' outer edges if the letters filled that span). The initial is the wordmark's own glyph,
    //! so it resolves exactly as well as the name does.
    //! At 416 px: lozenge x 188..228, y 110..128; wordmark caps y 134..148.
    function logo(dc as Dc, L as Layout, pal as Palette, fonts as Fonts) as Void {
        var cx = L.cx;
        var font = fonts.logo;
        var hw = L.px(20);                                // 40 px wide: narrower than a window so it is not a third aperture
        var hh = L.px(9);                                 // 18 px tall
        var ey = L.winY + L.winH / 2 + L.px(6) + hh;      // tip 6 px under the windows -> centre y 119
        var yWord = L.subY - L.subR - L.px(9);            // 141: cap centre, 9 px above the sub-dial tops
        var span = L.winW + 2 * L.winDX;                  // 100: outer edge to outer edge of the windows

        // hallmark lozenge: a crisp one-pixel hairline in full print ink (anti-aliased, the diagonal
        // spreads over two half-tone pixels and reads as a grey ghost on the silver face)
        if (dc has :setAntiAlias) {
            dc.setAntiAlias(false);
        }
        dc.setPenWidth(1);
        dc.setColor(pal.ink, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(cx, ey - hh, cx + hw, ey);
        dc.drawLine(cx + hw, ey, cx, ey + hh);
        dc.drawLine(cx, ey + hh, cx - hw, ey);
        dc.drawLine(cx - hw, ey, cx, ey - hh);
        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }

        // the initial, in its own smaller size so it clears both tips
        dc.drawText(cx, ey, fonts.mark, "F", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // wordmark: measured glyph by glyph; gaps spread to the window span, capped at 7 px and centred
        var word = ["F", "E", "N", "I", "X"] as Array<String>;
        var n = word.size();
        var widths = new Array<Number>[n];
        var total = 0;
        for (var i = 0; i < n; i++) {
            widths[i] = dc.getTextWidthInPixels(word[i], font);
            total += widths[i];
        }
        var track = (span - total).toFloat() / (n - 1);
        var maxTrack = L.px(7).toFloat();
        if (track > maxTrack) {
            track = maxTrack;
        }
        var x = cx - (total + track * (n - 1)) / 2.0;
        for (var i = 0; i < n; i++) {
            dc.drawText((x + 0.5).toNumber(), yWord, font, word[i],
                        Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            x += widths[i] + track;
        }
    }

    function windowFrame(dc as Dc, L as Layout, pal as Palette, x as Number) as Void {
        var w = L.winW;
        var h = L.winH;
        var left = x - w / 2;
        var top = L.winY - h / 2;
        dc.setColor(pal.winFrame, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(left, top, w, h, L.px(3));
        dc.setColor(pal.winDisc, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(left + 2, top + 2, w - 4, h - 4, L.px(2));
    }
}
