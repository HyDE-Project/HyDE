.pragma library

.import "shapes/point.js" as Point
.import "shapes/rounded-polygon.js" as RoundedPolygon
.import "shapes/corner-rounding.js" as CornerRounding
.import "geometry/offset.js" as Offset
.import "graphics/matrix.js" as Matrix

var _circle = null
var _square = null
var _slanted = null
var _arch = null
var _fan = null
var _arrow = null
var _semiCircle = null
var _oval = null
var _pill = null
var _triangle = null
var _diamond = null
var _clamShell = null
var _pentagon = null
var _gem = null
var _verySunny = null
var _sunny = null
var _cookie4Sided = null
var _cookie6Sided = null
var _cookie7Sided = null
var _cookie9Sided = null
var _cookie12Sided = null
var _ghostish = null
var _clover4Leaf = null
var _clover8Leaf = null
var _burst = null
var _softBurst = null
var _boom = null
var _softBoom = null
var _flower = null
var _puffy = null
var _puffyDiamond = null
var _pixelCircle = null
var _pixelTriangle = null
var _bun = null
var _heart = null

var cornerRound15 = new CornerRounding.CornerRounding(0.15)
var cornerRound20 = new CornerRounding.CornerRounding(0.2)
var cornerRound30 = new CornerRounding.CornerRounding(0.3)
var cornerRound50 = new CornerRounding.CornerRounding(0.5)
var cornerRound100 = new CornerRounding.CornerRounding(1.0)

var rotateNeg30 = new Matrix.Matrix();
rotateNeg30.rotateZ(-30);
var rotateNeg45 = new Matrix.Matrix();
rotateNeg45.rotateZ(-45);
var rotateNeg90 = new Matrix.Matrix();
rotateNeg90.rotateZ(-90);
var rotateNeg135 = new Matrix.Matrix();
rotateNeg135.rotateZ(-135);
var rotate30 = new Matrix.Matrix();
rotate30.rotateZ(30);
var rotate45 = new Matrix.Matrix();
rotate45.rotateZ(45);
var rotate60 = new Matrix.Matrix();
rotate60.rotateZ(60);
var rotate90 = new Matrix.Matrix();
rotate90.rotateZ(90);
var rotate120 = new Matrix.Matrix();
rotate120.rotateZ(120);
var rotate135 = new Matrix.Matrix();
rotate135.rotateZ(135);
var rotate180 = new Matrix.Matrix();
rotate180.rotateZ(180);

var rotate28th = new Matrix.Matrix();
rotate28th.rotateZ(360/28);
var rotateNeg16th = new Matrix.Matrix();
rotateNeg16th.rotateZ(-360/16);

function getCircle() {
    if (_circle !== null) return _circle;
    _circle = circle();
    return _circle;
}

function getSquare() {
    if (_square !== null) return _square;
    _square = square();
    return _square;
}

function getSlanted() {
    if (_slanted !== null) return _slanted;
    _slanted = slanted();
    return _slanted;
}

function getArch() {
    if (_arch !== null) return _arch;
    _arch = arch();
    return _arch;
}

function getFan() {
    if (_fan !== null) return _fan;
    _fan = fan();
    return _fan;
}

function getArrow() {
    if (_arrow !== null) return _arrow;
    _arrow = arrow();
    return _arrow;
}

function getSemiCircle() {
    if (_semiCircle !== null) return _semiCircle;
    _semiCircle = semiCircle();
    return _semiCircle;
}

function getOval() {
    if (_oval !== null) return _oval;
    _oval = oval();
    return _oval;
}

function getPill() {
    if (_pill !== null) return _pill;
    _pill = pill();
    return _pill;
}

function getTriangle() {
    if (_triangle !== null) return _triangle;
    _triangle = triangle();
    return _triangle;
}

function getDiamond() {
    if (_diamond !== null) return _diamond;
    _diamond = diamond();
    return _diamond;
}

function getClamShell() {
    if (_clamShell !== null) return _clamShell;
    _clamShell = clamShell();
    return _clamShell;
}

function getPentagon() {
    if (_pentagon !== null) return _pentagon;
    _pentagon = pentagon();
    return _pentagon;
}

function getGem() {
    if (_gem !== null) return _gem;
    _gem = gem();
    return _gem;
}

function getSunny() {
    if (_sunny !== null) return _sunny;
    _sunny = sunny();
    return _sunny;
}

