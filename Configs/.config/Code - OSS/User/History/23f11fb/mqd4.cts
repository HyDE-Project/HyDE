/*
 * Type Definitions for Gjs (https://gjs.guide/)
 *
 * These type definitions are automatically generated, do not edit them by hand.
 * If you found a bug fix it in ts-for-gir itself or create a bug report on https://github.com/gjsify/ts-for-gir
 */
import './ambient.d.ts';

import type GObject from '@girs/gobject-2.0';
import type GLib from '@girs/glib-2.0';
import gettext from './gettext.js';
import system from './system.js';
import cairo from './cairo.js';

// https://gitlab.gnome.org/GNOME/gjs/-/blob/1.72.0/modules/script/package.js
declare namespace package {
    /**
     * Although there are references in the documentation of more properties that
     * this object should accepts, only the following are actually used in the init code,
     * and all the other have their values derived from them.
     */
    interface PackageInitParams {
        name: string
        version: string
        prefix: string
        libdir: string
    }

    export const name: string | undefined
    export const version: string | undefined
    export const prefix: string | undefined
    export const datadir: string | undefined
    export const libdir: string | undefined
    export const pkgdatadir: string | undefined
    export const pkglibdir: string | undefined
    export const moduledir: string | undefined
    export const localedir: string | undefined

    export function init(params: PackageInitParams): void
    export function run(module: { main: (argv: string[]) => void }): void
    /** shortcut to init+run */
    export function start(params: PackageInitParams): void
    export function require(libs: Record<string, string>): void
    export function requireSymbol(lib: string, ver: string, symbol: string): void
    export function checkSymbol(lib: string, ver: string, symbol: string): void
    export function initGettext(): void
    /** @deprecated Use JS string interpolation */
    export function initFormat(): void
    export function initSubmodule(module: string): void
}

declare namespace byteArray {
    export class ByteArray {
        static get(target: any, property: string, receiver: any): any
        static set(target: any, property: string, value: any, receiver: any): boolean

        length: number
        protected _array: Uint8Array

        constructor(x: Uint8Array | number)
        toString(encoding?: TextDecoderEncoding): string
        fromString(input: string, encoding?: TextDecoderEncoding): ByteArray
        toGBytes(): GLib.Bytes
    }

    /** @deprecated Use {@link TextEncoder.encode} instead */
    export function fromString(input: string, encoding?: TextDecoderEncoding): Uint8Array

    /** @deprecated Use {@link GLib.Bytes.toArray} instead */
    export function fromGBytes(input: GLib.Bytes): Uint8Array

    /** @deprecated Use {@link TextDecoder.decode} instead */
    export function toString(x: Uint8Array, encoding?: TextDecoderEncoding): string

    /** @deprecated Use {@link GLib.Bytes new GLib.Bytes() } instead */
    export function toGBytes(x: Uint8Array): GLib.Bytes

    /** @deprecated Use {@link ByteArray new ByteArray()} instead */
    export function fromArray(array: Iterable<number>): ByteArray
}

declare namespace lang {
    // TODO: There is a lot more in Lang
    export function Class(props: any): void

    export function bind(area: DrawingArea<{ lastImmediateActiveWs: number; immediateActiveWs: number; initialized: boolean; workspaceMask: number; workspaceGroup: number; updateMask: (self: any) => void; toggleMask: (self: any, occupied: any, name: any) => void; }>, arg1: (area: any, cr: any) => void): (self: import("types/widgets/drawingarea.js").DrawingArea<{ lastImmediateActiveWs: number; immediateActiveWs: number; initialized: boolean; workspaceMask: number; workspaceGroup: number; updateMask: (self: any) => void; toggleMask: (self: any, occupied: any, name: any) => void; }>, ...args: any[]) => void {
        throw new Error('Function not implemented.');
    }
}

declare namespace format {
    export function vprintf(str: string, args: string[]): string
    export function printf(fmt: string, ...args: any[]): void
    // Following docs from gjs/modules/format.js
    /**
     * This function is intended to extend the String object and provide
     * an String.format API for string formatting.
     * It has to be set up using String.prototype.format = Format.format;
     * Usage:
     * "somestring %s %d".format('hello', 5);
     * It supports %s, %d, %x and %f, for %f it also support precisions like
     * "%.2f".format(1.526). All specifiers can be prefixed with a minimum
     * field width, e.g. "%5s".format("foo"). Unless the width is prefixed
     * with '0', the formatted string will be padded with spaces.
     */
    export function format(fmt: string, ...args: any[]): string
}

declare namespace mainloop {
    export function quit(name: string): void
    export function idle_source(handler: any, priority?: number): any
    export function idle_add(handler: any, priority?: number): any
    export function timeout_source(timeout: any, handler: any, priority?: number): any
    export function timeout_seconds_source(timeout: any, handler: any, priority?: number): any
    export function timeout_add(timeout: any, handler: any, priority?: number): any
    export function timeout_add_seconds(timeout: any, handler: any, priority?: number): any
    export function source_remove(id: any): any
    export function run(name: string): void
}

