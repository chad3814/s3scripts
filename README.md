s3scripts
=========

bash scripts to interact with S3

I have written these scripts a few times at my past couple jobs using my memory and my [stackoverflow](http://stackoverflow.com/) [answer](http://stackoverflow.com/questions/893585/how-to-parse-xml-in-bash/7052168#7052168). So, now thanks to [Grokker](http://grokker.com), I am able to release these. Hopefully they will help someone who needs to manipulate S3 objects from bash.

-----------------------------

Usage:
======

All of the scripts take an AWSID and Secret as the first two arguments. Most of them then take a file and bucket as the next two.

* [s3_get.sh](#get) - copy an object from S3 into a local file
* [s3_put.sh](#put) - copy a local file into an S3 object
* [s3_head.sh](#head) - get some information on an S3 object
* [s3_delete.sh](#delete) - remove an object from S3
* [s3_list.sh](#list) - list the contents of an S3 bucket
* [s3_make_public.sh](#make_public) - change the acl on an S3 object into 'public'
* [s3_copy_bucket.sh](#copy_bucket) - copy the objects from one S3 bucket into another, uses s3_get.sh and s3_put.sh to ensure large objects (>5GB) get copied
* [s3_list_multipart_uploads.sh](#list_mpu) - list unfinished multipart uploads including the uploadid. Objects greater then 5GB require the use of AWS's [multipart upload](http://docs.aws.amazon.com/AmazonS3/latest/dev/mpuoverview.html) process
* [s3_abort_multipart_upload.sh](#abort_mpu) - abort any unfinished multipart upload

<a name="get" />
### s3_get.sh ###
    s3_get.sh <AWSID> <AWSSEC> <object key> <bucket> [local file]
        <AWSID>       - Amazon Web Services ID
        <AWSSEC>      - Amazon Web Services Secret
        <object key>  - The object key (file) in the bucket to retrieve
        <bucket>      - The S3 bucket which contains the object
        [local file]  - An optional local file to store the object in, by default it
                        saves it in <object key> (any directories included)

<a name="put" />
### s3_put.sh ###
    s3_put.sh <AWSID> <AWSSEC> <file> <bucket> [object key] [mime type]
        <AWSID>       - Amazon Web Services ID
        <AWSSEC>      - Amazon Web Services Secret
        <local file>  - The file to put into an object in S3
        <bucket>      - The S3 bucket which will contain the object
        [object key]  - An optional object key to store the object within, by default
                        it will be the basename of the local file (no directories)
        [mime type]   - An optional mime type to be set, by default it will use *file*
                        to automatically determine the mime type. *file* fails on .js
                        .css and .svg, so those are hard coded.
        [local file]  - An optional local file to store the object in, by default it
                        saves it in <object key> (any directories included)

<a name="head" />
### s3_head.sh ###
    s3_head.sh <AWSID> <AWSSEC> <object key> <bucket>
        <AWSID>       - Amazon Web Services ID
        <AWSSEC>      - Amazon Web Services Secret
        <object key>  - The object key (file) in the bucket to get information about
        <bucket>      - The S3 bucket which contains the object

<a name="delete" />
### s3_delete.sh ###
    s3_delete.sh <AWSID> <AWSSEC> <object key> <bucket>
        <AWSID>       - Amazon Web Services ID
        <AWSSEC>      - Amazon Web Services Secret
        <object key>  - The object key (file) in the bucket to remove
        <bucket>      - The S3 bucket which contains the object

<a name="list" />
### s3_list.sh ###
    s3_list.sh <AWSID> <AWSSEC> <bucket> [all?] [marker]
        <AWSID>       - Amazon Web Services ID
        <AWSSEC>      - Amazon Web Services Secret
        <bucket>      - The S3 bucket from which you want a listing of object
        [all?]        - Optional, if specified and not an empty string it will list
                        all of the objects in the bucket, otherwise it will only
                        list the first 1,000
        [marker]      - Optional, if specified it will start listing objects after
                        this object key

<a name="make_public" />
### s3_make_public.sh ###
    s3_make_public.sh <AWSID> <AWSSEC> <object key> <bucket>
        <AWSID>       - Amazon Web Services ID
        <AWSSEC>      - Amazon Web Services Secret
        <object key>  - The object key (file) in the bucket to make publicly available
        <bucket>      - The S3 bucket which contains the object

<a name="copy_bucket" />
### s3_copy_bucket.sh ###
    s3_copy_bucket.sh <AWSID> <AWSSEC> <src bucket> <dest bucket>
        <AWSID>       - Amazon Web Services ID
        <AWSSEC>      - Amazon Web Services Secret
        <src bucket>  - The S3 bucket which contains the objects you want copied
        <dest bucket> - The S3 bucket into which you want the objects copied

<a name="list_mpu" />
### s3_list_multipart_uploads.sh ###
    s3_list_multipart_uploads.sh <AWSID> <AWSSEC> <bucket> [all?] [marker]
        <AWSID>       - Amazon Web Services ID
        <AWSSEC>      - Amazon Web Services Secret
        <bucket>      - The S3 bucket from which you want a listing of object
        [all?]        - Optional, if specified and not an empty string it will list
                        all of the current multipart uploads not finished in the bucket,
                        otherwise it will only list the first 1,000
        [marker]      - Optional, if specified it will start listing unfinished multipart
                        uploads after this object key

<a name="abort_mpu" />
### s3_abort_multipart_upload.sh ###
    s3_abort_multipart_upload.sh <AWSID> <AWSSEC> <object key> <bucket> <uploadid>
        <AWSID>       - Amazon Web Services ID
        <AWSSEC>      - Amazon Web Services Secret
        <object key>  - The object key (file) in the bucket to remove
        <bucket>      - The S3 bucket which would contain the object
        <uploadid>    - The uploadid supplied for the multipart upload. You can also get
                        the uploadid from s3_list_multipart_uploads.sh
