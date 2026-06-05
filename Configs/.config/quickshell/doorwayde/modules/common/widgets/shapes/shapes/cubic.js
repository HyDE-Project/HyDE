.pragma library
.import "point.js" as PointModule
.import "utils.js" as UtilsModule

var Point = PointModule.Point;
var DistanceEpsilon = UtilsModule.DistanceEpsilon;
var interpolate = UtilsModule.interpolate;
var directionVector = UtilsModule.directionVector;
var distance = UtilsModule.distance;

/**
 * Represents a cubic Bézier curve with anchor and control points
 */
class Cubic {
    /**
     * @param {Array<float>} points Array of 8 numbers [anchor0X, anchor0Y, control0X, control0Y, control1X, control1Y, anchor1X, anchor1Y]
     */
    constructor(points) {
        this.points = points;
    }

    get anchor0X() { return this.points[0]; }
    get anchor0Y() { return this.points[1]; }
    get control0X() { return this.points[2]; }
    get control0Y() { return this.points[3]; }
    get control1X() { return this.points[4]; }
    get control1Y() { return this.points[5]; }
    get anchor1X() { return this.points[6]; }
    get anchor1Y() { return this.points[7]; }

    /**
     * @param {Point} anchor0
     * @param {Point} control0
     * @param {Point} control1
     * @param {Point} anchor1
     * @returns {Cubic}
     */
    static create(anchor0, control0, control1, anchor1) {
        return new Cubic([
            anchor0.x, anchor0.y,
            control0.x, control0.y,
            control1.x, control1.y,
            anchor1.x, anchor1.y
        ]);
    }

    /**
     * @param {float} t
     * @returns {Point}
     */
    pointOnCurve(t) {
        const u = 1 - t;
        return new Point(
            this.anchor0X * (u * u * u) +
            this.control0X * (3 * t * u * u) +
            this.control1X * (3 * t * t * u) +
            this.anchor1X * (t * t * t),
            this.anchor0Y * (u * u * u) +
            this.control0Y * (3 * t * u * u) +
            this.control1Y * (3 * t * t * u) +
            this.anchor1Y * (t * t * t)
        );
    }

    /**
     * @returns {boolean}
     */
    zeroLength() {
        return Math.abs(this.anchor0X - this.anchor1X) < DistanceEpsilon &&
               Math.abs(this.anchor0Y - this.anchor1Y) < DistanceEpsilon;
    }

    /**
     * @param {Cubic} next
     * @returns {boolean}
     */
    convexTo(next) {
        const prevVertex = new Point(this.anchor0X, this.anchor0Y);
        const currVertex = new Point(this.anchor1X, this.anchor1Y);
        const nextVertex = new Point(next.anchor1X, next.anchor1Y);
        return convex(prevVertex, currVertex, nextVertex);
    }

    /**
     * @param {float} value
     * @returns {boolean}
     */
    zeroIsh(value) {
        return Math.abs(value) < DistanceEpsilon;
    }

