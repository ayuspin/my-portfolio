import io
import zipfile
import mimetypes

import boto3

def lambda_handler(event, context):
    s3 = boto3.resource('s3')
    sns = boto3.resource('sns')
    try:
        build_bucket = s3.Bucket('portfoliobuild.acloud.guru')
        portfolio_bucket = s3.Bucket('portfolio.acloud.guru')
        topic = sns.Topic('arn:aws:sns:us-east-1:315089025365:deployPortfolioTopic')

        portfolio_zip = io.BytesIO()
        build_bucket.download_fileobj('portfoliobuild.zip', portfolio_zip)

        with zipfile.ZipFile(portfolio_zip) as myzip:
            for nm in myzip.namelist():
                obj = myzip.open(nm)
                portfolio_bucket.upload_fileobj(obj, nm,
                ExtraArgs={'ContentType': mimetypes.guess_type(nm)[0]})
                portfolio_bucket.Object(nm).Acl().put(ACL='public-read')
    except:
        topic.publish(Subject='Portfolio', Message='Portfolio deployment failied')
        raise
    topic.publish(Subject='Portfolio', Message='Portfolio deployed')
    return "Return from DeployPortfolio"
