#!/bin/sh

A2U__TERMINAL_HANDLER=xdg-terminal-exec
A2U__SELF_NAME=${0##*/}

# special characters
A2U__OIFS=$IFS
A2U__LF='
'
{
    read -r A2U__RSEP
    read -r A2U__USEP
    read -r A2U__CR
} <<-EOF
	$(printf '%b\n' '\036' '\037' '\r')
EOF

# Treat non-zero exit status from simple commands as an error
# Treat unset variables as errors when performing parameter expansion
# Disable pathname expansion
set -euf

shcat() {
    while IFS= read -r a2u__line; do
        printf '%s\n' "$a2u__line"
    done
}

usage() {
    shcat <<-EOF
		Usage:
		  $A2U__SELF_NAME \\
		    [-h | --help]
		    [-s a|b|s|custom.slice] \\$(
        case "$A2U__SELF_NAME" in
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
		    [-p {Property=value | @property_file}] \\
		    [-S {out|err|both}] \\
		    [{-c|-C}] \\
		    [-T] \\$(
        case "$A2U__SELF_NAME" in
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
        case "$A2U__SELF_NAME" in
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
		$A2U__SELF_NAME - Application launcher, file opener, default terminal launcher
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

		  -x
		    Do not insert "-\${desktop}" substring into generated unit name.
		    Also can be preset with APP2UNIT_INSERT_XSD=false.

		  -X
		    Insert "-\${desktop}" substring into generated unit name (default).
		    Also can be preset with APP2UNIT_INSERT_XSD=true.

		  -d description
		    Set/override unit description. By default description is generated from
		    Entry's "Name=" and "GenericName=" keys.

		  -p Property=value, -p @property_file
		    Set additional properties for unit or load them from a file.

	EOF
    case "$A2U__SELF_NAME" in
    *-term | *-terminal | *-term-scope | *-terminal-scope | *-term-service | *-terminal-service) true ;;
    *)
        shcat <<-EOF
			  -T
			    Force launch in terminal (${A2U__TERMINAL_HANDLER} is used). Any unknown option
			    starting with '-' after this will be passed to ${A2U__TERMINAL_HANDLER}.
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
    case "$A2U__SELF_NAME" in
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

    case "$A2U__SELF_NAME" in
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
			  Arguments should be supproted by Desktop Entry.

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
        notify-send -u critical -i dialog-error -a "${A2U__SELF_NAME}" "Error" "$1"
    fi
}

warning() {
    # Print messages to stdout, send notification (only first arg) if stdout is not interactive
    printf '%s\n' "$@"
    # if notify-send is installed and stdout is not a terminal, also send notification
    if [ ! -t 1 ] && command -v notify-send >/dev/null; then
        notify-send -u normal -i dialog-warning -a "${A2U__SELF_NAME}" "Warning" "$1"
    fi
}

message() {
    # Print messages to stdout, send notification (only first arg) if stdout is not interactive
    printf '%s\n' "$@"
    # if notify-send is installed and stdout is not a terminal, also send notification
    if [ ! -t 1 ] && command -v notify-send >/dev/null; then
        notify-send -u normal -i dialog-information -a "${A2U__SELF_NAME}" "Info" "$1"
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
if check_bool "${APP2UNIT_DEBUG-${DEBUG-0}}"; then
    A2U__DEBUG=true
    debug() {
        # print each arg at new line, prefix each printed line with 'D: '
        while IFS= read -r a2u__debug_line; do
            printf 'D: %s\n' "$a2u__debug_line"
        done <<-EOF >&2
			$(printf '%s\n' "$@")
		EOF
    }
else
    A2U__DEBUG=
    debug() { :; }
fi

replace() {
    # takes $1, replaces $2 with $3
    # does it in large chunks
    # writes result to global A2U__REPLACED_STR to avoid $() newline issues

    # right part of string
    a2u__r_remainder=${1}
    A2U__REPLACED_STR=
    while [ -n "$a2u__r_remainder" ]; do
        # left part before first encounter of $2
        a2u__r_left=${a2u__r_remainder%%"$2"*}
        # append
        A2U__REPLACED_STR=${A2U__REPLACED_STR}$a2u__r_left
        case "$a2u__r_left" in
        # nothing left to cut
        "$a2u__r_remainder") break ;;
        esac
        # append replace substring
        A2U__REPLACED_STR=${A2U__REPLACED_STR}$3
        # cut remainder
        a2u__r_remainder=${a2u__r_remainder#*"$2"}
    done
}

normpath() {
    # lightly normalize paths for comparison purposes
    # write to A2U__NORMALIZED_PATH var
    case "$1" in
    /*) a2u__path_result= ;;
    *) a2u__path_result=${PWD} ;;
    esac
    IFS='/'
    for a2u__path_item in $1; do
        case "$a2u__path_item" in
        # ignore empty element or current dir
        '.' | '') true ;;
        # deal with parent dir
        '..')
            case "$a2u__path_result" in
            # nothing above root
            '/') true ;;
            # remove last component if more than one
            '/'*'/'*) a2u__path_result=${a2u__path_result%/*} ;;
            # last component, reduce to root
            /*) a2u__path_result='/' ;;
            esac
            ;;
        *) a2u__path_result=${a2u__path_result}/${a2u__path_item} ;;
        esac
    done
    IFS=$A2U__OIFS
    debug "before normpath: $1" " after normpath: $a2u__path_result"
    A2U__NORMALIZED_PATH=$a2u__path_result
}

make_paths() {
    # constructs normalized A2U__APPLICATIONS_DIRS
    IFS=':'
    A2U__APPLICATIONS_DIRS=
    # Populate list of directories to search for entries in, in descending order of preference
    for a2u__dir in ${XDG_DATA_HOME:-${HOME}/.local/share}${IFS}${XDG_DATA_DIRS:-/usr/local/share:/usr/share}; do
        case "$a2u__dir" in
        /*) true ;;
        *)
            error "Non-absolute path in \$XDG_DATA_HOME:\$XDG_DATA_DIRS: $a2u__dir"
            exit 1
            ;;
        esac
        # Normalise base path and append the data subdirectory with a trailing '/'
        normpath "${a2u__dir}"
        A2U__APPLICATIONS_DIRS=${A2U__APPLICATIONS_DIRS:+${A2U__APPLICATIONS_DIRS}:}${A2U__NORMALIZED_PATH}/applications/
    done
    IFS=$A2U__OIFS
}

find_entry() {
    # finds entry by ID
    # writes to A2U__FOUND_ENTRY_PATH var
    a2u__fe_find_entry_id=$1

    # start assembling find args
    set --

    # Append application directory paths to be searched
    IFS=':'
    for a2u__fe_directory in $A2U__APPLICATIONS_DIRS; do
        # Append '.' to delimit start of Entry ID
        set -- "$@" "$a2u__fe_directory".
    done

    # Find all files
    set -- "$@" -type f

    # Append path conditions per directory
    a2u__or_arg=
    for a2u__fe_directory in $A2U__APPLICATIONS_DIRS; do
        # Match full path with proper first character of Entry ID and .desktop extension
        # Reject paths with invalid characters in Entry ID
        set -- "$@" ${a2u__or_arg} '(' -path "$a2u__fe_directory"'./[a-zA-Z0-9_]*.desktop' ! -path "$a2u__fe_directory"'./*[^a-zA-Z0-9_./-]*' ')'
        a2u__or_arg='-o'
    done

    # iterate over found paths
    IFS=$A2U__OIFS
    while read -r a2u__fe_entry_path <&3; do
        # raw drop or parse and separate data dir path from entry
        case "$a2u__fe_entry_path" in
        # empties, just in case
        '' | */./) continue ;;
        # subdir, also replace / with -
        */./*/*)
            replace "${a2u__fe_entry_path#*/./}" "/" "-"
            a2u__fe_entry_id=$A2U__REPLACED_STR
            ;;
        # normal separation
        */./*) a2u__fe_entry_id=${a2u__fe_entry_path#*/./} ;;
        esac
        # check ID
        case "$a2u__fe_entry_id" in
        "$a2u__fe_find_entry_id")
            A2U__FOUND_ENTRY_PATH=$a2u__fe_entry_path
            return 0
            ;;
        esac
    done 3<<-EOP
		$(find -L "$@" 2>/dev/null)
	EOP

    error "Could not find entry '$a2u__fe_find_entry_id'!"
    return 1
}

de_expand_str() {
    # expands \s, \n, \t, \r, \\
    # https://specifications.freedesktop.org/desktop-entry-spec/latest/value-types.html
    # writes result to global $A2U__EXPANDED_STR in place to avoid $() expansion newline issues
    debug "expander received: $1"
    A2U__EXPANDED_STR=
    a2u__exp_remainder=$1
    while [ -n "$a2u__exp_remainder" ]; do
        # left is substring of remainder before the first encountered backslash
        a2u__exp_left=${a2u__exp_remainder%%\\*}

        # append left to A2U__EXPANDED_STR
        A2U__EXPANDED_STR=${A2U__EXPANDED_STR}${a2u__exp_left}
        debug "expander appended: $a2u__exp_left"

        case "$a2u__exp_left" in
        "$a2u__exp_remainder")
            debug "expander ended: $A2U__EXPANDED_STR"
            # no more backslashes left
            break
            ;;
        esac

        # remove left substring and backslash from remainder
        a2u__exp_remainder=${a2u__exp_remainder#"$a2u__exp_left"\\}

        case "$a2u__exp_remainder" in
        # expand and append to A2U__EXPANDED_STR
        s*)
            A2U__EXPANDED_STR=${A2U__EXPANDED_STR}' '
            a2u__exp_remainder=${a2u__exp_remainder#?}
            debug "expander substituted space"
            ;;
        n*)
            A2U__EXPANDED_STR=${A2U__EXPANDED_STR}$A2U__LF
            a2u__exp_remainder=${a2u__exp_remainder#?}
            debug "expander substituted newline"
            ;;
        t*)
            A2U__EXPANDED_STR=${A2U__EXPANDED_STR}'	'
            a2u__exp_remainder=${a2u__exp_remainder#?}
            debug "expander substituted tab"
            ;;
        r*)
            A2U__EXPANDED_STR=${A2U__EXPANDED_STR}${A2U__CR}
            a2u__exp_remainder=${a2u__exp_remainder#?}
            debug "expander substituted caret return"
            ;;
        \\*)
            A2U__EXPANDED_STR=${A2U__EXPANDED_STR}\\
            a2u__exp_remainder=${a2u__exp_remainder#?}
            debug "expander substituted backslash"
            ;;
        # unsupported sequence, reappend backslash
        #*)
        #	A2U__EXPANDED_STR=${A2U__EXPANDED_STR}\\
        #	debug 'expander reappended backslash'
        #	;;
        esac
    done
}