    /**
     * @param {Array<float>} bounds
     * @param {boolean} [approximate=false]
     */
    calculateBounds(bounds, approximate = false) {
        if (this.zeroLength()) {
            bounds[0] = this.anchor0X;
            bounds[1] = this.anchor0Y;
            bounds[2] = this.anchor0X;
            bounds[3] = this.anchor0Y;
            return;
        }

        let minX = Math.min(this.anchor0X, this.anchor1X);
        let minY = Math.min(this.anchor0Y, this.anchor1Y);
        let maxX = Math.max(this.anchor0X, this.anchor1X);
        let maxY = Math.max(this.anchor0Y, this.anchor1Y);

        if (approximate) {
            bounds[0] = Math.min(minX, Math.min(this.control0X, this.control1X));
            bounds[1] = Math.min(minY, Math.min(this.control0Y, this.control1Y));
            bounds[2] = Math.max(maxX, Math.max(this.control0X, this.control1X));
            bounds[3] = Math.max(maxY, Math.max(this.control0Y, this.control1Y));
            return;
        }

        // Find extrema using derivatives
        const xa = -this.anchor0X + 3 * this.control0X - 3 * this.control1X + this.anchor1X;
        const xb = 2 * this.anchor0X - 4 * this.control0X + 2 * this.control1X;
        const xc = -this.anchor0X + this.control0X;

        if (this.zeroIsh(xa)) {
            if (xb != 0) {
                const t = 2 * xc / (-2 * xb);
                if (t >= 0 && t <= 1) {
                    const it = this.pointOnCurve(t).x;
                    if (it < minX) minX = it;
                    if (it > maxX) maxX = it;
                }
            }
        } else {
            const xs = xb * xb - 4 * xa * xc;
            if (xs >= 0) {
                const t1 = (-xb + Math.sqrt(xs)) / (2 * xa);
                if (t1 >= 0 && t1 <= 1) {
                    const it = this.pointOnCurve(t1).x;
                    if (it < minX) minX = it;
                    if (it > maxX) maxX = it;
                }

                const t2 = (-xb - Math.sqrt(xs)) / (2 * xa);
                if (t2 >= 0 && t2 <= 1) {
                    const it = this.pointOnCurve(t2).x;
                    if (it < minX) minX = it;
                    if (it > maxX) maxX = it;
                }
            }
        }

        // Repeat for y coord
        const ya = -this.anchor0Y + 3 * this.control0Y - 3 * this.control1Y + this.anchor1Y;
        const yb = 2 * this.anchor0Y - 4 * this.control0Y + 2 * this.control1Y;
        const yc = -this.anchor0Y + this.control0Y;

        if (this.zeroIsh(ya)) {
            if (yb != 0) {
                const t = 2 * yc / (-2 * yb);
                if (t >= 0 && t <= 1) {
                    const it = this.pointOnCurve(t).y;
                    if (it < minY) minY = it;
                    if (it > maxY) maxY = it;
                }
            }
        } else {
            const ys = yb * yb - 4 * ya * yc;
            if (ys >= 0) {
                const t1 = (-yb + Math.sqrt(ys)) / (2 * ya);
                if (t1 >= 0 && t1 <= 1) {
                    const it = this.pointOnCurve(t1).y;
                    if (it < minY) minY = it;
                    if (it > maxY) maxY = it;
                }

                const t2 = (-yb - Math.sqrt(ys)) / (2 * ya);
                if (t2 >= 0 && t2 <= 1) {
                    const it = this.pointOnCurve(t2).y;
                    if (it < minY) minY = it;
                    if (it > maxY) maxY = it;
                }
            }
        }
        bounds[0] = minX;
        bounds[1] = minY;
        bounds[2] = maxX;
        bounds[3] = maxY;
    }

    /**
     * @param {float} t
     * @returns {{a: Cubic, b: Cubic}}
     */
    split(t) {
        const u = 1 - t;
        const pointOnCurve = this.pointOnCurve(t);
        return {
            a: new Cubic([
                this.anchor0X,
                this.anchor0Y,
                this.anchor0X * u + this.control0X * t,
                this.anchor0Y * u + this.control0Y * t,
                this.anchor0X * (u * u) + this.control0X * (2 * u * t) + this.control1X * (t * t),
                this.anchor0Y * (u * u) + this.control0Y * (2 * u * t) + this.control1Y * (t * t),
                pointOnCurve.x,
                pointOnCurve.y
            ]),
            b: new Cubic([
                pointOnCurve.x,
                pointOnCurve.y,
                this.control0X * (u * u) + this.control1X * (2 * u * t) + this.anchor1X * (t * t),
                this.control0Y * (u * u) + this.control1Y * (2 * u * t) + this.anchor1Y * (t * t),
                this.control1X * u + this.anchor1X * t,
                this.control1Y * u + this.anchor1Y * t,
                this.anchor1X,
                this.anchor1Y
            ])
        };
    }