function getVerySunny() {
    if (_verySunny !== null) return _verySunny;
    _verySunny = verySunny();
    return _verySunny;
}

function getCookie4Sided() {
    if (_cookie4Sided !== null) return _cookie4Sided;
    _cookie4Sided = cookie4();
    return _cookie4Sided;
}

function getCookie6Sided() {
    if (_cookie6Sided !== null) return _cookie6Sided;
    _cookie6Sided = cookie6();
    return _cookie6Sided;
}

function getCookie7Sided() {
    if (_cookie7Sided !== null) return _cookie7Sided;
    _cookie7Sided = cookie7();
    return _cookie7Sided;
}

function getCookie9Sided() {
    if (_cookie9Sided !== null) return _cookie9Sided;
    _cookie9Sided = cookie9();
    return _cookie9Sided;
}

function getCookie12Sided() {
    if (_cookie12Sided !== null) return _cookie12Sided;
    _cookie12Sided = cookie12();
    return _cookie12Sided;
}

function getGhostish() {
    if (_ghostish !== null) return _ghostish;
    _ghostish = ghostish();
    return _ghostish;
}

function getClover4Leaf() {
    if (_clover4Leaf !== null) return _clover4Leaf;
    _clover4Leaf = clover4();
    return _clover4Leaf;
}

function getClover8Leaf() {
    if (_clover8Leaf !== null) return _clover8Leaf;
    _clover8Leaf = clover8();
    return _clover8Leaf;
}

function getBurst() {
    if (_burst !== null) return _burst;
    _burst = burst();
    return _burst;
}

function getSoftBurst() {
    if (_softBurst !== null) return _softBurst;
    _softBurst = softBurst();
    return _softBurst;
}

function getBoom() {
    if (_boom !== null) return _boom;
    _boom = boom();
    return _boom;
}

function getSoftBoom() {
    if (_softBoom !== null) return _softBoom;
    _softBoom = softBoom();
    return _softBoom;
}

function getFlower() {
    if (_flower !== null) return _flower;
    _flower = flower();
    return _flower;
}

function getPuffy() {
    if (_puffy !== null) return _puffy;
    _puffy = puffy();
    return _puffy;
}

function getPuffyDiamond() {
    if (_puffyDiamond !== null) return _puffyDiamond;
    _puffyDiamond = puffyDiamond();
    return _puffyDiamond;
}

function getPixelCircle() {
    if (_pixelCircle !== null) return _pixelCircle;
    _pixelCircle = pixelCircle();
    return _pixelCircle;
}

function getPixelTriangle() {
    if (_pixelTriangle !== null) return _pixelTriangle;
    _pixelTriangle = pixelTriangle();
    return _pixelTriangle;
}

function getBun() {
    if (_bun !== null) return _bun;
    _bun = bun();
    return _bun;
}

function getHeart() {
    if (_heart !== null) return _heart;
    _heart = heart();
    return _heart;
}

function circle() {
    return RoundedPolygon.RoundedPolygon.circle(10)
        .transformed((x, y) => rotate45.map(new Offset.Offset(x, y)))
        .normalized();
}

function square() {
    return RoundedPolygon.RoundedPolygon.rectangle(1, 1, cornerRound30).normalized();
}

function slanted() {
    return customPolygon([
        new PointNRound(new Offset.Offset(0.926, 0.970), new CornerRounding.CornerRounding(0.189, 0.811)),
        new PointNRound(new Offset.Offset(-0.021, 0.967), new CornerRounding.CornerRounding(0.187, 0.057)),
    ], 2).normalized();
}

function arch() {
    return RoundedPolygon.RoundedPolygon.rectangle(1, 1, CornerRounding.Unrounded, [cornerRound20, cornerRound20, cornerRound100, cornerRound100])
        .normalized();
}

function fan() {
    return customPolygon([
        new PointNRound(new Offset.Offset(1.004, 1.000), new CornerRounding.CornerRounding(0.148, 0.417)),
        new PointNRound(new Offset.Offset(0.000, 1.000), new CornerRounding.CornerRounding(0.151)),
        new PointNRound(new Offset.Offset(0.000, -0.003), new CornerRounding.CornerRounding(0.148)),
        new PointNRound(new Offset.Offset(0.978, 0.020), new CornerRounding.CornerRounding(0.803)),
    ], 1).normalized();
}