de_tokenize_exec() {
    # Shell-based DE Exec string tokenizer.
    # https://specifications.freedesktop.org/desktop-entry-spec/latest/exec-variables.html
    # How hard can it be?
    # Fills global A2U__EXEC_USEP var with $A2U__USEP-separated command array in place to avoid $() expansion newline issues
    debug "tokenizer received: $1"
    A2U__EXEC_USEP=
    a2u__tok_remainder=$1
    a2u__tok_quoted=0
    a2u__tok_in_space=0
    while [ -n "$a2u__tok_remainder" ]; do
        # left is substring of remainder before the first encountered special char
        a2u__tok_left=${a2u__tok_remainder%%[[:space:]\"\`\$\\\'\>\<\~\|\&\;\*\?\#\(\)]*}

        # left should be safe to append right away
        A2U__EXEC_USEP=${A2U__EXEC_USEP}${a2u__tok_left}
        debug "tokenizer appended: >$a2u__tok_left<"

        # end of the line
        case "$a2u__tok_remainder" in
        "$a2u__tok_left")
            debug "tokenizer is out of special chars"
            break
            ;;
        esac

        # isolate special char
        a2u__tok_remainder=${a2u__tok_remainder#"$a2u__tok_left"}
        a2u__cut=${a2u__tok_remainder#?}
        a2u__tok_char=${a2u__tok_remainder%"$a2u__cut"}
        unset a2u__cut
        # cut it from remainder
        a2u__tok_remainder=${a2u__tok_remainder#"$a2u__tok_char"}

        # check if still in space
        case "${a2u__tok_in_space}${a2u__tok_left}${a2u__tok_char}" in
        1[[:space:]])
            debug "tokenizer still in space :) skipping space character"
            continue
            ;;
        1*)
            debug "tokenizer no longer in space :("
            a2u__tok_in_space=0
            ;;
        esac

        ## decide what to do with the character
        # doublequote while quoted
        case "${a2u__tok_quoted}${a2u__tok_char}" in
        '1"')
            a2u__tok_quoted=0
            debug "tokenizer closed double quotes"
            continue
            ;;
        # doublequote while unquoted
        '0"')
            a2u__tok_quoted=1
            debug "tokenizer opened double quotes"
            continue
            ;;
        # error out on unquoted special chars
        0[\`\$\\\'\>\<\~\|\&\;\*\?\#\(\)])
            error "${A2U__ENTRY_ID}: Encountered unquoted character: '$a2u__tok_char'"
            return 1
            ;;
        # error out on quoted but unescaped chars
        1[\`\$])
            error "${A2U__ENTRY_ID}: Encountered unescaped quoted character: '$a2u__tok_char'"
            return 1
            ;;
        # process quoted escapes
        1\\)
            case "$a2u__tok_remainder" in
            # if there is no next char, fail
            '')
                error "${A2U__ENTRY_ID}: Dangling backslash encountered!"
                return 1
                ;;
            # cut and append the next char right away
            # or a half of multibyte char, the other half should go into the next
            # 'a2u__tok_left' hopefully...
            *)
                a2u__cut=${a2u__tok_remainder#?}
                a2u__tok_char=${a2u__tok_remainder%"$a2u__cut"}
                a2u__tok_remainder=${a2u__cut}
                unset a2u__cut
                A2U__EXEC_USEP=${A2U__EXEC_USEP}${a2u__tok_char}
                debug "tokenizer appended escaped: >$a2u__tok_char<"
                ;;
            esac
            ;;
        # Consider Cosmos
        0[[:space:]])
            case "${a2u__tok_remainder}" in
            # there is non-space to follow
            *[![:space:]]*)
                # append separator
                A2U__EXEC_USEP=${A2U__EXEC_USEP}${A2U__USEP}
                a2u__tok_in_space=1
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
            A2U__EXEC_USEP=${A2U__EXEC_USEP}${a2u__tok_char}
            debug "tokenizer appended quoted char: >$a2u__tok_char<"
            ;;
        # this should not happen
        *)
            error "${A2U__ENTRY_ID}: parsing error at char '$a2u__tok_char', (quoted: $a2u__tok_quoted)"
            return 1
            ;;
        esac
    done
    case "$a2u__tok_quoted" in
    1)
        error "${A2U__ENTRY_ID}: Double quote was not closed!"
        return 1
        ;;
    esac

    [ -n "$A2U__DEBUG" ] || return 0
    # shellcheck disable=SC2086
    debug "tokenizer ended:" "$(
        IFS=$A2U__USEP
        printf '  >%s<\n' $A2U__EXEC_USEP
    )"
}

de_inject_fields() {
    # Operates on argument array and $A2U__EXEC_RSEP_USEP from entry
    # modifies $A2U__EXEC_RSEP_USEP according to args/fields
    # no arguments, erase fields from $A2U__EXEC_RSEP_USEP
    a2u__exec_usep=
    a2u__fu_found=false
    a2u__exec_iter_usep=
    IFS=$A2U__USEP
    for a2u__arg in $A2U__EXEC_RSEP_USEP; do
        case "$a2u__arg" in
        # remove deprecated fields
        *[!%]'%'[dDnNvm]* | '%'[dDnNvm]*) debug "injector removed deprecated '$a2u__arg'" ;;
        # treat file fields
        *[!%]'%'[fFuU]* | '%'[fFuU]*)
            case "$a2u__fu_found" in
            true)
                error "${A2U__ENTRY_ID}: Encountered more than one %[fFuU] field!"
                return 1
                ;;
            esac
            a2u__fu_found=true
            if [ "$#" -eq "0" ]; then
                debug "injector removed '$a2u__arg'"
                continue
            fi
            case "$a2u__arg" in
            *[!%]'%F'* | *'%F'?* | *[!%]'%U'* | *'%U'?*)
                error "${A2U__ENTRY_ID}: Encountered non-standalone field '$a2u__arg'"
                return 1
                ;;
            *[!%]'%f'* | '%f'*)
                for a2u__carg in "$@"; do
                    replace "$a2u__arg" "%f" "$a2u__carg"
                    a2u__carg=$A2U__REPLACED_STR
                    debug "injector adding '$a2u__arg' iteration as '$a2u__carg'"
                    a2u__exec_iter_usep=${a2u__exec_iter_usep}${a2u__exec_iter_usep:+$A2U__USEP}${a2u__carg}
                done
                # placeholder arg
                a2u__exec_usep=${a2u__exec_usep}${a2u__exec_usep:+$A2U__USEP}%%__ITER__%%
                ;;
            '%F')
                for a2u__carg in "$@"; do
                    debug "injector extending '$a2u__arg' with '$a2u__carg'"
                    a2u__exec_usep=${a2u__exec_usep}${a2u__exec_usep:+$A2U__USEP}${a2u__carg}
                done
                ;;
            *[!%]'%u'* | '%u'*)
                for a2u__carg in "$@"; do
                    urlencode "$a2u__carg"
                    a2u__carg=$A2U__URLENCODED_STRING
                    replace "$a2u__arg" "%u" "$a2u__carg"
                    a2u__carg=$A2U__REPLACED_STR
                    debug "injector adding '$a2u__arg' iteration as '$a2u__carg'"
                    a2u__exec_iter_usep=${a2u__exec_iter_usep}${a2u__exec_iter_usep:+$A2U__USEP}${a2u__carg}
                done
                # placeholder arg
                a2u__exec_usep=${a2u__exec_usep}${a2u__exec_usep:+$A2U__USEP}%%__ITER__%%
                ;;
            '%U')
                for a2u__carg in "$@"; do
                    urlencode "$a2u__carg"
                    a2u__carg=$A2U__URLENCODED_STRING
                    debug "injector extending '$a2u__arg' with '$a2u__carg'"
                    a2u__exec_usep=${a2u__exec_usep}${a2u__exec_usep:+$A2U__USEP}${a2u__carg}
                done
                ;;
            *) error "${A2U__ENTRY_ID}: not implemented '$a2u__arg'" ;;
            esac
            ;;
        # icon field
        *[!%]'%i'* | '%i'*)
            if [ -n "$A2U__ENTRY_ICON" ]; then
                replace "$a2u__arg" "%i" "$A2U__ENTRY_ICON"
                a2u__rarg=$A2U__REPLACED_STR
                debug "injector replacing '%i': '$a2u__arg' -> '$a2u__rarg'"
                a2u__exec_usep=${a2u__exec_usep}${a2u__exec_usep:+$A2U__USEP}${a2u__rarg}
            else
                debug "injector removed '$a2u__rarg'"
            fi
            ;;
        # name field
        *[!%]'%c'* | '%c'*)
            replace "$a2u__arg" "%c" "$A2U__ENTRY_NAME"
            a2u__rarg=$A2U__REPLACED_STR
            debug "injector replacing '%c': '$a2u__arg' -> '$a2u__rarg'"
            a2u__exec_usep=${a2u__exec_usep}${a2u__exec_usep:+$A2U__USEP}${a2u__rarg}
            ;;
        # literal %
        *[!%]%%* | %%*)
            replace "$a2u__arg" "%%" "%"
            a2u__rarg=$A2U__REPLACED_STR
            debug "injector replacing '%%': '$a2u__arg' -> '$a2u__rarg'"
            a2u__exec_usep=${a2u__exec_usep}${a2u__exec_usep:+$A2U__USEP}${a2u__rarg}
            ;;
        # invalid field
        *%?* | *[!%]%)
            error "${A2U__ENTRY_ID}: unknown % field in argument '${a2u__arg}'"
            return 1
            ;;
        *)
            debug "injector keeped: '$a2u__arg'"
            a2u__exec_usep=${a2u__exec_usep}${a2u__exec_usep:+$A2U__USEP}${a2u__arg}
            ;;
        esac
    done
    # fill A2U__EXEC_RSEP_USEP with argument iterations
    if [ -n "$a2u__exec_iter_usep" ]; then
        A2U__EXEC_RSEP_USEP=
        for a2u__arg in $a2u__exec_iter_usep; do
            replace "$a2u__exec_usep" "%%__ITER__%%" "$a2u__arg"
            a2u__cmd=$A2U__REPLACED_STR
            A2U__EXEC_RSEP_USEP=${A2U__EXEC_RSEP_USEP}${A2U__EXEC_RSEP_USEP:+$A2U__RSEP}${a2u__cmd}
        done
    else
        A2U__EXEC_RSEP_USEP=$a2u__exec_usep
    fi
    IFS=$A2U__OIFS
}

parse_entry_key() {
    # set global vars or fail entry
    a2u__key=$1
    a2u__value=$2
    a2u__action=$3
    a2u__read_exec=$4
    a2u__in_main=$5
    a2u__in_action=$6

    case "${a2u__in_action};${a2u__key}" in
    'false;'* | 'true;Name' | 'true;Name['*']' | 'true;Exec' | 'true;Icon') true ;;
    *)
        error "${A2U__ENTRY_ID}: Encountered '$a2u__key' key inside action!"
        return 1
        ;;
    esac

    case "$a2u__key" in
    Type)
        debug "captured '$a2u__key' '$a2u__value'"
        case "$a2u__value" in
        Application | Link) A2U__ENTRY_TYPE=$a2u__value ;;
        *)
            error "${A2U__ENTRY_ID}: Unsupported type '$a2u__value'!"
            return 1
            ;;
        esac
        ;;
    Actions)
        # `It is not valid to have an action group for an action identifier not mentioned in the Actions key.
        # Such an action group must be ignored by implementors.`
        # ignore if no action requested
        [ -z "$a2u__action" ] && return 0
        debug "checking for '$a2u__action' in Actions '$a2u__value'"
        IFS=';'
        for a2u__check_action in $a2u__value; do
            case "$a2u__check_action" in
            "$a2u__action")
                IFS=$A2U__OIFS
                a2u__action_listed=true
                return 0
                ;;
            esac
        done
        error "${A2U__ENTRY_ID}: Action '$a2u__action' is not listed in entry!"
        return 1
        ;;
    TryExec)
        if [ -z "$a2u__value" ]; then
            debug "ignored empty '$a2u__key'"
            return 0
        fi
        debug "checking TryExec executable '$a2u__value'"
        de_expand_str "$a2u__value"
        a2u__value=$A2U__EXPANDED_STR
        if ! command -v "$a2u__value" >/dev/null 2>&1; then
            error "${A2U__ENTRY_ID}: TryExec '$a2u__value' failed!"
            return 1
        fi
        ;;
    Hidden)
        debug "checking boolean Hidden '$a2u__value'"
        case "$a2u__value" in
        true)
            error "${A2U__ENTRY_ID}: Entry is Hidden"
            return 1
            ;;
        esac
        ;;
    Exec)
        case "$a2u__read_exec" in
        false)
            debug "ignored Exec from wrong section"
            return 0
            ;;
        esac
        case "$a2u__in_action" in
        true) a2u__action_exec=true ;;
        esac
        debug "read Exec '$a2u__value'"
        # skip acutal reading if array is already filled
        if [ -n "$A2U__EXEC_RSEP_USEP" ]; then
            debug "skipping re-filling exec array"
            return 0
        fi
        # expand string-level escape sequences
        de_expand_str "$a2u__value"
        # Split Exec and save as string delimited by unit separator
        de_tokenize_exec "$A2U__EXPANDED_STR"
        A2U__EXEC_RSEP_USEP=$A2U__EXEC_USEP
        # get Exec[0]
        IFS=$A2U__USEP read -r a2u__exec0 _rest <<-EOCMD
			$A2U__EXEC_RSEP_USEP
		EOCMD
        case "$a2u__exec0" in
        '')
            error "${A2U__ENTRY_ID}: Could not extract Exec[0]!"
            return 1
            ;;
        */*)
            A2U__EXEC_NAME=${a2u__exec0##*/}
            A2U__EXEC_PATH=${a2u__exec0}
            ;;
        *) A2U__EXEC_NAME=${a2u__exec0} ;;
        esac
        debug "checking Exec[0] executable '${A2U__EXEC_PATH:-$A2U__EXEC_NAME}'"
        if ! command -v "${A2U__EXEC_PATH:-$A2U__EXEC_NAME}" >/dev/null 2>&1; then
            error "${A2U__ENTRY_ID}: Exec command '${A2U__EXEC_PATH:-$A2U__EXEC_NAME}' not found"
            return 127
        fi
        ;;
    URL)
        debug "captured '$a2u__key' '$a2u__value'"
        de_expand_str "$a2u__value"
        A2U__ENTRY_URL=$A2U__EXPANDED_STR
        ;;
    "Name[${A2U__LCODE}]")
        case "${a2u__in_main}_${a2u__in_action}_${a2u__value}" in
        true_false_ | false_true_) debug "discarded empty '$a2u__key'" ;;
        true_false_*)
            debug "captured '$a2u__key' '$a2u__value'"
            de_expand_str "$a2u__value"
            A2U__ENTRY_NAME_L=$A2U__EXPANDED_STR
            ;;
        false_true_*)
            debug "captured '$a2u__key' '$a2u__value'"
            de_expand_str "$a2u__value"
            A2U__ENTRY_ACTION_NAME_L=$A2U__EXPANDED_STR
            ;;
        *) debug "discarded '$a2u__key' '$a2u__value'" ;;
        esac
        ;;
    Name)
        case "${a2u__in_main}_${a2u__in_action}_${a2u__value}" in
        true_false_ | false_true_) debug "discarded empty '$a2u__key'" ;;
        true_false_*)
            debug "captured '$a2u__key' '$a2u__value'"
            de_expand_str "$a2u__value"
            A2U__ENTRY_NAME=$A2U__EXPANDED_STR
            ;;
        false_true_*)
            debug "captured '$a2u__key' '$a2u__value'"
            de_expand_str "$a2u__value"
            A2U__ENTRY_ACTION_NAME=$A2U__EXPANDED_STR
            ;;
        *) debug "discarded '$a2u__key' '$a2u__value'" ;;
        esac
        ;;
    "GenericName[${A2U__LCODE}]")
        debug "captured '$a2u__key' '$a2u__value'"
        de_expand_str "$a2u__value"
        A2U__ENTRY_GENERICNAME_L=$A2U__EXPANDED_STR
        ;;
    GenericName)
        debug "captured '$a2u__key' '$a2u__value'"
        de_expand_str "$a2u__value"
        A2U__ENTRY_GENERICNAME=$A2U__EXPANDED_STR
        ;;
    Icon)
        if [ -n "$a2u__value" ] && { [ "$a2u__in_main" = "true" ] || [ "$a2u__in_action" = "true" ]; }; then
            debug "captured '$a2u__key' '$a2u__value'"
            de_expand_str "$a2u__value"
            A2U__ENTRY_ICON=$A2U__EXPANDED_STR
        else
            debug "discarded '$a2u__key' '$a2u__value'"
        fi
        ;;
    Path)
        if [ -z "$a2u__value" ]; then
            debug "ignored empty '$a2u__key'"
            return 0
        fi
        debug "captured '$a2u__key' '$a2u__value'"
        de_expand_str "$a2u__value"
        A2U__ENTRY_WORKDIR=$A2U__EXPANDED_STR
        if [ ! -e "$A2U__ENTRY_WORKDIR" ]; then
            error "${A2U__ENTRY_ID}: Requested 'Path' '${A2U__ENTRY_WORKDIR}' does not exist!"
            return 1
        elif [ ! -d "$A2U__ENTRY_WORKDIR" ]; then
            error "${A2U__ENTRY_ID}: Requested 'Path' '${A2U__ENTRY_WORKDIR}' is not a directory!"
            return 1
        fi
        ;;
    Terminal)
        debug "captured '$a2u__key' '$a2u__value'"
        case "$A2U__FUZZEL_COMPAT" in
        true)
            debug "ignoring Terminal in fuzzel compat mode"
            return 0
            ;;
        esac
        case "$a2u__value" in
        true)
            # if terminal was not requested explicitly, check terminal handler
            case "$A2U__TERMINAL" in
            false) check_terminal_handler ;;
            esac
            A2U__TERMINAL=true
            ;;
        esac
        ;;
    esac
    # By default unrecognised keys, empty lines and comments get ignored
}

