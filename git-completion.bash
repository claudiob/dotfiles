# From https://raw.github.com/markgandolfo/git-bash-completion/master/git-completion.bash
# Edited to remove unused aliases and cygwin code
# NOTE that the 'official' one does not autocomplete alias:
# https://raw.github.com/git/git/master/contrib/completion/git-completion.bash

__gitdir ()
{
	if [ -z "$1" ]; then
		if [ -n "$__git_dir" ]; then
			echo "$__git_dir"
		elif [ -d .git ]; then
			echo .git
		else
			git rev-parse --git-dir 2>/dev/null
		fi
	elif [ -d "$1/.git" ]; then
		echo "$1/.git"
	else
		echo "$1"
	fi
}

__git_ps1 ()
{
	local b="$(git symbolic-ref HEAD 2>/dev/null)"
	if [ -n "$b" ]; then
		if [ -n "$1" ]; then
			printf "$1" "${b##refs/heads/}"
		else
			printf " (%s)" "${b##refs/heads/}"
		fi
	fi
}

__gitcomp ()
{
	local all c s=$'\n' IFS=' '$'\t'$'\n'
	local cur="${COMP_WORDS[COMP_CWORD]}"
	if [ $# -gt 2 ]; then
		cur="$3"
	fi
	for c in $1; do
		case "$c$4" in
		--*=*) all="$all$c$4$s" ;;
		*.)    all="$all$c$4$s" ;;
		*)     all="$all$c$4 $s" ;;
		esac
	done
	IFS=$s
	COMPREPLY=($(compgen -P "$2" -W "$all" -- "$cur"))
	return
}

__git_heads ()
{
	local cmd i is_hash=y dir="$(__gitdir "$1")"
	if [ -d "$dir" ]; then
		for i in $(git --git-dir="$dir" \
			for-each-ref --format='%(refname)' \
			refs/heads ); do
			echo "${i#refs/heads/}"
		done
		return
	fi
	for i in $(git-ls-remote "$1" 2>/dev/null); do
		case "$is_hash,$i" in
		y,*) is_hash=n ;;
		n,*^{}) is_hash=y ;;
		n,refs/heads/*) is_hash=y; echo "${i#refs/heads/}" ;;
		n,*) is_hash=y; echo "$i" ;;
		esac
	done
}

__git_tags ()
{
	local cmd i is_hash=y dir="$(__gitdir "$1")"
	if [ -d "$dir" ]; then
		for i in $(git --git-dir="$dir" \
			for-each-ref --format='%(refname)' \
			refs/tags ); do
			echo "${i#refs/tags/}"
		done
		return
	fi
	for i in $(git-ls-remote "$1" 2>/dev/null); do
		case "$is_hash,$i" in
		y,*) is_hash=n ;;
		n,*^{}) is_hash=y ;;
		n,refs/tags/*) is_hash=y; echo "${i#refs/tags/}" ;;
		n,*) is_hash=y; echo "$i" ;;
		esac
	done
}

__git_refs ()
{
	local cmd i is_hash=y dir="$(__gitdir "$1")"
	if [ -d "$dir" ]; then
		if [ -e "$dir/HEAD" ]; then echo HEAD; fi
		for i in $(git --git-dir="$dir" \
			for-each-ref --format='%(refname)' \
			refs/tags refs/heads refs/remotes); do
			case "$i" in
				refs/tags/*)    echo "${i#refs/tags/}" ;;
				refs/heads/*)   echo "${i#refs/heads/}" ;;
				refs/remotes/*) echo "${i#refs/remotes/}" ;;
				*)              echo "$i" ;;
			esac
		done
		return
	fi
	for i in $(git-ls-remote "$dir" 2>/dev/null); do
		case "$is_hash,$i" in
		y,*) is_hash=n ;;
		n,*^{}) is_hash=y ;;
		n,refs/tags/*) is_hash=y; echo "${i#refs/tags/}" ;;
		n,refs/heads/*) is_hash=y; echo "${i#refs/heads/}" ;;
		n,refs/remotes/*) is_hash=y; echo "${i#refs/remotes/}" ;;
		n,*) is_hash=y; echo "$i" ;;
		esac
	done
}

__git_refs2 ()
{
	local i
	for i in $(__git_refs "$1"); do
		echo "$i:$i"
	done
}

__git_refs_remotes ()
{
	local cmd i is_hash=y
	for i in $(git-ls-remote "$1" 2>/dev/null); do
		case "$is_hash,$i" in
		n,refs/heads/*)
			is_hash=y
			echo "$i:refs/remotes/$1/${i#refs/heads/}"
			;;
		y,*) is_hash=n ;;
		n,*^{}) is_hash=y ;;
		n,refs/tags/*) is_hash=y;;
		n,*) is_hash=y; ;;
		esac
	done
}

__git_remotes ()
{
	local i ngoff IFS=$'\n' d="$(__gitdir)"
	shopt -q nullglob || ngoff=1
	shopt -s nullglob
	for i in "$d/remotes"/*; do
		echo ${i#$d/remotes/}
	done
	[ "$ngoff" ] && shopt -u nullglob
	for i in $(git --git-dir="$d" config --list); do
		case "$i" in
		remote.*.url=*)
			i="${i#remote.}"
			echo "${i/.url=*/}"
			;;
		esac
	done
}

