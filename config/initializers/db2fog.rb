# See: https://github.com/yob/db2fog
#
# Both :s3_access_key and :s3_secret preferences are defined in Spree's
# app_configuration, while the S3_BACKUPS_BUCKET env var is defined by OFN in
# ofn-install
if ENV['S3_BACKUPS_BUCKET']
  DB2Fog.config = {
    :aws_access_key_id     => ENV.fetch('S3_ACCESS_KEY', Spree::Config[:s3_access_key]),
    :aws_secret_access_key => ENV.fetch('S3_SECRET', Spree::Config[:s3_secret]),
    :directory             => ENV['S3_BACKUPS_BUCKET'],
    :provider              => 'AWS'
  }
end