read_entry_path() {
    # Read entry from given path
    a2u__entry_path="$1"
    a2u__entry_action="${2-}"
    a2u__read_exec=false
    a2u__action_listed=false
    a2u__in_main=false
    a2u__in_action=false
    a2u__action_exec=false
    a2u__break_on_next_section=false
    # shellcheck disable=SC2016
    debug "reading desktop entry '$a2u__entry_path'${a2u__entry_action:+ action '$a2u__entry_action'}"
    # Let `read` trim leading/trailing whitespace from the line
    while read -r a2u__rep_line; do
        case $a2u__rep_line in
        # `There should be nothing preceding [the Desktop Entry group] in the desktop entry file but [comments]`
        # if entry_action is not requested, allow reading Exec right away from the main group
        '[Desktop Entry]'*)
            debug "entered section: $a2u__rep_line"
            a2u__in_main=true
            if [ -z "$a2u__entry_action" ]; then
                a2u__read_exec=true
                a2u__break_on_next_section=true
            fi
            ;;
        # A `Key=Value` pair
        [a-zA-Z0-9-]*=*)
            # Split
            IFS='=' read -r a2u__key a2u__value <<-EOL
				$a2u__rep_line
			EOL
            # Trim
            { read -r a2u__key && read -r a2u__value; } <<-EOL
				$a2u__key
				$a2u__value
			EOL
            # Parse key, or abort
            parse_entry_key "$a2u__key" "$a2u__value" "$a2u__entry_action" "$a2u__read_exec" "$a2u__in_main" "$a2u__in_action" || return 1
            ;;
        # found requested action, allow reading Exec
        "[Desktop Action ${a2u__entry_action}]"*)
            debug "entered section: $a2u__rep_line"
            a2u__in_main=false
            a2u__break_on_next_section=true
            case "$a2u__action_listed" in
            true)
                a2u__read_exec=true
                a2u__in_action=true
                ;;
            *)
                error "${A2U__ENTRY_ID}: Action '$a2u__entry_action' is not listed in Actions key!"
                return 1
                ;;
            esac
            ;;
        # Start of the next group header, stop if already read exec
        '['*)
            debug "entered section: $a2u__rep_line"
            [ "$a2u__break_on_next_section" = "true" ] && break
            a2u__in_main=false
            a2u__in_action=false
            a2u__read_exec=false
            ;;
        esac
        # By default empty lines and comments get ignored
    done <"$a2u__entry_path"

    # check for required things for action
    if [ -n "$a2u__entry_action" ]; then
        case "$a2u__action_listed" in
        true) true ;;
        *)
            error "${A2U__ENTRY_ID}: Action '$a2u__entry_action' is not listed in Actions key or does not exist!"
            return 1
            ;;
        esac
        if [ "$a2u__action_exec" != "true" ] || [ -z "${A2U__ENTRY_ACTION_NAME_L:-${A2U__ENTRY_ACTION_NAME:-}}" ]; then
            error "${A2U__ENTRY_ID}: Action '$a2u__entry_action' is incomplete"
            return 1
        fi
    fi

    # check for required things for types
    case "${A2U__ENTRY_TYPE};;${A2U__EXEC_RSEP_USEP};;${A2U__ENTRY_URL}" in
    'Application;;'?*';;' | 'Link;;;;'?*) true ;;
    ';;'*)
        error "${A2U__ENTRY_ID}: type not specified!"
        return 1
        ;;
    *)
        error "${A2U__ENTRY_ID}: type and keys mismatch: '$A2U__ENTRY_TYPE', Exec is$([ -z "${A2U__EXEC_RSEP_USEP}" ] && echo ' not') set, URL is$([ -z "${A2U__ENTRY_URL}" ] && echo ' not') set"
        return 1
        ;;
    esac
}