function arrow() {
    return customPolygon([
        new PointNRound(new Offset.Offset(1.225, 1.060), new CornerRounding.CornerRounding(0.211)),
        new PointNRound(new Offset.Offset(0.500, 0.892), new CornerRounding.CornerRounding(0.313)),
        new PointNRound(new Offset.Offset(-0.216, 1.050), new CornerRounding.CornerRounding(0.207)),
        new PointNRound(new Offset.Offset(0.499, -0.160), new CornerRounding.CornerRounding(0.215, 1.000)),
    ], 1).normalized();
}

function semiCircle() {
    return RoundedPolygon.RoundedPolygon.rectangle(1.6, 1, CornerRounding.Unrounded, [cornerRound20, cornerRound20, cornerRound100, cornerRound100]).normalized();
}

function oval() {
    const scaleMatrix = new Matrix.Matrix();
    scaleMatrix.scale(1, 0.64);
    return RoundedPolygon.RoundedPolygon.circle()
        .transformed((x, y) => rotateNeg90.map(new Offset.Offset(x, y)))
        .transformed((x, y) => scaleMatrix.map(new Offset.Offset(x, y)))
        .transformed((x, y) => rotate135.map(new Offset.Offset(x, y)))
        .normalized();
}

function pill() {
    return customPolygon([
        // new PointNRound(new Offset.Offset(0.609, 0.000), new CornerRounding.CornerRounding(1.000)),
        new PointNRound(new Offset.Offset(0.428, -0.001), new CornerRounding.CornerRounding(0.426)),
        new PointNRound(new Offset.Offset(0.961, 0.039), new CornerRounding.CornerRounding(0.426)),
        new PointNRound(new Offset.Offset(1.001, 0.428)),
        new PointNRound(new Offset.Offset(1.000, 0.609), new CornerRounding.CornerRounding(1.000)),
    ], 2)
        .transformed((x, y) => rotate180.map(new Offset.Offset(x, y)))
        .normalized();
}

function triangle() {
    return RoundedPolygon.RoundedPolygon.fromNumVertices(3, 1, 0.5, 0.5, cornerRound20)
        .transformed((x, y) => rotate30.map(new Offset.Offset(x, y)))
        .normalized()
}

function diamond() {
    return customPolygon([
        new PointNRound(new Offset.Offset(0.500, 1.096), new CornerRounding.CornerRounding(0.151, 0.524)),
        new PointNRound(new Offset.Offset(0.040, 0.500), new CornerRounding.CornerRounding(0.159)),
    ], 2).normalized();
}

function clamShell() {
    return customPolygon([
        new PointNRound(new Offset.Offset(0.829, 0.841), new CornerRounding.CornerRounding(0.159)),
        new PointNRound(new Offset.Offset(0.171, 0.841), new CornerRounding.CornerRounding(0.159)),
        new PointNRound(new Offset.Offset(-0.020, 0.500), new CornerRounding.CornerRounding(0.140)),
    ], 2).normalized();
}

function pentagon() {
    return customPolygon([
        new PointNRound(new Offset.Offset(0.828, 0.970), new CornerRounding.CornerRounding(0.169)),
        new PointNRound(new Offset.Offset(0.172, 0.970), new CornerRounding.CornerRounding(0.169)),
        new PointNRound(new Offset.Offset(-0.030, 0.365), new CornerRounding.CornerRounding(0.164)),
        new PointNRound(new Offset.Offset(0.500, -0.009), new CornerRounding.CornerRounding(0.172)),
        new PointNRound(new Offset.Offset(1.030, 0.365), new CornerRounding.CornerRounding(0.164)),
    ], 1).normalized();
}

function gem() {
    return customPolygon([
        new PointNRound(new Offset.Offset(1.005, 0.792), new CornerRounding.CornerRounding(0.208)),
        new PointNRound(new Offset.Offset(0.5, 1.023), new CornerRounding.CornerRounding(0.241, 0.778)),
        new PointNRound(new Offset.Offset(-0.005, 0.792), new CornerRounding.CornerRounding(0.208)),
        new PointNRound(new Offset.Offset(0.073, 0.258), new CornerRounding.CornerRounding(0.228)),
        new PointNRound(new Offset.Offset(0.5, 0.000), new CornerRounding.CornerRounding(0.241, 0.778)),
        new PointNRound(new Offset.Offset(0.927, 0.258), new CornerRounding.CornerRounding(0.228)),
    ], 1).normalized();
}