__git_merge_strategies ()
{
	if [ -n "$__git_merge_strategylist" ]; then
		echo "$__git_merge_strategylist"
		return
	fi
	sed -n "/^all_strategies='/{
		s/^all_strategies='//
		s/'//
		p
		q
		}" "$(git --exec-path)/git-merge"
}
__git_merge_strategylist=
__git_merge_strategylist="$(__git_merge_strategies 2>/dev/null)"

__git_complete_file ()
{
	local pfx ls ref cur="${COMP_WORDS[COMP_CWORD]}"
	case "$cur" in
	?*:*)
		ref="${cur%%:*}"
		cur="${cur#*:}"
		case "$cur" in
		?*/*)
			pfx="${cur%/*}"
			cur="${cur##*/}"
			ls="$ref:$pfx"
			pfx="$pfx/"
			;;
		*)
			ls="$ref"
			;;
	    esac
		COMPREPLY=($(compgen -P "$pfx" \
			-W "$(git --git-dir="$(__gitdir)" ls-tree "$ls" \
				| sed '/^100... blob /s,^.*	,,
				       /^040000 tree /{
				           s,^.*	,,
				           s,$,/,
				       }
				       s/^.*	//')" \
			-- "$cur"))
		;;
	*)
		__gitcomp "$(__git_refs)"
		;;
	esac
}

__git_complete_revlist ()
{
	local pfx cur="${COMP_WORDS[COMP_CWORD]}"
	case "$cur" in
	*...*)
		pfx="${cur%...*}..."
		cur="${cur#*...}"
		__gitcomp "$(__git_refs)" "$pfx" "$cur"
		;;
	*..*)
		pfx="${cur%..*}.."
		cur="${cur#*..}"
		__gitcomp "$(__git_refs)" "$pfx" "$cur"
		;;
	*.)
		__gitcomp "$cur."
		;;
	*)
		__gitcomp "$(__git_refs)"
		;;
	esac
}