random_string() {
    # gets random 8 hex characters
    LC_ALL=C tr -dc '0-9a-f' </dev/urandom 2>/dev/null | head -c 8
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

is_url() {
    # checks if string starts with a scheme
    case "${1%%':'*}" in
    [!a-zA-Z]* | *[!a-zA-Z0-9+.-]*) return 1 ;;
    *[a-zA-Z0-9+.-]*) return 0 ;;
    *) return 1 ;;
    esac
}

is_file_url() {
    case "$1" in
    'file://'*) return 0 ;;
    *) return 1 ;;
    esac
}

urlencode() {
    # pretty dumb urlencode,
    # produces file:// URL or returns existing URL as is
    # writes to A2U__URLENCODED_STRING var
    debug "urlencode input: $1"
    a2u__ue_string=$1
    # already an url
    if is_url "$a2u__ue_string"; then
        debug "urlencode: return as is"
        A2U__URLENCODED_STRING=$a2u__ue_string
        return
    fi
    case "$a2u__ue_string" in
    # assuming absolute path
    /*) true ;;
    # assuming relative path
    *)
        debug "urlencode: prepended $PWD"
        a2u__ue_string=${PWD}/$a2u__ue_string
        ;;
    esac

    case "$a2u__ue_string" in
    # if contains extra chars, encode
    *[!._~0-9A-Za-z/-]*)
        debug "urlencode: encoding"
        # shellcheck disable=SC2030
        A2U__URLENCODED_STRING="file://$(
            while [ -n "$a2u__ue_string" ]; do
                a2u__ue_right=${a2u__ue_string#?}
                a2u__ue_char=${a2u__ue_string%"$a2u__ue_right"}
                case $a2u__ue_char in
                [._~0-9A-Za-z/-])
                    debug "urlencode string $a2u__ue_string" "urlencode right $a2u__ue_right" "urlencode char '$a2u__ue_char' (lit)"
                    printf '%s' "$a2u__ue_char"
                    ;;
                *)
                    debug "urlencode string $a2u__ue_string" "urlencode right $a2u__ue_right" "urlencode char '$a2u__ue_char' (enc)"
                    printf '%%%02x' "'$a2u__ue_char"
                    ;;
                esac
                a2u__ue_string=$a2u__ue_right
            done
        )"
        ;;
    # no extra chars, append as is
    *)
        debug "urlencode: just return with file://"
        # shellcheck disable=SC2031
        A2U__URLENCODED_STRING="file://${a2u__ue_string}"
        ;;
    esac
    debug "urlencode output: $A2U__URLENCODED_STRING"
}

urldecode() {
    # pretty dumb % urldecode, no scheme
    # writes to A2U__URLDECODED_STR var
    debug "urldecode input: $1"
    case "${1}" in
    *%[0-9a-fA-F][0-9a-fA-F]*) true ;;
    *)
        debug "urldecode: return as is"
        A2U__URLDECODED_STR="$1"
        return 0
        ;;
    esac
    a2u__ud_remainder=${1}
    # no way forward but via a couple of forks,
    # need to feed printf ouptut to another printf
    A2U__URLDECODED_STR=$(
        while [ -n "${a2u__ud_remainder}" ]; do
            # left part before first encounter of %XX
            a2u__ud_left=${a2u__ud_remainder%%"%"[0-9a-fA-F][0-9a-fA-F]*}
            # append
            printf '%s\n' "${a2u__ud_left}"
            case "${a2u__ud_left}" in
            # nothing left to cut
            "${a2u__ud_remainder}") break ;;
            esac
            # %XX and reminder after %XX
            a2u__ud_code=${a2u__ud_remainder#"${a2u__ud_left}%"}
            a2u__ud_remainder=${a2u__ud_code#??}
            a2u__ud_code=${a2u__ud_code%"${a2u__ud_remainder}"}
            # append octal substring
            printf '\\0%03o\n' "0x${a2u__ud_code}"
        done | while IFS= read -r a2u__ud_chunk; do
            case "$a2u__ud_chunk" in
            # convert from octal to string
            '\0'[0-7][0-7][0-7]) printf '%b' "$a2u__ud_chunk" ;;
            # print as is
            *) printf '%s' "$a2u__ud_chunk" ;;
            esac
        done
    )
    debug "urldecode output: $A2U__URLDECODED_STR"
}

validate_file_url() {
    # check URL for invalid/path-unsafe chars and forbidden/malformed sequences
    # (only suitable for file:// without scheme)
    case "$1" in
    '')
        error "File URL is empty"
        return 1
        ;;
    [!/]*)
        error "File URL does not start with /: $1"
        return 1
        ;;
    *[!%a-zA-Z0-9/:@._~!\$\&\'\(\)*+,\;=-]*)
        error "URL contains invalid characters: $1"
        return 1
        ;;
    *%00* | *%2[Ff]* | *%5[Cc]* | *%2[Ee]%2[Ee]* | *%01* | *%1[0-9a-fA-F]* | *%7[Ff]*)
        error "URL contains forbidden %-sequences: $1"
        return 1
        ;;
    *%[0-9a-fA-F][!0-9a-fA-F]* | *%[!0-9a-fA-F]* | *%?[!0-9a-fA-F]* | *%? | *%)
        error "URL contains malformed %-sequences: $1"
        return 1
        ;;
    esac
    return 0
}

gen_unit_id() {
    # generate Unit ID based on Entry ID or exec name if A2U__UNIT_ID is not already set
    # sets A2U__UNIT_ID

    if [ -z "$A2U__UNIT_ID" ]; then
        if [ -z "$A2U__UNIT_APP_SUBSTRING" ] && [ -n "${A2U__ENTRY_ID}" ]; then
            A2U__UNIT_APP_SUBSTRING=${A2U__ENTRY_ID%.desktop}
        elif [ -z "$A2U__UNIT_APP_SUBSTRING" ]; then
            A2U__UNIT_APP_SUBSTRING=${A2U__EXEC_NAME}
        fi
        case "${A2U__INSERT_XSD}" in
        true)
            if [ -n "${XDG_SESSION_DESKTOP:-}" ]; then
                A2U__UNIT_DESKTOP_SUBSTRING=${XDG_SESSION_DESKTOP}
            elif [ -n "${XDG_CURRENT_DESKTOP:-}" ]; then
                A2U__UNIT_DESKTOP_SUBSTRING=${XDG_CURRENT_DESKTOP%%:*}
            else
                A2U__UNIT_DESKTOP_SUBSTRING=NoDesktop
            fi
            ;;
        false)
            A2U__UNIT_DESKTOP_SUBSTRING=
            ;;
        esac
        # escape substrings if needed
        case "${A2U__UNIT_DESKTOP_SUBSTRING}${A2U__UNIT_APP_SUBSTRING}" in
        *[!a-zA-Z:_.]*)
            # prepend a character to shield potential . from being first
            read -r A2U__UNIT_DESKTOP_SUBSTRING A2U__UNIT_APP_SUBSTRING <<-EOL
				$(systemd-escape "A$A2U__UNIT_DESKTOP_SUBSTRING" "A$A2U__UNIT_APP_SUBSTRING")
			EOL
            # remove character
            A2U__UNIT_DESKTOP_SUBSTRING=${A2U__UNIT_DESKTOP_SUBSTRING#A}
            A2U__UNIT_APP_SUBSTRING=${A2U__UNIT_APP_SUBSTRING#A}
            ;;
        esac

        A2U__RANDOM_STRING=$(random_string)
        case "$A2U__UNIT_TYPE" in
        service)
            A2U__UNIT_ID="app${A2U__UNIT_DESKTOP_SUBSTRING:+-}${A2U__UNIT_DESKTOP_SUBSTRING}-${A2U__UNIT_APP_SUBSTRING}@${A2U__RANDOM_STRING}.service"
            ;;
        scope)
            A2U__UNIT_ID="app${A2U__UNIT_DESKTOP_SUBSTRING:+-}${A2U__UNIT_DESKTOP_SUBSTRING}-${A2U__UNIT_APP_SUBSTRING}-${A2U__RANDOM_STRING}.scope"
            ;;
        *)
            error "Unsupported unit type '$A2U__UNIT_TYPE'!"
            return 1
            ;;
        esac
    else
        case "$A2U__UNIT_ID" in
        *?".$A2U__UNIT_TYPE") true ;;
        *)
            error "Unit ID '$A2U__UNIT_ID' is not of type '$A2U__UNIT_TYPE'"
            return 1
            ;;
        esac
    fi
    if [ "${#A2U__UNIT_ID}" -gt "254" ]; then
        error "Unit ID too long (${#A2U__UNIT_ID})!: $A2U__UNIT_ID"
        return 1
    fi
    case "$A2U__UNIT_ID" in
    .service | .scope | '')
        error "Unit ID is empty!"
        return 1
        ;;
    *.service | *.scope) true ;;
    *)
        error "Invalid Unit ID '$A2U__UNIT_ID'!"
        return 1
        ;;
    esac
}

randomize_unit_id() {
    # updates random string in existing A2U__UNIT_ID

    if [ -z "$A2U__RANDOM_STRING" ]; then
        debug "refusing to randomize unit ID"
        return 0
    fi
    A2U__NEW_RANDOM_STRING=$(random_string)
    debug "new random string: $A2U__NEW_RANDOM_STRING"
    A2U__UNIT_ID=${A2U__UNIT_ID%"${A2U__RANDOM_STRING}.${A2U__UNIT_TYPE}"}${A2U__NEW_RANDOM_STRING}.${A2U__UNIT_TYPE}
    #"
    A2U__RANDOM_STRING=${A2U__NEW_RANDOM_STRING}
}

systemd_run_finalize_usep() {
    # wrapper for systemd-run
    # generate and prepend common args, append execution modification flag
    # fill A2U__FINAL_EXEC_RSEP_USEP
    A2U__UNIT_SLICE_ID=${A2U__UNIT_SLICE_ID:-app-graphical.slice}
    if [ -z "$A2U__UNIT_DESCRIPTION" ] && [ -n "${A2U__ENTRY_NAME_L:-$A2U__ENTRY_NAME}" ] && [ -n "${A2U__ENTRY_GENERICNAME_L:-$A2U__ENTRY_GENERICNAME}" ]; then
        A2U__UNIT_DESCRIPTION="${A2U__ENTRY_NAME_L:-$A2U__ENTRY_NAME} - ${A2U__ENTRY_GENERICNAME_L:-$A2U__ENTRY_GENERICNAME}"
    elif [ -z "$A2U__UNIT_DESCRIPTION" ] && [ -n "${A2U__ENTRY_NAME_L:-$A2U__ENTRY_NAME}" ]; then
        A2U__UNIT_DESCRIPTION="${A2U__ENTRY_NAME_L:-$A2U__ENTRY_NAME}"
    elif [ -z "$A2U__UNIT_DESCRIPTION" ] && [ -n "$A2U__EXEC_NAME" ]; then
        A2U__UNIT_DESCRIPTION=${A2U__EXEC_NAME}
    fi

    set -- \
        --slice="$A2U__UNIT_SLICE_ID" \
        --unit="$A2U__UNIT_ID" \
        --description="$A2U__UNIT_DESCRIPTION" \
        --quiet \
        --collect \
        -- "$@"

    # prepend extra properties
    IFS=${A2U__USEP}
    for a2u__prop in $A2U__UNIT_PROPERTIES; do
        set -- "--property=${a2u__prop}" "$@"
    done
    IFS=${A2U__OIFS}

    if [ -n "$A2U__ENTRY_PATH" ]; then
        # prepend SourcePath property
        set -- "--property=SourcePath=${A2U__ENTRY_PATH}" "$@"
    fi

    if [ "$A2U__PART_OF_GST" = "true" ]; then
        # prepend graphical session dependency/ordering args
        set -- \
            --property=After=graphical-session.target \
            --property=PartOf=graphical-session.target \
            "$@"
    fi

    if [ -n "$A2U__ENTRY_WORKDIR" ]; then
        # prepend requested Path or samedir
        set -- "--working-directory=${A2U__ENTRY_WORKDIR}" "$@"
    else
        set -- --same-dir "$@"
    fi

    # prepend unit type-dependent args
    case "$A2U__UNIT_TYPE" in
    scope) set -- --scope "$@" ;;
    service)
        set -- --property=Type=exec --property=ExitType=cgroup "$@"
        # pass session-specific variables from compositor
        for a2u__svar in XDG_SEAT XDG_SEAT_PATH XDG_SESSION_ID XDG_SESSION_PATH XDG_VTNR; do
            eval "a2u__sval=\${${a2u__svar}:-}"
            if [ -n "$a2u__sval" ]; then
                set -- "--setenv=${a2u__svar}=${a2u__sval}" "$@"
            fi
        done
        # silence service
        case "$A2U__SILENT" in
        # silence out
        out)
            set -- --property=StandardOutput=null "$@"
            # unsilence stderr if it is inheriting
            a2u__dso=
            a2u__dse=
            while IFS='=' read -r a2u__key a2u__value; do
                case "$a2u__key" in
                DefaultStandardOutput) a2u__dso=$a2u__value ;;
                DefaultStandardError) a2u__dse=$a2u__value ;;
                esac
            done <<-EOF
				$(systemctl --user show --property DefaultStandardOutput --property DefaultStandardError)
			EOF
            case "$a2u__dse" in
            inherit) set -- --property=StandardError="$a2u__dso" "$@" ;;
            esac
            ;;
        # silence err
        err) set -- --property=StandardError=null "$@" ;;
        # silence both
        both) set -- --property=StandardOutput=null --property=StandardError=null "$@" ;;
        esac
        ;;
    esac

    # final command
    set -- systemd-run --user "$@"

    [ -z "$A2U__DEBUG" ] || debug "systemd run" "$(printf '  >%s<\n' "$@")"

    # Flag to represent test and scope silence modes
    # print args in test mode
    a2u__flag=0
    case "$A2U__TEST_MODE" in
    true) a2u__flag=T ;;
    *)
        # silence scope output
        case "${A2U__UNIT_TYPE}_${A2U__SILENT}" in
        scope_out) a2u__flag=O ;;
        scope_err) a2u__flag=E ;;
        scope_both) a2u__flag=B ;;
        esac
        ;;
    esac

    # compose array with $A2U__USEP separator
    a2u__command_usep=
    for a2u__arg in "$@" "${a2u__flag}"; do
        a2u__command_usep=${a2u__command_usep}${a2u__command_usep:+$A2U__USEP}${a2u__arg}
    done

    # Append to A2U__FINAL_EXEC_RSEP_USEP
    A2U__FINAL_EXEC_RSEP_USEP=${A2U__FINAL_EXEC_RSEP_USEP}${A2U__FINAL_EXEC_RSEP_USEP:+${A2U__RSEP}}${a2u__command_usep}
}

parse_main_arg() {
    # fills some of global variables depending on main arg $1
    A2U__MAIN_ARG=$1

    A2U__ENTRY_ID=
    A2U__ENTRY_ACTION=
    A2U__ENTRY_PATH=
    A2U__EXEC_NAME=
    A2U__EXEC_PATH=

    case "$A2U__MAIN_ARG" in
    '')
        error "Empty main argument"
        return 1
        ;;
    *.desktop:*)
        IFS=':' read -r A2U__ENTRY_ID A2U__ENTRY_ACTION <<-EOA
			$A2U__MAIN_ARG
		EOA
        ;;
    *.desktop)
        A2U__ENTRY_ID=$A2U__MAIN_ARG
        A2U__ENTRY_ACTION=
        ;;
    esac
    debug "A2U__ENTRY_ID: $A2U__ENTRY_ID" "A2U__ENTRY_ACTION: $A2U__ENTRY_ACTION"

    if [ -n "$A2U__ENTRY_ID" ]; then
        case "$A2U__ENTRY_ID" in
        */*)
            # this is a path
            A2U__ENTRY_PATH=$A2U__ENTRY_ID
            A2U__ENTRY_ID=${A2U__ENTRY_ID##*/}
            if [ ! -f "$A2U__ENTRY_PATH" ]; then
                error "File not found: '$A2U__ENTRY_PATH'"
                return 127
            fi
            ;;
        esac

        if ! validate_entry_id "$A2U__ENTRY_ID"; then
            if [ -z "$A2U__ENTRY_PATH" ]; then
                error "Invalid Entry ID '$A2U__ENTRY_ID'!"
                return 1
            else
                warning "Invalid Entry ID '$A2U__ENTRY_ID'!"
            fi
        fi
        if ! validate_action_id "$A2U__ENTRY_ACTION"; then
            error "Invalid Entry Action ID '$A2U__ENTRY_ACTION'!"
            return 1
        fi
        return 0
    fi

    # what's left is executable
    case "$A2U__MAIN_ARG" in
    */*)
        A2U__EXEC_PATH=$A2U__MAIN_ARG
        A2U__EXEC_NAME=${A2U__EXEC_PATH##*/}
        debug "A2U__EXEC_PATH: $A2U__EXEC_PATH" "A2U__EXEC_NAME: $A2U__EXEC_NAME"
        if [ ! -f "$A2U__EXEC_PATH" ]; then
            error "File not found: '$A2U__EXEC_PATH'"
            return 127
        fi
        if [ ! -x "$A2U__EXEC_PATH" ]; then
            error "File is not executable: '$A2U__EXEC_PATH'"
            return 1
        fi
        return
        ;;
    esac

    A2U__EXEC_NAME=$A2U__MAIN_ARG
    debug "A2U__EXEC_NAME: $A2U__EXEC_NAME"
    if ! command -v "$A2U__EXEC_NAME" >/dev/null 2>&1; then
        error "Executable not found: '$A2U__EXEC_NAME'"
        return 127
    fi
}

