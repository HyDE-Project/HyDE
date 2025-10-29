#!/usr/bin/env sh

N='
'
OIFS=$IFS
RSEP=$(printf '%b' '\036')
USEP=$(printf '%b' '\037')
TERMINAL_HANDLER=xdg-terminal-exec
SELF_NAME=${0##*/}

# Treat non-zero exit status from simple commands as an error
# Treat unset variables as errors when performing parameter expansion
# Disable pathname expansion
set -euf

shcat() {
    while IFS='' read -r line; do
        printf '%s\n' "$line"
    done
}

usage() {
    shcat <<-EOF
		Usage:
		  $SELF_NAME \\
		    [-h | --help]
		    [-s a|b|s|custom.slice] \\$(
        case "$SELF_NAME" in
        *-scope | *-service) true ;;
        *)
            printf '\n'
            # shellcheck disable=SC1003
            printf '    %s\n' '[-t scope|service] \'
            ;;
        esac
    )
		    [{-a app_name | -u unit_id}] \\
		    [-d description] \\
		    [-S {out|err|both}] \\
		    [{-c|-C}] \\
		    [-T] \\$(
        case "$SELF_NAME" in
        *-open | *-open-scope | *-open-service) true ;;
        *)
            printf '\n'
            # shellcheck disable=SC1003
            printf '    %s\n' '[-O | --open ] \'
            ;;
        esac
    )
		    [--fuzzel-compat] \\
		    [--test] \\
		    [--] $(
        case "$SELF_NAME" in
        *-open | *-open-scope | *-open-service) printf '%s\n' '{file|URL ...}' ;;
        *-term | *-terminal | *-term-scope | *-terminal-scope | *-term-service | *-terminal-service)
            printf '%s\n' '[entry-id.desktop | entry-id.desktop:action-id | command] [args ...]'
            ;;
        *)
            printf '%s\n' '{entry-id.desktop | entry-id.desktop:action-id | command} [args ...]'
            ;;
        esac
    )
	EOF
}

help() {
    shcat <<-EOF
		$SELF_NAME - Application launcher, file opener, default terminal launcher
		for systemd environments.

		Launches applications from Desktop Entries or arbitrary
		command lines, as systemd user scopes or services.

		$(usage)

		Options:

		  -s a|b|s|custom.slice
		    Select slice among short references:
		    a=app.slice b=background.slice s=session.slice
		    Or set slice explicitly.
		    Default and short references can be preset via APP2UNIT_SLICES env var in
		    the format above.

		  -t scope|service
		    Type of unit to launch. Can be preselected via APP2UNIT_TYPE env var and
		    if \$0 ends with '-scope' or '-service'.

		  -a app_name
		    Override substring of Unit ID representing application name.
		    Defaults to Entry ID without extension, or executable name.

		  -u unit_id
		    Override the whole Unit ID. Must match type. Defaults to recommended
		    templates:
		      app-\${desktop}-\${app_name}@\${random}.service
		      app-\${desktop}-\${app_name}-\${random}.scope

		  -d description
		    Set/override unit description. By default description is generated from
		    Entry's "Name=" and "GenericName=" keys.

	EOF
    case "$SELF_NAME" in
    *-term | *-terminal | *-term-scope | *-terminal-scope | *-term-service | *-terminal-service) true ;;
    *)
        shcat <<-EOF
			  -T
			    Force launch in terminal (${TERMINAL_HANDLER} is used). Any unknown option
			    starting with '-' after this will be passed to ${TERMINAL_HANDLER}.
			    Command may be omitted to just launch default terminal.
			    This mode can also be selected if \$0 ends with '-term' or '-terminal',
			    also optionally followed by '-scope' or '-service' unit type suffixes.

		EOF
        ;;
    esac
    shcat <<-EOF
		  -S out|err|both
		    Silence stdout stderr or both.

		  -c
		    Do not add graphical-session.target dependency and ordering.
		    Also can be preset with APP2UNIT_PART_OF_GST=false.

		  -C
		    Add graphical-session.target dependency and ordering.
		    Also can be preset with APP2UNIT_PART_OF_GST=true.

	EOF
    case "$SELF_NAME" in
    *-open | *-open-scope | *-open-service) true ;;
    *)
        shcat <<-EOF
			  -O | --open (also selected by default if \$0 ends with '-open')
			    Opener mode: argument(s) are treated as file(s) or URL(s) to open.
			    Desktop Entry for them is found via xdg-mime. Only single association
			    is supported.
			    This mode can also be selected if \$0 ends with '-open', also optionally
			    followed by '-scope' or '-service' unit type suffixes.

			  --fuzzel-compat
			    For using in fuzzel like this:
			      fuzzel --launch-prefix='app2unit --fuzzel-compat --'

		EOF
        ;;
    esac

    shcat <<-EOF
		  --test
		    Do not run anything, print command.

		  --
		    Disambiguate command from options.

	EOF

    case "$SELF_NAME" in
    *-open | *-open-scope | *-open-service)
        shcat <<-EOF
			File(s)|URL(s):

			  Objects to query xdg-mime for associations and open. The only
			  restriction is: all given objects should have the same association.
		EOF
        ;;
    *)
        shcat <<-EOF
			Desktop Entry or Command:

			  Use Desktop Entry ID, optionally suffixed with Action ID:
			    entry-id.desktop
			    entry-id.desktop:action-id
			  Arguments should be supported by Desktop Entry.

			  Or use a custom command, arguments will be passed as is.
		EOF
        ;;
    esac
}

error() {
    # Print messages to stderr, send notification (only first arg) if stderr is not interactive
    printf '%s\n' "$@" >&2
    # if notify-send is installed and stderr is not a terminal, also send notification
    if [ ! -t 2 ] && command -v notify-send >/dev/null; then
        notify-send -u critical -i error -a "${SELF_NAME}" "Error" "$1"
    fi
}

message() {
    # Print messages to stdout, send notification (only first arg) if stdout is not interactive
    printf '%s\n' "$@"
    # if notify-send is installed and stdout is not a terminal, also send notification
    if [ ! -t 1 ] && command -v notify-send >/dev/null; then
        notify-send -u normal -i info -a "${SELF_NAME}" "Info" "$1"
    fi
}

check_bool() {
    case "$1" in
    true | True | TRUE | yes | Yes | YES | 1) return 0 ;;
    false | False | FALSE | no | No | NO | 0) return 1 ;;
    *)
        error "Assuming '$1' means no"
        return 1
        ;;
    esac
}

# Utility function to print debug messages to stderr (or not)
if check_bool "${DEBUG-0}"; then
    debug() {
        # print each arg at new line, prefix each printed line with 'D: '
        while IFS='' read -r debug_line; do
            printf 'D: %s\n' "$debug_line"
        done <<-EOF >&2
			$(printf '%s\n' "$@")
		EOF
    }
else
    debug() { :; }
fi

replace() {
    # takes $1, replaces $2 with $3
    # does it in large chunks
    # writes result to global REPLACED_STR to avoid $() newline issues

    # right part of string
    r_remainder=${1}
    REPLACED_STR=
    while [ -n "$r_remainder" ]; do
        # left part before first encounter of $2
        r_left=${r_remainder%%"$2"*}
        # append
        REPLACED_STR=${REPLACED_STR}$r_left
        case "$r_left" in
        # nothing left to cut
        "$r_remainder") break ;;
        esac
        # append replace substring
        REPLACED_STR=${REPLACED_STR}$3
        # cut remainder
        r_remainder=${r_remainder#*"$2"}
    done
}

