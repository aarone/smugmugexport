
URL_ROOT="https://api.smugmug.com/hack/json/1.2.0/"

SESSION_ID=$1

URL="${URL_ROOT}?method=smugmug.albums.get&SessionID=${SESSION_ID}"
echo $URL

curl -ks ${URL}
echo ""
