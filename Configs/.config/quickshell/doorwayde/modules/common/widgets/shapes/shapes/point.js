.pragma library

/**
 * @param {number} x
 * @param {number} y
 * @returns {Point}
 */
function createPoint(x, y) {
    return new Point(x, y);
}

class Point {
    /**
     * @param {float} x
     * @param {float} y
     */
    constructor(x, y) {
        this.x = x;
        this.y = y;
    }

    /**
     * @param {float} x
     * @param {float} y
     * @returns {Point}
     */
    copy(x = this.x, y = this.y) {
        return new Point(x, y);
    }

    /**
     * @returns {float}
     */
    getDistance() {
        return Math.sqrt(this.x * this.x + this.y * this.y);
    }

    /**
     * @returns {float}
     */
    getDistanceSquared() {
        return this.x * this.x + this.y * this.y;
    }

    /**
     * @param {Point} other
     * @returns {float}
     */
    dotProduct(other) {
        return this.x * other.x + this.y * other.y;
    }

    /**
     * @param {float} otherX
     * @param {float} otherY
     * @returns {float}
     */
    dotProductScalar(otherX, otherY) {
        return this.x * otherX + this.y * otherY;
    }

    /**
     * @param {Point} other
     * @returns {boolean}
     */
    clockwise(other) {
        return this.x * other.y - this.y * other.x > 0;
    }

    /**
     * @returns {Point}
     */
    getDirection() {
        const d = this.getDistance();
        return this.div(d);
    }

    /**
     * @returns {Point}
     */
    negate() {
        return new Point(-this.x, -this.y);
    }

    /**
     * @param {Point} other
     * @returns {Point}
     */
    minus(other) {
        return new Point(this.x - other.x, this.y - other.y);
    }

    /**
     * @param {Point} other
     * @returns {Point}
     */
    plus(other) {
        return new Point(this.x + other.x, this.y + other.y);
    }

    /**
     * @param {float} operand
     * @returns {Point}
     */
    times(operand) {
        return new Point(this.x * operand, this.y * operand);
    }

    /**
     * @param {float} operand
     * @returns {Point}
     */
    div(operand) {
        return new Point(this.x / operand, this.y / operand);
    }

    /**
     * @param {float} operand
     * @returns {Point}
     */
    rem(operand) {
        return new Point(this.x % operand, this.y % operand);
    }

    /**
     * @param {Point} start
     * @param {Point} stop
     * @param {float} fraction
     * @returns {Point}
     */
    static interpolate(start, stop, fraction) {
        return new Point(
            start.x + (stop.x - start.x) * fraction,
            start.y + (stop.y - start.y) * fraction
        );
    }

    /**
     * @param {function(float, float): Point} f
     * @returns {Point}
     */
    transformed(f) {
        const result = f(this.x, this.y);
        return new Point(result.x, result.y);
    }

    /**
     * @returns {Point}
     */
    rotate90() {
        return new Point(-this.y, this.x);
    }
}

