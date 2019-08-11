#!/bin/bash
name="Rob Wood"
sftpaddress="robertwood@studentweb.uvic.ca"
webdir="/Users/rw/Developer/Web/robertwood"
website="https://studentweb.uvic.ca/~robertwood"
css="../style.css"
blogfile="blog.html"
indexfile="blogindex.html"
rssfile="rss.xml"
[ -z "$EDITOR" ] && EDITOR="vim"

if [ ! -d "$webdir/blog/.drafts" ]; then
    read -erp "Init blog in $webdir?" ask && if [ "$ask" = "y" ]; then
        printf "Initializing blog system...\\n"
        mkdir -pv "$webdir/blog/.drafts" || printf "Error. Do you have write permissions in this directory?\\n"
        echo -e "Options +Indexes\n<Files ~ '^.*\.([Hh][Tt][Aa])'>\norder allow,deny\ndeny from all\n</Files>\n<IfModule mod_autoindex.c>\nIndexOptions IgnoreCase FancyIndexing FoldersFirst SuppressHTMLPreamble NameWidth=30px\nIndexOrderDefault Descending Name\nHeaderName header.html\nReadmeName footer.html\nIndexIgnore header.html footer.html\n</IfModule>\n" > "$webdir/blog/.htaccess"
    else
        exit
    fi
fi

newpost() { read -erp "New entry title:
    " title
    echo "$title" | grep "\"" > /dev/null && printf "Double quotations are not allowed in entry titles.\\n" && exit
    url="$(echo "$title" | iconv -c -f UTF-8 -t ASCII//TRANSLIT | tr -d '[:punct:]' | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed "s/-\+/-/g;s/\(^-\|-\$\)//g")"
    echo "AddDescription \"$title\" \"$url.html\"" >> "$webdir/blog/.htaccess" || { echo "Error. Is htaccess writeable?"; exit; }
    [ -f "$webdir/blog/.drafts/$url.html" ] && echo "Error. Title exists in drafts." && exit
    [ -f "$webdir/blog/$url.html" ] && echo "Error. Title exists as published entries." && exit
    $EDITOR "$webdir/blog/.drafts/$url.html" ;}

listandReturn() { printf "Listing contents of %s.\\n" "$1" 
    ls -rc "$1" | awk -F '/' '{print $NF}' | nl
    read -erp "Pick an entry by number to $2, or press ctrl-c to cancel. " number
    chosen="$(ls -rc "$1" | nl | grep -w "$number" | awk '{print $2}')"
    basefile="$(basename "$chosen")" && base="${basefile%.*}" ;}

publish() { \
    delete
    htaccessentry=$(grep "$basefile" "$webdir/blog/.htaccess")
    realname="$(echo "$htaccessentry" | cut -d'"' -f2)"
    rssdate="$(grep "$basefile" $webdir/blog/.htaccess | sed "s/.*\.html\"* *#*//g" | tr -d '\n')"
    [ -z "$rssdate" ] && rssdate="$(LC_TIME=en_CA date '+%a, %d %b %Y %H:%M:%S %z')"
    webdate="$(date '+%a, %d %b %Y %H:%M:%S %z')"
    tmpdir=$(mktemp -d)
    printf "<html lang='en'>\\n<head>\\n<title>%s</title>\\n<link rel='stylesheet' type='text/css' href='%s'>\\n<link href='https://fonts.googleapis.com/css?family=Roboto+Mono|Roboto+Slab&display=swap' rel='stylesheet'>\\n</head>\\n<body>\\n<div class='container'>\\n<div class='panel-main'>\\n<div class='panel-left'>\\n<div class='blog-entry'>\\n<h2>%s</h2>\\n<small>[<a href='%s#%s'>link</a>&mdash;<a style='color: var(--altbg); padding: 0 2px 0 2px; background-color: var(--red);'>standalone</a>]</small>\\n%s\\n</div>\\n</div>\\n<div class='panel-right'>\\n<div class='panel-right-top'>\\n<h1 style='text-align: center; font-size: 44px;'>Blog</h1>\\n</div>\\n<div class='panel-right-bottom'>\\n<hr>\\n<h1>Links &nbsp;<a href='%s'\\nstyle='font-size: 28; font-weight: normal; padding: 0 4px 0 4px'\\ntitle='return home'>&crarr;</a></h1>\\n<ul>\\n<li>Content:\\n<ul>\\n<li><a target='_blank' href='https://github.com/legallyrobert'>Github</a></li>\\n</ul>\\n</li>\\n<li>Personal:\\n<ul>\\n<li><a href='../email.html'>Email</a></li>\\n<li><a href='%s'>Blog</a></li>\\n<li><a href='%s'>RSS Feed</a></li>\\n</ul>\\n</li>\\n<li><a href='../files/' style='font-size: 18px'>Downloadables</a></li>\\n</ul>\\n</div>\\n</div>\\n</div>\\n</div>\\n</body>\\n</html>" "$realname" "$css" "$realname" "../$blogfile" "$base" "$(cat "$webdir/blog/.drafts/$basefile")" "$../indexfile" "../$blogfile" "../$rssfile" > "$webdir/blog/$basefile"
     printf "<item>\\n<title>%s</title>\\n<guid>%s/%s#%s</guid>\\n<pubdate>%s</pubdate>\\n<description><![CDATA[\\n%s\\n]]></description>\\n</item>\\n" "$realname" "$website" "$blogfile" "$base" "$rssdate" "$(cat "$webdir/blog/.drafts/$basefile")" > "$tmpdir/rss"
     printf "<div class='blog-entry'>\\n<h2 id='%s'>%s</h2>\\n<small>[<a href='#%s'>link</a>&mdash;<a href='%s'>standalone</a>]</small>\\n%s\\n<small>%s</small>\\n<hr>\\n</div>\\n" "$base" "$realname" "$base" "blog/$basefile" "$(cat "$webdir/blog/.drafts/$basefile")" "$webdate" > "$tmpdir/html"
    printf "<li>%s $ndash; <a href='blog/%s'>%s</a></li>\\n" "$(date '+%Y %b %d')" "$basefile" "$realname" > "$tmpdir/index"
    sed -i "" "/<!-- RB -->/r $tmpdir/html" "$webdir/$blogfile"
    sed -i "" "/<!-- RB -->/r $tmpdir/rss" "$webdir/$rssfile"
    sed -i "" "/<!-- RB -->/r $tmpdir/index" "$webdir/$indexfile"
    sed -i "" "/ \"$base.html\"/d" "$webdir/blog/.htaccess"
    echo "AddDescription \"$realname\" \"$basefile\" #$rssdate" >> "$webdir/blog/.htaccess"
    repl=$(grep -E "^<li>" "$webdir/$indexfile" | sed 5q | tr -d '\n' | sed -e 's/[\/&\;\!]/\\&/g')
    sed -i "" "s/<\!--BLOG-->.*/<\!--BLOG-->$repl/g" "$webdir/index.html"
    echo -e "lcd $webdir\ncd www\nput index.html\nput blog.html\nput blogindex.html\nput rss.xml\nlcd blog\ncd blog\nput .htaccess\nput $basefile\nquit" | sftp -P 22 $sftpaddress
    rm -f "$webdir/blog/.drafts/$chosen"
}

