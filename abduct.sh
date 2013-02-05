#!/usr/bin/env bash

login_url="http://plus.mysteriousuniverse.org/mp/40531"
index_url="http://plus.mysteriousuniverse.org/s/admin/index.php?"
plus_content_url="${index_url}req_tag=list_subscription_episodes"
mu_user=""
mu_pass=""
cookie_jar="$(mktemp -t mu-downloader)"
response=""
account=""

while getopts btu:p: opt
do
    case "$opt" in
      b)  bypass_login=1;;
      t)  cookie_jar="cookies.txt";;
      u)  mu_user="$OPTARG";;
      p)  mu_pass="$OPTARG";;
      \?) usage;;
    esac
done

function usage() {
    echo "This script will abduct all of the Mysterious Universe back-catalog episodes."
    echo "Be aware that the collection is large - make sure you have about 15GB free."
    echo ""
    echo "Usage:"
    echo ""
    echo "abduct.sh -u <username> -p <password>"
}

if [ "$mu_user" = '' ]; then
    usage
    exit
fi

if [ "$mu_pass" = '' ]; then
	echo -n "Please enter your MU+ password: "
	read -s mu_pass
	echo ""
fi

function muLogin() {
	curl -ss -L -c $cookie_jar -d "p_admin_email=${mu_user}&password=${mu_pass}&login-attempt=1&future_req_tag=" $login_url > /dev/null
}

function curlWithCookie() {
	local url=$1
	curl -s -L -b $cookie_jar $url
}

function makePlusUrl() {
	echo "${1}&ac=${account}"
}

#muLogin
#cat $cookie_jar

if [[ $bypass_login -ne 1 ]] ; then
	muLogin
else
	echo "will bypass login"
fi

echo "Luring the episodes with the promise of a job interview..."
response=$(curlWithCookie $index_url)
#echo $response
#exit
account=$(echo "$response" | grep -Eo "\&ac=[0-9a-z]+\"" | grep -Eo "[a-z0-9]{3,}" | head -n1)
plus_content_url=$(makePlusUrl $plus_content_url)
plus_content=$(curlWithCookie $plus_content_url)
podcast_pages=$(echo "$plus_content" | sed -En "s/.*<td valign=middle>[ ]*<a[ ]+class=\"membership_links\" href=\"([^\"]+)\">[^<]+<\/a>[ ]*<\/td>/\1/p")
if [[ $podcast_pages = '' ]]; then
	echo "They saw through the cover story, MIBs' are en-route to your location"
	echo "But seriously, your credentials didn't check out. Double check them and try again"
	exit
fi
echo "Cover story successful, abduction in progress..."
echo ""
echo "$podcast_pages" | while read url; do
	page=$(curlWithCookie $url)
	
	download_link=$(echo "$page" | sed -En "s/.*<a href=\"([^\"]+)\" target=_blank id=\"[^\"]+\">Click here for the File Download<\/a>.*/\1/p")
	if [[ $download_link = "" ]] ; then
		echo "Uh-oh: $url"
	else
		filename=$(echo "$download_link" | sed -En "s/.*\/(.*\.mp3)/\1/p")
		echo "Abducting $filename"
		curl -LO --progress-bar $download_link
	fi
done
