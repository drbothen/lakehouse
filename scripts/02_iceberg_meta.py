import boto3
import json

# Define Minio connection parameters
minio_client = boto3.client(
    's3',
    endpoint_url='http://172.27.0.3:9000',  # Minio IP address from docker inspect
    aws_access_key_id='admin',
    aws_secret_access_key='password',
    region_name='us-east-1'
)

# Specify the bucket and metadata file path
bucket_name = 'warehouse'
metadata_file_key = 'sales/sales_data_raw_a2c0456f-77a6-4121-8d3a-1d8168404edc/metadata/00000-ea121056-0c00-46cb-b9ca-88643d3492cb.metadata.json'  # Example metadata path

# Download the metadata file
metadata_file = minio_client.get_object(Bucket=bucket_name, Key=metadata_file_key)
metadata_content = metadata_file['Body'].read().decode('utf-8')

# Parse and print the metadata content
metadata_json = json.loads(metadata_content)
print(json.dumps(metadata_json, indent=4))