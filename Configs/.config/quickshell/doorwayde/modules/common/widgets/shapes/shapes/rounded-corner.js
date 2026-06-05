.pragma library
.import "point.js" as PointModule
.import "corner-rounding.js" as RoundingModule
.import "utils.js" as UtilsModule
.import "cubic.js" as CubicModule

var Point = PointModule.Point;
var CornerRounding = RoundingModule.CornerRounding;
var DistanceEpsilon = UtilsModule.DistanceEpsilon;
var directionVector = UtilsModule.directionVector;
var Cubic = CubicModule.Cubic;

class RoundedCorner {
    /**
     * @param {Point} p0
     * @param {Point} p1
     * @param {Point} p2
     * @param {CornerRounding} [rounding=null]
     */
    constructor(p0, p1, p2, rounding = null) {
        this.p0 = p0;
        this.p1 = p1;
        this.p2 = p2;
        this.rounding = rounding;
        this.center = new Point(0, 0);

        const v01 = p0.minus(p1);
        const v21 = p2.minus(p1);
        const d01 = v01.getDistance();
        const d21 = v21.getDistance();
        
        if (d01 > 0 && d21 > 0) {
            this.d1 = v01.div(d01);
            this.d2 = v21.div(d21);
            this.cornerRadius = rounding?.radius ?? 0;
            this.smoothing = rounding?.smoothing ?? 0;

            // cosine of angle at p1 is dot product of unit vectors to the other two vertices
            this.cosAngle = this.d1.dotProduct(this.d2);

            // identity: sin^2 + cos^2 = 1
            // sinAngle gives us the intersection
            this.sinAngle = Math.sqrt(1 - Math.pow(this.cosAngle, 2));
            
            // How much we need to cut, as measured on a side, to get the required radius
            // calculating where the rounding circle hits the edge
            // This uses the identity of tan(A/2) = sinA/(1 + cosA), where tan(A/2) = radius/cut
            this.expectedRoundCut = this.sinAngle > 1e-3 ? this.cornerRadius * (this.cosAngle + 1) / this.sinAngle : 0;
        } else {
            // One (or both) of the sides is empty, not much we can do.
            this.d1 = new Point(0, 0);
            this.d2 = new Point(0, 0);
            this.cornerRadius = 0;
            this.smoothing = 0;
            this.cosAngle = 0;
            this.sinAngle = 0;
            this.expectedRoundCut = 0;
        }
    }

    get expectedCut() {
        return ((1 + this.smoothing) * this.expectedRoundCut);
    }

    /**
     * @param {float} allowedCut0
     * @param {float} [allowedCut1]
     * @returns {Array<Cubic>}
     */
    getCubics(allowedCut0, allowedCut1 = allowedCut0) {
        // We use the minimum of both cuts to determine the radius, but if there is more space
        // in one side we can use it for smoothing.
        const allowedCut = Math.min(allowedCut0, allowedCut1);
        
        // Nothing to do, just use lines, or a point
        if (
            this.expectedRoundCut < DistanceEpsilon ||
            allowedCut < DistanceEpsilon ||
            this.cornerRadius < DistanceEpsilon
        ) {
            this.center = this.p1;
            return [Cubic.straightLine(this.p1.x, this.p1.y, this.p1.x, this.p1.y)];
        }
        
        // How much of the cut is required for the rounding part.
        const actualRoundCut = Math.min(allowedCut, this.expectedRoundCut);
        
        // We have two smoothing values, one for each side of the vertex
        // Space is used for rounding values first. If there is space left over, then we
        // apply smoothing, if it was requested
        const actualSmoothing0 = this.calculateActualSmoothingValue(allowedCut0);
        const actualSmoothing1 = this.calculateActualSmoothingValue(allowedCut1);
        
        // Scale the radius if needed
        const actualR = this.cornerRadius * actualRoundCut / this.expectedRoundCut;
        
        // Distance from the corner (p1) to the center
        const centerDistance = Math.sqrt(Math.pow(actualR, 2) + Math.pow(actualRoundCut, 2));
        
        // Center of the arc we will use for rounding
        this.center = this.p1.plus(this.d1.plus(this.d2).div(2).getDirection().times(centerDistance));
        
        const circleIntersection0 = this.p1.plus(this.d1.times(actualRoundCut));
        const circleIntersection2 = this.p1.plus(this.d2.times(actualRoundCut));
        
        const flanking0 = this.computeFlankingCurve(
            actualRoundCut,
            actualSmoothing0,
            this.p1,
            this.p0,
            circleIntersection0,
            circleIntersection2,
            this.center,
            actualR
        );
        
        const flanking2 = this.computeFlankingCurve(
            actualRoundCut,
            actualSmoothing1,
            this.p1,
            this.p2,
            circleIntersection2,
            circleIntersection0,
            this.center,
            actualR
        ).reverse();
        
        return [
            flanking0,
            Cubic.circularArc(
                this.center.x,
                this.center.y,
                flanking0.anchor1X,
                flanking0.anchor1Y,
                flanking2.anchor0X,
                flanking2.anchor0Y
            ),
            flanking2
        ];
    }

