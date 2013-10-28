#!/bin/bash

# Config
# File size to trigger chunking: 512M
BIG_SIZE=$(( 1024 * 1024 * 512 ))
# Size of each chunk, min 5M max 5G: 100M
CHUNK_SIZE=$(( 1024 * 1024 * 100 ))
TMP='/tmp'
if [[ -d '/mnt/tmp' ]] ; then
    TMP='/mnt/tmp'
fi

AWSID=$1
shift
AWSSEC=$1
shift
FILE=$1
shift
BUCKET=$1
shift
REMOTE_FILE=$1  # optional, default to basename of $FILE
shift
MIME_TYPE=$1  # optional, calculated if not specified
shift

if [[ -z $AWSID ]] ; then
    echo "missing awsid parameter" >&2
    exit 1
fi
if [[ -z $AWSSEC ]] ; then
    echo "missing awssec parameter" >&2
    exit 1
fi
if [[ -z $FILE ]] ; then
    echo "missing file parameter" >&2
    exit 1
fi
if [[ -z $BUCKET ]] ; then
    echo "missing bucket parameter" >&2
    exit 1
fi
if [[ -z $REMOTE_FILE ]] ; then
    REMOTE_FILE=`basename "$FILE"`
fi
if [[ -z $MIME_TYPE ]] ; then
    if [[ "css" = ${FILE##*.} ]] ; then
        MIME_TYPE="text/css; charset=us-ascii"
    elif [[ "js" = ${FILE##*.} ]] ; then
        MIME_TYPE="text/javascript; charset=us-ascii"
    elif [[ "svg" = ${FILE##*.} ]] ; then
        MIME_TYPE="image/svg+xml; charset=utf-8"
    elif [[ "woff" = ${FILE##*.} ]] ; then
        MIME_TYPE="application/x-font-woff"
    else
        MIME_TYPE=`file --brief --mime "$FILE"`
    fi
fi

md5_base64() {
    local file=$1
    openssl dgst -md5 -binary "$file" | openssl enc -e -a
}

send_part() {
    local file=$1
    local remote_file=$2
    local content_type=$3
    local headers_file=$4
    local DATE=`date '+%a, %d %b %Y %T %Z'`
    local md5=`md5_base64 "$file"`
    local SIGNATURE=`echo -ne "PUT\n$md5\n$content_type\n\nx-amz-date:$DATE\n/$BUCKET/$remote_file" | openssl dgst -binary -sha1 -hmac "$AWSSEC" | openssl enc -e -a`
    local AUTH_HEADER="Authorization: AWS ${AWSID}:$SIGNATURE"
    local DATE_HEADER="X-amz-date: $DATE"
    local HOST_HEADER="Host: $BUCKET.s3.amazonaws.com"
    local CONTENT_MD5="Content-MD5: $md5"
    local CONTENT_HEADER="Content-Type:"
    if [[ -n $content_type ]] ; then
        CONTENT_HEADER="Content-Type: $content_type"
    fi
    HEADERS_OPT=''
    if [[ -n $headers_file ]] ; then
        HEADERS_OPT="-D $headers_file"
    fi
    curl -X PUT $HEADERS_OPT -H "$CONTENT_MD5" -H "$CONTENT_HEADER" -H "$DATE_HEADER" -H "$AUTH_HEADER" -H "$HOST_HEADER" -T "$file" "http://s3.amazonaws.com/$remote_file"
}

# if the file is over 5G, need to split it into parts
BYTES=`wc -c "$FILE" | awk '{print $1}'`
if [[ $BYTES -le $BIG_SIZE ]] ; then
    send_part "$FILE" "$REMOTE_FILE" "$MIME_TYPE"
    exit
fi

echo "Too big for one shot"

# this bash function breaks XML up, for a detailed description see:
# http://stackoverflow.com/questions/893585/how-to-parse-xml-in-bash#7052168
read_dom () {
    local IFS=\>
    read -d \< ENTITY CONTENT
    local RET=$?
    TAG_NAME=${ENTITY%% *}
    ATTRIBUTES=${ENTITY#* }
    return $RET
}

# first need to init multipart upload
DATE=`date '+%a, %d %b %Y %T %Z'`
SIGNATURE=`echo -ne "POST\n\n\n\nx-amz-date:$DATE\n/$BUCKET/$REMOTE_FILE?uploads" | openssl dgst -binary -sha1 -hmac "$AWSSEC" | openssl enc -e -a`
DATE_HEADER="X-amz-date: $DATE"
HOST_HEADER="Host: $BUCKET.s3.amazonaws.com"
AUTH_HEADER="Authorization: AWS ${AWSID}:$SIGNATURE"

UPLOADID=''

curl -s -X POST -H "$DATE_HEADER" -H "$AUTH_HEADER" -H "$HOST_HEADER" "http://s3.amazonaws.com/$REMOTE_FILE?uploads" > ${TMP}/${REMOTE_FILE}.xml
while read_dom
do
    if [[ $ENTITY = "UploadId" ]] ; then
        export UPLOADID="$CONTENT"
    fi
done < ${TMP}/${REMOTE_FILE}.xml

if [[ -z $UPLOADID ]] ; then
    echo "Error getting the uploadid"
    cat ${TMP}/${REMOTE_FILE}.xml
    exit 1
fi

echo "<CompleteMultipartUpload>" > ${TMP}/${REMOTE_FILE}.xml
echo "Sending chunks..."
CHUNK_SIZE_M1=$(( $CHUNK_SIZE - 1 ))
CHUNKS=$(( ($BYTES + CHUNK_SIZE_M1) / $CHUNK_SIZE ))  # add $CHUNK_SIZE minus 1 to get a ceiling on number of chunks
for chunk in `seq 1 $CHUNKS`
{
    skip=$(( $chunk - 1 ))
    dd "if=$FILE" of="${TMP}/${REMOTE_FILE}.$chunk" bs=$CHUNK_SIZE count=1 skip=$skip &>/dev/null
    send_part "${TMP}/${REMOTE_FILE}.$chunk" "$REMOTE_FILE?partNumber=$chunk&uploadId=$UPLOADID" '' "${TMP}/${REMOTE_FILE}.${chunk}.head"
    ETAG=`grep '^ETag: ' "${TMP}/${REMOTE_FILE}.${chunk}.head" | cut -c 7- | tr -d '\r'`
    echo -e "  <Part>\n    <PartNumber>$chunk</PartNumber>\n    <ETag>$ETAG</ETag>\n  </Part>" >> ${TMP}/${REMOTE_FILE}.xml
    rm "${TMP}/${REMOTE_FILE}.$chunk" "${TMP}/${REMOTE_FILE}.${chunk}.head"
}
echo "</CompleteMultipartUpload>" >> ${TMP}/${REMOTE_FILE}.xml

echo "Chunks uploaded, assembling"

DATE=`date '+%a, %d %b %Y %T %Z'`
SIGNATURE=`echo -ne "POST\n\n\n\nx-amz-date:$DATE\n/$BUCKET/$REMOTE_FILE?uploadId=$UPLOADID" | openssl dgst -binary -sha1 -hmac "$AWSSEC" | openssl enc -e -a`
DATE_HEADER="X-amz-date: $DATE"
HOST_HEADER="Host: $BUCKET.s3.amazonaws.com"
AUTH_HEADER="Authorization: AWS ${AWSID}:$SIGNATURE"

curl -s -X POST -H "$DATE_HEADER" -H "$AUTH_HEADER" -H "$HOST_HEADER" -T "${TMP}/${REMOTE_FILE}.xml" "http://s3.amazonaws.com/$REMOTE_FILE?uploadId=$UPLOADID" > ${TMP}/${REMOTE_FILE}.assemble.xml
rm ${TMP}/${REMOTE_FILE}.xml
while read_dom
do
    if [[ $TAG_NAME = "CompleteMultipartUploadResult" ]] ; then
        echo "Success!"
        rm ${TMP}/${REMOTE_FILE}.assemble.xml
        exit
    fi
done < ${TMP}/${REMOTE_FILE}.assemble.xml

echo "Something went wrong"
cat ${TMP}/${REMOTE_FILE}.assemble.xml