function sunny() {
    return RoundedPolygon.RoundedPolygon.star(8, 1, 0.8, cornerRound15)
        .transformed((x, y) => rotate45.map(new Offset.Offset(x, y)))
        .normalized();
}

function verySunny() {
    return customPolygon([
        new PointNRound(new Offset.Offset(0.500, 1.080), new CornerRounding.CornerRounding(0.085)),
        new PointNRound(new Offset.Offset(0.358, 0.843), new CornerRounding.CornerRounding(0.085)),
    ], 8)
        .transformed((x, y) => rotateNeg45.map(new Offset.Offset(x, y)))
        .normalized();
}

function cookie4() {
    return customPolygon([
        new PointNRound(new Offset.Offset(1.237, 1.236), new CornerRounding.CornerRounding(0.258)),
        new PointNRound(new Offset.Offset(0.500, 0.918), new CornerRounding.CornerRounding(0.233)),
    ], 4).normalized();
}

function cookie6() {
    return customPolygon([
        new PointNRound(new Offset.Offset(0.723, 0.884), new CornerRounding.CornerRounding(0.394)),
        new PointNRound(new Offset.Offset(0.500, 1.099), new CornerRounding.CornerRounding(0.398)),
    ], 6).normalized();
}

function cookie7() {
    return RoundedPolygon.RoundedPolygon.star(7, 1, 0.75, cornerRound50)
        .normalized()
        .transformed((x, y) => rotate28th.map(new Offset.Offset(x, y)))
        .transformed((x, y) => rotate28th.map(new Offset.Offset(x, y)))
        .transformed((x, y) => rotate28th.map(new Offset.Offset(x, y)))
        .transformed((x, y) => rotate28th.map(new Offset.Offset(x, y)))
        .transformed((x, y) => rotate28th.map(new Offset.Offset(x, y)))
        .normalized();
}

function cookie9() {
    return RoundedPolygon.RoundedPolygon.star(9, 1, 0.8, cornerRound50)
        .transformed((x, y) => rotate30.map(new Offset.Offset(x, y)))
        .normalized();
}

function cookie12() {
    return RoundedPolygon.RoundedPolygon.star(12, 1, 0.8, cornerRound50)
        .transformed((x, y) => rotate30.map(new Offset.Offset(x, y)))
        .normalized();
}

function ghostish() {
    return customPolygon([
        new PointNRound(new Offset.Offset(1.000, 1.140), new CornerRounding.CornerRounding(0.254, 0.106)),
        new PointNRound(new Offset.Offset(0.575, 0.906), new CornerRounding.CornerRounding(0.253)),
        new PointNRound(new Offset.Offset(0.425, 0.906), new CornerRounding.CornerRounding(0.253)),
        new PointNRound(new Offset.Offset(0.000, 1.140), new CornerRounding.CornerRounding(0.254, 0.106)),
        new PointNRound(new Offset.Offset(0.000, 0.000), new CornerRounding.CornerRounding(1.0)),
        new PointNRound(new Offset.Offset(0.500, 0.000), new CornerRounding.CornerRounding(1.0)),
        new PointNRound(new Offset.Offset(1.000, 0.000), new CornerRounding.CornerRounding(1.0)),
    ], 1).normalized();
}

function clover4() {
    return customPolygon([
        new PointNRound(new Offset.Offset(1.099, 0.725), new CornerRounding.CornerRounding(0.476)),
        new PointNRound(new Offset.Offset(0.725, 1.099), new CornerRounding.CornerRounding(0.476)),
        new PointNRound(new Offset.Offset(0.500, 0.926)),
    ], 4).normalized();
}

function clover8() {
    return customPolygon([
        new PointNRound(new Offset.Offset(0.758, 1.101), new CornerRounding.CornerRounding(0.209)),
        new PointNRound(new Offset.Offset(0.500, 0.964)),
    ], 8).normalized();
}

function burst() {
    return customPolygon([
        new PointNRound(new Offset.Offset(0.592, 0.842), new CornerRounding.CornerRounding(0.006)),
        new PointNRound(new Offset.Offset(0.500, 1.006), new CornerRounding.CornerRounding(0.006)),
    ], 12)
        .transformed((x, y) => rotateNeg30.map(new Offset.Offset(x, y)))
        .transformed((x, y) => rotateNeg30.map(new Offset.Offset(x, y)))
        .normalized();
}

