#!/usr/bin/env bash
# The icon theme named by path from the scripts has to be deployed by a dot.
#
# It is the one entry of restore_fnt.lst that was never carried over, and the
# script that read that list is called by nothing, so the theme stopped being
# deployed while the scripts kept naming it.

. "$(dirname -- "$0")/lib/common.sh"

archive="$REPO_ROOT/Source/arcs/Icon_Wallbash.tar.gz"
[ -f "$archive" ] ||
    fail "the icon theme archive is missing from the checkout"

# The tree carries the archive, never a second unpacked copy of it.
if [ -d "$REPO_ROOT/Configs/.local/share/icons/Wallbash-Icon" ]; then
    fail "the icon theme is unpacked into Configs as well as shipped as an archive"
fi

dot=$(grep -rl "Icon_Wallbash" "$REPO_ROOT/Scripts/dots" 2>/dev/null | head -n 1)
[ -n "$dot" ] ||
    fail "no dot metafile deploys the icon theme archive"

if [ -n "$dot" ]; then
    grep -q 'source *= *"Source/arcs/Icon_Wallbash.tar.gz"' "$dot" ||
        fail "$(basename "$dot") does not name the icon archive relative to the source root"
    grep -q 'target_root *= *"\${XDG_DATA_HOME}/icons/Wallbash-Icon"' "$dot" ||
        fail "$(basename "$dot") does not deploy the icon theme where the scripts look for it"
fi

# Every icon the scripts name has to be in the archive, or the deployment is
# complete and the component still reports a missing file.
listed=$(tar tzf "$archive" 2>/dev/null | sed 's#^Wallbash-Icon/##')
checked=0
while IFS= read -r wanted; do
    [ -n "$wanted" ] || continue
    checked=$((checked + 1))
    printf '%s\n' "$listed" | grep -qxF "$wanted" ||
        fail "the scripts name $wanted, which the archive does not carry"
done <<EOF
$(grep -rhoE '(iconsDir|ICONS_DIR|XDG_DATA_HOME)[^"]*/Wallbash-Icon/[A-Za-z0-9._/-]+' \
    "$REPO_ROOT/Configs/.local/lib/hyde" "$REPO_ROOT/Configs/.local/share/wallbash" 2>/dev/null |
    sed 's#.*/Wallbash-Icon/##' | grep -v '\$' |
    grep -E '\.(svg|png|icon)$' | sort -u)
EOF

# The group the installer loads has to be the one carrying that dot.
installed=$(grep -oE 'dots-groups/[A-Za-z0-9_-]+\.toml' "$REPO_ROOT/Scripts/install.sh" |
    sed 's#dots-groups/##' | sort -u)
reached=false
for group in $installed; do
    group_file="$REPO_ROOT/Scripts/dots-groups/$group"
    [ -f "$group_file" ] || continue
    while IFS= read -r included; do
        [ "$REPO_ROOT/Scripts/dots/$included" = "$dot" ] && reached=true
    done <<EOF2
$(grep -oE '"\.\./dots/[A-Za-z0-9_-]+\.toml"' "$group_file" | tr -d '"' | sed 's#\.\./dots/##')
EOF2
done
[ "$reached" = true ] ||
    fail "the icon theme dot lives in no group the installer loads"

printf '    %d icon reference(s) checked\n' "$checked"

finish
