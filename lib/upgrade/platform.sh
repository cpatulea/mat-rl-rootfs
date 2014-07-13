PART_NAME=firmware

platform_check_image() {
	[ "$#" -gt 1 ] && return 1

	case "$(get_magic_word "$1")" in
		# .trx files
		4844) return 0;;
		*)
			echo "Invalid image type. Please use only .trx files"
			return 1
		;;
	esac
}

platform_do_upgrade() {
	local machine="$(awk 'BEGIN{FS="[ \t]+:[ \t]"} /machine/ {print $2}' /proc/cpuinfo)"

	default_do_upgrade "$ARGV"

	case "$machine" in
	*WRT54G*)
		mtd fixtrx firmware
		;;
	esac
}