__git_commands ()
{
	if [ -n "$__git_commandlist" ]; then
		echo "$__git_commandlist"
		return
	fi
	local i IFS=" "$'\n'
	for i in $(git help -a|egrep '^ ')
	do
		case $i in
		*--*)             : helper pattern;;
		applymbox)        : ask gittus;;
		applypatch)       : ask gittus;;
		archimport)       : import;;
		cat-file)         : plumbing;;
		check-attr)       : plumbing;;
		check-ref-format) : plumbing;;
		commit-tree)      : plumbing;;
		cvsexportcommit)  : export;;
		cvsimport)        : import;;
		cvsserver)        : daemon;;
		daemon)           : daemon;;
		diff-files)       : plumbing;;
		diff-index)       : plumbing;;
		diff-tree)        : plumbing;;
		fast-import)      : import;;
		fsck-objects)     : plumbing;;
		fetch-pack)       : plumbing;;
		fmt-merge-msg)    : plumbing;;
		for-each-ref)     : plumbing;;
		hash-object)      : plumbing;;
		http-*)           : transport;;
		index-pack)       : plumbing;;
		init-db)          : deprecated;;
		local-fetch)      : plumbing;;
		mailinfo)         : plumbing;;
		mailsplit)        : plumbing;;
		merge-*)          : plumbing;;
		mktree)           : plumbing;;
		mktag)            : plumbing;;
		pack-objects)     : plumbing;;
		pack-redundant)   : plumbing;;
		pack-refs)        : plumbing;;
		parse-remote)     : plumbing;;
		patch-id)         : plumbing;;
		peek-remote)      : plumbing;;
		prune)            : plumbing;;
		prune-packed)     : plumbing;;
		quiltimport)      : import;;
		read-tree)        : plumbing;;
		receive-pack)     : plumbing;;
		reflog)           : plumbing;;
		repo-config)      : deprecated;;
		rerere)           : plumbing;;
		rev-list)         : plumbing;;
		rev-parse)        : plumbing;;
		runstatus)        : plumbing;;
		sh-setup)         : internal;;
		shell)            : daemon;;
		send-pack)        : plumbing;;
		show-index)       : plumbing;;
		ssh-*)            : transport;;
		stripspace)       : plumbing;;
		svn)              : import export;;
		symbolic-ref)     : plumbing;;
		tar-tree)         : deprecated;;
		unpack-file)      : plumbing;;
		unpack-objects)   : plumbing;;
		update-index)     : plumbing;;
		update-ref)       : plumbing;;
		update-server-info) : daemon;;
		upload-archive)   : plumbing;;
		upload-pack)      : plumbing;;
		write-tree)       : plumbing;;
		verify-tag)       : plumbing;;
		*) echo $i;;
		esac
	done
}
__git_commandlist=
__git_commandlist="$(__git_commands 2>/dev/null)"

__git_aliases ()
{
	local i IFS=$'\n'
	for i in $(git --git-dir="$(__gitdir)" config --list); do
		case "$i" in
		alias.*)
			i="${i#alias.}"
			echo "${i/=*/}"
			;;
		esac
	done
}

__git_aliased_command ()
{
	local word cmdline=$(git --git-dir="$(__gitdir)" \
		config --get "alias.$1")
	for word in $cmdline; do
		if [ "${word##-*}" ]; then
			echo $word
			return
		fi
	done
}

__git_whitespacelist="nowarn warn error error-all strip"

_git_am ()
{
	local cur="${COMP_WORDS[COMP_CWORD]}"
	if [ -d .dotest ]; then
		__gitcomp "--skip --resolved"
		return
	fi
	case "$cur" in
	--whitespace=*)
		__gitcomp "$__git_whitespacelist" "" "${cur##--whitespace=}"
		return
		;;
	--*)
		__gitcomp "
			--signoff --utf8 --binary --3way --interactive
			--whitespace=
			"
		return
	esac
	COMPREPLY=()
}

_git_apply ()
{
	local cur="${COMP_WORDS[COMP_CWORD]}"
	case "$cur" in
	--whitespace=*)
		__gitcomp "$__git_whitespacelist" "" "${cur##--whitespace=}"
		return
		;;
	--*)
		__gitcomp "
			--stat --numstat --summary --check --index
			--cached --index-info --reverse --reject --unidiff-zero
			--apply --no-add --exclude=
			--whitespace= --inaccurate-eof --verbose
			"
		return
	esac
	COMPREPLY=()
}

_git_add ()
{
	local cur="${COMP_WORDS[COMP_CWORD]}"
	case "$cur" in
	--*)
		__gitcomp "--interactive --refresh"
		return
	esac
	COMPREPLY=()
}

_git_bisect ()
{
	local i c=1 command
	while [ $c -lt $COMP_CWORD ]; do
		i="${COMP_WORDS[c]}"
		case "$i" in
		start|bad|good|reset|visualize|replay|log)
			command="$i"
			break
			;;
		esac
		c=$((++c))
	done

	if [ $c -eq $COMP_CWORD -a -z "$command" ]; then
		__gitcomp "start bad good reset visualize replay log"
		return
	fi

	case "$command" in
	bad|good|reset)
		__gitcomp "$(__git_refs)"
		;;
	*)
		COMPREPLY=()
		;;
	esac
}

_git_branch ()
{
	__gitcomp "$(__git_refs)"
}

_git_bundle ()
{
	local mycword="$COMP_CWORD"
	case "${COMP_WORDS[0]}" in
	git)
		local cmd="${COMP_WORDS[2]}"
		mycword="$((mycword-1))"
		;;
	git-bundle*)
		local cmd="${COMP_WORDS[1]}"
		;;
	esac
	case "$mycword" in
	1)
		__gitcomp "create list-heads verify unbundle"
		;;
	2)
		# looking for a file
		;;
	*)
		case "$cmd" in
			create)
				__git_complete_revlist
			;;
		esac
		;;
	esac
}

