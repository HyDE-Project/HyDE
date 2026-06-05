.pragma library
.import "cubic.js" as CubicModule

var Cubic = CubicModule.Cubic;

/**
 * Base class for shape features (edges and corners)
 */
class Feature {
    /**
     * @param {Array<Cubic>} cubics
     */
    constructor(cubics) {
        this.cubics = cubics;
    }

    /**
     * @param {Array<Cubic>} cubics
     * @returns {Edge}
     */
    buildIgnorableFeature(cubics) {
        return new Edge(cubics);
    }

    /**
     * @param {Cubic} cubic
     * @returns {Edge}
     */
    buildEdge(cubic) {
        return new Edge([cubic]);
    }

    /**
     * @param {Array<Cubic>} cubics
     * @returns {Corner}
     */
    buildConvexCorner(cubics) {
        return new Corner(cubics, true);
    }

    /**
     * @param {Array<Cubic>} cubics
     * @returns {Corner}
     */
    buildConcaveCorner(cubics) {
        return new Corner(cubics, false);
    }
}

class Edge extends Feature {
    constructor(cubics) {
        super(cubics);
        this.isIgnorableFeature = true;
        this.isEdge = true;
        this.isConvexCorner = false;
        this.isConcaveCorner = false;
    }

    /**
     * @param {function(float, float): Point} f
     * @returns {Feature}
     */
    transformed(f) {
        return new Edge(this.cubics.map(c => c.transformed(f)));
    }

    /**
     * @returns {Feature}
     */
    reversed() {
        return new Edge(this.cubics.map(c => c.reverse()));
    }
}

class Corner extends Feature {
    /**
     * @param {Array<Cubic>} cubics
     * @param {boolean} convex
     */
    constructor(cubics, convex) {
        super(cubics);
        this.convex = convex;
        this.isIgnorableFeature = false;
        this.isEdge = false;
        this.isConvexCorner = convex;
        this.isConcaveCorner = !convex;
    }

    /**
     * @param {function(float, float): Point} f
     * @returns {Feature}
     */
    transformed(f) {
        return new Corner(this.cubics.map(c => c.transformed(f)), this.convex);
    }

    /**
     * @returns {Feature}
     */
    reversed() {
        return new Corner(this.cubics.map(c => c.reverse()), !this.convex);
    }
}