check_terminal_handler() {
    # checks terminal handler availability
    if ! command -v "$A2U__TERMINAL_HANDLER" >/dev/null; then
        error "Terminal launch requested but '$A2U__TERMINAL_HANDLER' is unavailable!"
        exit 1
    fi
}

get_mime() {
    # gets mime type of file or url
    # writes to A2U__MIME var
    a2u__f_mime=
    if is_url "$1"; then
        a2u__scheme=${1%%:*}
        debug "scheme '$a2u__scheme'"
        a2u__f_mime=x-scheme-handler/$a2u__scheme
    else
        a2u__f_mime=$(xdg-mime query filetype "$1")
    fi

    case "$a2u__f_mime" in
    '' | 'x-scheme-handler/')
        error "Could not query mime type for '$1'"
        return 1
        ;;
    *)
        debug "got mime '$a2u__f_mime' for '$1'"
        A2U__MIME=$a2u__f_mime
        ;;
    esac
}

get_assoc() {
    # gets file association for mime type
    # writes to A2U__ASSOC var
    a2u__f_assoc=$(xdg-mime query default "$1")
    case "$a2u__f_assoc" in
    ?*.desktop)
        debug "got association '$a2u__f_assoc' for mime '$1'"
        A2U__ASSOC=$a2u__f_assoc
        ;;
    *)
        error "Could not query association for mime '$1'"
        return 1
        ;;
    esac
}

