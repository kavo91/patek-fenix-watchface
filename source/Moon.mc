import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! Moon phase from the mean synodic month. Good to a few hours, which is all a dial needs.
module Moon {
    const SYNODIC_DAYS = 29.530588853;
    const REF_NEW_MOON = 947182440;   // 2000-01-06 18:14 UTC, unix seconds

    //! 0.0 = new, 0.25 = first quarter, 0.5 = full, 0.75 = last quarter.
    function phase(epochSeconds as Number) as Float {
        var days = (epochSeconds - REF_NEW_MOON) / 86400.0;
        var cycles = days / SYNODIC_DAYS;
        var p = cycles - Math.floor(cycles);
        if (p < 0) {
            p += 1.0;
        }
        return p.toFloat();
    }

    //! Draw the moon disc. Waxing lit limb is on the right in the north, mirrored in the south.
    function draw(dc as Dc, cx as Number, cy as Number, r as Number, p as Float, south as Boolean,
                  moonColor as Number, shadeColor as Number) as Void {
        dc.setColor(moonColor, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, r);

        var waxing = p < 0.5;
        var shadeRight = (waxing == south);
        dc.setColor(shadeColor, Graphics.COLOR_TRANSPARENT);
        if (shadeRight) {
            dc.setClip(cx, cy - r - 1, r + 2, 2 * r + 3);
        } else {
            dc.setClip(cx - r - 1, cy - r - 1, r + 2, 2 * r + 3);
        }
        dc.fillCircle(cx, cy, r);
        dc.clearClip();

        // terminator: an ellipse whose half-width follows cos(phase)
        var k = Math.cos(2.0 * Math.PI * p);
        var w = (k.abs() * r + 0.5).toNumber();
        if (w >= 1) {
            var crescent = (p < 0.25) || (p > 0.75);
            dc.setColor(crescent ? shadeColor : moonColor, Graphics.COLOR_TRANSPARENT);
            dc.fillEllipse(cx, cy, w, r);
        }
        // faint rim so a new moon still reads as a disc
        dc.setPenWidth(1);
        dc.setColor(shadeColor, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(cx, cy, r);
    }
}