confirm() { read -erp "Really $1 \"$base\"? (y/N) " choice && echo "$choice" | grep -i "^y$" > /dev/null || exit 1; }

delete() { \
    sed -i "" "/<item/{:a
        N
        /<\\/item>/!ba
        }
        /#$base<\\/guid/d" "$webdir/$rssfile"
    sed -i "" "/<div class='blog-entry'>/{:a
        N
        /<\\/div>/!ba
        }
        /id='$base'/d" "$webdir/$blogfile"
    sed -i "" "/<li>.*<a href='blog\\/$base.html'>/d" "$webdir/$indexfile"
    echo -e "lcd $webdir\ncd www\nput index.html\nput blog.html\nput blogindex.html\nput rss.xml\nlcd blog\ncd blog\nput .htaccess\nrm $basefile\nquit" | sftp -P 22 $sftpaddress
    rm "$webdir/blog/$basefile" 2>/dev/null && printf "Old blog entry removed.\\n" ; }

revise() { awk '/^<small>\[/{flag=1;next}/<\/div>/{flag=0}flag' "$webdir/blog/$chosen" > "$webdir/blog/.drafts/$basefile"
	"$EDITOR" "$webdir/blog/.drafts/$basefile"
	printf "Revision stored in blog/.drafts. Publish as normal entry when desired.\\n" ;}

case "$1" in
    n*) newpost ;;
    e*) listandReturn "$webdir"/blog/.drafts/ edit && "$EDITOR" "$webdir/blog/.drafts/$chosen" ;;
    p*) listandReturn "$webdir"/blog/.drafts publish && publish ;;
    t*) listandReturn "$webdir"/blog/.drafts/ trash && confirm trash && rm -f "$webdir/blog/.drafts/$chosen" && sed -i "" "/ \"$base.html\"/d" "$webdir/blog/.htaccess" ; printf "Draft deleted.\\n" ;;
    d*) listandReturn "$webdir"/blog/ delete && confirm delete && delete && sed -i "" "/ \"$base.html\"/d" "$webdir/blog/.htaccess" ;;
    r*) listandReturn "$webdir"/blog/ revise && revise ;;
    *) printf "Luke Smith's lb modified as rb by Rob Wood <robertwood@uvic.ca>\\nUsage:\\n  rb n:\\tnew draft\\n  rb e:\\tedit draft\\n  rb p:\\tpublish/finalize draft\\n  rb r:\\trevise published entry\\n  rb t:\\tdiscard draft\\n  rb d:\\tdelete published entry\\n\\nBe sure to have the following pattern added to your RSS feed, blog file and blog index:\\n\\n<!-- RB -->\\n\\nNew content will be added directly below that sequence. This is required.\\nSee https://github.com/LukeSmithxyz/lb for more.\\n" ;;
esac
