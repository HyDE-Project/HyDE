.pragma library

/**
 * Represents corner rounding configuration
 */
class CornerRounding {
    /**
     * @param {float} [radius=0]
     * @param {float} [smoothing=0]
     */
    constructor(radius = 0, smoothing = 0) {
        this.radius = radius;
        this.smoothing = smoothing;
    }
}

// Static property
CornerRounding.Unrounded = new CornerRounding();