_git_checkout ()
{
	__gitcomp "$(__git_refs)"
}

_git_cherry ()
{
	__gitcomp "$(__git_refs)"
}

_git_cherry_pick ()
{
	local cur="${COMP_WORDS[COMP_CWORD]}"
	case "$cur" in
	--*)
		__gitcomp "--edit --no-commit"
		;;
	*)
		__gitcomp "$(__git_refs)"
		;;
	esac
}

_git_commit ()
{
	local cur="${COMP_WORDS[COMP_CWORD]}"
	case "$cur" in
	--*)
		__gitcomp "
			--all --author= --signoff --verify --no-verify
			--edit --amend --include --only
			"
		return
	esac
	COMPREPLY=()
}

_git_describe ()
{
	__gitcomp "$(__git_refs)"
}

_git_diff ()
{
	local cur="${COMP_WORDS[COMP_CWORD]}"
	case "$cur" in
	--*)
		__gitcomp "--cached --stat --numstat --shortstat --summary
			--patch-with-stat --name-only --name-status --color
			--no-color --color-words --no-renames --check
			--full-index --binary --abbrev --diff-filter
			--find-copies-harder --pickaxe-all --pickaxe-regex
			--text --ignore-space-at-eol --ignore-space-change
			--ignore-all-space --exit-code --quiet --ext-diff
			--no-ext-diff"
		return
		;;
	esac
	__git_complete_file
}

_git_diff_tree ()
{
	__gitcomp "$(__git_refs)"
}

_git_fetch ()
{
	local cur="${COMP_WORDS[COMP_CWORD]}"

	case "${COMP_WORDS[0]},$COMP_CWORD" in
	git-fetch*,1)
		__gitcomp "$(__git_remotes)"
		;;
	git,2)
		__gitcomp "$(__git_remotes)"
		;;
	*)
		case "$cur" in
		*:*)
			__gitcomp "$(__git_refs)" "" "${cur#*:}"
			;;
		*)
			local remote
			case "${COMP_WORDS[0]}" in
			git-fetch) remote="${COMP_WORDS[1]}" ;;
			git)       remote="${COMP_WORDS[2]}" ;;
			esac
			__gitcomp "$(__git_refs2 "$remote")"
			;;
		esac
		;;
	esac
}

_git_format_patch ()
{
	local cur="${COMP_WORDS[COMP_CWORD]}"
	case "$cur" in
	--*)
		__gitcomp "
			--stdout --attach --thread
			--output-directory
			--numbered --start-number
			--numbered-files
			--keep-subject
			--signoff
			--in-reply-to=
			--full-index --binary
			--not --all
			"
		return
		;;
	esac
	__git_complete_revlist
}

_git_gc ()
{
	local cur="${COMP_WORDS[COMP_CWORD]}"
	case "$cur" in
	--*)
		__gitcomp "--prune --aggressive"
		return
		;;
	esac
	COMPREPLY=()
}

_git_ls_remote ()
{
	__gitcomp "$(__git_remotes)"
}

_git_ls_tree ()
{
	__git_complete_file
}

_git_log ()
{
	local cur="${COMP_WORDS[COMP_CWORD]}"
	case "$cur" in
	--pretty=*)
		__gitcomp "
			oneline short medium full fuller email raw
			" "" "${cur##--pretty=}"
		return
		;;
	--date=*)
		__gitcomp "
			relative iso8601 rfc2822 short local default
		" "" "${cur##--date=}"
		return
		;;
	--*)
		__gitcomp "
			--max-count= --max-age= --since= --after=
			--min-age= --before= --until=
			--root --topo-order --date-order --reverse
			--no-merges --follow
			--abbrev-commit --abbrev=
			--relative-date --date=
			--author= --committer= --grep=
			--all-match
			--pretty= --name-status --name-only --raw
			--not --all
			--left-right --cherry-pick
			"
		return
		;;
	esac
	__git_complete_revlist
}