function softBurst() {
    return customPolygon([
        new PointNRound(new Offset.Offset(0.193, 0.277), new CornerRounding.CornerRounding(0.053)),
        new PointNRound(new Offset.Offset(0.176, 0.055), new CornerRounding.CornerRounding(0.053)),
    ], 10)
        .transformed((x, y) => rotate180.map(new Offset.Offset(x, y)))
        .normalized();
}

function boom() {
    return customPolygon([
        new PointNRound(new Offset.Offset(0.457, 0.296), new CornerRounding.CornerRounding(0.007)),
        new PointNRound(new Offset.Offset(0.500, -0.051), new CornerRounding.CornerRounding(0.007)),
    ], 15)
        .transformed((x, y) => rotate120.map(new Offset.Offset(x, y)))
        .normalized();
}

function softBoom() {
    return customPolygon([
        new PointNRound(new Offset.Offset(0.733, 0.454)),
        new PointNRound(new Offset.Offset(0.839, 0.437), new CornerRounding.CornerRounding(0.532)),
        new PointNRound(new Offset.Offset(0.949, 0.449), new CornerRounding.CornerRounding(0.439, 1.000)),
        new PointNRound(new Offset.Offset(0.998, 0.478), new CornerRounding.CornerRounding(0.174)),
        // mirrored points
        new PointNRound(new Offset.Offset(0.998, 0.522), new CornerRounding.CornerRounding(0.174)),
        new PointNRound(new Offset.Offset(0.949, 0.551), new CornerRounding.CornerRounding(0.439, 1.000)),
        new PointNRound(new Offset.Offset(0.839, 0.563), new CornerRounding.CornerRounding(0.532)),
        new PointNRound(new Offset.Offset(0.733, 0.546)),
    ], 16)
        .transformed((x, y) => rotate45.map(new Offset.Offset(x, y)))
        .transformed((x, y) => rotateNeg16th.map(new Offset.Offset(x, y)))
        .normalized();
}

function flower() {
    return customPolygon([
        new PointNRound(new Offset.Offset(0.370, 0.187)),
        new PointNRound(new Offset.Offset(0.416, 0.049), new CornerRounding.CornerRounding(0.381)),
        new PointNRound(new Offset.Offset(0.479, 0.001), new CornerRounding.CornerRounding(0.095)),
        // mirrored points
        new PointNRound(new Offset.Offset(0.521, 0.001), new CornerRounding.CornerRounding(0.095)),
        new PointNRound(new Offset.Offset(0.584, 0.049), new CornerRounding.CornerRounding(0.381)),
        new PointNRound(new Offset.Offset(0.630, 0.187)),
    ], 8)
        .transformed((x, y) => rotate135.map(new Offset.Offset(x, y)))
        .normalized();
}

function puffy() {
    const m = new Matrix.Matrix();
    m.scale(1, 0.742);
    const shape = customPolygon([
        // mirrored points
        new PointNRound(new Offset.Offset(1.003, 0.563), new CornerRounding.CornerRounding(0.255)),
        new PointNRound(new Offset.Offset(0.940, 0.656), new CornerRounding.CornerRounding(0.126)),
        new PointNRound(new Offset.Offset(0.881, 0.654)),
        new PointNRound(new Offset.Offset(0.926, 0.711), new CornerRounding.CornerRounding(0.660)),
        new PointNRound(new Offset.Offset(0.914, 0.851), new CornerRounding.CornerRounding(0.660)),
        new PointNRound(new Offset.Offset(0.777, 0.998), new CornerRounding.CornerRounding(0.360)),
        new PointNRound(new Offset.Offset(0.722, 0.872)),
        new PointNRound(new Offset.Offset(0.717, 0.934), new CornerRounding.CornerRounding(0.574)),
        new PointNRound(new Offset.Offset(0.670, 1.035), new CornerRounding.CornerRounding(0.426)),
        new PointNRound(new Offset.Offset(0.545, 1.040), new CornerRounding.CornerRounding(0.405)),
        new PointNRound(new Offset.Offset(0.500, 0.947)),
        // original points
        new PointNRound(new Offset.Offset(0.500, 1-0.053)),
        new PointNRound(new Offset.Offset(1-0.545, 1+0.040), new CornerRounding.CornerRounding(0.405)),
        new PointNRound(new Offset.Offset(1-0.670, 1+0.035), new CornerRounding.CornerRounding(0.426)),
        new PointNRound(new Offset.Offset(1-0.717, 1-0.066), new CornerRounding.CornerRounding(0.574)),
        new PointNRound(new Offset.Offset(1-0.722, 1-0.128)),
        new PointNRound(new Offset.Offset(1-0.777, 1-0.002), new CornerRounding.CornerRounding(0.360)),
        new PointNRound(new Offset.Offset(1-0.914, 1-0.149), new CornerRounding.CornerRounding(0.660)),
        new PointNRound(new Offset.Offset(1-0.926, 1-0.289), new CornerRounding.CornerRounding(0.660)),
        new PointNRound(new Offset.Offset(1-0.881, 1-0.346)),
        new PointNRound(new Offset.Offset(1-0.940, 1-0.344), new CornerRounding.CornerRounding(0.126)),
        new PointNRound(new Offset.Offset(1-1.003, 1-0.437), new CornerRounding.CornerRounding(0.255)),
    ], 2);
    return shape.transformed((x, y) => m.map(new Offset.Offset(x, y))).normalized();
}

