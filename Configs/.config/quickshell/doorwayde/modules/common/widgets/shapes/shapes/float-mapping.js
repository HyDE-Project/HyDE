.pragma library
.import "utils.js" as UtilsModule

var positiveModulo = UtilsModule.positiveModulo;

/**
 * Maps values between two ranges
 */
class DoubleMapper {
    constructor(...mappings) {
        this.sourceValues = [];
        this.targetValues = [];
        
        for (const mapping of mappings) {
            this.sourceValues.push(mapping.a);
            this.targetValues.push(mapping.b);
        }
    }

    /**
     * @param {float} x
     * @returns {float}
     */
    map(x) {
        return linearMap(this.sourceValues, this.targetValues, x);
    }

    /**
     * @param {float} x
     * @returns {float}
     */
    mapBack(x) {
        return linearMap(this.targetValues, this.sourceValues, x);
    }
}

// Static property
DoubleMapper.Identity = new DoubleMapper({ a: 0, b: 0 }, { a: 0.5, b: 0.5 });

/**
 * @param {Array<float>} xValues
 * @param {Array<float>} yValues
 * @param {float} x
 * @returns {float}
 */
function linearMap(xValues, yValues, x) {
    let segmentStartIndex = -1;
    for (let i = 0; i < xValues.length; i++) {
        const nextIndex = (i + 1) % xValues.length;
        if (progressInRange(x, xValues[i], xValues[nextIndex])) {
            segmentStartIndex = i;
            break;
        }
    }

    if (segmentStartIndex === -1) {
        throw new Error("No valid segment found");
    }

    const segmentEndIndex = (segmentStartIndex + 1) % xValues.length;
    const segmentSizeX = positiveModulo(xValues[segmentEndIndex] - xValues[segmentStartIndex], 1);
    const segmentSizeY = positiveModulo(yValues[segmentEndIndex] - yValues[segmentStartIndex], 1);

    let positionInSegment;
    if (segmentSizeX < 0.001) {
        positionInSegment = 0.5;
    } else {
        positionInSegment = positiveModulo(x - xValues[segmentStartIndex], 1) / segmentSizeX;
    }

    return positiveModulo(yValues[segmentStartIndex] + segmentSizeY * positionInSegment, 1);
}

/**
 * @param {float} progress
 * @param {float} progressFrom
 * @param {float} progressTo
 * @returns {boolean}
 */
function progressInRange(progress, progressFrom, progressTo) {
    if (progressTo >= progressFrom) {
        return progress >= progressFrom && progress <= progressTo;
    } else {
        return progress >= progressFrom || progress <= progressTo;
    }
}