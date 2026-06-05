.pragma library

.import "cubic.js" as Cubic
.import "point.js" as Point
.import "feature-mapping.js" as FeatureMapping
.import "utils.js" as Utils
.import "feature.js" as Feature

class MeasuredPolygon {
    constructor(measurer, features, cubics, outlineProgress) {
        this.measurer = measurer
        this.features = features
        this.outlineProgress = outlineProgress
        this.cubics = []

        const measuredCubics = []
        let startOutlineProgress = 0
        for(let i = 0; i < cubics.length; i++) {
            if ((outlineProgress[i + 1] - outlineProgress[i]) > Utils.DistanceEpsilon) {
                measuredCubics.push(
                    new MeasuredCubic(this, cubics[i], startOutlineProgress, outlineProgress[i + 1])
                )
                // The next measured cubic will start exactly where this one ends.
                startOutlineProgress = outlineProgress[i + 1]
            }
        }

        measuredCubics[measuredCubics.length - 1].updateProgressRange(measuredCubics[measuredCubics.length - 1].startOutlineProgress, 1)
        this.cubics = measuredCubics
    }

    cutAndShift(cuttingPoint) {
        if (cuttingPoint < Utils.DistanceEpsilon) return this

        // Find the index of cubic we want to cut
        const targetIndex = this.cubics.findIndex(it => cuttingPoint >= it.startOutlineProgress && cuttingPoint <= it.endOutlineProgress)
        const target = this.cubics[targetIndex]
        // Cut the target cubic.
        // b1, b2 are two resulting cubics after cut
        const { a: b1, b: b2 } = target.cutAtProgress(cuttingPoint)

        // Construct the list of the cubics we need:
        // * The second part of the target cubic (after the cut)
        // * All cubics after the target, until the end + All cubics from the start, before the
        //   target cubic
        // * The first part of the target cubic (before the cut)
        const retCubics = [b2.cubic]
        for(let i = 1; i < this.cubics.length; i++) {
            retCubics.push(this.cubics[(i + targetIndex) % this.cubics.length].cubic)
        }
        retCubics.push(b1.cubic)

        // Construct the array of outline progress.
        // For example, if we have 3 cubics with outline progress [0 .. 0.3], [0.3 .. 0.8] &
        // [0.8 .. 1.0], and we cut + shift at 0.6:
        // 0.  0123456789
        //     |--|--/-|-|
        // The outline progresses will start at 0 (the cutting point, that shifs to 0.0),
        // then 0.8 - 0.6 = 0.2, then 1 - 0.6 = 0.4, then 0.3 - 0.6 + 1 = 0.7,
        // then 1 (the cutting point again),
        // all together: (0.0, 0.2, 0.4, 0.7, 1.0)
        const retOutlineProgress = []
        for (let i = 0; i < this.cubics.length + 2; i++) {
            if (i === 0) {
                retOutlineProgress.push(0)
            } else if(i === this.cubics.length + 1) {
                retOutlineProgress.push(1)
            } else {
                const cubicIndex = (targetIndex + i - 1) % this.cubics.length
                retOutlineProgress.push(Utils.positiveModulo(this.cubics[cubicIndex].endOutlineProgress - cuttingPoint, 1))
            }
        }

        // Shift the feature's outline progress too.
        const newFeatures = []
        for(let i = 0; i < this.features.length; i++) {
            newFeatures.push(new FeatureMapping.ProgressableFeature(Utils.positiveModulo(this.features[i].progress - cuttingPoint, 1), this.features[i].feature))
        }

        // Filter out all empty cubics (i.e. start and end anchor are (almost) the same point.)
        return new MeasuredPolygon(this.measurer, newFeatures, retCubics, retOutlineProgress)
    }

    static measurePolygon(measurer, polygon) {
        const cubics = []
        const featureToCubic = []

        for (let featureIndex = 0; featureIndex < polygon.features.length; featureIndex++) {
            const feature = polygon.features[featureIndex]
            for (let cubicIndex = 0; cubicIndex < feature.cubics.length; cubicIndex++) {
                if (feature instanceof Feature.Corner && cubicIndex == feature.cubics.length / 2) {
                    featureToCubic.push({ a: feature, b: cubics.length })
                }
                cubics.push(feature.cubics[cubicIndex])
            }
        }

        const measures = [0] // Initialize with 0 like in Kotlin's scan
        for (const cubic of cubics) {
            const measurement = measurer.measureCubic(cubic)
            if (measurement < 0) {
                throw new Error("Measured cubic is expected to be greater or equal to zero")
            }
            const lastMeasure = measures[measures.length - 1]
            measures.push(lastMeasure + measurement)
        }
        const totalMeasure = measures[measures.length - 1]

        const outlineProgress = []
        for (let i = 0; i < measures.length; i++) {
            outlineProgress.push(measures[i] / totalMeasure)
        }

        const features = []
        for (let i = 0; i < featureToCubic.length; i++) {
            const ix = featureToCubic[i].b
            features.push(
                new FeatureMapping.ProgressableFeature(Utils.positiveModulo((outlineProgress[ix] + outlineProgress[ix + 1]) / 2, 1), featureToCubic[i].a))
        }

        return new MeasuredPolygon(measurer, features, cubics, outlineProgress)
    }
}

class MeasuredCubic {
    constructor(polygon, cubic, startOutlineProgress, endOutlineProgress) {
        this.polygon = polygon
        this.cubic = cubic
        this.startOutlineProgress = startOutlineProgress
        this.endOutlineProgress = endOutlineProgress
        this.measuredSize = this.polygon.measurer.measureCubic(cubic)
    }

    updateProgressRange(
        startOutlineProgress = this.startOutlineProgress,
        endOutlineProgress = this.endOutlineProgress,
    ) {
        this.startOutlineProgress = startOutlineProgress
        this.endOutlineProgress = endOutlineProgress
    }

    cutAtProgress(cutOutlineProgress) {
        const boundedCutOutlineProgress = Utils.coerceIn(cutOutlineProgress, this.startOutlineProgress, this.endOutlineProgress)
        const outlineProgressSize = this.endOutlineProgress - this.startOutlineProgress
        const progressFromStart = boundedCutOutlineProgress - this.startOutlineProgress

        const relativeProgress = progressFromStart / outlineProgressSize
        const t = this.polygon.measurer.findCubicCutPoint(this.cubic, relativeProgress * this.measuredSize)

        const {a: c1, b: c2} = this.cubic.split(t)
        return { 
            a: new MeasuredCubic(this.polygon, c1, this.startOutlineProgress, boundedCutOutlineProgress), 
            b: new MeasuredCubic(this.polygon, c2, boundedCutOutlineProgress, this.endOutlineProgress) 
        }
    }
}

class LengthMeasurer {
    constructor() {
        this.segments = 3
    }

    measureCubic(c) {
        return this.closestProgressTo(c, Number.POSITIVE_INFINITY).y
    }

    findCubicCutPoint(c, m) {
        return this.closestProgressTo(c, m).x
    }

    closestProgressTo(cubic, threshold) {
        let total = 0
        let remainder = threshold
        let prev = new Point.Point(cubic.anchor0X, cubic.anchor0Y)

        for (let i = 1; i < this.segments; i++) {
            const progress = i / this.segments
            const point = cubic.pointOnCurve(progress)
            const segment = point.minus(prev).getDistance()

            if (segment >= remainder) {
                return new Point.Point(progress - (1.0 - remainder / segment) / this.segments, threshold)
            }

            remainder -= segment
            total += segment
            prev = point
        }

        return new Point.Point(1.0, total)
    }
}