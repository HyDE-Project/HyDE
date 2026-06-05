.pragma library
.import "feature.js" as FeatureModule
.import "float-mapping.js" as MappingModule
.import "point.js" as PointModule
.import "utils.js" as UtilsModule

var Feature = FeatureModule.Feature;
var Corner = FeatureModule.Corner;
var Point = PointModule.Point;
var DoubleMapper = MappingModule.DoubleMapper;
var progressInRange = MappingModule.progressInRange;
var DistanceEpsilon = UtilsModule.DistanceEpsilon;

var IdentityMapping = [{ a: 0, b: 0 }, { a: 0.5, b: 0.5 }];

class ProgressableFeature {
    /**
     * @param {float} progress
     * @param {Feature} feature
     */
    constructor(progress, feature) {
        this.progress = progress;
        this.feature = feature;
    }
}

class DistanceVertex {
    /**
     * @param {float} distance
     * @param {ProgressableFeature} f1
     * @param {ProgressableFeature} f2
     */
    constructor(distance, f1, f2) {
        this.distance = distance;
        this.f1 = f1;
        this.f2 = f2;
    }
}

class MappingHelper {
    constructor() {
        this.mapping = [];
        this.usedF1 = new Set();
        this.usedF2 = new Set();
    }

    /**
     * @param {ProgressableFeature} f1
     * @param {ProgressableFeature} f2
     */
    addMapping(f1, f2) {
        if (this.usedF1.has(f1) || this.usedF2.has(f2)) {
            return;
        }

        const index = this.mapping.findIndex(x => x.a === f1.progress);
        const insertionIndex = -index - 1;
        const n = this.mapping.length;

        if (n >= 1) {
            const { a: before1, b: before2 } = this.mapping[(insertionIndex + n - 1) % n];
            const { a: after1, b: after2 } = this.mapping[insertionIndex % n];

            if (
                progressDistance(f1.progress, before1) < DistanceEpsilon ||
                progressDistance(f1.progress, after1) < DistanceEpsilon ||
                progressDistance(f2.progress, before2) < DistanceEpsilon ||
                progressDistance(f2.progress, after2) < DistanceEpsilon
            ) {
                return;
            }

            if (n > 1 && !progressInRange(f2.progress, before2, after2)) {
                return;
            }
        }

        this.mapping.splice(insertionIndex, 0, { a: f1.progress, b: f2.progress });
        this.usedF1.add(f1);
        this.usedF2.add(f2);
    }
}

/**
 * @param {Array<ProgressableFeature>} features1
 * @param {Array<ProgressableFeature>} features2
 * @returns {DoubleMapper}
 */
function featureMapper(features1, features2) {
    const filteredFeatures1 = features1.filter(f => f.feature instanceof Corner);
    const filteredFeatures2 = features2.filter(f => f.feature instanceof Corner);

    const featureProgressMapping = doMapping(filteredFeatures1, filteredFeatures2);
    return new DoubleMapper(...featureProgressMapping);
}

/**
 * @param {Array<ProgressableFeature>} features1
 * @param {Array<ProgressableFeature>} features2
 * @returns {Array<{a: float, b: float}>}
 */
function doMapping(features1, features2) {
    const distanceVertexList = [];
    
    for (const f1 of features1) {
        for (const f2 of features2) {
            const d = featureDistSquared(f1.feature, f2.feature);
            if (d !== Number.MAX_VALUE) {
                distanceVertexList.push(new DistanceVertex(d, f1, f2));
            }
        }
    }
    
    distanceVertexList.sort((a, b) => a.distance - b.distance);

    // Special cases
    if (distanceVertexList.length === 0) {
        return IdentityMapping;
    } else if (distanceVertexList.length === 1) {
        const { f1, f2 } = distanceVertexList[0];
        const p1 = f1.progress;
        const p2 = f2.progress;
        return [
            { a: p1, b: p2 },
            { a: (p1 + 0.5) % 1, b: (p2 + 0.5) % 1 }
        ];
    }

    const helper = new MappingHelper();
    distanceVertexList.forEach(({ f1, f2 }) => helper.addMapping(f1, f2));
    return helper.mapping;
}

/**
 * @param {Feature} f1
 * @param {Feature} f2
 * @returns {float}
 */
function featureDistSquared(f1, f2) {
    if (f1 instanceof Corner && f2 instanceof Corner && f1.convex != f2.convex) {
        return Number.MAX_VALUE;
    }
    return featureRepresentativePoint(f1).minus(featureRepresentativePoint(f2)).getDistanceSquared();
}

/**
 * @param {Feature} feature
 * @returns {Point}
 */
function featureRepresentativePoint(feature) {
    const firstCubic = feature.cubics[0];
    const lastCubic = feature.cubics[feature.cubics.length - 1];
    const x = (firstCubic.anchor0X + lastCubic.anchor1X) / 2;
    const y = (firstCubic.anchor0Y + lastCubic.anchor1Y) / 2;
    return new Point(x, y);
}

/**
 * @param {float} p1
 * @param {float} p2
 * @returns {float}
 */
function progressDistance(p1, p2) {
    const it = Math.abs(p1 - p2);
    return Math.min(it, 1 - it);
}