make_paths() {
    # constructs normalized APPLICATIONS_DIRS
    IFS=':'
    APPLICATIONS_DIRS=''
    # Populate list of directories to search for entries in, in descending order of preference
    for dir in ${XDG_DATA_HOME:-${HOME}/.local/share}${IFS}${XDG_DATA_DIRS:-/usr/local/share:/usr/share}; do
        # Normalise base path and append the data subdirectory with a trailing '/'
        APPLICATIONS_DIRS=${APPLICATIONS_DIRS:+${APPLICATIONS_DIRS}${IFS}}${dir%/}/applications/
    done
}
# Mask IFS change
alias make_paths='IFS= make_paths'

find_entry() {
    # finds entry by ID
    ENTRY_ID=$1

    # start assembling find args
    set --
    OIFS=$IFS
    IFS=':'

    # Append application directory paths to be searched
    IFS=':'
    for directory in $APPLICATIONS_DIRS; do
        # Append '.' to delimit start of Entry ID
        set -- "$@" "$directory".
    done

    # Find all files
    set -- "$@" -type f

    # Append path conditions per directory
    or_arg=''
    for directory in $APPLICATIONS_DIRS; do
        # Match full path with proper first character of Entry ID and .desktop extension
        # Reject paths with invalid characters in Entry ID
        set -- "$@" ${or_arg} '(' -path "$directory"'./[a-zA-Z0-9_]*.desktop' ! -path "$directory"'./*[^a-zA-Z0-9_./-]*' ')'
        or_arg='-o'
    done

    # iterate over found paths
    IFS=$OIFS
    while read -r entry_path <&3; do
        # raw drop or parse and separate data dir path from entry
        case "$entry_path" in
        # empties, just in case
        '' | */./) continue ;;
        # subdir, also replace / with -
        */./*/*)
            replace "${entry_path#*/./}" "/" "-"
            entry_id=$REPLACED_STR
            ;;
        # normal separation
        */./*) entry_id=${entry_path#*/./} ;;
        esac
        # check ID
        case "$entry_id" in
        "$ENTRY_ID")
            printf '%s' "$entry_path"
            return 0
            ;;
        esac
    done 3<<-EOP
		$(find -L "$@" 2>/dev/null)
	EOP

    error "Could not find entry '$ENTRY_ID'!"
    return 1
}
alias find_entry='IFS= find_entry'

de_expand_str() {
    # expands \s, \n, \t, \r, \\
    # https://specifications.freedesktop.org/desktop-entry-spec/latest/value-types.html
    # writes result to global $EXPANDED_STR in place to avoid $() expansion newline issues
    debug "expander received: $1"
    EXPANDED_STR=
    exp_remainder=$1
    while [ -n "$exp_remainder" ]; do
        # left is substring of remainder before the first encountered backslash
        exp_left=${exp_remainder%%\\*}

        # append left to EXPANDED_STR
        EXPANDED_STR=${EXPANDED_STR}${exp_left}
        debug "expander appended: $exp_left"

        case "$exp_left" in
        "$exp_remainder")
            debug "expander ended: $EXPANDED_STR"
            # no more backslashes left
            break
            ;;
        esac

        # remove left substring and backslash from remainder
        exp_remainder=${exp_remainder#"$exp_left"\\}

        case "$exp_remainder" in
        # expand and append to EXPANDED_STR
        s*)
            EXPANDED_STR=${EXPANDED_STR}' '
            exp_remainder=${exp_remainder#?}
            debug "expander substituted space"
            ;;
        n*)
            EXPANDED_STR=${EXPANDED_STR}$N
            exp_remainder=${exp_remainder#?}
            debug "expander substituted newline"
            ;;
        t*)
            EXPANDED_STR=${EXPANDED_STR}'	'
            exp_remainder=${exp_remainder#?}
            debug "expander substituted tab"
            ;;
        r*)
            EXPANDED_STR=${EXPANDED_STR}$(printf '%b' '\r')
            exp_remainder=${exp_remainder#?}
            debug "expander substituted caret return"
            ;;
        \\*)
            EXPANDED_STR=${EXPANDED_STR}\\
            exp_remainder=${exp_remainder#?}
            debug "expander substituted backslash"
            ;;
        # unsupported sequence, reappend backslash
        #*)
        #	EXPANDED_STR=${EXPANDED_STR}\\
        #	debug 'expander reappended backslash'
        #	;;
        esac
    done
}

