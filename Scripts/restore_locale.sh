#!/usr/bin/env bash
# Adapts locale-dependent defaults to the running system:
#   - keyboard layout, read from 'localectl' (systemd-localed), seeded into
#     hyprland.lua once, on its first deploy only -- the file is a
#     user-preserve target afterwards, so this never touches a customised one.
#   - waybar clock time format (12h vs 24h) and date order (day/month/year
#     position), re-derived from LC_TIME on every run, since the clock
#     module is a synced (always redeployed) dot.
#   - keybindings authored against US punctuation keys (e.g. "slash" for the
#     keybindings-hint menu) are unbound and re-registered under whatever
#     symbol the physically same key produces on the detected layout, so the
#     hint overlay shows what is actually printed on the keyboard instead of
#     a hidden US reference. Regenerated in full on every run.

scrDir="$(dirname "$(realpath "$0")")"
# shellcheck disable=SC1091
if ! source "${scrDir}/global_fn.sh"; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

flg_DryRun=${flg_DryRun:-0}
confDir=${confDir:-"$HOME/.config"}
dataDir="${XDG_DATA_HOME:-$HOME/.local/share}"

kbLayout=""
if command -v localectl >/dev/null 2>&1; then
    kbLayout=$(localectl status 2>/dev/null | awk -F': ' '/X11 Layout/{print $2; exit}')
fi

# --- keyboard layout ----------------------------------------------------
hyprLua="${confDir}/hypr/hyprland.lua"
if [ -f "${hyprLua}" ] && ! grep -q "kb_layout" "${hyprLua}"; then
    if [ -n "${kbLayout}" ] && [ "${kbLayout}" != "us" ]; then
        if [ "${flg_DryRun}" -eq 1 ]; then
            print_log -y "[LOCALE] " -b "dry-run :: " "Would set kb_layout to '${kbLayout}'"
        else
            {
                echo ""
                echo "-- Auto-detected from 'localectl' on first install; edit or remove freely."
                echo "hl.config({"
                echo "	input = {"
                echo "		kb_layout = \"${kbLayout}\","
                echo "	},"
                echo "})"
            } >>"${hyprLua}"
            print_log -g "[LOCALE] " -b "keyboard :: " "kb_layout set to '${kbLayout}'"
        fi
    fi
fi

# --- clock: time format (12h vs 24h), from LC_TIME's t_fmt ----------------
clockFile="${dataDir}/waybar/modules/clock.jsonc"
if [ -f "${clockFile}" ] && command -v jq >/dev/null 2>&1; then
    timeFmt=$(locale -k LC_TIME 2>/dev/null | grep '^t_fmt=' | cut -d= -f2 | tr -d '"')
    # glibc uses %r/%T as shorthand for the 12h/24h forms on many locales
    # instead of spelling out %I/%p or %H -- match both.
    newTimeFmt="{:%I:%M %p}"
    if [[ "${timeFmt}" == *%I* || "${timeFmt}" == *%p* || "${timeFmt}" == *%r* ]]; then
        newTimeFmt="{:%I:%M %p}"
    elif [[ "${timeFmt}" == *%H* || "${timeFmt}" == *%T* || "${timeFmt}" == *%k* ]]; then
        newTimeFmt="{:%H:%M}"
    fi

    # --- clock: date order (day/month/year position), from LC_TIME's d_fmt
    dateFmt=$(locale -k LC_TIME 2>/dev/null | grep '^d_fmt=' | cut -d= -f2 | tr -d '"')
    order=""
    while read -r tok; do
        case "${tok}" in
        %d | %e) order+="d" ;;
        %m) order+="m" ;;
        %Y | %y) order+="y" ;;
        esac
    done < <(grep -oE '%[a-zA-Z]' <<<"${dateFmt}")

    newDateSeg="%d·%m·%y"
    if [ "${#order}" -eq 3 ] && [[ "${order}" == *d* && "${order}" == *m* && "${order}" == *y* ]]; then
        newDateSeg=""
        for i in 0 1 2; do
            case "${order:${i}:1}" in
            d) newDateSeg+="%d" ;;
            m) newDateSeg+="%m" ;;
            y) newDateSeg+="%y" ;;
            esac
            [ "${i}" -lt 2 ] && newDateSeg+="·"
        done
    fi

    currentFmt=$(jq -r '.clock.format // ""' "${clockFile}" 2>/dev/null)
    currentAlt=$(jq -r '.clock["format-alt"] // ""' "${clockFile}" 2>/dev/null)
    newAlt=$(jq -rn --arg alt "${currentAlt}" --arg seg "${newDateSeg}" '$alt | sub("%d·%m·%y"; $seg)')

    if [ "${currentFmt}" != "${newTimeFmt}" ] || [ "${currentAlt}" != "${newAlt}" ]; then
        if [ "${flg_DryRun}" -eq 1 ]; then
            print_log -y "[LOCALE] " -b "dry-run :: " "Would update clock time/date format"
        else
            tmp="$(mktemp)"
            if jq --arg fmt "${newTimeFmt}" --arg alt "${newAlt}" \
                '.clock.format = $fmt | .clock["format-alt"] = $alt' \
                "${clockFile}" >"${tmp}" 2>/dev/null; then
                mv "${tmp}" "${clockFile}"
                print_log -g "[LOCALE] " -b "clock :: " "time/date format matched to locale"
            else
                rm -f "${tmp}"
                print_log -warn "[LOCALE] " "Failed to update clock format in ${clockFile}"
            fi
        fi
    fi
