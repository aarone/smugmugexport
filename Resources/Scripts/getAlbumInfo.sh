
URL_ROOT="https://api.smugmug.com/hack/json/1.2.0/"

SESSION_ID=$1
ALBUM_ID=$2

URL="${URL_ROOT}?method=smugmug.albums.getInfo&SessionID=${SESSION_ID}&AlbumID=${ALBUM_ID}"

curl -ks ${URL}
echo ""
