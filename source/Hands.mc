import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! Hand outlines at the 416 px reference size. Points are [x, y] relative to the pivot; -y points to 12.
module Hands {
    var HOUR as Array<Array<Float>> = [[-6.0, 20.0], [-6.0, -92.0], [0.0, -116.0], [6.0, -92.0], [6.0, 20.0]];
    var HOUR_LUME as Array<Array<Float>> = [[-3.0, -24.0], [-3.0, -88.0], [0.0, -104.0], [3.0, -88.0], [3.0, -24.0]];
    var MINUTE as Array<Array<Float>> = [[-5.0, 20.0], [-5.0, -152.0], [0.0, -176.0], [5.0, -152.0], [5.0, 20.0]];
    var MINUTE_LUME as Array<Array<Float>> = [[-2.5, -24.0], [-2.5, -148.0], [0.0, -162.0], [2.5, -148.0], [2.5, -24.0]];
    var SECOND as Array<Array<Float>> = [[-1.0, 42.0], [-1.0, -180.0], [1.0, -180.0], [1.0, 42.0]];
    var SUB as Array<Array<Float>> = [[-2.5, 9.0], [-2.5, -30.0], [0.0, -44.0], [2.5, -30.0], [2.5, 9.0]];
    var DATE as Array<Array<Float>> = [[-2.5, 10.0], [-2.5, -46.0], [0.0, -61.0], [2.5, -46.0], [2.5, 10.0]];

    //! Rotate/scale shape about (cx, cy) into out, writing the existing point arrays in place.
    function transform(shape as Array<Array<Float>>, out as Array<Array<Numeric>>, cx as Numeric, cy as Numeric,
                       angle as Float, scale as Float) as Void {
        var s = Math.sin(angle);
        var c = Math.cos(angle);
        for (var i = 0; i < shape.size(); i++) {
            var px = shape[i][0] * scale;
            var py = shape[i][1] * scale;
            var o = out[i];
            o[0] = cx + px * c - py * s;
            o[1] = cy + px * s + py * c;
        }
    }

    //! Preallocate an output array with n mutable [x, y] points.
    function points(n as Number) as Array<Array<Numeric>> {
        var out = new Array<Array<Numeric>>[n];
        for (var i = 0; i < n; i++) {
            out[i] = [0.0, 0.0];
        }
        return out;
    }

    //! Close the polygon outline with lines (fillPolygon has no stroke).
    function outline(dc as Dc, pts as Array<Array<Numeric>>) as Void {
        var n = pts.size();
        for (var i = 0; i < n; i++) {
            var a = pts[i];
            var b = pts[(i + 1) % n];
            dc.drawLine(a[0], a[1], b[0], b[1]);
        }
    }

    //! Luminous-style hand: body, edge line, lume insert.
    function drawLumed(dc as Dc, body as Array<Array<Numeric>>, lume as Array<Array<Numeric>>, pal as Palette) as Void {
        dc.setColor(pal.handBody, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(body as Array<Point2D>);
        dc.setPenWidth(1);
        dc.setColor(pal.handEdge, Graphics.COLOR_TRANSPARENT);
        outline(dc, body);
        dc.setColor(pal.lume, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(lume as Array<Point2D>);
    }
}