_git_merge ()
{
	local cur="${COMP_WORDS[COMP_CWORD]}"
	case "${COMP_WORDS[COMP_CWORD-1]}" in
	-s|--strategy)
		__gitcomp "$(__git_merge_strategies)"
		return
	esac
	case "$cur" in
	--strategy=*)
		__gitcomp "$(__git_merge_strategies)" "" "${cur##--strategy=}"
		return
		;;
	--*)
		__gitcomp "
			--no-commit --no-summary --squash --strategy
			"
		return
	esac
	__gitcomp "$(__git_refs)"
}

_git_merge_base ()
{
	__gitcomp "$(__git_refs)"
}

_git_name_rev ()
{
	__gitcomp "--tags --all --stdin"
}

_git_pull ()
{
	local cur="${COMP_WORDS[COMP_CWORD]}"

	case "${COMP_WORDS[0]},$COMP_CWORD" in
	git-pull*,1)
		__gitcomp "$(__git_remotes)"
		;;
	git,2)
		__gitcomp "$(__git_remotes)"
		;;
	*)
		local remote
		case "${COMP_WORDS[0]}" in
		git-pull)  remote="${COMP_WORDS[1]}" ;;
		git)       remote="${COMP_WORDS[2]}" ;;
		esac
		__gitcomp "$(__git_refs "$remote")"
		;;
	esac
}

_git_push ()
{
	local cur="${COMP_WORDS[COMP_CWORD]}"

	case "${COMP_WORDS[0]},$COMP_CWORD" in
	git-push*,1)
		__gitcomp "$(__git_remotes)"
		;;
	git,2)
		__gitcomp "$(__git_remotes)"
		;;
	*)
		case "$cur" in
		*:*)
			local remote
			case "${COMP_WORDS[0]}" in
			git-push)  remote="${COMP_WORDS[1]}" ;;
			git)       remote="${COMP_WORDS[2]}" ;;
			esac
			__gitcomp "$(__git_refs "$remote")" "" "${cur#*:}"
			;;
		+*)
			__gitcomp "$(__git_refs)" + "${cur#+}"
			;;
		*)
			__gitcomp "$(__git_refs)"
			;;
		esac
		;;
	esac
}

_git_rebase ()
{
	local cur="${COMP_WORDS[COMP_CWORD]}"
	if [ -d .dotest ] || [ -d .git/.dotest-merge ]; then
		__gitcomp "--continue --skip --abort"
		return
	fi
	case "${COMP_WORDS[COMP_CWORD-1]}" in
	-s|--strategy)
		__gitcomp "$(__git_merge_strategies)"
		return
	esac
	case "$cur" in
	--strategy=*)
		__gitcomp "$(__git_merge_strategies)" "" "${cur##--strategy=}"
		return
		;;
	--*)
		__gitcomp "--onto --merge --strategy"
		return
	esac
	__gitcomp "$(__git_refs)"
}

