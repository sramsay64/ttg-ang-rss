#!/usr/bin/zsh
# Note to others reading this code or me in 6 months: I'm using `sed 's|old|new|g'` instead of `sed 's/old/new/g'` because my old expresions often have '/' as part of html closing tags

DIR=`dirname $0`
mkdir -p $DIR/tmp/

rawprefix() {
	awk '{print "'$1'" $0}'
}

makeRssItem() { # $1 ~ title, $2 ~ link, $3 ~ url
	cat $DIR/templates/item.xml | sed "s|{{{title}}}|$1|g" | sed "s|{{{link}}}|$2|g" | sed "s|{{{url}}}|$3|g" 
}

curl 'http://www.teatreegullyanglican.org.au/sermon-listing' | grep -ozP "(?s)<tbody>.*?sermons.*?</tbody>" | tr "\000" "\n" | grep -P '"/sermons.*?">' | sed 's|.*"\(/sermons.*\)".*|\1|g' | rawprefix 'http://www.teatreegullyanglican.org.au' > $DIR/tmp/tmp-urls.txt

echo -n > $DIR/tmp/tmp-items.xml

getTitle() {
	cat $DIR/tmp/tmp-file.html | grep "<title>.*</title>" | sed "s/.*<title>\(.*\) | Tea Tree Gully Anglican Church.*/\1/g"
}

getUrl() {
	cat $DIR/tmp/tmp-file.html | grep -ozP '(?s)class="field-label">Sermon Audio: .*?</a>' | tr "\000" "\n" | grep "<a" | sed 's|.*"\(/download.*\)".*|\1|g' | rawprefix 'http://www.teatreegullyanglican.org.au'
}

for link in $(cat $DIR/tmp/tmp-urls.txt); do
	curl $link > $DIR/tmp/tmp-file.html
	echo "============================"
	echo -n "link: "
	echo $link
	echo -n "url: "
	getUrl
	echo -n "title: "
	getTitle
	echo "============================"
	makeRssItem "$(getTitle)" "$link" "$(getUrl)" >> $DIR/tmp/tmp-items.xml
	echo "============================"
done

OUTPUTFILE="$DIR/tmp/output.rss.xml"
if (( $# > 0 ))
then
	OUTPUTFILE="$*"
fi	

cat $DIR/templates/main-feed-start.xml $DIR/tmp/tmp-items.xml $DIR/templates/main-feed-end.xml > $OUTPUTFILE