de_tokenize_exec() {
    # Shell-based DE Exec string tokenizer.
    # https://specifications.freedesktop.org/desktop-entry-spec/latest/exec-variables.html
    # How hard can it be?
    # Fills global EXEC_USEP var with $USEP-separated command array in place to avoid $() expansion newline issues
    debug "tokenizer received: $1"
    EXEC_USEP=
    tok_remainder=$1
    tok_quoted=0
    tok_in_space=0
    while [ -n "$tok_remainder" ]; do
        # left is substring of remainder before the first encountered special char
        tok_left=${tok_remainder%%[[:space:]\"\`\$\\\'\>\<\~\|\&\;\*\?\#\(\)]*}

        # left should be safe to append right away
        EXEC_USEP=${EXEC_USEP}${tok_left}
        debug "tokenizer appended: >$tok_left<"

        # end of the line
        case "$tok_remainder" in
        "$tok_left")
            debug "tokenizer is out of special chars"
            break
            ;;
        esac

        # isolate special char
        tok_remainder=${tok_remainder#"$tok_left"}
        cut=${tok_remainder#?}
        tok_char=${tok_remainder%"$cut"}
        unset cut
        # cut it from remainder
        tok_remainder=${tok_remainder#"$tok_char"}

        # check if still in space
        case "${tok_in_space}${tok_left}${tok_char}" in
        1[[:space:]])
            debug "tokenizer still in space :) skipping space character"
            continue
            ;;
        1*)
            debug "tokenizer no longer in space :("
            tok_in_space=0
            ;;
        esac

        ## decide what to do with the character
        # doublequote while quoted
        case "${tok_quoted}${tok_char}" in
        '1"')
            tok_quoted=0
            debug "tokenizer closed double quotes"
            continue
            ;;
        # doublequote while unquoted
        '0"')
            tok_quoted=1
            debug "tokenizer opened double quotes"
            continue
            ;;
        # error out on unquoted special chars
        0[\`\$\\\'\>\<\~\|\&\;\*\?\#\(\)])
            error "${ENTRY_ID}: Encountered unquoted character: '$tok_char'"
            return 1
            ;;
        # error out on quoted but unescaped chars
        1[\`\$])
            error "${ENTRY_ID}: Encountered unescaped quoted character: '$tok_char'"
            return 1
            ;;
        # process quoted escapes
        1\\)
            case "$tok_remainder" in
            # if there is no next char, fail
            '')
                error "${ENTRY_ID}: Dangling backslash encountered!"
                return 1
                ;;
            # cut and append the next char right away
            # or a half of multibyte char, the other half should go into the next
            # 'tok_left' hopefully...
            *)
                cut=${tok_remainder#?}
                tok_char=${tok_remainder%"$cut"}
                tok_remainder=${cut}
                unset cut
                EXEC_USEP=${EXEC_USEP}${tok_char}
                debug "tokenizer appended escaped: >$tok_char<"
                ;;
            esac
            ;;
        # Consider Cosmos
        0[[:space:]])
            case "${tok_remainder}" in
            # there is non-space to follow
            *[![:space:]]*)
                # append separator
                EXEC_USEP=${EXEC_USEP}${USEP}
                tok_in_space=1
                debug "tokenizer entered spaaaaaace!!!! separator appended"
                ;;
            # ignore unquoted space at the end of string
            *)
                debug "tokenizer entered outer spaaaaaace!!!! separator skipped, this is the end"
                break
                ;;
            esac
            ;;
        # append quoted chars
        1[[:space:]\'\>\<\~\|\&\;\*\?\#\(\)])
            EXEC_USEP=${EXEC_USEP}${tok_char}
            debug "tokenizer appended quoted char: >$tok_char<"
            ;;
        # this should not happen
        *)
            error "${ENTRY_ID}: parsing error at char '$tok_char', (quoted: $tok_quoted)"
            return 1
            ;;
        esac
    done
    case "$tok_quoted" in
    1)
        error "${ENTRY_ID}: Double quote was not closed!"
        return 1
        ;;
    esac
    # shellcheck disable=SC2086
    debug "tokenizer ended:" "$(
        IFS=$USEP
        printf '  >%s<\n' $EXEC_USEP
    )"
}

de_inject_fields() {
    # Operates on argument array and $EXEC_RSEP_USEP from entry
    # modifies $EXEC_RSEP_USEP according to args/fields
    # no arguments, erase fields from $EXEC_RSEP_USEP
    exec_usep=''
    fu_found=false
    exec_iter_usep=''
    IFS=$USEP
    for arg in $EXEC_RSEP_USEP; do
        case "$arg" in
        # remove deprecated fields
        *[!%]'%'[dDnNvm]* | '%'[dDnNvm]*) debug "injector removed deprecated '$arg'" ;;
        # treat file fields
        *[!%]'%'[fFuU]* | '%'[fFuU]*)
            case "$fu_found" in
            true)
                error "${ENTRY_ID}: Encountered more than one %[fFuU] field!"
                return 1
                ;;
            esac
            fu_found=true
            if [ "$#" -eq "0" ]; then
                debug "injector removed '$arg'"
                continue
            fi
            case "$arg" in
            *[!%]'%F'* | *'%F'?* | *[!%]'%U'* | *'%U'?*)
                error "${ENTRY_ID}: Encountered non-standalone field '$arg'"
                return 1
                ;;
            *[!%]'%f'* | '%f'*)
                for carg in "$@"; do
                    replace "$arg" "%f" "$carg"
                    carg=$REPLACED_STR
                    debug "injector adding '$arg' iteration as '$carg'"
                    exec_iter_usep=${exec_iter_usep}${exec_iter_usep:+$USEP}${carg}
                done
                # placeholder arg
                exec_usep=${exec_usep}${exec_usep:+$USEP}%%__ITER__%%
                ;;
            '%F')
                for carg in "$@"; do
                    debug "injector extending '$arg' with '$carg'"
                    exec_usep=${exec_usep}${exec_usep:+$USEP}${carg}
                done
                ;;
            *[!%]'%u'* | '%u'*)
                for carg in "$@"; do
                    carg=$(urlencode "$carg")
                    replace "$arg" "%u" "$carg"
                    carg=$REPLACED_STR
                    debug "injector adding '$arg' iteration as '$carg'"
                    exec_iter_usep=${exec_iter_usep}${exec_iter_usep:+$USEP}${carg}
                done
                # placeholder arg
                exec_usep=${exec_usep}${exec_usep:+$USEP}%%__ITER__%%
                ;;
            '%U')
                for carg in "$@"; do
                    carg=$(urlencode "$carg")
                    debug "injector extending '$arg' with '$carg'"
                    exec_usep=${exec_usep}${exec_usep:+$USEP}${carg}
                done
                ;;
            *) error "${ENTRY_ID}: not implemented '$arg'" ;;
            esac
            ;;
        # icon field
        *[!%]'%i'* | '%i'*)
            if [ -n "$ENTRY_ICON" ]; then
                replace "$arg" "%i" "$ENTRY_ICON"
                rarg=$REPLACED_STR
                debug "injector replacing '%i': '$arg' -> '$rarg'"
                exec_usep=${exec_usep}${exec_usep:+$USEP}${rarg}
            else
                debug "injector removed '$rarg'"
            fi
            ;;
        # name field
        *[!%]'%c'* | '%c'*)
            replace "$arg" "%c" "$ENTRY_NAME"
            rarg=$REPLACED_STR
            debug "injector replacing '%c': '$arg' -> '$rarg'"
            exec_usep=${exec_usep}${exec_usep:+$USEP}${rarg}
            ;;
        # literal %
        *[!%]%%* | %%*)
            replace "$arg" "%%" "%"
            rarg=$REPLACED_STR
            debug "injector replacing '%%': '$arg' -> '$rarg'"
            exec_usep=${exec_usep}${exec_usep:+$USEP}${rarg}
            ;;
        # invalid field
        *%?* | *[!%]%)
            error "${ENTRY_ID}: unknown % field in argument '${arg}'"
            return 1
            ;;
        *)
            debug "injector keeped: '$arg'"
            exec_usep=${exec_usep}${exec_usep:+$USEP}${arg}
            ;;
        esac
    done
    # fill EXEC_RSEP_USEP with argument iterations
    if [ -n "$exec_iter_usep" ]; then
        EXEC_RSEP_USEP=''
        for arg in $exec_iter_usep; do
            replace "$exec_usep" "%%__ITER__%%" "$arg"
            cmd=$REPLACED_STR
            EXEC_RSEP_USEP=${EXEC_RSEP_USEP}${EXEC_RSEP_USEP:+$RSEP}${cmd}
        done
    else
        EXEC_RSEP_USEP=$exec_usep
    fi
    IFS=$OIFS
}

parse_entry_key() {
    # set global vars or fail entry
    key=$1
    value=$2
    action=$3
    read_exec=$4
    in_main=$5
    in_action=$6

    case "${in_action};${key}" in
    'false;'* | 'true;Name' | 'true;Name['*']' | 'true;Exec' | 'true;Icon') true ;;
    *)
        error "${ENTRY_ID}: Encountered '$key' key inside action!"
        return 1
        ;;
    esac

    case "$key" in
    Type)
        debug "captured '$key' '$value'"
        case "$value" in
        Application | Link) ENTRY_TYPE=$value ;;
        *)
            error "${ENTRY_ID}: Unsupported type '$value'!"
            return 1
            ;;
        esac
        ;;
    Actions)
        # `It is not valid to have an action group for an action identifier not mentioned in the Actions key.
        # Such an action group must be ignored by implementors.`
        # ignore if no action requested
        [ -z "$action" ] && return 0
        debug "checking for '$action' in Actions '$value'"
        IFS=';'
        for check_action in $value; do
            case "$check_action" in
            "$action")
                action_listed=true
                return 0
                ;;
            esac
        done
        error "${ENTRY_ID}: Action '$action' is not listed in entry!"
        return 1
        ;;
    TryExec)
        debug "checking TryExec executable '$value'"
        de_expand_str "$value"
        value=$EXPANDED_STR
        if ! type "$value" >/dev/null 2>&1; then
            error "${ENTRY_ID}: TryExec '$value' failed!"
            return 1
        fi
        ;;
    Hidden)
        debug "checking boolean Hidden '$value'"
        case "$value" in
        true)
            error "${ENTRY_ID}: Entry is Hidden"
            return 1
            ;;
        esac
        ;;
    Exec)
        case "$read_exec" in
        false)
            debug "ignored Exec from wrong section"
            return 0
            ;;
        esac
        case "$in_action" in
        true) action_exec=true ;;
        esac
        debug "read Exec '$value'"
        # skip actual reading if array is already filled
        if [ -n "$EXEC_RSEP_USEP" ]; then
            debug "skipping re-filling exec array"
            return 0
        fi
        # expand string-level escape sequences
        de_expand_str "$value"
        # Split Exec and save as string delimited by unit separator
        de_tokenize_exec "$EXPANDED_STR"
        EXEC_RSEP_USEP=$EXEC_USEP
        # get Exec[0]
        IFS=$USEP read -r exec0 _rest <<-EOCMD
			$EXEC_RSEP_USEP
		EOCMD
        case "$exec0" in
        '')
            error "${ENTRY_ID}: Could not extract Exec[0]!"
            return 1
            ;;
        */*)
            EXEC_NAME=${exec0##*/}
            EXEC_PATH=${exec0}
            ;;
        *) EXEC_NAME=${exec0} ;;
        esac
        debug "checking Exec[0] executable '${EXEC_PATH:-$EXEC_NAME}'"
        if ! type "${EXEC_PATH:-$EXEC_NAME}" >/dev/null 2>&1; then
            error "${ENTRY_ID}: Exec command '${EXEC_PATH:-$EXEC_NAME}' not found"
            return 1
        fi
        ;;
    URL)
        debug "captured '$key' '$value'"
        de_expand_str "$value"
        ENTRY_URL=$EXPANDED_STR
        ;;
    "Name[${LCODE}]")
        case "${in_main}_${in_action}" in
        true_false)
            debug "captured '$key' '$value'"
            de_expand_str "$value"
            ENTRY_LNAME=$EXPANDED_STR
            ;;
        false_true)
            debug "captured '$key' '$value'"
            de_expand_str "$value"
            ENTRY_LNAME_ACTION=$EXPANDED_STR
            ;;
        *) debug "discarded '$key' '$value'" ;;
        esac
        ;;
    Name)
        case "${in_main}_${in_action}" in
        true_false)
            debug "captured '$key' '$value'"
            de_expand_str "$value"
            ENTRY_NAME=$EXPANDED_STR
            ;;
        false_true)
            debug "captured '$key' '$value'"
            de_expand_str "$value"
            ENTRY_NAME_ACTION=$EXPANDED_STR
            ;;
        *) debug "discarded '$key' '$value'" ;;
        esac
        ;;
    "GenericName[${LCODE}]")
        debug "captured '$key' '$value'"
        de_expand_str "$value"
        ENTRY_LCOMMENT=$EXPANDED_STR
        ;;
    GenericName)
        debug "captured '$key' '$value'"
        de_expand_str "$value"
        ENTRY_COMMENT=$EXPANDED_STR
        ;;
    Icon)
        if [ "$in_main" = "true" ] || [ "$in_action" = "true" ]; then
            debug "captured '$key' '$value'"
            de_expand_str "$value"
            ENTRY_ICON=$EXPANDED_STR
        else
            debug "discarded '$key' '$value'"
        fi
        ;;
    Path)
        debug "captured '$key' '$value'"
        de_expand_str "$value"
        ENTRY_WORKDIR=$EXPANDED_STR
        if [ ! -e "$ENTRY_WORKDIR" ]; then
            error "${ENTRY_ID}: Requested 'Path' '${ENTRY_WORKDIR}' does not exist!"
            return 1
        elif [ ! -d "$ENTRY_WORKDIR" ]; then
            error "${ENTRY_ID}: Requested 'Path' '${ENTRY_WORKDIR}' is not a directory!"
            return 1
        fi
        ;;
    Terminal)
        debug "captured '$key' '$value'"
        case "$FUZZEL_COMPAT" in
        true)
            debug "ignoring Terminal in fuzzel compat mode"
            return 0
            ;;
        esac
        case "$value" in
        true)
            # if terminal was not requested explicitly, check terminal handler
            case "$TERMINAL" in
            false) check_terminal_handler ;;
            esac
            TERMINAL=true
            ;;
        esac
        ;;
    esac
    # By default unrecognised keys, empty lines and comments get ignored
}
# Mask IFS within function to allow temporary changes
alias parse_entry_key='IFS= parse_entry_key'

