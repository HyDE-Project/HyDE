.pragma library

.import "../geometry/offset.js" as Offset

class Matrix {
    constructor(values = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]) {
        this.values = values;
    }

    get(row, column) {
        return this.values[(row * 4) + column];
    }

    set(row, column, v) {
        this.values[(row * 4) + column] = v;
    }

    /** Does the 3D transform on [point] and returns the `x` and `y` values in an [Offset]. */
    map(point) {
        if (this.values.length < 16) return point;

        const v00 = this.get(0, 0);
        const v01 = this.get(0, 1);
        const v03 = this.get(0, 3);
        const v10 = this.get(1, 0);
        const v11 = this.get(1, 1);
        const v13 = this.get(1, 3);
        const v30 = this.get(3, 0);
        const v31 = this.get(3, 1);
        const v33 = this.get(3, 3);

        const x = point.x;
        const y = point.y;
        const z = v03 * x + v13 * y + v33;
        const inverseZ = 1 / z;
        const pZ = isFinite(inverseZ) ? inverseZ : 0;

        return new Offset.Offset(pZ * (v00 * x + v10 * y + v30), pZ * (v01 * x + v11 * y + v31));
    }

    /** Multiply this matrix by [m] and assign the result to this matrix. */
    timesAssign(m) {
        const v = this.values;
        if (v.length < 16) return;
        if (m.values.length < 16) return;

        const v00 = this.dot(0, m, 0);
        const v01 = this.dot(0, m, 1);
        const v02 = this.dot(0, m, 2);
        const v03 = this.dot(0, m, 3);
        const v10 = this.dot(1, m, 0);
        const v11 = this.dot(1, m, 1);
        const v12 = this.dot(1, m, 2);
        const v13 = this.dot(1, m, 3);
        const v20 = this.dot(2, m, 0);
        const v21 = this.dot(2, m, 1);
        const v22 = this.dot(2, m, 2);
        const v23 = this.dot(2, m, 3);
        const v30 = this.dot(3, m, 0);
        const v31 = this.dot(3, m, 1);
        const v32 = this.dot(3, m, 2);
        const v33 = this.dot(3, m, 3);

        v[0] = v00;
        v[1] = v01;
        v[2] = v02;
        v[3] = v03;
        v[4] = v10;
        v[5] = v11;
        v[6] = v12;
        v[7] = v13;
        v[8] = v20;
        v[9] = v21;
        v[10] = v22;
        v[11] = v23;
        v[12] = v30;
        v[13] = v31;
        v[14] = v32;
        v[15] = v33;
    }

    dot(row, m, column) {
        return this.get(row, 0) * m.get(0, column) +
            this.get(row, 1) * m.get(1, column) +
            this.get(row, 2) * m.get(2, column) +
            this.get(row, 3) * m.get(3, column);
    }

    /** Resets the `this` to the identity matrix. */
    reset() {
        const v = this.values;
        if (v.length < 16) return;
        v[0] = 1;
        v[1] = 0;
        v[2] = 0;
        v[3] = 0;
        v[4] = 0;
        v[5] = 1;
        v[6] = 0;
        v[7] = 0;
        v[8] = 0;
        v[9] = 0;
        v[10] = 1;
        v[11] = 0;
        v[12] = 0;
        v[13] = 0;
        v[14] = 0;
        v[15] = 1;
    }

    /** Applies a [degrees] rotation around Z to `this`. */
    rotateZ(degrees) {
        if (this.values.length < 16) return;

        const r = degrees * (Math.PI / 180.0);
        const s = Math.sin(r);
        const c = Math.cos(r);

        const a00 = this.get(0, 0);
        const a10 = this.get(1, 0);
        const v00 = c * a00 + s * a10;
        const v10 = -s * a00 + c * a10;

        const a01 = this.get(0, 1);
        const a11 = this.get(1, 1);
        const v01 = c * a01 + s * a11;
        const v11 = -s * a01 + c * a11;

        const a02 = this.get(0, 2);
        const a12 = this.get(1, 2);
        const v02 = c * a02 + s * a12;
        const v12 = -s * a02 + c * a12;

        const a03 = this.get(0, 3);
        const a13 = this.get(1, 3);
        const v03 = c * a03 + s * a13;
        const v13 = -s * a03 + c * a13;

        this.set(0, 0, v00);
        this.set(0, 1, v01);
        this.set(0, 2, v02);
        this.set(0, 3, v03);
        this.set(1, 0, v10);
        this.set(1, 1, v11);
        this.set(1, 2, v12);
        this.set(1, 3, v13);
    }

    /** Scale this matrix by [x], [y], [z] */
    scale(x = 1, y = 1, z = 1) {
        if (this.values.length < 16) return;
        this.set(0, 0, this.get(0, 0) * x);
        this.set(0, 1, this.get(0, 1) * x);
        this.set(0, 2, this.get(0, 2) * x);
        this.set(0, 3, this.get(0, 3) * x);
        this.set(1, 0, this.get(1, 0) * y);
        this.set(1, 1, this.get(1, 1) * y);
        this.set(1, 2, this.get(1, 2) * y);
        this.set(1, 3, this.get(1, 3) * y);
        this.set(2, 0, this.get(2, 0) * z);
        this.set(2, 1, this.get(2, 1) * z);
        this.set(2, 2, this.get(2, 2) * z);
        this.set(2, 3, this.get(2, 3) * z);
    }

    /** Translate this matrix by [x], [y], [z] */
    translate(x = 0, y = 0, z = 0) {
        if (this.values.length < 16) return;
        const t1 = this.get(0, 0) * x + this.get(1, 0) * y + this.get(2, 0) * z + this.get(3, 0);
        const t2 = this.get(0, 1) * x + this.get(1, 1) * y + this.get(2, 1) * z + this.get(3, 1);
        const t3 = this.get(0, 2) * x + this.get(1, 2) * y + this.get(2, 2) * z + this.get(3, 2);
        const t4 = this.get(0, 3) * x + this.get(1, 3) * y + this.get(2, 3) * z + this.get(3, 3);
        this.set(3, 0, t1);
        this.set(3, 1, t2);
        this.set(3, 2, t3);
        this.set(3, 3, t4);
    }

    toString() {
        return `${this.get(0, 0)} ${this.get(0, 1)} ${this.get(0, 2)} ${this.get(0, 3)}\n` +
            `${this.get(1, 0)} ${this.get(1, 1)} ${this.get(1, 2)} ${this.get(1, 3)}\n` +
            `${this.get(2, 0)} ${this.get(2, 1)} ${this.get(2, 2)} ${this.get(2, 3)}\n` +
            `${this.get(3, 0)} ${this.get(3, 1)} ${this.get(3, 2)} ${this.get(3, 3)}`;
    }
}

// Companion object constants
Matrix.ScaleX = 0;
Matrix.SkewY = 1;
Matrix.Perspective0 = 3;
Matrix.SkewX = 4;
Matrix.ScaleY = 5;
Matrix.Perspective1 = 7;
Matrix.ScaleZ = 10;
Matrix.TranslateX = 12;
Matrix.TranslateY = 13;
Matrix.TranslateZ = 14;
Matrix.Perspective2 = 15;