fi

# --- keybindings: WYSIWYG remap of punctuation-triggered binds ------------
#
# Why this exists:
# key_binds.lua names bind keys by XKB keysym, e.g. `hl.bind(MOD .. " +
# slash", ...)` for the keybindings-hint menu. With a single kb_layout
# configured (what the section above sets), Hyprland resolves that keysym
# name against the *active* layout to find the physical key to bind -- and
# for letters this already does the right thing with zero help from us:
# German QWERTZ swaps Y and Z relative to US QWERTY, but "SUPER + Z" still
# resolves to whichever physical key produces "Z" on the active German
# layout, i.e. the key labelled Z. Same story for AZERTY's A/Q and W/Z
# swap. No remap needed for letters or digits on any layout, ever.
#
# Punctuation is the one place that breaks: a punctuation keysym can be
# *entirely absent* from the target layout's unshifted level, rather than
# just moved. On German, "/" isn't reachable at all next to where you'd
# expect it -- it only exists on Shift+7. Hyprland's resolution still
# "succeeds" in that case, it just lands the bind on Shift+7, which is not
# what pressing the US-equivalent physical key does. That's the actual gap
# this section closes: for every bind key that is a real XKB keysym name
# (letters/Hyprland's own aliases like "A" or "Delete" never match one, so
# they're naturally excluded, no allowlist needed), look up which physical
# key produces it on 'us' via xkbcli, then look up what that same physical
# key produces on the detected layout. Only unbind+re-register when that
# comes back different -- i.e. only ever punctuation, in practice.
#
# Regenerated in full on every run into a HyDE-owned file; never edit
# locale_remap.lua by hand, it will be overwritten.
keyBindsFile="${dataDir}/hypr/lua/key_binds.lua"
remapFile="${confDir}/hypr/locale_remap.lua"
if [ -f "${keyBindsFile}" ] && [ -f "${hyprLua}" ] && command -v xkbcli >/dev/null 2>&1 &&
    [ -n "${kbLayout}" ] && [ "${kbLayout}" != "us" ]; then

    # gawk-specific: \s and the 3-arg match(..., array) form. Called
    # explicitly rather than via plain 'awk', since a non-GNU awk provider
    # (mawk, BusyBox) would silently return nothing here.
    xkb_code_sym_pairs() {
        xkbcli compile-keymap --layout "$1" 2>/dev/null | gawk '
            /^\s*key <[A-Z0-9]+>\s*\{/ {
                match($0, /<([A-Z0-9]+)>/, c); match($0, /\[\s*([A-Za-z0-9_]+)/, s)
                if (c[1] != "" && s[1] != "") print c[1], s[1]
            }'
    }

    declare -A usSym2Code=() tgtCode2Sym=()
    while read -r code sym; do
        [ -n "${code}" ] && usSym2Code["${sym}"]="${code}"
    done < <(xkb_code_sym_pairs us)
    while read -r code sym; do
        [ -n "${code}" ] && tgtCode2Sym["${code}"]="${sym}"
    done < <(xkb_code_sym_pairs "${kbLayout}")

    remaps=()
    while read -r triggerName; do
        [[ "${triggerName}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || continue
        code="${usSym2Code[${triggerName}]:-}"
        [ -n "${code}" ] || continue
        tgtSym="${tgtCode2Sym[${code}]:-}"
        [ -n "${tgtSym}" ] || continue
        [ "${tgtSym}" = "${triggerName}" ] && continue
        remaps+=("${triggerName}:${tgtSym}")
    done < <(grep -oE 'MOD \.\. " \+ [^"]+"' "${keyBindsFile}" | sed -E 's/.*\+ //; s/"$//' | awk '{print $NF}' | sort -u)

    # All unbinds run before any bind: if one pair's target symbol equals a
    # later pair's source symbol, interleaving them would let a later
    # unbind remove the earlier pair's freshly-registered bind.
    unbindLines=""
    bindLines=""
    for pair in "${remaps[@]}"; do
        us="${pair%%:*}"
        tgt="${pair##*:}"
        while read -r lineno; do
            bindLine=$(sed -n "${lineno}p" "${keyBindsFile}")
            descLine=$(sed -n "$((lineno - 1))p" "${keyBindsFile}")
            [[ "${descLine}" == _F\ =\ * ]] || continue
            combo="${bindLine#*MOD .. \"}"
            combo="${combo%%\"*}"
            newBindLine="${bindLine/+ ${us}\"/+ ${tgt}\"}"
            unbindLines+="hl.unbind(MOD .. \"${combo}\")"$'\n'
            bindLines+="${descLine}"$'\n'
            bindLines+="${newBindLine}"$'\n\n'
        done < <(grep -nF "+ ${us}\"" "${keyBindsFile}" | cut -d: -f1)
    done
    remapBody="${unbindLines}${unbindLines:+$'\n'}${bindLines}"

    if [ -n "${remapBody}" ]; then
        newRemapFile=$(
            echo "-- Auto-generated by Scripts/restore_locale.sh -- do not edit, it is"
            echo "-- overwritten on every restore. Remaps US-authored punctuation binds"
            echo "-- to the physically same key on the '${kbLayout}' layout."
            echo "local MOD = hyde.config.modifiers.main"
            echo ""
            printf '%s' "${remapBody}"
        )

        if [ ! -f "${remapFile}" ] || [ "$(cat "${remapFile}" 2>/dev/null)" != "${newRemapFile}" ]; then
            if [ "${flg_DryRun}" -eq 1 ]; then
                print_log -y "[LOCALE] " -b "dry-run :: " "Would remap keybinds for '${kbLayout}': ${remaps[*]}"
            else
                printf '%s\n' "${newRemapFile}" >"${remapFile}"
                print_log -g "[LOCALE] " -b "keybinds :: " "remapped for '${kbLayout}': ${remaps[*]}"
            fi
        fi

        if ! grep -q 'check_require("locale_remap")' "${hyprLua}"; then
            if [ "${flg_DryRun}" -ne 1 ]; then
                {
                    echo ""
                    echo "-- Loads Scripts/restore_locale.sh's generated keybind remap, if any."
                    echo "check_require(\"locale_remap\")"
                } >>"${hyprLua}"
            fi
        fi
    fi
fi

# --- waybar modules: translate tooltip/text strings via the same locale --
# json shutils/l10n.sh (bash) and pyutils/wrapper/libnotify.py (Python)
# already read -- one file, every runtime including this one goes through
# it, no separate module-string dictionary to keep in sync.
#
# Every module under .local/share/waybar/modules is a synced dot (deez
# redeploys it from the repo template on every restore, same as
# clock.jsonc above), so translation has to happen here, post-deploy.
# Deliberately generic: every quoted string *value* anywhere in a module
# file that exactly matches a locale/<lang>.json key is swapped for its
# translation -- a new module or a newly-translated string needs no
# change here, only a de.json entry.
#
# This is text substitution on the raw file, not a JSON-parse-then-dump
# round trip, on purpose: several modules are genuine JSONC (line
# comments, e.g. bluetooth.jsonc), which a strict parser -- jq included --
# refuses to load at all. A regex finds every "..." token and only
# replaces it if it is *not* immediately followed by a colon: that is
# the one condition that always means "this token is a JSON object key,
# not a value" (custom-mediaplayer.jsonc's "next"/"previous" keys must
# stay put; group-mediaplayer.jsonc's "next"/"previous" *values* are
# exactly what's meant to be translated). Comments, formatting and
# trailing commas outside of a translated token are left untouched.
#
# Same DESKTOP_LANG detection as shutils/l10n.sh -- duplicated rather than
# sourced, since that file lives under the deployed .local/lib/hyde tree,
# not anywhere reachable from Scripts/ by a stable relative path.
_desktopLang="${LC_ALL:-${LANG:-en}}"
_desktopLang="${_desktopLang:0:2}"
_desktopLang="${_desktopLang,,}"
[[ "${_desktopLang}" == "c" || "${_desktopLang}" == "po" ]] && _desktopLang="en"
localeJsonFile="${dataDir}/hyde/locale/${_desktopLang}.json"
waybarModulesDir="${dataDir}/waybar/modules"
waybarMenusDir="${dataDir}/waybar/menus"
if [ -f "${localeJsonFile}" ] && [ -d "${waybarModulesDir}" ] && command -v python3 >/dev/null 2>&1; then
    python3 - "${localeJsonFile}" "${waybarModulesDir}" "${waybarMenusDir}" "${flg_DryRun}" <<'PYEOF'
import glob
import json
import os
import re
import sys

locale_path, modules_dir, menus_dir, dry_run = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4] == "1"

with open(locale_path, encoding="utf-8") as f:
    translations = json.load(f)

token_re = re.compile(r'"(?:[^"\\]|\\.)*"')
# Waybar's own display-text fields, only -- not every field that happens
# to hold a string. Scoping this way is what keeps a short, generic de.json
# entry (input for the wallbash mode picker, say "auto") from also
# matching an unrelated *config* value that happens to be the identical
# literal, e.g. cava.jsonc's "source": "auto" (an enum cava itself
# requires verbatim, not display text -- translating it would silently
# break auto source detection instead of translating anything visible).
DISPLAY_FIELDS_RE = re.compile(r"^(text|format-alt|tooltip(-format)?.*)$")
key_re = re.compile(r'"([a-zA-Z0-9_-]+)"\s*:\s*$')


def translate_json_strings(content: str) -> str:
    # A quoted token not immediately followed by a colon is a value,
    # never a key -- JSON syntax has no other way to write "key": that a
    # value could be confused with. Checked *after* matching, against the
    # untouched original text, and not as a lookahead baked into the
    # regex: a lookahead that disqualifies a match makes re's scanner
    # retry one character later, landing inside the rejected token and
    # matching garbage through to some unrelated later quote.
    out = []
    last = 0
    for m in token_re.finditer(content):
        out.append(content[last : m.start()])
        raw = m.group(0)
        is_key = bool(re.match(r"\s*:", content[m.end() :]))
        if not is_key:
            key_match = key_re.search(content[:m.start()])
            field = key_match.group(1) if key_match else ""
            if DISPLAY_FIELDS_RE.match(field):
                try:
                    value = json.loads(raw)
                except json.JSONDecodeError:
                    value = None
                translated = translations.get(value) if value is not None else None
                if translated is not None:
                    raw = json.dumps(translated, ensure_ascii=False)
        out.append(raw)
        last = m.end()
    out.append(content[last:])
    return "".join(out)


paths = sorted(glob.glob(os.path.join(modules_dir, "*.json")) + glob.glob(os.path.join(modules_dir, "*.jsonc")))
for path in paths:
    with open(path, encoding="utf-8") as f:
        content = f.read()
    new_content = translate_json_strings(content)
    if new_content == content:
        continue
    name = os.path.basename(path)
    if dry_run:
        print(f"DRY:{name}")
    else:
        with open(path, "w", encoding="utf-8") as f:
            f.write(new_content)
        print(f"OK:{name}")

# Waybar right-click menus (custom-hyde-menu.jsonc and friends point a
# "menu-file" at one of these): a separate GtkBuilder XML format, whose
# <property name="label">...</property> elements are unambiguously
# display text -- no key/value distinction to make here, unlike the JSON
# modules above.
label_re = re.compile(r'(<property name="label">)((?:(?!</property>).)*)(</property>)')


def translate_xml_labels(content: str) -> str:
    def replace(m: re.Match) -> str:
        translated = translations.get(m.group(2))
        return m.group(1) + (translated if translated is not None else m.group(2)) + m.group(3)

    return label_re.sub(replace, content)


for path in sorted(glob.glob(os.path.join(menus_dir, "*.xml"))):
    with open(path, encoding="utf-8") as f:
        content = f.read()
    new_content = translate_xml_labels(content)
    if new_content == content:
        continue
    name = os.path.basename(path)
    if dry_run:
        print(f"DRY:{name}")
    else:
        with open(path, "w", encoding="utf-8") as f:
            f.write(new_content)
        print(f"OK:{name}")
PYEOF
fi | while IFS=: read -r status name; do
    case "${status}" in
    DRY) print_log -y "[LOCALE] " -b "dry-run :: " "Would translate ${name}" ;;
    OK) print_log -g "[LOCALE] " -b "waybar :: " "translated ${name}" ;;
    esac
done
