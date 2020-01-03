import io
import zipfile

import boto3


session = boto3.session.Session(profile_name='pythonAutomation')
s3 = session.resource('s3')
build_bucket = s3.Bucket('portfoliobuild.acloud.guru')
portfolio_bucket = s3.Bucket('portfolio.acloud.guru')

portfolio_zip = io.BytesIO()
build_bucket.download_fileobj('portfoliobuild.zip', portfolio_zip)

with zipfile.ZipFile(portfolio_zip) as myzip:
    for nm in myzip.namelist():
        obj = myzip.open(nm)
        portfolio_bucket.upload_fileobj(obj, nm)
        portfolio_bucket.Object(nm).Acl().put(ACL='public-read')
