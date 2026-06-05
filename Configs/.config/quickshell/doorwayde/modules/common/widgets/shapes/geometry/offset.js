.pragma library

/**
 * @param {number} x
 * @param {number} y
 * @returns {Offset}
 */
function createOffset(x, y) {
    return new Offset(x, y);
}

class Offset {
    /**
     * @param {number} x
     * @param {number} y
     */
    constructor(x, y) {
        this.x = x;
        this.y = y;
    }

    /**
     * @param {number} x
     * @param {number} y
     * @returns {Offset}
     */
    copy(x = this.x, y = this.y) {
        return new Offset(x, y);
    }

    /**
     * @returns {number}
     */
    getDistance() {
        return Math.sqrt(this.x * this.x + this.y * this.y);
    }

    /**
     * @returns {number}
     */
    getDistanceSquared() {
        return this.x * this.x + this.y * this.y;
    }

    /**
     * @returns {boolean}
     */
    isValid() {
        return isFinite(this.x) && isFinite(this.y);
    }

    /**
     * @returns {boolean}
     */
    get isFinite() {
        return isFinite(this.x) && isFinite(this.y);
    }

    /**
     * @returns {boolean}
     */
    get isSpecified() {
        return !this.isUnspecified;
    }

    /**
     * @returns {boolean}
     */
    get isUnspecified() {
        return Object.is(this.x, NaN) && Object.is(this.y, NaN);
    }

    /**
     * @returns {Offset}
     */
    negate() {
        return new Offset(-this.x, -this.y);
    }

    /**
     * @param {Offset} other
     * @returns {Offset}
     */
    minus(other) {
        return new Offset(this.x - other.x, this.y - other.y);
    }

    /**
     * @param {Offset} other
     * @returns {Offset}
     */
    plus(other) {
        return new Offset(this.x + other.x, this.y + other.y);
    }

    /**
     * @param {number} operand
     * @returns {Offset}
     */
    times(operand) {
        return new Offset(this.x * operand, this.y * operand);
    }

    /**
     * @param {number} operand
     * @returns {Offset}
     */
    div(operand) {
        return new Offset(this.x / operand, this.y / operand);
    }

    /**
     * @param {number} operand
     * @returns {Offset}
     */
    rem(operand) {
        return new Offset(this.x % operand, this.y % operand);
    }

    /**
     * @returns {string}
     */
    toString() {
        if (this.isSpecified) {
            return `Offset(${this.x.toFixed(1)}, ${this.y.toFixed(1)})`;
        } else {
            return 'Offset.Unspecified';
        }
    }

    /**
     * @param {Offset} start
     * @param {Offset} stop
     * @param {number} fraction
     * @returns {Offset}
     */
    static lerp(start, stop, fraction) {
        return new Offset(
            start.x + (stop.x - start.x) * fraction,
            start.y + (stop.y - start.y) * fraction
        );
    }

    /**
     * @param {function(): Offset} block
     * @returns {Offset}
     */
    takeOrElse(block) {
        return this.isSpecified ? this : block();
    }

    /**
     * @returns {number}
     */
    angleDegrees() {
        return Math.atan2(this.y, this.x) * 180 / Math.PI;
    }

    /**
     * @param {number} angle
     * @param {Offset} center
     * @returns {Offset}
     */
    rotateDegrees(angle, center = Offset.Zero) {
        const a = angle * Math.PI / 180;
        const off = this.minus(center);
        const cosA = Math.cos(a);
        const sinA = Math.sin(a);
        const newX = off.x * cosA - off.y * sinA;
        const newY = off.x * sinA + off.y * cosA;
        return new Offset(newX, newY).plus(center);
    }
}

Offset.Zero = new Offset(0, 0);
Offset.Infinite = new Offset(Infinity, Infinity);
Offset.Unspecified = new Offset(NaN, NaN);
