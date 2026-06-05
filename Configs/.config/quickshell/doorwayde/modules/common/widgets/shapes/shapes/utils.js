.pragma library
.import "point.js" as PointModule

var Point = PointModule.Point;
var DistanceEpsilon = 1e-4;
var AngleEpsilon = 1e-6;

/**
 * @param {Point} previous
 * @param {Point} current
 * @param {Point} next
 * @returns {boolean}
 */
function convex(previous, current, next) {
    return (current.minus(previous)).clockwise(next.minus(current));
}

/**
 * @param {float} start
 * @param {float} stop
 * @param {float} fraction
 * @returns {float}
 */
function interpolate(start, stop, fraction) {
    return (1 - fraction) * start + fraction * stop;
}

/**
 * @param {float} x
 * @param {float} y
 * @returns {Point}
 */
function directionVector(x, y) {
    const d = distance(x, y);
    return new Point(x / d, y / d);
}

/**
 * @param {float} x
 * @param {float} y
 * @returns {float}
 */
function distance(x, y) {
    return Math.sqrt(x * x + y * y);
}

/**
 * @param {float} x
 * @param {float} y
 * @returns {float}
 */
function distanceSquared(x, y) {
    return x * x + y * y;
}

/**
 * @param {float} radius
 * @param {float} angleRadians
 * @param {Point} [center]
 * @returns {Point}
 */
function radialToCartesian(radius, angleRadians, center = new Point(0, 0)) {
    return new Point(Math.cos(angleRadians), Math.sin(angleRadians))
        .times(radius)
        .plus(center);
}

/**
 * @param {float} value
 * @param {float|object} min
 * @param {float} [max]
 * @returns {float}
 */
function coerceIn(value, min, max) {
    if (max === undefined) {
        if (typeof min === 'object' && 'start' in min && 'endInclusive' in min) {
            return Math.max(min.start, Math.min(min.endInclusive, value));
        }
        throw new Error("Invalid arguments for coerceIn");
    }

    const [actualMin, actualMax] = min <= max ? [min, max] : [max, min];
    return Math.max(actualMin, Math.min(actualMax, value));
}

/**
 * @param {float} value
 * @param {float} mod
 * @returns {float}
 */
function positiveModulo(value, mod) {
    return ((value % mod) + mod) % mod;
}

