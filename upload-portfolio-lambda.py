import io
import zipfile
import mimetypes

import boto3

def lambda_handler(event, context):
    session = boto3.session.Session()
    s3 = session.resource('s3')
    build_bucket = s3.Bucket('portfoliobuild.acloud.guru')
    portfolio_bucket = s3.Bucket('portfolio.acloud.guru')

    portfolio_zip = io.BytesIO()
    build_bucket.download_fileobj('portfoliobuild.zip', portfolio_zip)

    with zipfile.ZipFile(portfolio_zip) as myzip:
        for nm in myzip.namelist():
            obj = myzip.open(nm)
            portfolio_bucket.upload_fileobj(obj, nm,
            ExtraArgs={'ContentType': mimetypes.guess_type(nm)[0]})
            portfolio_bucket.Object(nm).Acl().put(ACL='public-read')

    return "Return from DeployPortfolio"