gen_exec() {
    # main'ish function, generates command array(s)
    # commands separated by record separator with extra trailing one
    # arguments separated by unit separator with [TOEB] function flag appended
    # writes to A2U__EXEC_RSEP_USEP

    [ -z "$A2U__DEBUG" ] || debug "initial args:" "$(printf '  >%s<\n' "$@")"

    A2U__TEST_MODE=false

    A2U__UNIT_TYPE=${APP2UNIT_TYPE:-scope}
    case "$A2U__UNIT_TYPE" in
    service | scope) true ;;
    *)
        error "Unsupported unit type '$A2U__UNIT_TYPE'!"
        exit 1
        ;;
    esac

    # deal with unit slice choices and default
    A2U__UNIT_SLICE_CHOICES=${APP2UNIT_SLICES:-"a=app.slice b=background.slice s=session.slice"}
    for a2u__choice in $A2U__UNIT_SLICE_CHOICES; do
        debug "evaluating slice choice '$a2u__choice'"
        a2u__slice_abbr=
        a2u__slice_id=
        case "$a2u__choice" in
        *[!a-zA-Z0-9=._-]* | *=*=* | *[!a-z]*=* | *=[!a-zA-Z0-9._-]* | *[!.][!s][!l][!i][!c][!e])
            error "Invalid slice choice '$a2u__choice', ignoring."
            continue
            ;;
        [a-z]*=[a-zA-Z0-9_.-]*.slice)
            IFS='=' read -r a2u__slice_abbr a2u__slice_id <<-EOF
				$a2u__choice
			EOF
            ;;
        *)
            error "Invalid slice choice '$a2u__choice', ignoring."
            continue
            ;;
        esac
        if [ -z "$A2U__UNIT_SLICE_ID" ]; then
            A2U__UNIT_SLICE_CHOICES=
            A2U__UNIT_SLICE_ID="${a2u__slice_id}"
            debug "reset default slice as '${a2u__slice_id}'"
        fi
        debug "adding choice ${a2u__slice_abbr}=${a2u__slice_id}"
        A2U__UNIT_SLICE_CHOICES=${A2U__UNIT_SLICE_CHOICES}${A2U__UNIT_SLICE_CHOICES:+ }${a2u__slice_abbr}=${a2u__slice_id}
    done
    if [ -z "$A2U__UNIT_SLICE_ID" ]; then
        A2U__UNIT_SLICE_ID=app.slice
        debug "falling back to default slice 'app.slice'"
    fi

    A2U__INSERT_XSD=true
    if [ -z "${APP2UNIT_INSERT_XSD:-}" ]; then
        A2U__INSERT_XSD=true
    else
        if check_bool "$APP2UNIT_INSERT_XSD"; then
            A2U__INSERT_XSD=true
        else
            A2U__INSERT_XSD=false
        fi
    fi

    A2U__PART_OF_GST=true
    if [ -z "${APP2UNIT_PART_OF_GST:-}" ]; then
        A2U__PART_OF_GST=true
    else
        if check_bool "$APP2UNIT_PART_OF_GST"; then
            A2U__PART_OF_GST=true
        else
            A2U__PART_OF_GST=false
        fi
    fi

    A2U__TERMINAL=false
    A2U__FUZZEL_COMPAT=false
    A2U__OPENER_MODE=false

    a2u__capture_terminal_args=false
    case "$A2U__SELF_NAME" in
    *-open | *-open-scope | *-open-service)
        A2U__OPENER_MODE=true
        case "$A2U__SELF_NAME" in
        *-scope) A2U__UNIT_TYPE=scope ;;
        *-service) A2U__UNIT_TYPE=service ;;
        esac
        ;;
    *-term | *-terminal | *-term-scope | *-terminal-scope | *-term-service | *-terminal-service)
        A2U__TERMINAL=true
        a2u__capture_terminal_args=true
        case "$A2U__SELF_NAME" in
        *-scope) A2U__UNIT_TYPE=scope ;;
        *-service) A2U__UNIT_TYPE=service ;;
        esac
        ;;
    esac

    # will be set where needed
    A2U__RANDOM_STRING=

    A2U__LCODE=${LANGUAGE:-"$LANG"}
    A2U__LCODE=${A2U__LCODE%_*}
    A2U__LCODE=${A2U__LCODE:-A2U__NOLCODE}

    # expand short args
    a2u__first=true
    a2u__found_delim=false
    for a2u__arg in "$@"; do
        case "$a2u__first" in
        true)
            set --
            a2u__first=false
            ;;
        esac
        case "$a2u__found_delim" in
        true)
            set -- "$@" "$a2u__arg"
            continue
            ;;
        esac
        case "$a2u__arg" in
        --)
            a2u__found_delim=true
            set -- "$@" "$a2u__arg"
            ;;
        -[a-zA-Z][a-zA-Z]*)
            a2u__arg=${a2u__arg#-}
            while [ -n "$a2u__arg" ]; do
                a2u__cut=${a2u__arg#?}
                a2u__char=${a2u__arg%"$a2u__cut"}
                set -- "$@" "-$a2u__char"
                a2u__arg=$a2u__cut
            done
            ;;
        *) set -- "$@" "$a2u__arg" ;;
        esac
    done

    a2u__part_of_gst_set=false
    a2u__insert_xsd_set=false
    # parse args
    A2U__TERMINAL_ARGS_USEP=
    while [ "$#" -gt "0" ]; do
        case "$1" in
        -h | --help)
            help
            exit 0
            ;;
        -s)
            debug "a2u__arg '$1' '${2:-}'"
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
                A2U__UNIT_SLICE_ID=$2
                shift 2
                continue
                ;;
            *)
                for a2u__choice in $A2U__UNIT_SLICE_CHOICES; do
                    IFS='=' read -r a2u__slice_abbr a2u__slice_id <<-EOF
						$a2u__choice
					EOF
                    case "$a2u__slice_abbr" in
                    "$2")
                        A2U__UNIT_SLICE_ID=$a2u__slice_id
                        shift 2
                        continue 2
                        ;;
                    esac
                done
                error "'$2' does not point to a slice choice!" "Choices: $A2U__UNIT_SLICE_CHOICES" "$(usage)"
                exit 1
                ;;
            esac
            error "Failed to parse '-s' argument" "$(usage)"
            exit 1
            ;;
        -t)
            debug "arg '$1' '${2:-}'"
            case "${2:-}" in
            scope | service) A2U__UNIT_TYPE=$2 ;;
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
            elif [ -n "$A2U__UNIT_ID" ]; then
                error "Conflicting options: -a, -u!" "$(usage)"
                exit 1
            else
                A2U__UNIT_APP_SUBSTRING=$2
            fi
            shift 2
            ;;
        -u)
            debug "arg '$1' '${2:-}'"
            if [ -z "${2:-}" ]; then
                error "Expected Unit ID for -u!" "$(usage)"
                exit 1
            elif [ -n "$A2U__UNIT_APP_SUBSTRING" ]; then
                error "Conflicting options: -u, -a!" "$(usage)"
                exit 1
            else
                A2U__UNIT_ID=$2
            fi
            shift 2
            ;;
        -d)
            debug "arg '$1' '${2:-}'"
            if [ -z "${2:-}" ]; then
                error "Expected unit description for -d!" "$(usage)"
                exit 1
            else
                A2U__UNIT_DESCRIPTION="$2"
            fi
            shift 2
            ;;
        -x)
            case "$a2u__insert_xsd_set" in
            true)
                error "-x conflicts with -X" "$(usage)"
                exit 1
                ;;
            esac
            debug "arg '$1'"
            A2U__INSERT_XSD=false
            a2u__insert_xsd_set=true
            shift
            ;;
        -X)
            case "$a2u__insert_xsd_set" in
            true)
                error "-X conflicts with -x" "$(usage)"
                exit 1
                ;;
            esac
            debug "arg '$1'"
            A2U__INSERT_XSD=true
            a2u__insert_xsd_set=true
            shift
            ;;
        -c)
            case "$a2u__part_of_gst_set" in
            true)
                error "-c conflicts with -C" "$(usage)"
                exit 1
                ;;
            esac
            debug "arg '$1'"
            A2U__PART_OF_GST=false
            a2u__part_of_gst_set=true
            shift
            ;;
        -C)
            case "$a2u__part_of_gst_set" in
            true)
                error "-C conflicts with -c" "$(usage)"
                exit 1
                ;;
            esac
            debug "arg '$1'"
            A2U__PART_OF_GST=true
            a2u__part_of_gst_set=true
            shift
            ;;
        -S)
            debug "arg '$1' '${2:-}'"
            case "${2:-}" in
            out | err | both) A2U__SILENT=$2 ;;
            *)
                error "Expected silent mode out|err|both for -S, got '${2:-}'!" "$(usage)"
                exit 1
                ;;
            esac
            shift 2
            ;;
        -T)
            A2U__TERMINAL=true
            a2u__capture_terminal_args=true
            debug "arg '$1'"
            check_terminal_handler
            shift
            ;;
        -O | --open)
            A2U__OPENER_MODE=true
            debug "arg '$1'"
            shift
            ;;
        -p)
            debug "arg '$1' '${2:-}'"
            case "${2:-}" in
            @)
                error "Expected file path after @ for -p" "$(usage)"
                exit 1
                ;;
            @*)
                a2u__prop_file=${2#@}
                if [ -f "$a2u__prop_file" ]; then
                    a2u__counter=0
                    while read -r a2u__prop_line; do
                        a2u__counter=$((a2u__counter + 1))
                        case "$a2u__prop_line" in
                        '' | '#' | '#'*) continue ;;
                        '='*)
                            error "File: ${a2u__prop_file}:${a2u__counter}" "Expected unit property assignment for -p, got '${a2u__prop_line}'!" "$(usage)"
                            exit 1
                            ;;
                        *'='*) A2U__UNIT_PROPERTIES=${A2U__UNIT_PROPERTIES}${A2U__UNIT_PROPERTIES:+${A2U__USEP}}${a2u__prop_line} ;;
                        *)
                            error "File: ${a2u__prop_file}:${a2u__counter}" "Expected unit property assignment for -p, got '${a2u__prop_line}'!" "$(usage)"
                            exit 1
                            ;;
                        esac
                    done <"$a2u__prop_file"
                else
                    error "Property file '$a2u__prop_file' not found!"
                    exit 127
                fi
                ;;
            '='*)
                error "Expected unit property assignment for -p, got '${2:-}'!" "$(usage)"
                ;;
            *'='*)
                A2U__UNIT_PROPERTIES=${A2U__UNIT_PROPERTIES}${A2U__UNIT_PROPERTIES:+${A2U__USEP}}${2}
                ;;
            *)
                error "Expected unit property assignment for -p, got '${2:-}'!" "$(usage)"
                exit 1
                ;;
            esac
            shift 2
            ;;
        --fuzzel-compat)
            debug "arg '$1'"
            if [ -z "${DESKTOP_ENTRY_NAME:-}" ]; then
                debug "enabled fuzzel compat"
                A2U__FUZZEL_COMPAT=true
            else
                debug "skipping old fuzzel compat since DESKTOP_ENTRY_NAME is defined"
            fi
            shift
            ;;
        --test)
            A2U__TEST_MODE=true
            debug "arg '$1'"
            shift
            ;;
        --)
            debug "arg '$1', breaking"
            shift
            break
            ;;
        -*)
            case "$a2u__capture_terminal_args" in
            false)
                error "Unknown option '$1'!" "$(usage)"
                exit 1
                ;;
            true)
                debug "storing unknown opt '$1' for terminal"
                A2U__TERMINAL_ARGS_USEP=${A2U__TERMINAL_ARGS_USEP}${A2U__TERMINAL_ARGS_USEP:+$A2U__USEP}${1}
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

    if [ "$#" -eq "0" ] && [ "$A2U__TERMINAL" = "false" ]; then
        error "Arguments expected" "$(usage)"
        exit 1
    fi

    if [ "$A2U__FUZZEL_COMPAT" = "true" ]; then
        if [ -z "${FUZZEL_DESKTOP_FILE_ID:-}" ]; then
            debug "no FUZZEL_DESKTOP_FILE_ID, cancelling FUZZEL_COMPAT"
            A2U__FUZZEL_COMPAT=false
        fi
        if [ "$A2U__OPENER_MODE" = "true" ]; then
            debug "opener mode, cancelling FUZZEL_COMPAT"
            A2U__FUZZEL_COMPAT=false
        fi
    fi

    if [ "$A2U__OPENER_MODE" = "true" ]; then
        if [ "$#" = "0" ]; then
            error "File(s) or URL(s) expected for open mode."
            exit 1
        fi
        A2U__MAIN_ARG=
        # determine if file or URL, get associations for A2U__MAIN_ARG
        a2u__first_arg=true
        for a2u__arg in "$@"; do
            case "${a2u__first_arg}" in
            true)
                # drop arg array for re-adding
                set --
                a2u__first_arg=
                ;;
            esac
            # convert file:// url to path
            if is_file_url "${a2u__arg}"; then
                validate_file_url "${a2u__arg#"file://"}"
                urldecode "${a2u__arg#"file://"}"
                a2u__arg=$A2U__URLDECODED_STR
            fi
            get_mime "$a2u__arg"
            a2u__mime=$A2U__MIME
            get_assoc "$a2u__mime"
            a2u__assoc=$A2U__ASSOC
            if [ -z "$A2U__MAIN_ARG" ]; then
                debug "setting MAIN_ARG from association for '$a2u__arg': '$a2u__assoc'"
                A2U__MAIN_ARG=$a2u__assoc
            elif [ "$A2U__MAIN_ARG" = "$a2u__assoc" ]; then
                debug "arg '$a2u__arg' has the same association"
                true
            else
                error "Can not open multiple files/URLs with different associations"
                exit 1
            fi
            # re-add arg
            set -- "$@" "$a2u__arg"
        done
    elif [ "$A2U__FUZZEL_COMPAT" = "true" ]; then
        debug "setting A2U__MAIN_ARG from FUZZEL_DESKTOP_FILE_ID: '$FUZZEL_DESKTOP_FILE_ID'" "passing arguments to exec array"
        A2U__MAIN_ARG=$FUZZEL_DESKTOP_FILE_ID
        # Fuzzel compat mode, awaiting for https://codeberg.org/dnkl/fuzzel/issues/292
        # ignore command from entry, take only metadata, use arg array as is.
        if ! command -v "$1" >/dev/null 2>&1; then
            error "Executable not found: '$1'"
            exit 127
        fi
        for a2u__item in "$@"; do
            A2U__EXEC_RSEP_USEP=${A2U__EXEC_RSEP_USEP}${a2u__item}${A2U__USEP}
        done
        A2U__EXEC_RSEP_USEP=${A2U__EXEC_RSEP_USEP%"$A2U__USEP"}
    elif [ "$#" -eq "0" ] && [ "$A2U__TERMINAL" = "true" ]; then
        # special case for launching just terminal

        # get entry path and cmdline from terminal handler
        if a2u__path_and_cmd=$(
            IFS=$A2U__USEP
            # shellcheck disable=SC2086
            set -- $A2U__TERMINAL_ARGS_USEP
            IFS=$A2U__OIFS
            # prevent old xdg-terminal-exec from running anything
            unset DISPLAY WAYLAND_DISPLAY
            "$A2U__TERMINAL_HANDLER" --print-path --print-cmd='\037' "$@"
        ) && case "$a2u__path_and_cmd" in '/'*".desktop$A2U__LF"* | '/'*'.desktop:'*"$A2U__LF"*) true ;; *) false ;; esac then
            # entry path and action before newline
            A2U__MAIN_ARG=${a2u__path_and_cmd%%"$A2U__LF"*}
            # cmd after newline, fill exec array right away
            A2U__EXEC_RSEP_USEP=${a2u__path_and_cmd#*"$A2U__LF"}
            # shellcheck disable=SC2086
            [ -z "$A2U__DEBUG" ] || debug "initial args:" "$(printf '  >%s<\n' "$@")" \
                "replaced A2U__MAIN_ARG with '$A2U__MAIN_ARG'" \
                "populated A2U__EXEC_RSEP_USEP with:" \
                "$(
                    IFS=$A2U__USEP
                    printf '  > %s\n' $A2U__EXEC_RSEP_USEP
                )"
        else
            # issue a warning to stderr
            {
                # shellcheck disable=SC2028
                echo "Could not determine default terminal entry via '$A2U__TERMINAL_HANDLER --print-path --print-cmd=\037'!"
                echo "Falling back to injecting '$A2U__TERMINAL_HANDLER' as the main argument."
            } >&2
            A2U__MAIN_ARG="$A2U__TERMINAL_HANDLER"
        fi
        A2U__TERMINAL=false
    else
        A2U__MAIN_ARG=$1
        shift
    fi
    parse_main_arg "$A2U__MAIN_ARG"

    if [ -n "$A2U__ENTRY_PATH" ]; then
        # reverse-deduce and correct Entry ID against applications dirs
        make_paths
        normpath "$A2U__ENTRY_PATH"
        A2U__ENTRY_PATH=${A2U__NORMALIZED_PATH}
        IFS=':'
        for a2u__dir in $A2U__APPLICATIONS_DIRS; do
            if [ "$A2U__ENTRY_PATH" != "${A2U__ENTRY_PATH#"$a2u__dir"}" ]; then
                A2U__ENTRY_ID_PRE=${A2U__ENTRY_PATH#"$a2u__dir"}
                debug "Processing Entry ID '$A2U__ENTRY_ID_PRE' as deduced in '$a2u__dir'"
                case "$A2U__ENTRY_ID_PRE" in
                */*)
                    replace "$A2U__ENTRY_ID_PRE" "/" "-"
                    A2U__ENTRY_ID_PRE=$A2U__REPLACED_STR
                    ;;
                esac
                if validate_entry_id "$A2U__ENTRY_ID_PRE"; then
                    A2U__ENTRY_ID=$A2U__ENTRY_ID_PRE
                    debug "deduced Entry ID '$A2U__ENTRY_ID_PRE'"
                else
                    error "Deduced Entry ID '$A2U__ENTRY_ID_PRE' is invalid!"
                fi
                break
            fi
        done
        IFS=$A2U__OIFS
    elif [ -n "$A2U__ENTRY_ID" ]; then
        make_paths
        find_entry "$A2U__ENTRY_ID"
        A2U__ENTRY_PATH=$A2U__FOUND_ENTRY_PATH
    fi

    # read and parse entry, fill A2U__ENTRY_* vars and A2U__EXEC_RSEP_USEP
    if [ -n "$A2U__ENTRY_PATH" ]; then
        read_entry_path "$A2U__ENTRY_PATH" "$A2U__ENTRY_ACTION"
    fi

    # handle Link type URL
    if [ -n "$A2U__ENTRY_URL" ]; then
        debug "re-parsing for Link entry URL: $A2U__ENTRY_URL"
        get_mime "$A2U__ENTRY_URL"
        a2u__mime=$A2U__MIME
        get_assoc "$a2u__mime"
        a2u__assoc=$A2U__ASSOC
        # replace initial vars and arg
        A2U__ENTRY_ID=$a2u__assoc
        set -- "$A2U__ENTRY_URL"
        A2U__ENTRY_URL=
        # re-parse new entry
        find_entry "$A2U__ENTRY_ID"
        A2U__ENTRY_PATH=$A2U__FOUND_ENTRY_PATH
        read_entry_path "$A2U__ENTRY_PATH"
    fi

    ## compose and print final command array(s)
    # entry mode
    if [ -n "$A2U__ENTRY_ID" ]; then

        # generate Unit ID as A2U__UNIT_ID
        gen_unit_id

        # do not bother with fields in fuzzel compat, since there are no open args
        case "$A2U__FUZZEL_COMPAT" in
        false) de_inject_fields "$@" ;;
        esac

        # deal with potential multiple iterations
        case "$A2U__EXEC_RSEP_USEP" in
        *"$A2U__RSEP"*)
            IFS=$A2U__RSEP
            a2u__first=true
            for a2u__cmd in $A2U__EXEC_RSEP_USEP; do
                IFS=$A2U__USEP
                # shellcheck disable=SC2086
                set -- $a2u__cmd
                IFS=$A2U__OIFS
                case "$A2U__TERMINAL" in
                true)
                    # inject terminal handler
                    debug "injected $A2U__TERMINAL_HANDLER"
                    IFS=$A2U__USEP
                    # shellcheck disable=SC2086
                    set -- "$A2U__TERMINAL_HANDLER" $A2U__TERMINAL_ARGS_USEP "$@"
                    IFS=$A2U__OIFS
                    ;;
                esac
                [ -z "$A2U__DEBUG" ] || debug "entry iteration, first: $a2u__first" "$(printf '  >%s<\n' "$@")"
                if [ "$a2u__first" = "false" ]; then
                    randomize_unit_id
                fi
                a2u__first=false

                # get wrapped command array into A2U__FINAL_EXEC_RSEP_USEP
                systemd_run_finalize_usep "$@"
            done
            ;;
        *)
            IFS=$A2U__USEP
            # shellcheck disable=SC2086
            set -- $A2U__EXEC_RSEP_USEP
            IFS=$A2U__OIFS
            case "$A2U__TERMINAL" in
            true)
                # inject terminal handler
                debug "injected $A2U__TERMINAL_HANDLER"
                IFS=$A2U__USEP
                # shellcheck disable=SC2086
                set -- "$A2U__TERMINAL_HANDLER" $A2U__TERMINAL_ARGS_USEP "$@"
                IFS=$A2U__OIFS
                ;;
            esac
            [ -z "$A2U__DEBUG" ] || debug "entry single" "$(printf '  >%s<\n' "$@")"

            # get wrapped command array into A2U__FINAL_EXEC_RSEP_USEP
            systemd_run_finalize_usep "$@"
            ;;
        esac
    # plain exec mode
    else
        # if no Entry ID came from the main argument,
        # and launcher set entry data in env vars,
        # fill them now
        [ -z "${DESKTOP_ENTRY_ID-}" ] || A2U__ENTRY_ID=$DESKTOP_ENTRY_ID
        [ -z "${DESKTOP_ENTRY_PATH-}" ] || A2U__ENTRY_PATH=$DESKTOP_ENTRY_PATH
        [ -z "${DESKTOP_ENTRY_NAME-}" ] || A2U__ENTRY_NAME=$DESKTOP_ENTRY_NAME
        [ -z "${DESKTOP_ENTRY_NAME_L-}" ] || A2U__ENTRY_NAME_L=$DESKTOP_ENTRY_NAME_L
        [ -z "${DESKTOP_ENTRY_GENERICNAME-}" ] || A2U__ENTRY_GENERICNAME=$DESKTOP_ENTRY_GENERICNAME
        [ -z "${DESKTOP_ENTRY_GENERICNAME_L-}" ] || A2U__ENTRY_GENERICNAME_L=$DESKTOP_ENTRY_GENERICNAME_L
        [ -z "${DESKTOP_ENTRY_ICON-}" ] || A2U__ENTRY_ICON=$DESKTOP_ENTRY_ICON
        [ -z "${DESKTOP_ENTRY_ACTION-}" ] || A2U__ENTRY_ACTION=$DESKTOP_ENTRY_ACTION
        [ -z "${DESKTOP_ENTRY_ACTION_NAME-}" ] || A2U__ENTRY_ACTION_NAME=$DESKTOP_ENTRY_ACTION_NAME
        [ -z "${DESKTOP_ENTRY_ACTION_NAME_L-}" ] || A2U__ENTRY_ACTION_NAME_L=$DESKTOP_ENTRY_ACTION_NAME_L
        #[ -z "${DESKTOP_ENTRY_ACTION_ICON-}" ] || A2U__ENTRY_ACTION_ICON=$DESKTOP_ENTRY_ACTION_ICON

        # generate Unit ID as A2U__UNIT_ID
        gen_unit_id

        set -- "${A2U__EXEC_PATH:-$A2U__EXEC_NAME}" "$@"
        IFS=$A2U__OIFS
        case "$A2U__TERMINAL" in
        true)
            # inject terminal handler
            debug "injected $A2U__TERMINAL_HANDLER"
            IFS=$A2U__USEP
            # shellcheck disable=SC2086
            set -- "$A2U__TERMINAL_HANDLER" $A2U__TERMINAL_ARGS_USEP "$@"
            IFS=$A2U__OIFS
            ;;
        esac
        [ -z "$A2U__DEBUG" ] || debug "command" "$(printf '  >%s<\n' "$@")"

        # get wrapped command array into A2U__FINAL_EXEC_RSEP_USEP
        systemd_run_finalize_usep "$@"
    fi
}

[ -z "$A2U__DEBUG" ] || debug "initial args:" "$(printf '  >%s<\n' "$@")"

# this var will contain complete finalized execution array(s)
A2U__FINAL_EXEC_RSEP_USEP=

# "isolate" most of other upper case vars by making shell revert them after gen_exec function
A2U__APPLICATIONS_DIRS='' \
    A2U__ASSOC='' \
    A2U__CR='' \
    A2U__ENTRY_='' \
    A2U__ENTRY_GENERICNAME='' \
    A2U__ENTRY_GENERICNAME_L='' \
    A2U__ENTRY_ICON='' \
    A2U__ENTRY_ID='' \
    A2U__ENTRY_ID_PRE='' \
    A2U__ENTRY_NAME='' \
    A2U__ENTRY_NAME_L='' \
    A2U__ENTRY_ACTION='' \
    A2U__ENTRY_ACTION_NAME='' \
    A2U__ENTRY_ACTION_NAME_L='' \
    A2U__ENTRY_PATH='' \
    A2U__ENTRY_TYPE='' \
    A2U__ENTRY_URL='' \
    A2U__ENTRY_WORKDIR='' \
    A2U__EXEC_NAME='' \
    A2U__EXEC_PATH='' \
    A2U__EXEC_RSEP_USEP='' \
    A2U__EXEC_USEP='' \
    A2U__EXPANDED_STR='' \
    A2U__FOUND_ENTRY_PATH='' \
    A2U__FUZZEL_COMPAT='' \
    A2U__LCODE='' \
    A2U__MAIN_ARG='' \
    A2U__MIME='' \
    A2U__NEW_RANDOM_STRING='' \
    A2U__NOLCODE='' \
    A2U__NORMALIZED_PATH='' \
    A2U__OPENER_MODE='' \
    A2U__PART_OF_GST='' \
    A2U__INSERT_XSD='' \
    A2U__RANDOM_STRING='' \
    A2U__REPLACED_STR='' \
    A2U__SILENT='' \
    A2U__TERMINAL='' \
    A2U__TERMINAL_ARGS_USEP='' \
    A2U__TEST_MODE='' \
    A2U__UNIT_APP_SUBSTRING='' \
    A2U__UNIT_DESCRIPTION='' \
    A2U__UNIT_DESKTOP_SUBSTRING='' \
    A2U__UNIT_ID='' \
    A2U__UNIT_PROPERTIES='' \
    A2U__UNIT_SLICE_CHOICES='' \
    A2U__UNIT_SLICE_ID='' \
    A2U__UNIT_TYPE='' \
    A2U__URLENCODED_STRING='' \
    gen_exec "$@"

# unset all launcher meta vars
unset DESKTOP_ENTRY_ID \
    DESKTOP_ENTRY_PATH \
    DESKTOP_ENTRY_NAME \
    DESKTOP_ENTRY_NAME_L \
    DESKTOP_ENTRY_COMMENT \
    DESKTOP_ENTRY_COMMENT_L \
    DESKTOP_ENTRY_GENERICNAME \
    DESKTOP_ENTRY_GENERICNAME_L \
    DESKTOP_ENTRY_ICON \
    DESKTOP_ENTRY_ACTION \
    DESKTOP_ENTRY_ACTION_NAME \
    DESKTOP_ENTRY_ACTION_NAME_L \
    DESKTOP_ENTRY_ACTION_ICON

# extract and execute command(s)
case "$A2U__FINAL_EXEC_RSEP_USEP" in
*"$A2U__RSEP"*)
    # record separator present, iterate over multiple background commands
    IFS=$A2U__RSEP
    a2u__pids=
    for a2u__iter_cmd_flag in $A2U__FINAL_EXEC_RSEP_USEP; do
        # cut flag
        a2u__command=${a2u__iter_cmd_flag%"${A2U__USEP}"?}
        a2u__flag=${a2u__iter_cmd_flag#"${a2u__command}${A2U__USEP}"}
        IFS=$A2U__USEP
        # shellcheck disable=SC2086
        set -- $a2u__command
        IFS=$A2U__OIFS
        [ -z "$A2U__DEBUG" ] || debug "exec iteration" "$(printf '  >%s<\n' "$@")" "flag: $a2u__flag"

        # execute command in background according to flag (or just print in test mode)
        case "$a2u__flag" in
        T)
            printf '%s\n' 'Command and arguments:'
            printf '  >%s<\n' "$@"
            continue
            ;;
        O) "$@" >/dev/null & ;;
        E) "$@" 2>/dev/null & ;;
        B) "$@" >/dev/null 2>&1 & ;;
        *) "$@" & ;;
        esac
        a2u__pids=${a2u__pids}${a2u__pids:+ }$!
    done

    # collect exit codes and exit with verdict
    a2u__ec=0
    # shellcheck disable=SC2086
    for a2u__pid in $a2u__pids; do
        wait $a2u__pid || a2u__ec=1
    done
    exit $a2u__ec
    ;;
*)
    # single command
    # cut flag
    a2u__command=${A2U__FINAL_EXEC_RSEP_USEP%"${A2U__USEP}"?}
    a2u__flag=${A2U__FINAL_EXEC_RSEP_USEP#"${a2u__command}${A2U__USEP}"}
    IFS=$A2U__USEP
    # shellcheck disable=SC2086
    set -- $a2u__command
    IFS=$A2U__OIFS
    [ -z "$A2U__DEBUG" ] || debug "exec single" "$(printf '  >%s<\n' "$@")"

    # execute command according to flag (or just print in test mode)
    case "$a2u__flag" in
    T)
        printf '%s\n' 'Command and arguments:'
        printf '  >%s<\n' "$@"
        ;;
    O) exec "$@" >/dev/null ;;
    E) exec "$@" 2>/dev/null ;;
    B) exec "$@" >/dev/null 2>&1 ;;
    *) exec "$@" ;;
    esac
    ;;
esac