    /**
     * @private
     * @param {float} allowedCut
     * @returns {float}
     */
    calculateActualSmoothingValue(allowedCut) {
        if (allowedCut > this.expectedCut) {
            return this.smoothing;
        } else if (allowedCut > this.expectedRoundCut) {
            return this.smoothing * (allowedCut - this.expectedRoundCut) / (this.expectedCut - this.expectedRoundCut);
        } else {
            return 0;
        }
    }

    /**
     * @private
     * @param {float} actualRoundCut
     * @param {float} actualSmoothingValues
     * @param {Point} corner
     * @param {Point} sideStart
     * @param {Point} circleSegmentIntersection
     * @param {Point} otherCircleSegmentIntersection
     * @param {Point} circleCenter
     * @param {float} actualR
     * @returns {Cubic}
     */
    computeFlankingCurve(
        actualRoundCut,
        actualSmoothingValues,
        corner,
        sideStart,
        circleSegmentIntersection,
        otherCircleSegmentIntersection,
        circleCenter,
        actualR
    ) {
        // sideStart is the anchor, 'anchor' is actual control point
        const sideDirection = (sideStart.minus(corner)).getDirection();
        const curveStart = corner.plus(sideDirection.times(actualRoundCut * (1 + actualSmoothingValues)));
        
        // We use an approximation to cut a part of the circle section proportional to 1 - smooth,
        // When smooth = 0, we take the full section, when smooth = 1, we take nothing.
        const p = Point.interpolate(
            circleSegmentIntersection,
            (circleSegmentIntersection.plus(otherCircleSegmentIntersection)).div(2),
            actualSmoothingValues
        );
        
        // The flanking curve ends on the circle
        const curveEnd = circleCenter.plus(
            directionVector(p.x - circleCenter.x, p.y - circleCenter.y).times(actualR)
        );
        
        // The anchor on the circle segment side is in the intersection between the tangent to the
        // circle in the circle/flanking curve boundary and the linear segment.
        const circleTangent = (curveEnd.minus(circleCenter)).rotate90();
        const anchorEnd = this.lineIntersection(sideStart, sideDirection, curveEnd, circleTangent) ?? circleSegmentIntersection;
        
        // From what remains, we pick a point for the start anchor.
        // 2/3 seems to come from design tools?
        const anchorStart = (curveStart.plus(anchorEnd.times(2))).div(3);
        
        return Cubic.create(curveStart, anchorStart, anchorEnd, curveEnd);
    }

    /**
     * @private
     * @param {Point} p0
     * @param {Point} d0
     * @param {Point} p1
     * @param {Point} d1
     * @returns {Point|null}
     */
    lineIntersection(p0, d0, p1, d1) {
        const rotatedD1 = d1.rotate90();
        const den = d0.dotProduct(rotatedD1);
        if (Math.abs(den) < DistanceEpsilon) return null;
        
        const num = (p1.minus(p0)).dotProduct(rotatedD1);
        // Also check the relative value. This is equivalent to abs(den/num) < DistanceEpsilon,
        // but avoid doing a division
        if (Math.abs(den) < DistanceEpsilon * Math.abs(num)) return null;
        
        const k = num / den;
        return p0.plus(d0.times(k));
    }
}