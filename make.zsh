#!/usr/bin/zsh
# Note to others reading this code or me in 6 months: I'm using `sed 's|old|new|g'` instead of `sed 's/old/new/g'` because my old expresions often have '/' as part of html closing tags

rawprefix() {
	awk '{print "'$1'" $0}'
}

makeRssItem() { # $1 ~ title, $2 ~ link, $3 ~ url
	cat item.xml | sed "s|{{{title}}}|$1|g" | sed "s|{{{link}}}|$2|g" | sed "s|{{{url}}}|$3|g" 
}

curl 'http://www.teatreegullyanglican.org.au/sermon-listing' | grep -ozP "(?s)<tbody>.*?sermons.*?</tbody>" | grep -P '"/sermons.*?">' | sed 's|.*"\(/sermons.*\)".*|\1|g' | rawprefix 'http://www.teatreegullyanglican.org.au' > tmp-urls.txt

echo -n > tmp-items.xml

getTitle() {
	cat tmp-file.html | grep "<title>.*</title>" | sed "s/.*<title>\(.*\) | Tea Tree Gully Anglican Church.*/\1/g"
}

getUrl() {
	cat tmp-file.html | grep -ozP '(?s)class="field-label">Sermon Audio: .*?</a>' | grep "<a" | sed 's|.*"\(/download.*\)".*|\1|g' | rawprefix 'http://www.teatreegullyanglican.org.au'
}

for link in $(cat tmp-urls.txt); do
	curl $link > tmp-file.html
	echo "============================"
	echo -n "link: "
	echo $link
	echo -n "url: "
	getUrl
	echo -n "title: "
	getTitle
	echo "============================"
	makeRssItem "$(getTitle)" "$link" "$(getUrl)" >> tmp-items.xml
	echo "============================"
done

cat main-feed-start.xml tmp-items.xml main-feed-end.xml > output.rss.xml