read_entry_path() {
    # Read entry from given path
    entry_path="$1"
    entry_action="${2-}"
    read_exec=false
    action_listed=false
    in_main=false
    in_action=false
    action_exec=false
    break_on_next_section=false
    # shellcheck disable=SC2016
    debug "reading desktop entry '$entry_path'${entry_action:+ action '$entry_action'}"
    # Let `read` trim leading/trailing whitespace from the line
    while read -r line; do
        case $line in
        # `There should be nothing preceding [the Desktop Entry group] in the desktop entry file but [comments]`
        # if entry_action is not requested, allow reading Exec right away from the main group
        '[Desktop Entry]'*)
            debug "entered section: $line"
            in_main=true
            if [ -z "$entry_action" ]; then
                read_exec=true
                break_on_next_section=true
            fi
            ;;
        # A `Key=Value` pair
        [a-zA-Z0-9-]*=*)
            # Split
            IFS='=' read -r key value <<-EOL
				$line
			EOL
            # Trim
            { read -r key && read -r value; } <<-EOL
				$key
				$value
			EOL
            # Parse key, or abort
            parse_entry_key "$key" "$value" "$entry_action" "$read_exec" "$in_main" "$in_action" || return 1
            ;;
        # found requested action, allow reading Exec
        "[Desktop Action ${entry_action}]"*)
            debug "entered section: $line"
            in_main=false
            break_on_next_section=true
            case "$action_listed" in
            true)
                read_exec=true
                in_action=true
                ;;
            *)
                error "${ENTRY_ID}: Action '$entry_action' is not listed in Actions key!"
                return 1
                ;;
            esac
            ;;
        # Start of the next group header, stop if already read exec
        '['*)
            debug "entered section: $line"
            [ "$break_on_next_section" = "true" ] && break
            in_main=false
            in_action=false
            read_exec=false
            ;;
        esac
        # By default empty lines and comments get ignored
    done <"$entry_path"

    # check for required things for action
    if [ -n "$entry_action" ]; then
        case "$action_listed" in
        true) true ;;
        *)
            error "${ENTRY_ID}: Action '$entry_action' is not listed in Actions key or does not exist!"
            return 1
            ;;
        esac
        if [ "$action_exec" != "true" ] || [ -z "${ENTRY_LNAME_ACTION:-$ENTRY_NAME_ACTION}" ]; then
            error "${ENTRY_ID}: Action '$entry_action' is incomplete"
            return 1
        fi
    fi

    # check for required things for types
    case "${ENTRY_TYPE};;${EXEC_RSEP_USEP};;${ENTRY_URL}" in
    'Application;;'?*';;' | 'Link;;;;'?*) true ;;
    ';;'*)
        error "${ENTRY_ID}: type not specified!"
        return 1
        ;;
    *)
        error "${ENTRY_ID}: type and keys mismatch: '$ENTRY_TYPE', Exec is$([ -z "${EXEC_RSEP_USEP}" ] && echo ' not') set, URL is$([ -z "${ENTRY_URL}" ] && echo ' not') set"
        return 1
        ;;
    esac
}

