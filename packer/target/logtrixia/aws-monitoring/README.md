## Prerequisites
- An Access to Elasticsearch
- An Access to AWS Config
- An AWS Config Aggregator for all regions
- An AWS Role that has permission
  - AWSConfigUserAccess
  - AWSLambdaBasicExecutionRole 
## How to test AWS monitoring function 
### Configure AWS credentials
Copy .env.tmpl to .env and update these values accordingly
```
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_DEFAULT_REGION=us-east-2
ELASTICSEARCH_HOST=52.30.24.9
ELASTICSEARCH_PORT=9200
ELASTICSEARCH_USERNAME=elastic
ELASTICSEARCH_PASSWORD=changeme
AWS_AGGREGATOR_NAME=AllRegionsAggregator
```
### Install requirements
```
pip3 install -r requirements.txt
```
### Run script
```
python3 src\config_sampler.py
```
## How to deploy AWS monitoring function as Lambda
### Create a Lambda Function
Use AWS Console to build a lambda function with name  ```aws-monitor```
### Populate environment variables
```
ELASTICSEARCH_HOST=
ELASTICSEARCH_PORT=
ELASTICSEARCH_USERNAME
ELASTICSEARCH_PASSWORD
AWS_AGGREGATOR_NAME=AllRegionsAggregator
```
### Build package
```
mkdir build
pip3 install --target ./build -r requirements.txt
cd build
zip -r ../lambda-package.zip .
```
### Add function
```
cd src
zip -g ../lambda-package.zip lambda_function.py
```
### Deploy function 
```
aws lambda update-function-code --function-name aws-monitor --zip-file fileb://lambda-package.zip
```
