## How to monitor AWS resources
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