random_string() {
    # gets random 8 hex characters
    tr -dc '0-9a-f' </dev/urandom 2>/dev/null | head -c 8
}

validate_entry_id() {
    # validates Entry ID ($1)

    case "$1" in
    # invalid characters or degrees of emptiness
    *[!a-zA-Z0-9_.-]* | *[!a-zA-Z0-9_.-] | [!a-zA-Z0-9_.-]* | [!a-zA-Z0-9_.-] | '' | .desktop)
        debug "string not valid as Entry ID: '$1'"
        return 1
        ;;
    # all that left with .desktop
    *.desktop) return 0 ;;
    # and without
    *)
        debug "string not valid as Entry ID '$1'"
        return 1
        ;;
    esac
}

validate_action_id() {
    # validates action ID ($1)

    case "$1" in
    # empty is ok
    '') return 0 ;;
    # invalid characters
    *[!a-zA-Z0-9-]* | *[!a-zA-Z0-9-] | [!a-zA-Z0-9-]* | [!a-zA-Z0-9-])
        debug "string not valid as Action ID: '$1'"
        return 1
        ;;
    # all that left
    *) return 0 ;;
    esac
}

urlencode() {
    string=$1
    case "$string" in
    # assuming already url
    *[a-zA-Z0-9_-]://*)
        echo "$string"
        return
        ;;
    # assuming absolute path
    /*) true ;;
    # assuming relative path
    *) string=$(pwd)/$string ;;
    esac

    printf '%s' 'file://'

    case "$string" in
    # if contains extra chars, encode
    *[!._~0-9A-Za-z/-]*)
        while [ -n "$string" ]; do
            right=${string#?}
            char=${string%"$right"}
            debug "urlencode string $string" "urlencode right $right" "urlencode char $char"
            case $char in
            [._~0-9A-Za-z/-]) printf '%s' "$char" ;;
            *) printf '%%%02x' "'$char" ;;
            esac
            string=$right
        done
        ;;
    *) printf '%s' "$string" ;;
    esac
}

gen_unit_id() {
    # generate Unit ID based on Entry ID or exec name if UNIT_ID is not already set
    # sets UNIT_ID

    if [ -z "$UNIT_ID" ]; then
        if [ -z "$UNIT_APP_SUBSTRING" ] && [ -n "${ENTRY_ID}" ]; then
            UNIT_APP_SUBSTRING=${ENTRY_ID%.desktop}
        elif [ -z "$UNIT_APP_SUBSTRING" ]; then
            UNIT_APP_SUBSTRING=${EXEC_NAME}
        fi
        if [ -n "${XDG_SESSION_DESKTOP:-}" ]; then
            UNIT_DESKTOP_SUBSTRING=${XDG_SESSION_DESKTOP}
        elif [ -n "${XDG_CURRENT_DESKTOP:-}" ]; then
            UNIT_DESKTOP_SUBSTRING=${XDG_CURRENT_DESKTOP%%:*}
        else
            UNIT_DESKTOP_SUBSTRING=NoDesktop
        fi
        # escape substrings if needed
        case "${UNIT_DESKTOP_SUBSTRING}${UNIT_APP_SUBSTRING}" in
        *[!a-zA-Z:_.]*)
            # prepend a character to shield potential . from being first
            read -r UNIT_DESKTOP_SUBSTRING UNIT_APP_SUBSTRING <<-EOL
				$(systemd-escape "A$UNIT_DESKTOP_SUBSTRING" "A$UNIT_APP_SUBSTRING")
			EOL
            # remove character
            UNIT_DESKTOP_SUBSTRING=${UNIT_DESKTOP_SUBSTRING#A}
            UNIT_APP_SUBSTRING=${UNIT_APP_SUBSTRING#A}
            ;;
        esac

        RANDOM_STRING=$(random_string)
        case "$UNIT_TYPE" in
        service)
            UNIT_ID="app-${UNIT_DESKTOP_SUBSTRING}-${UNIT_APP_SUBSTRING}@${RANDOM_STRING}.service"
            ;;
        scope)
            UNIT_ID="app-${UNIT_DESKTOP_SUBSTRING}-${UNIT_APP_SUBSTRING}-${RANDOM_STRING}.scope"
            ;;
        *)
            error "Unsupported unit type '$UNIT_TYPE'!"
            return 1
            ;;
        esac
    else
        case "$UNIT_ID" in
        *?".$UNIT_TYPE") true ;;
        *)
            error "Unit ID '$UNIT_ID' is not of type '$UNIT_TYPE'"
            return 1
            ;;
        esac
    fi
    if [ "${#UNIT_ID}" -gt "254" ]; then
        error "Unit ID too long (${#UNIT_ID})!: $UNIT_ID"
        return 1
    fi
    case "$UNIT_ID" in
    .service | .scope | '')
        error "Unit ID is empty!"
        return 1
        ;;
    *.service | *.scope) true ;;
    *)
        error "Invalid Unit ID '$UNIT_ID'!"
        return 1
        ;;
    esac
}

randomize_unit_id() {
    # updates random string in existing UNIT_ID

    if [ -z "$RANDOM_STRING" ]; then
        debug "refusing to randomize unit ID"
        return 0
    fi
    NEW_RANDOM_STRING=$(random_string)
    debug "new random string: $NEW_RANDOM_STRING"
    UNIT_ID=${UNIT_ID%"${RANDOM_STRING}.${UNIT_TYPE}"}${NEW_RANDOM_STRING}.${UNIT_TYPE}
    #"
    RANDOM_STRING=${NEW_RANDOM_STRING}
}

systemd_run() {
    # wrapper for systemd-run
    # prepend common args
    UNIT_SLICE_ID=${UNIT_SLICE_ID:-app-graphical.slice}
    if [ -z "$UNIT_DESCRIPTION" ] && [ -n "${ENTRY_LNAME:-$ENTRY_NAME}" ] && [ -n "${ENTRY_LCOMMENT:-$ENTRY_COMMENT}" ]; then
        UNIT_DESCRIPTION="${ENTRY_LNAME:-$ENTRY_NAME} - ${ENTRY_LCOMMENT:-$ENTRY_COMMENT}"
    elif [ -z "$UNIT_DESCRIPTION" ] && [ -n "${ENTRY_LNAME:-$ENTRY_NAME}" ]; then
        UNIT_DESCRIPTION="${ENTRY_LNAME:-$ENTRY_NAME}"
    elif [ -z "$UNIT_DESCRIPTION" ] && [ -n "$EXEC_NAME" ]; then
        UNIT_DESCRIPTION=${EXEC_NAME}
    fi

    set -- \
        --slice="$UNIT_SLICE_ID" \
        --unit="$UNIT_ID" \
        --description="$UNIT_DESCRIPTION" \
        --quiet \
        --collect \
        -- "$@"

    if [ "$PART_OF_GST" = "true" ]; then
        # prepend graphical session dependency/ordering args
        set -- \
            --property=After=graphical-session.target \
            --property=PartOf=graphical-session.target \
            "$@"
    fi

    if [ -n "$ENTRY_WORKDIR" ]; then
        # prepend requested Path or samedir
        set -- "--working-directory=${ENTRY_WORKDIR}" "$@"
    else
        set -- --same-dir "$@"
    fi

    # prepend unit type-dependent args
    case "$UNIT_TYPE" in
    scope) set -- --scope "$@" ;;
    service)
        set -- --property=Type=exec --property=ExitType=cgroup "$@"
        # silence service
        case "$SILENT" in
        # silence out
        out)
            set -- --property=StandardOutput=null "$@"
            # unsilence stderr if it is inheriting
            dso=''
            dse=''
            while IFS='=' read -r key value; do
                case "$key" in
                DefaultStandardOutput) dso=$value ;;
                DefaultStandardError) dse=$value ;;
                esac
            done <<-EOF
				$(systemctl --user show --property DefaultStandardOutput --property DefaultStandardError)
			EOF
            case "$dse" in
            inherit) set -- --property=StandardError="$dso" "$@" ;;
            esac
            ;;
        # silence err
        err) set -- --property=StandardError=null "$@" ;;
        # silence both
        both) set -- --property=StandardOutput=null --property=StandardError=null "$@" ;;
        esac
        ;;
    esac

    debug "systemd run" "$(printf '  >%s<\n' systemd-run "$@")"

    # print args in test mode
    case "$TEST_MODE" in
    true)
        printf '%s\n' 'Command and arguments:'
        printf '  >%s<\n' systemd-run --user "$@"
        exit 0
        ;;
    esac

    # silence scope output
    case "${UNIT_TYPE}_${SILENT}" in
    scope_out) exec >/dev/null ;;
    scope_err) exec 2>/dev/null ;;
    scope_both) exec >/dev/null 2>&1 ;;
    esac

    # exec
    exec systemd-run --user "$@"
}

parse_main_arg() {
    # fills some of global variables depending on main arg $1
    MAIN_ARG=$1

    ENTRY_ID=''
    ENTRY_ACTION=''
    ENTRY_PATH=''
    EXEC_NAME=''
    EXEC_PATH=''

    case "$MAIN_ARG" in
    '')
        error "Empty main argument"
        return 1
        ;;
    *.desktop:*)
        IFS=':' read -r ENTRY_ID ENTRY_ACTION <<-EOA
			$MAIN_ARG
		EOA
        ;;
    *.desktop)
        ENTRY_ID=$MAIN_ARG
        ENTRY_ACTION=''
        ;;
    esac
    debug "ENTRY_ID: $ENTRY_ID" "ENTRY_ACTION: $ENTRY_ACTION"

    if [ -n "$ENTRY_ID" ]; then
        case "$ENTRY_ID" in
        */*)
            # this is a path
            ENTRY_PATH=$ENTRY_ID
            ENTRY_ID=${ENTRY_ID##*/}
            if [ ! -f "$ENTRY_PATH" ]; then
                error "File not found: '$ENTRY_PATH'"
                return 1
            fi
            return
            ;;
        esac

        if ! validate_entry_id "$ENTRY_ID"; then
            error "Invalid Entry ID '$ENTRY_ID'!"
            return 1
        fi
        if ! validate_action_id "$ENTRY_ACTION"; then
            error "Invalid Entry Action ID '$ENTRY_ACTION'!"
            return 1
        fi
        return 0
    fi

    # what's left is executable
    case "$MAIN_ARG" in
    */*)
        EXEC_PATH=$MAIN_ARG
        EXEC_NAME=${EXEC_PATH##*/}
        debug "EXEC_PATH: $EXEC_PATH" "EXEC_NAME: $EXEC_NAME"
        if [ ! -f "$EXEC_PATH" ]; then
            error "File not found: '$EXEC_PATH'"
            return 1
        fi
        if [ ! -x "$EXEC_PATH" ]; then
            error "File is not executable: '$EXEC_PATH'"
            return 1
        fi
        return
        ;;
    esac

    EXEC_NAME=$MAIN_ARG
    debug "EXEC_NAME: $EXEC_NAME"
    if ! type "$EXEC_NAME" >/dev/null 2>&1; then
        error "Executable not found: '$EXEC_NAME'"
        return 1
    fi
}

