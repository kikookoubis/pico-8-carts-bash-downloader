#!/bin/bash

# *******************************************************************
# Change this to the directory you want the file to be downloaded to:
readonly DOWNLOAD_DIR="/home/bob/.lexaloffle/pico-8/carts/incoming"
# *******************************************************************

# v0.3 - March 23, 2017

readonly TMPFILE="lexaloffle-tmp.html"
readonly TMP_TXTFILE="lexaloffle-tmp.txt"
readonly LEXALOFFLE_ID_URL="http://www.lexaloffle.com/bbs/?tid="
readonly ARGS="$@"

main(){

	cmdline $ARGS
}

cart_download() {
	
	local URL="$1"
	download_tmp_html_page "$URL"

	local BBS_ID=$(get_BBS_ID)
	local GAME_ID=$(get_GAME_ID)
	local AUTHOR_NAME=$(get_AUTHOR_NAME "$GAME_ID")
	local GAME_TITLE=$(get_GAME_TITLE "$GAME_ID")
	local DOWNLOAD_URL=$(get_DOWNLOAD_URL)

	#You can edit this variable to change the final name of the cart:	
	local FINAL_FILENAME="$AUTHOR_NAME"_"$GAME_TITLE"_"$BBS_ID"_"$GAME_ID".p8.png
		
	download_file $DOWNLOAD_URL
	delete_tmp_html_page
}

get_DOWNLOAD_URL() {

	local SEARCH_STRING="toggle_playarea(pa,""$GAME_ID"

	local DL_URL=$(cat "$TMPFILE" \
		| grep "$SEARCH_STRING" \
		| cut -d "/" -f 2- \
		| sed -e "s/[^a-z|0-9|/|.]//g"
		)

	echo "http://www.lexaloffle.com/""$DL_URL"

}

download_file() {

	echo "Downloading: ""$FINAL_FILENAME"
	wget --quiet $1 -O "$DOWNLOAD_DIR/$FINAL_FILENAME"
}

clean_string() {

	local DIRTY_HAMSTER=`echo $1 \
		| tr '[A-Z]' '[a-z]' \
		| sed -e "s/[^a-z|0-9| |.]//g" \
		| tr -s " " \
		| tr -s "." \
		| tr " " "-"`

	echo $DIRTY_HAMSTER

}

get_GAME_TITLE() {

	local SEARCH_STRING=$1'\"\].title'

	local TITLE=$(cat "$TMPFILE" \
		| grep "$SEARCH_STRING" \
		| cut -d ">" -f2 \
		| cut -d "<" -f1
		)

	TITLE=$(clean_string "$TITLE")
	echo "$TITLE"
}

get_AUTHOR_NAME() {

	local SEARCH_STRING=$1'\"\].author'

	local AUTHOR=$(cat "$TMPFILE" \
		| grep "$SEARCH_STRING" \
	 	| cut -d ">" -f 2- \
		| cut -d "<" -f1
		)

	AUTHOR=$(clean_string "$AUTHOR")
	echo "$AUTHOR"
}

get_GAME_ID() {

	local ID=$(cat "$TMPFILE" \
		| grep "pa_pid\[0\]" \
		| cut -d "=" -f 2- \
		| sed -e s/[^0-9]*//g
		)

	echo $ID
}

get_BBS_ID() {

	local ID=$(echo "$URL" \
		| cut -d "=" -f 2- \
		| cut -d "#" -f1
		)

		# cleaning regular urls: cut -d "=" -f 2-
		# http://www.lexaloffle.com/bbs/?pid=17977
		
		# cleaning urls with anchors: cut -d "#" -f1
		# http://www.lexaloffle.com/bbs/?pid=17977#p17977

	echo $ID
}

download_tmp_html_page() {

#	is_empty $URL \
#		&& usage_no_url \
#		|| wget --quiet --output-document="$TMPFILE" "$URL"

	local URL="$1"
	wget --quiet --output-document="$TMPFILE" "$URL"
}

delete_tmp_html_page() {
	rm "$TMPFILE"
}

is_empty() {
    local var=$1
    [[ -z $var ]]
}

is_not_empty() {
    local var=$1
    [[ -n $var ]]
}

is_file() {
    local file=$1
    [[ -f $file ]]
}

is_dir() {
    local dir=$1
    [[ -d $dir ]]
}


usage_no_url() {

		echo ""
		echo "*** You must provide an url to download. ***"
		echo ""
		exit 1
}

function cmdline() {

	while [[ $# -gt 1 ]]
	do
		key="$1"

		case $key in
			-p|--page)
				local INDEX_PAGE_URL="$2"
				carts_from_url "$INDEX_PAGE_URL"
				shift # past argument
				;;

			-f|--file)
				local FILE="$2"
				carts_from_file "$FILE"
				shift # past argument
				;;

			*)
			       # unknown option
			;;
		esac
		shift # past argument or value
	done

	if [[ -n $1 ]]; then
		local URL="$1"
		cart_download "$URL"
	fi
}

function carts_from_url() {

	local URL="$1"
	download_tmp_html_page "$URL"
	get_carts_from_file "$TMPFILE"
}


function carts_from_file() {

	local FILE="$1"
	get_carts_from_file "$FILE"
}

function get_carts_from_file() {

	local FILE="$1"
	
	cat $FILE \
		| grep "bbs/?tid" \
		| cut -d "=" -f 2- \
		| cut -d "=" -f 2- \
		| cut -d "\"" -f 1 \
		> $TMP_TXTFILE

	while read line
		do
			local URL="$LEXALOFFLE_ID_URL""$line"
			cart_download "$URL"
		done < ./$TMP_TXTFILE

}

main