    /**
     * @returns {Cubic}
     */
    reverse() {
        return new Cubic([
            this.anchor1X, this.anchor1Y,
            this.control1X, this.control1Y,
            this.control0X, this.control0Y,
            this.anchor0X, this.anchor0Y
        ]);
    }

    /**
     * @param {Cubic} other
     * @returns {Cubic}
     */
    plus(other) {
        return new Cubic(other.points.map((_, index) => this.points[index] + other.points[index]));
    }

    /**
     * @param {float} x
     * @returns {Cubic}
     */
    times(x) {
        return new Cubic(this.points.map(v => v * x));
    }

    /**
     * @param {float} x
     * @returns {Cubic}
     */
    div(x) {
        return this.times(1 / x);
    }

    /**
     * @param {Cubic} other
     * @returns {boolean}
     */
    equals(other) {
        return this.points.every((p, i) => other.points[i] === p);
    }

    /**
     * @param {function(float, float): Point} f
     * @returns {Cubic}
     */
    transformed(f) {
        const newCubic = new MutableCubic([...this.points]);
        newCubic.transform(f);
        return newCubic;
    }

    /**
     * @param {float} x0
     * @param {float} y0
     * @param {float} x1
     * @param {float} y1
     * @returns {Cubic}
     */
    static straightLine(x0, y0, x1, y1) {
        return new Cubic([
            x0,
            y0,
            interpolate(x0, x1, 1/3),
            interpolate(y0, y1, 1/3),
            interpolate(x0, x1, 2/3),
            interpolate(y0, y1, 2/3),
            x1,
            y1
        ]);
    }

    /**
     * @param {float} centerX
     * @param {float} centerY
     * @param {float} x0
     * @param {float} y0
     * @param {float} x1
     * @param {float} y1
     * @returns {Cubic}
     */
    static circularArc(centerX, centerY, x0, y0, x1, y1) {
        const p0d = directionVector(x0 - centerX, y0 - centerY);
        const p1d = directionVector(x1 - centerX, y1 - centerY);
        const rotatedP0 = p0d.rotate90();
        const rotatedP1 = p1d.rotate90();
        const clockwise = rotatedP0.dotProductScalar(x1 - centerX, y1 - centerY) >= 0;
        const cosa = p0d.dotProduct(p1d);
        
        if (cosa > 0.999) {
            return Cubic.straightLine(x0, y0, x1, y1);
        }

        const k = distance(x0 - centerX, y0 - centerY) * 4/3 * 
                 (Math.sqrt(2 * (1 - cosa)) - Math.sqrt(1 - cosa * cosa)) / 
                 (1 - cosa) * (clockwise ? 1 : -1);
                 
        return new Cubic([
            x0, y0,
            x0 + rotatedP0.x * k,
            y0 + rotatedP0.y * k,
            x1 - rotatedP1.x * k,
            y1 - rotatedP1.y * k,
            x1, y1
        ]);
    }

    /**
     * @param {float} x0
     * @param {float} y0
     * @returns {Cubic}
     */
    static empty(x0, y0) {
        return new Cubic([x0, y0, x0, y0, x0, y0, x0, y0]);
    }
}

class MutableCubic extends Cubic {
    /**
     * @param {function(float, float): Point} f
     */
    transform(f) {
        this.transformOnePoint(f, 0);
        this.transformOnePoint(f, 2);
        this.transformOnePoint(f, 4);
        this.transformOnePoint(f, 6);
    }

    /**
     * @param {Cubic} c1
     * @param {Cubic} c2
     * @param {float} progress
     */
    interpolate(c1, c2, progress) {
        for (let i = 0; i < 8; i++) {
            this.points[i] = interpolate(c1.points[i], c2.points[i], progress);
        }
    }

    /**
     * @private
     * @param {function(float, float): Point} f
     * @param {number} ix
     */
    transformOnePoint(f, ix) {
        const result = f(this.points[ix], this.points[ix + 1]);
        this.points[ix] = result.x;
        this.points[ix + 1] = result.y;
    }
}