check_terminal_handler() {
    # checks terminal handler availability
    if ! command -v "$TERMINAL_HANDLER" >/dev/null; then
        error "Terminal launch requested but '$TERMINAL_HANDLER' is unavailable!"
        exit 1
    fi
}

get_mime() {
    # prints mime type of file or url
    mime=
    case "$1" in
    [a-zA-Z]*:*)
        IFS=':' read -r scheme _rest <<-EOF
			$1
		EOF
        debug "potential scheme '$scheme'"
        case "$scheme" in
        *[!a-zA-Z0-9+.-]*)
            debug "not a valid scheme '$scheme', assuming file"
            mime=$(xdg-mime query filetype "$1")
            ;;
        *) mime=x-scheme-handler/$scheme ;;
        esac
        ;;
    *) mime=$(xdg-mime query filetype "$1") ;;
    esac

    case "$mime" in
    '' | 'x-scheme-handler/')
        error "Could not query mime type for '$1'"
        return 1
        ;;
    *)
        debug "got mime '$mime' for '$1'"
        echo "$mime"
        return 0
        ;;
    esac
}

get_assoc() {
    # prints file association for mime type
    assoc=$(xdg-mime query default "$1")
    case "$assoc" in
    ?*.desktop)
        debug "got association '$assoc' for mime '$1'"
        echo "$assoc"
        return 0
        ;;
    *)
        error "Could not query association for mime '$1'"
        return 1
        ;;
    esac
}

########################

debug "initial args:" "$(printf '  >%s<\n' "$@")"

EXEC_NAME=''
EXEC_PATH=''
EXEC_RSEP_USEP=''
ENTRY_PATH=''
ENTRY_ID=''
ENTRY_TYPE=''
ENTRY_URL=''
ENTRY_COMMENT=''
ENTRY_NAME=''
ENTRY_ICON=''
ENTRY_WORKDIR=''
UNIT_DESCRIPTION=''
UNIT_ID=''
UNIT_APP_SUBSTRING=''

SILENT=''
TEST_MODE=false

# vars for expander, tokenizer, injector output
EXPANDED_STR=''
EXEC_USEP=''
REPLACED_STR=''

UNIT_TYPE=${APP2UNIT_TYPE:-scope}
case "$UNIT_TYPE" in
service | scope) true ;;
*)
    error "Unsupported unit type '$UNIT_TYPE'!"
    exit 1
    ;;
esac

# deal with unit slice choices and default
UNIT_SLICE_ID=''
UNIT_SLICE_CHOICES=${APP2UNIT_SLICES:-"a=app.slice b=background.slice s=session.slice"}
for choice in $UNIT_SLICE_CHOICES; do
    debug "evaluating slice choice '$choice'"
    slice_abbr=
    slice_id=
    case "$choice" in
    *[!a-zA-Z0-9=._-]* | *=*=* | *[!a-z]*=* | *=[!a-zA-Z0-9._-]* | *[!.][!s][!l][!i][!c][!e])
        error "Invalid slice choice '$choice', ignoring."
        continue
        ;;
    [a-z]*=[a-zA-Z0-9_.-]*.slice)
        IFS='=' read -r slice_abbr slice_id <<-EOF
			$choice
		EOF
        ;;
    *)
        error "Invalid slice choice '$choice', ignoring."
        continue
        ;;
    esac
    if [ -z "$UNIT_SLICE_ID" ]; then
        UNIT_SLICE_CHOICES=
        UNIT_SLICE_ID="${slice_id}"
        debug "reset default slice as '${slice_id}'"
    fi
    debug "adding choice ${slice_abbr}=${slice_id}"
    UNIT_SLICE_CHOICES=${UNIT_SLICE_CHOICES}${UNIT_SLICE_CHOICES:+ }${slice_abbr}=${slice_id}