/**
 * You can use the `Signals.addSignalMethods` method to apply the `Signals` convenience methods to an `Object`.
 * Generally, this is called on an object prototype, but may also be called on an object instance.
 * You can use this Interface for this object or prototype to make the methods in typescript known
 * @example
 * ```ts
 * const Signals = imports.signals;
 * 
 * // Define an interface with the same name of your class to make the methods known
 * interface Events extends Signals.Methods {}
 * 
 * class Events {}
 * Signals.addSignalMethods(Events.prototype);
 * 
 * const events = new Events();
 * 
 * // Typescript will not complain here
 * events.emit("test-signal", "test argument");
 * ```
 */
export interface SignalMethods {
    /**
     * Connects a callback to a signal for an object. Pass the returned ID to
     * `disconnect()` to remove the handler.
     * 
     * If `callback` returns `true`, emission will stop and no other handlers will be
     * invoked.
     * 
     * > Warning: Unlike GObject signals, `this` within a signal callback will always
     * > refer to the global object (ie. `globalThis`).
     * 
     * @param sigName A signal name
     * @param callback A callback function
     * @returns A handler ID
     */
    connect(sigName: string, callback: (self: any, ...args: any[]) => void): number;
    /**
     * Emits a signal for an object. Emission stops if a signal handler returns `true`.
     * 
     * Unlike GObject signals, it is not necessary to declare signals or define their
     * signature. Simply call `emit()` with whatever signal name you wish, with
     * whatever arguments you wish.
     * @param sigName A signal name
     * @param args Any number of arguments, of any type
     */
    emit(sigName: string, ...args: any[]): void;
    /**
     * Disconnects a handler for a signal.
     * @param id The ID of the handler to be disconnected
     */
    disconnect(id: number): void;
    /**
     * Disconnects all signal handlers for an object.
     */
    disconnectAll(): void
    /**
     * Checks if a handler ID is connected.
     * @param id The ID of the handler to be disconnected
     * @returns `true` if connected, or `false` if not
     */
    signalHandlerIsConnected(id: number): boolean;
}

declare namespace signals {
    export function addSignalMethods<T = any>(proto: T): proto is T & SignalMethods;
}

