#!/usr/bin/env sh
# restore_locale.sh's 12h->24h swap (hyprlock) and locale-format blanking
# (SDDM theme.conf) are plain sed one-liners with no coverage elsewhere.
# This exercises the exact patterns against every known preset shape rather
# than the whole locale-detection pipeline, which depends on which locales
# happen to be generated on the machine running the suite.

. "$(dirname -- "$0")/lib/common.sh"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# --- hyprlock: %I/%-I (+ optional ":%M" and " %p") -> %H, other tokens untouched
hyprlock_sed() {
    sed -E 's/%-?I(:%M)?( %p)?/%H\1/g'
}

check_hyprlock() {
    input=$1
    expected=$2
    got=$(printf '%s' "$input" | hyprlock_sed)
    [ "$got" = "$expected" ] || fail "hyprlock swap: '$input' -> '$got', expected '$expected'"
}

check_hyprlock 'date +"%I"' 'date +"%H"'
check_hyprlock 'date +"%-I:%M %p"' 'date +"%H:%M"'
check_hyprlock 'date +"%I:%M %p"' 'date +"%H:%M"'
check_hyprlock 'date +"%I:%M"' 'date +"%H:%M"'
check_hyprlock 'date +"%A, %B %d - %I:%M %p"' 'date +"%A, %B %d - %H:%M"'
check_hyprlock 'date +"%H"' 'date +"%H"' # already 24h: untouched
check_hyprlock 'date +%H | awk ...' 'date +%H | awk ...' # already 24h: untouched

# --- SDDM: HourFormat=/DateFormat= blanked regardless of prior value
sddm_sed() {
    sed -E 's/^(HourFormat=).*/\1""/; s/^(DateFormat=).*/\1""/'
}

conf="$tmp/theme.conf"
cat >"$conf" <<'EOF'
[General]
Locale=""
HourFormat="hh:mm A"
DateFormat="dddd, d of MMMM"
EOF
sddm_sed <"$conf" >"$conf.out"
grep -qx 'HourFormat=""' "$conf.out" || fail "SDDM HourFormat was not blanked"
grep -qx 'DateFormat=""' "$conf.out" || fail "SDDM DateFormat was not blanked"
grep -qx 'Locale=""' "$conf.out" || fail "SDDM sed touched an unrelated key"

# --- waybar: date-order segment re-detected regardless of which order a
# previous run (under a different locale) left it in, not just the shipped
# default's "%d·%m·%y" literal.
if command -v jq >/dev/null 2>&1; then
    check_date_order() {
        alt=$1
        seg=$2
        expected=$3
        got=$(jq -rn --arg alt "$alt" --arg seg "$seg" '$alt | sub("%[dmy]·%[dmy]·%[dmy]"; $seg)')
        [ "$got" = "$expected" ] || fail "date-order resub: '$alt' with seg '$seg' -> '$got', expected '$expected'"
    }

    check_date_order '{:%R X %d·%m·%y}' '%d·%m·%y' '{:%R X %d·%m·%y}'
    # the actual bug: a prior run already left the segment in a different
    # order (e.g. after a 12h/US locale ran once) -- must still be found.
    check_date_order '{:%R X %m·%d·%y}' '%d·%m·%y' '{:%R X %d·%m·%y}'
else
    skip "jq is not installed"
fi

finish