done
if [ -z "$UNIT_SLICE_ID" ]; then
    UNIT_SLICE_ID=app.slice
    debug "falling back to default slice 'app.slice'"
fi

PART_OF_GST=true
if [ -z "${APP2UNIT_PART_OF_GST:-}" ]; then
    PART_OF_GST=true
else
    if check_bool "$APP2UNIT_PART_OF_GST"; then
        PART_OF_GST=true
    else
        PART_OF_GST=false
    fi
fi

TERMINAL=false
FUZZEL_COMPAT=false
OPENER_MODE=false

capture_terminal_args=false
case "$SELF_NAME" in
*-open | *-open-scope | *-open-service)
    OPENER_MODE=true
    case "$SELF_NAME" in
    *-scope) UNIT_TYPE=scope ;;
    *-service) UNIT_TYPE=service ;;
    esac
    ;;
*-term | *-terminal | *-term-scope | *-terminal-scope | *-term-service | *-terminal-service)
    TERMINAL=true
    capture_terminal_args=true
    case "$SELF_NAME" in
    *-scope) UNIT_TYPE=scope ;;
    *-service) UNIT_TYPE=service ;;
    esac
    ;;
esac

# will be set where needed
RANDOM_STRING=

LCODE=${LANGUAGE:-"$LANG"}
LCODE=${LCODE%_*}
LCODE=${LCODE:-NOLCODE}

# expand short args
first=true
found_delim=false
for arg in "$@"; do
    case "$first" in
    true)
        set --
        first=false
        ;;
    esac
    case "$found_delim" in
    true)
        set -- "$@" "$arg"
        continue
        ;;
    esac
    case "$arg" in
    --)
        found_delim=true
        set -- "$@" "$arg"
        ;;
    -[a-zA-Z][a-zA-Z]*)
        arg=${arg#-}
        while [ -n "$arg" ]; do
            cut=${arg#?}
            char=${arg%"$cut"}
            set -- "$@" "-$char"
            arg=$cut
        done
        ;;
    *) set -- "$@" "$arg" ;;
    esac
done

part_of_gst_set=false
# parse args
TERMINAL_ARGS_USEP=
while [ "$#" -gt "0" ]; do
    case "$1" in
    -h | --help)
        help
        exit 0
        ;;
    -s)
        debug "arg '$1' '${2:-}'"
        case "${2:-}" in
        .slice | '')
            error "Empty slice id '${2:-}'" "$(usage)"
            exit 1
            ;;
        *[!a-zA-Z0-9_.-]*)
            error "Invalid slice id '$2'" "$(usage)"
            exit 1
            ;;
        *.slice)
            UNIT_SLICE_ID=$2
            shift 2
            continue
            ;;
        *)
            for choice in $UNIT_SLICE_CHOICES; do
                IFS='=' read -r slice_abbr slice_id <<-EOF
					$choice
				EOF
                case "$slice_abbr" in
                "$2")
                    UNIT_SLICE_ID=$slice_id
                    shift 2
                    continue 2
                    ;;
                esac
            done
            error "'$2' does not point to a slice choice!" "Choices: $UNIT_SLICE_CHOICES" "$(usage)"
            exit 1
            ;;
        esac
        error "Failed to parse '-s' argument" "$(usage)"
        exit 1
        ;;
    -t)
        debug "arg '$1' '${2:-}'"
        case "${2:-}" in
        scope | service) UNIT_TYPE=$2 ;;
        *)
            error "Expected unit type scope|service for -t, got '${2:-}'!" "$(usage)"
            exit 1
            ;;
        esac
        shift 2
        ;;
    -a)
        debug "arg '$1' '${2:-}'"
        if [ -z "${2:-}" ]; then
            error "Expected app name for -a!" "$(usage)"
            exit 1
        elif [ -n "$UNIT_ID" ]; then
            error "Conflicting options: -a, -u!" "$(usage)"
            exit 1
        else
            UNIT_APP_SUBSTRING=$2
        fi
        shift 2
        ;;
    -u)
        debug "arg '$1' '${2:-}'"
        if [ -z "${2:-}" ]; then
            error "Expected Unit ID for -u!" "$(usage)"
            exit 1
        elif [ -n "$UNIT_APP_SUBSTRING" ]; then
            error "Conflicting options: -u, -a!" "$(usage)"
            exit 1
        else
            UNIT_ID=$2
        fi
        shift 2
        ;;
    -d)
        debug "arg '$1' '${2:-}'"
        if [ -z "${2:-}" ]; then
            error "Expected unit description for -d!" "$(usage)"
            exit 1
        else
            UNIT_DESCRIPTION="$2"
        fi
        shift 2
        ;;
    -c)
        case "$part_of_gst_set" in
        true)
            error "-c conflicts with -C" "$(usage)"
            exit 1
            ;;
        esac
        debug "arg '$1'"
        PART_OF_GST=false
        part_of_gst_set=true
        shift
        ;;
    -C)
        case "$part_of_gst_set" in
        true)
            error "-C conflicts with -c" "$(usage)"
            exit 1
            ;;
        esac
        debug "arg '$1'"
        PART_OF_GST=true
        part_of_gst_set=true
        shift
        ;;
    -S)
        debug "arg '$1' '${2:-}'"
        case "${2:-}" in
        out | err | both) SILENT=$2 ;;
        *)
            error "Expected silent mode out|err|both for -S, got '${2:-}'!" "$(usage)"
            exit 1
            ;;
        esac
        shift 2
        ;;
    -T)
        TERMINAL=true
        capture_terminal_args=true
        debug "arg '$1'"
        check_terminal_handler
        shift
        ;;
    -O | --open)
        OPENER_MODE=true
        debug "arg '$1'"
        shift
        ;;
    --fuzzel-compat)
        FUZZEL_COMPAT=true
        debug "arg '$1'"
        shift
        ;;
    --test)
        TEST_MODE=true
        debug "arg '$1'"
        shift
        ;;
    --)
        debug "arg '$1', breaking"
        shift
        break
        ;;
    -*)
        case "$capture_terminal_args" in
        false)
            error "Unknown option '$1'!" "$(usage)"
            exit 1
            ;;
        true)
            debug "storing unknown opt '$1' for terminal"
            TERMINAL_ARGS_USEP=${TERMINAL_ARGS_USEP}${TERMINAL_ARGS_USEP:+$USEP}${1}
            shift
            ;;
        esac
        ;;
    *)
        debug "arg '$1', breaking"
        break
        ;;
    esac
done

if [ "$#" -eq "0" ] && [ "$TERMINAL" = "false" ]; then
    error "Arguments expected" "$(usage)"
    exit 1
fi

if [ "$FUZZEL_COMPAT" = "true" ]; then
    if [ -z "${FUZZEL_DESKTOP_FILE_ID:-}" ]; then
        debug "no FUZZEL_DESKTOP_FILE_ID, cancelling FUZZEL_COMPAT"
        FUZZEL_COMPAT=false
    fi
    if [ "$OPENER_MODE" = "true" ]; then
        debug "opener mode, cancelling FUZZEL_COMPAT"
        FUZZEL_COMPAT=false
    fi
fi