declare global {

    // https://gitlab.gnome.org/GNOME/gjs/-/blob/1.73.2/modules/esm/_encoding/encodingMap.js#L7-232
    type TextDecoderEncoding =
        | 'unicode-1-1-utf-8'
        | 'unicode11utf8'
        | 'unicode20utf8'
        | 'utf-8'
        | 'utf8'
        | 'x-unicode20utf8'
        | '866'
        | 'cp866'
        | 'csibm866'
        | 'ibm866'
        | 'csisolatin2'
        | 'iso-8859-2'
        | 'iso-ir-101'
        | 'iso8859-2'
        | 'iso88592'
        | 'iso_8859-2'
        | 'iso_8859-2:1987'
        | 'l2'
        | 'latin2'
        | 'csisolatin3'
        | 'iso-8859-3'
        | 'iso-ir-109'
        | 'iso8859-3'
        | 'iso88593'
        | 'iso_8859-3'
        | 'iso_8859-3:1988'
        | 'l3'
        | 'latin3'
        | 'csisolatin4'
        | 'iso-8859-4'
        | 'iso-ir-110'
        | 'iso8859-4'
        | 'iso88594'
        | 'iso_8859-4'
        | 'iso_8859-4:1988'
        | 'l4'
        | 'latin4'
        | 'csisolatincyrillic'
        | 'cyrillic'
        | 'iso-8859-5'
        | 'iso-ir-144'
        | 'iso8859-5'
        | 'iso88595'
        | 'iso_8859-5'
        | 'iso_8859-5:1988'
        | 'arabic'
        | 'asmo-708'
        | 'csiso88596e'
        | 'csiso88596i'
        | 'csisolatinarabic'
        | 'ecma-114'
        | 'iso-8859-6'
        | 'iso-8859-6-e'
        | 'iso-8859-6-i'
        | 'iso-ir-127'
        | 'iso8859-6'
        | 'iso88596'
        | 'iso_8859-6'
        | 'iso_8859-6:1987'
        | 'csisolatingreek'
        | 'ecma-118'
        | 'elot_928'
        | 'greek'
        | 'greek8'
        | 'iso-8859-7'
        | 'iso-ir-126'
        | 'iso8859-7'
        | 'iso88597'
        | 'iso_8859-7'
        | 'iso_8859-7:1987'
        | 'sun_eu_greek'
        | 'csiso88598e'
        | 'csisolatinhebrew'
        | 'hebrew'
        | 'iso-8859-8'
        | 'iso-8859-8-e'
        | 'iso-ir-138'
        | 'iso8859-8'
        | 'iso88598'
        | 'iso_8859-8'
        | 'iso_8859-8:1988'
        | 'visual'
        | 'csiso88598i'
        | 'iso-8859-8-i'
        | 'logical'
        | 'csisolatin6'
        | 'iso-8859-10'
        | 'iso-ir-157'
        | 'iso8859-10'
        | 'iso885910'
        | 'l6'
        | 'latin6'
        | 'iso-8859-13'
        | 'iso8859-13'
        | 'iso885913'
        | 'iso-8859-14'
        | 'iso8859-14'
        | 'iso885914'
        | 'csisolatin9'
        | 'iso-8859-15'
        | 'iso8859-15'
        | 'iso885915'
        | 'iso_8859-15'
        | 'l9'
        | 'iso-8859-16'
        | 'cskoi8r'
        | 'koi'
        | 'koi8'
        | 'koi8-r'
        | 'koi8_r'
        | 'koi8-ru'
        | 'koi8-u'
        | 'csmacintosh'
        | 'mac'
        | 'macintosh'
        | 'x-mac-roman'
        | 'dos-874'
        | 'iso-8859-11'
        | 'iso8859-11'
        | 'iso885911'
        | 'tis-620'
        | 'windows-874'
        | 'cp1250'
        | 'windows-1250'
        | 'x-cp1250'
        | 'cp1251'
        | 'windows-1251'
        | 'x-cp1251'
        | 'ansi_x3.4-1968'
        | 'ascii'
        | 'cp1252'
        | 'cp819'
        | 'csisolatin1'
        | 'ibm819'
        | 'iso-8859-1'
        | 'iso-ir-100'
        | 'iso8859-1'
        | 'iso88591'
        | 'iso_8859-1'
        | 'iso_8859-1:1987'
        | 'l1'
        | 'latin1'
        | 'us-ascii'
        | 'windows-1252'
        | 'x-cp1252'
        | 'cp1253'
        | 'windows-1253'
        | 'x-cp1253'
        | 'cp1254'
        | 'csisolatin5'
        | 'iso-8859-9'
        | 'iso-ir-148'
        | 'iso8859-9'
        | 'iso88599'
        | 'iso_8859-9'
        | 'iso_8859-9:1989'
        | 'l5'
        | 'latin5'
        | 'windows-1254'
        | 'x-cp1254'
        | 'cp1255'
        | 'windows-1255'
        | 'x-cp1255'
        | 'cp1256'
        | 'windows-1256'
        | 'x-cp1256'
        | 'cp1257'
        | 'windows-1257'
        | 'x-cp1257'
        | 'cp1258'
        | 'windows-1258'
        | 'x-cp1258'
        | 'x-mac-cyrillic'
        | 'x-mac-ukrainian'
        | 'chinese'
        | 'csgb2312'
        | 'csiso58gb231280'
        | 'gb2312'
        | 'gb_2312'
        | 'gb_2312-80'
        | 'gbk'
        | 'iso-ir-58'
        | 'x-gbk'
        | 'gb18030'
        | 'big5'
        | 'cn-big5'
        | 'csbig5'
        | 'x-x-big5'
        | 'cseucpkdfmtjapanese'
        | 'euc-jp'
        | 'x-euc-jp'
        | 'csiso2022jp'
        | 'iso-2022-jp'
        | 'csshiftjis'
        | 'ms932'
        | 'ms_kanji'
        | 'shift-jis'
        | 'shift_jis'
        | 'sjis'
        | 'windows-31j'
        | 'x-sjis'
        | 'cseuckr'
        | 'csksc56011987'
        | 'euc-kr'
        | 'iso-ir-149'
        | 'korean'
        | 'ks_c_5601-1987'
        | 'ks_c_5601-1989'
        | 'ksc5601'
        | 'ksc_5601'
        | 'windows-949'
        | 'unicodefffe'
        | 'utf-16be'
        | 'csunicode'
        | 'iso-10646-ucs-2'
        | 'ucs-2'
        | 'unicode'
        | 'unicodefeff'
        | 'utf-16'
        | 'utf-16le'

    interface GjsGiImports {
        // Will be extended by the import of more gir types
        versions: {
            [namespace: string]: string
        }
    }
    
    interface GjsImports {
        gi: GjsGiImports
        lang: typeof lang
        system: typeof system
        signals: typeof signals
        package: typeof package
        mainloop: typeof mainloop
        searchPath: string[]
        gettext: typeof gettext
        byteArray: typeof byteArray
        format: typeof format
        cairo: typeof cairo
    }

    function print(...args: any[]): void
    function printerr(...args: any[]): void
    function log(message: any): void
    function logError(exception: object, message?: any): void
    function logError(message?: any): void

    const pkg: typeof package

    interface BooleanConstructor {
        $gtype: GObject.GType<boolean>
    }

    interface NumberConstructor {
        $gtype: GObject.GType<number>
    }

    interface StringConstructor {
        $gtype: GObject.GType<string>
    }

    const imports: GjsImports

    const ARGV: string[]
}

declare const _imports: GjsImports
export default _imports
export { _imports as imports }