function puffyDiamond() {
    return customPolygon([
        // original points
        new PointNRound(new Offset.Offset(0.870, 0.130), new CornerRounding.CornerRounding(0.146)),
        new PointNRound(new Offset.Offset(0.818, 0.357)),
        new PointNRound(new Offset.Offset(1.000, 0.332), new CornerRounding.CornerRounding(0.853)),
        // mirrored points
        new PointNRound(new Offset.Offset(1.000, 1-0.332), new CornerRounding.CornerRounding(0.853)),
        new PointNRound(new Offset.Offset(0.818, 1-0.357)),
    ], 4)
        .transformed((x, y) => rotate90.map(new Offset.Offset(x, y)))
        .normalized();
}

function pixelCircle() {
    return customPolygon([
        new PointNRound(new Offset.Offset(1.000, 0.704)),
        new PointNRound(new Offset.Offset(0.926, 0.704)),
        new PointNRound(new Offset.Offset(0.926, 0.852)),
        new PointNRound(new Offset.Offset(0.843, 0.852)),
        new PointNRound(new Offset.Offset(0.843, 0.935)),
        new PointNRound(new Offset.Offset(0.704, 0.935)),
        new PointNRound(new Offset.Offset(0.704, 1.000)),
        new PointNRound(new Offset.Offset(0.500, 1.000)),
        new PointNRound(new Offset.Offset(1-0.704, 1.000)),
        new PointNRound(new Offset.Offset(1-0.704, 0.935)),
        new PointNRound(new Offset.Offset(1-0.843, 0.935)),
        new PointNRound(new Offset.Offset(1-0.843, 0.852)),
        new PointNRound(new Offset.Offset(1-0.926, 0.852)),
        new PointNRound(new Offset.Offset(1-0.926, 0.704)),
        new PointNRound(new Offset.Offset(1-1.000, 0.704)),
    ], 2)
        .normalized();
}

function pixelTriangle() {
    return customPolygon([
        // mirrored points
        new PointNRound(new Offset.Offset(0.888, 1-0.439)),
        new PointNRound(new Offset.Offset(0.789, 1-0.439)),
        new PointNRound(new Offset.Offset(0.789, 1-0.344)),
        new PointNRound(new Offset.Offset(0.675, 1-0.344)),
        new PointNRound(new Offset.Offset(0.674, 1-0.265)),
        new PointNRound(new Offset.Offset(0.560, 1-0.265)),
        new PointNRound(new Offset.Offset(0.560, 1-0.170)),
        new PointNRound(new Offset.Offset(0.421, 1-0.170)),
        new PointNRound(new Offset.Offset(0.421, 1-0.087)),
        new PointNRound(new Offset.Offset(0.287, 1-0.087)),
        new PointNRound(new Offset.Offset(0.287, 1-0.000)),
        new PointNRound(new Offset.Offset(0.113, 1-0.000)),
        // original points
        new PointNRound(new Offset.Offset(0.110, 0.500)),
        new PointNRound(new Offset.Offset(0.113, 0.000)),
        new PointNRound(new Offset.Offset(0.287, 0.000)),
        new PointNRound(new Offset.Offset(0.287, 0.087)),
        new PointNRound(new Offset.Offset(0.421, 0.087)),
        new PointNRound(new Offset.Offset(0.421, 0.170)),
        new PointNRound(new Offset.Offset(0.560, 0.170)),
        new PointNRound(new Offset.Offset(0.560, 0.265)),
        new PointNRound(new Offset.Offset(0.674, 0.265)),
        new PointNRound(new Offset.Offset(0.675, 0.344)),
        new PointNRound(new Offset.Offset(0.789, 0.344)),
        new PointNRound(new Offset.Offset(0.789, 0.439)),
        new PointNRound(new Offset.Offset(0.888, 0.439)),
    ], 1).normalized();
}