if [ "$OPENER_MODE" = "true" ]; then
    if [ "$#" = "0" ]; then
        error "File(s) or URL(s) expected for open mode."
        exit 1
    fi
    MAIN_ARG=
    # determine if file or URL, get associations for MAIN_ARG
    for arg in "$@"; do
        mime=$(get_mime "$arg")
        assoc=$(get_assoc "$mime")
        if [ -z "$MAIN_ARG" ]; then
            debug "setting MAIN_ARG from association for '$arg': '$assoc'"
            MAIN_ARG=$assoc
        elif [ "$MAIN_ARG" = "$assoc" ]; then
            debug "arg '$arg' has the same association"
            true
        else
            error "Can not open multiple files/URLs with different associations"
            exit 1
        fi
    done
elif [ "$FUZZEL_COMPAT" = "true" ]; then
    debug "setting MAIN_ARG from FUZZEL_DESKTOP_FILE_ID: '$FUZZEL_DESKTOP_FILE_ID'" "passing arguments to exec array"
    MAIN_ARG=$FUZZEL_DESKTOP_FILE_ID
    # Fuzzel compat mode, awaiting for https://codeberg.org/dnkl/fuzzel/issues/292
    # ignore command from entry, take only metadata, use arg array as is.
    if ! type "$1" >/dev/null 2>&1; then
        error "Executable not found: '$1'"
        exit 1
    fi
    EXEC_RSEP_USEP=$(
        printf "%s${USEP}" "$@"
    )
    EXEC_RSEP_USEP=${EXEC_RSEP_USEP%"$USEP"}
elif [ "$#" -eq "0" ] && [ "$TERMINAL" = "true" ]; then
    # special case for launching just terminal

    # get entry path and cmdline from terminal handler
    if path_and_cmd=$(
        IFS=$USEP
        # shellcheck disable=SC2086
        set -- $TERMINAL_ARGS_USEP
        IFS=$OIFS
        # prevent old xdg-terminal-exec from running anything
        unset DISPLAY WAYLAND_DISPLAY
        "$TERMINAL_HANDLER" --print-path --print-cmd='\037' "$@"
    ) && case "$path_and_cmd" in '/'*".desktop$N"* | '/'*'.desktop:'*"$N"*) true ;; *) false ;; esac then
        # entry path and action before newline
        MAIN_ARG=${path_and_cmd%%"$N"*}
        # cmd after newline, fill exec array right away
        EXEC_RSEP_USEP=${path_and_cmd#*"$N"}
        # shellcheck disable=SC2086
        debug "initial args:" "$(printf '  >%s<\n' "$@")"
        # shellcheck disable=SC2086
        debug "replaced MAIN_ARG with '$MAIN_ARG'" "populated EXEC_RSEP_USEP with:" "$(
            IFS=$USEP
            printf '  > %s\n' $EXEC_RSEP_USEP
        )"
    else
        # issue a warning
        {
            # shellcheck disable=SC2028
            echo "Could not determine default terminal entry via '$TERMINAL_HANDLER --print-path --print-cmd=\037'!"
            echo "Falling back to injecting '$TERMINAL_HANDLER' as the main argument."
        } >&2
        MAIN_ARG="$TERMINAL_HANDLER"
    fi
    TERMINAL=false
else
    MAIN_ARG=$1
    shift
fi
parse_main_arg "$MAIN_ARG"

if [ -n "$ENTRY_PATH" ]; then
    # reverse-deduce and correct Entry ID against applications dirs
    make_paths
    IFS=':'
    for dir in $APPLICATIONS_DIRS; do
        if [ "$ENTRY_PATH" != "${ENTRY_PATH#"$dir"}" ]; then
            ENTRY_ID_PRE=${ENTRY_PATH#"$dir"}
            case "$ENTRY_ID_PRE" in
            */*)
                replace "$ENTRY_ID_PRE" "/" "-"
                ENTRY_ID_PRE=$REPLACED_STR
                ;;
            esac
            if validate_entry_id "$ENTRY_ID_PRE"; then
                ENTRY_ID=$ENTRY_ID_PRE
            else
                error "Deduced Entry ID '$ENTRY_ID_PRE' is invalid!"
            fi
            break
        fi
    done
elif [ -n "$ENTRY_ID" ]; then
    make_paths
    ENTRY_PATH=$(find_entry "$ENTRY_ID")
fi

# read and parse entry, fill ENTRY_* vars and EXEC_RSEP_USEP
if [ -n "$ENTRY_PATH" ]; then
    read_entry_path "$ENTRY_PATH" "$ENTRY_ACTION"
fi

# handle Link type URL
if [ -n "$ENTRY_URL" ]; then
    debug "re-parsing for Link entry URL: $ENTRY_URL"
    mime=$(get_mime "$ENTRY_URL")
    assoc=$(get_assoc "$mime")
    # replace initial vars and arg
    ENTRY_ID=$assoc
    set -- "$ENTRY_URL"
    ENTRY_URL=
    # re-parse new entry
    ENTRY_PATH=$(find_entry "$ENTRY_ID")
    read_entry_path "$ENTRY_PATH"
fi

# generate Unit ID as UNIT_ID
gen_unit_id

# compose and execute arguments
if [ -n "$ENTRY_ID" ]; then

    # do not bother with fields in fuzzel compat, since there are no open args
    case "$FUZZEL_COMPAT" in
    false) de_inject_fields "$@" ;;
    esac

    # deal with potential multiple iterations
    case "$EXEC_RSEP_USEP" in
    *"$RSEP"*)
        IFS=$RSEP
        first=true
        for cmd in $EXEC_RSEP_USEP; do
            IFS=$USEP
            # shellcheck disable=SC2086
            set -- $cmd
            IFS=$OIFS
            case "$TERMINAL" in
            true)
                # inject terminal handler
                debug "injected $TERMINAL_HANDLER"
                IFS=$USEP
                # shellcheck disable=SC2086
                set -- "$TERMINAL_HANDLER" $TERMINAL_ARGS_USEP "$@"
                IFS=$OIFS
                ;;
            esac
            debug "entry iteration" "$(printf '  >%s<\n' "$@")"
            if [ "$first" = "false" ]; then
                randomize_unit_id
            fi
            systemd_run "$@" &
            first=false
        done
        wait
        exit
        ;;
    *)
        IFS=$USEP
        # shellcheck disable=SC2086
        set -- $EXEC_RSEP_USEP
        IFS=$OIFS
        case "$TERMINAL" in
        true)
            # inject terminal handler
            debug "injected $TERMINAL_HANDLER"
            IFS=$USEP
            # shellcheck disable=SC2086
            set -- "$TERMINAL_HANDLER" $TERMINAL_ARGS_USEP "$@"
            IFS=$OIFS
            ;;
        esac
        debug "entry single" "$(printf '  >%s<\n' "$@")"
        systemd_run "$@"
        ;;
    esac
else
    set -- "${EXEC_PATH:-$EXEC_NAME}" "$@"
    IFS=$OIFS
    case "$TERMINAL" in
    true)
        # inject terminal handler
        debug "injected $TERMINAL_HANDLER"
        IFS=$USEP
        # shellcheck disable=SC2086
        set -- "$TERMINAL_HANDLER" $TERMINAL_ARGS_USEP "$@"
        IFS=$OIFS
        ;;
    esac
    debug "command" "$(printf '  >%s<\n' "$@")"
    systemd_run "$@"
fi