_git_config ()
{
	local cur="${COMP_WORDS[COMP_CWORD]}"
	local prv="${COMP_WORDS[COMP_CWORD-1]}"
	case "$prv" in
	branch.*.remote)
		__gitcomp "$(__git_remotes)"
		return
		;;
	branch.*.merge)
		__gitcomp "$(__git_refs)"
		return
		;;
	remote.*.fetch)
		local remote="${prv#remote.}"
		remote="${remote%.fetch}"
		__gitcomp "$(__git_refs_remotes "$remote")"
		return
		;;
	remote.*.push)
		local remote="${prv#remote.}"
		remote="${remote%.push}"
		__gitcomp "$(git --git-dir="$(__gitdir)" \
			for-each-ref --format='%(refname):%(refname)' \
			refs/heads)"
		return
		;;
	pull.twohead|pull.octopus)
		__gitcomp "$(__git_merge_strategies)"
		return
		;;
	color.branch|color.diff|color.status)
		__gitcomp "always never auto"
		return
		;;
	color.*.*)
		__gitcomp "
			black red green yellow blue magenta cyan white
			bold dim ul blink reverse
			"
		return
		;;
	*.*)
		COMPREPLY=()
		return
		;;
	esac
	case "$cur" in
	--*)
		__gitcomp "
			--global --system --file=
			--list --replace-all
			--get --get-all --get-regexp
			--add --unset --unset-all
			--remove-section --rename-section
			"
		return
		;;
	branch.*.*)
		local pfx="${cur%.*}."
		cur="${cur##*.}"
		__gitcomp "remote merge" "$pfx" "$cur"
		return
		;;
	branch.*)
		local pfx="${cur%.*}."
		cur="${cur#*.}"
		__gitcomp "$(__git_heads)" "$pfx" "$cur" "."
		return
		;;
	remote.*.*)
		local pfx="${cur%.*}."
		cur="${cur##*.}"
		__gitcomp "
			url fetch push skipDefaultUpdate
			receivepack uploadpack tagopt
			" "$pfx" "$cur"
		return
		;;
	remote.*)
		local pfx="${cur%.*}."
		cur="${cur#*.}"
		__gitcomp "$(__git_remotes)" "$pfx" "$cur" "."
		return
		;;
	esac
	__gitcomp "
		apply.whitespace
		core.fileMode
		core.gitProxy
		core.ignoreStat
		core.preferSymlinkRefs
		core.logAllRefUpdates
		core.loosecompression
		core.repositoryFormatVersion
		core.sharedRepository
		core.warnAmbiguousRefs
		core.compression
		core.legacyHeaders
		core.packedGitWindowSize
		core.packedGitLimit
		clean.requireForce
		color.branch
		color.branch.current
		color.branch.local
		color.branch.remote
		color.branch.plain
		color.diff
		color.diff.plain
		color.diff.meta
		color.diff.frag
		color.diff.old
		color.diff.new
		color.diff.commit
		color.diff.whitespace
		color.pager
		color.status
		color.status.header
		color.status.added
		color.status.changed
		color.status.untracked
		diff.renameLimit
		diff.renames
		fetch.unpackLimit
		format.headers
		format.subjectprefix
		gitcvs.enabled
		gitcvs.logfile
		gitcvs.allbinary
		gitcvs.dbname gitcvs.dbdriver gitcvs.dbuser gitcvs.dvpass
		gc.packrefs
		gc.reflogexpire
		gc.reflogexpireunreachable
		gc.rerereresolved
		gc.rerereunresolved
		http.sslVerify
		http.sslCert
		http.sslKey
		http.sslCAInfo
		http.sslCAPath
		http.maxRequests
		http.lowSpeedLimit
		http.lowSpeedTime
		http.noEPSV
		i18n.commitEncoding
		i18n.logOutputEncoding
		log.showroot
		merge.tool
		merge.summary
		merge.verbosity
		pack.window
		pack.depth
		pack.windowMemory
		pack.compression
		pack.deltaCacheSize
		pack.deltaCacheLimit
		pull.octopus
		pull.twohead
		repack.useDeltaBaseOffset
		show.difftree
		showbranch.default
		tar.umask
		transfer.unpackLimit
		receive.unpackLimit
		receive.denyNonFastForwards
		user.name
		user.email
		user.signingkey
		whatchanged.difftree
		branch. remote.
	"
}

_git_remote ()
{
	local i c=1 command
	while [ $c -lt $COMP_CWORD ]; do
		i="${COMP_WORDS[c]}"
		case "$i" in
		add|rm|show|prune|update) command="$i"; break ;;
		esac
		c=$((++c))
	done

	if [ $c -eq $COMP_CWORD -a -z "$command" ]; then
		__gitcomp "add rm show prune update"
		return
	fi

	case "$command" in
	rm|show|prune)
		__gitcomp "$(__git_remotes)"
		;;
	update)
		local i c='' IFS=$'\n'
		for i in $(git --git-dir="$(__gitdir)" config --list); do
			case "$i" in
			remotes.*)
				i="${i#remotes.}"
				c="$c ${i/=*/}"
				;;
			esac
		done
		__gitcomp "$c"
		;;
	*)
		COMPREPLY=()
		;;
	esac
}

_git_reset ()
{
	local cur="${COMP_WORDS[COMP_CWORD]}"
	case "$cur" in
	--*)
		__gitcomp "--mixed --hard --soft"
		return
		;;
	esac
	__gitcomp "$(__git_refs)"
}

_git_shortlog ()
{
	local cur="${COMP_WORDS[COMP_CWORD]}"
	case "$cur" in
	--*)
		__gitcomp "
			--max-count= --max-age= --since= --after=
			--min-age= --before= --until=
			--no-merges
			--author= --committer= --grep=
			--all-match
			--not --all
			--numbered --summary
			"
		return
		;;
	esac
	__git_complete_revlist
}