function bun() {
    return customPolygon([
        // original points
        new PointNRound(new Offset.Offset(0.796, 0.500)),
        new PointNRound(new Offset.Offset(0.853, 0.518), cornerRound100),
        new PointNRound(new Offset.Offset(0.992, 0.631), cornerRound100),
        new PointNRound(new Offset.Offset(0.968, 1.000), cornerRound100), 
        // mirrored points
        new PointNRound(new Offset.Offset(0.032, 1-0.000), cornerRound100),
        new PointNRound(new Offset.Offset(0.008, 1-0.369), cornerRound100),
        new PointNRound(new Offset.Offset(0.147, 1-0.482), cornerRound100),
        new PointNRound(new Offset.Offset(0.204, 1-0.500)),
    ], 2).normalized();
}

function heart() {
    return customPolygon([
        new PointNRound(new Offset.Offset(0.782, 0.611)),
        new PointNRound(new Offset.Offset(0.499, 0.946), new CornerRounding.CornerRounding(0.000)),
        new PointNRound(new Offset.Offset(0.2175, 0.611)),
        new PointNRound(new Offset.Offset(-0.064, 0.276), new CornerRounding.CornerRounding(1.000)),
        new PointNRound(new Offset.Offset(0.208, -0.066), new CornerRounding.CornerRounding(0.958)),
        new PointNRound(new Offset.Offset(0.500, 0.268), new CornerRounding.CornerRounding(0.016)),
        new PointNRound(new Offset.Offset(0.792, -0.066), new CornerRounding.CornerRounding(0.958)),
        new PointNRound(new Offset.Offset(1.064, 0.276), new CornerRounding.CornerRounding(1.000)),
    ], 1)
        .normalized();
}

class PointNRound {
    constructor(o, r = CornerRounding.Unrounded) {
        this.o = o;
        this.r = r;
    }
}

function doRepeat(points, reps, center, mirroring) {
    if (mirroring) {
        const result = [];
        const angles = points.map(p => p.o.minus(center).angleDegrees());
        const distances = points.map(p => p.o.minus(center).getDistance());
        const actualReps = reps * 2;
        const sectionAngle = 360 / actualReps;
        for (let it = 0; it < actualReps; it++) {
            for (let index = 0; index < points.length; index++) {
                const i = (it % 2 === 0) ? index : points.length - 1 - index;
                if (i > 0 || it % 2 === 0) {
                    const baseAngle = angles[i];
                    const angle = it * sectionAngle + (it % 2 === 0 ? baseAngle : (2 * angles[0] - baseAngle));
                    const dist = distances[i];
                    const rad = angle * Math.PI / 180;
                    const x = center.x + dist * Math.cos(rad);
                    const y = center.y + dist * Math.sin(rad);
                    result.push(new PointNRound(new Offset.Offset(x, y), points[i].r));
                }
            }
        }
        return result;
    } else {
        const np = points.length;
        const result = [];
        for (let i = 0; i < np * reps; i++) {
            const point = points[i % np].o.rotateDegrees(Math.floor(i / np) * 360 / reps, center);
            result.push(new PointNRound(point, points[i % np].r));
        }
        return result;
    }
}

function customPolygon(pnr, reps = 1, center = new Offset.Offset(0.5, 0.5), mirroring = false) {
    const actualPoints = doRepeat(pnr, reps, center, mirroring);
    const vertices = [];
    for (const p of actualPoints) {
        vertices.push(p.o.x);
        vertices.push(p.o.y);
    }
    const perVertexRounding = actualPoints.map(p => p.r);
    return RoundedPolygon.RoundedPolygon.fromVertices(vertices, CornerRounding.Unrounded, perVertexRounding, center.x, center.y);
}