_git_show ()
{
	local cur="${COMP_WORDS[COMP_CWORD]}"
	case "$cur" in
	--pretty=*)
		__gitcomp "
			oneline short medium full fuller email raw
			" "" "${cur##--pretty=}"
		return
		;;
	--*)
		__gitcomp "--pretty="
		return
		;;
	esac
	__git_complete_file
}

_git_stash ()
{
	__gitcomp 'list show apply clear'
}

_git_submodule ()
{
	local i c=1 command
	while [ $c -lt $COMP_CWORD ]; do
		i="${COMP_WORDS[c]}"
		case "$i" in
		add|status|init|update) command="$i"; break ;;
		esac
		c=$((++c))
	done

	if [ $c -eq $COMP_CWORD -a -z "$command" ]; then
		local cur="${COMP_WORDS[COMP_CWORD]}"
		case "$cur" in
		--*)
			__gitcomp "--quiet --cached"
			;;
		*)
			__gitcomp "add status init update"
			;;
		esac
		return
	fi
}

_git_tag ()
{
	local i c=1 f=0
	while [ $c -lt $COMP_CWORD ]; do
		i="${COMP_WORDS[c]}"
		case "$i" in
		-d|-v)
			__gitcomp "$(__git_tags)"
			return
			;;
		-f)
			f=1
			;;
		esac
		c=$((++c))
	done

	case "${COMP_WORDS[COMP_CWORD-1]}" in
	-m|-F)
		COMPREPLY=()
		;;
	-*|tag|git-tag)
		if [ $f = 1 ]; then
			__gitcomp "$(__git_tags)"
		else
			COMPREPLY=()
		fi
		;;
	*)
		__gitcomp "$(__git_refs)"
		;;
	esac
}

_git ()
{
	local i c=1 command __git_dir

	while [ $c -lt $COMP_CWORD ]; do
		i="${COMP_WORDS[c]}"
		case "$i" in
		--git-dir=*) __git_dir="${i#--git-dir=}" ;;
		--bare)      __git_dir="." ;;
		--version|--help|-p|--paginate) ;;
		*) command="$i"; break ;;
		esac
		c=$((++c))
	done

	if [ $c -eq $COMP_CWORD -a -z "$command" ]; then
		case "${COMP_WORDS[COMP_CWORD]}" in
		--*=*) COMPREPLY=() ;;
		--*)   __gitcomp "
			--no-pager
			--git-dir=
			--bare
			--version
			--exec-path
			"
			;;
		*)     __gitcomp "$(__git_commands) $(__git_aliases)" ;;
		esac
		return
	fi

	local expansion=$(__git_aliased_command "$command")
	[ "$expansion" ] && command="$expansion"

	case "$command" in
	am)          _git_am ;;
	add)         _git_add ;;
	apply)       _git_apply ;;
	bisect)      _git_bisect ;;
	bundle)      _git_bundle ;;
	branch)      _git_branch ;;
	checkout)    _git_checkout ;;
	cherry)      _git_cherry ;;
	cherry-pick) _git_cherry_pick ;;
	commit)      _git_commit ;;
	config)      _git_config ;;
	describe)    _git_describe ;;
	diff)        _git_diff ;;
	fetch)       _git_fetch ;;
	format-patch) _git_format_patch ;;
	gc)          _git_gc ;;
	log)         _git_log ;;
	ls-remote)   _git_ls_remote ;;
	ls-tree)     _git_ls_tree ;;
	merge)       _git_merge;;
	merge-base)  _git_merge_base ;;
	name-rev)    _git_name_rev ;;
	pull)        _git_pull ;;
	push)        _git_push ;;
	rebase)      _git_rebase ;;
	remote)      _git_remote ;;
	reset)       _git_reset ;;
	shortlog)    _git_shortlog ;;
	show)        _git_show ;;
	show-branch) _git_log ;;
	stash)       _git_stash ;;
	submodule)   _git_submodule ;;
	tag)         _git_tag ;;
	whatchanged) _git_log ;;
	*)           COMPREPLY=() ;;
	esac
}

_gitk ()
{
	local cur="${COMP_WORDS[COMP_CWORD]}"
	case "$cur" in
	--*)
		__gitcomp "--not --all"
		return
		;;
	esac
	__git_complete_revlist
}

complete -o default -o nospace -F _git git
complete -o default -o nospace -F _gitk gitk