import clickhouse_driver as cd
import sys
import pymongo
from pymongo import *
import requests
import datetime
from datetime import datetime
from datetime import *



url='https://hooks.slack.com/services/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'

msg='national feedback dashboard data updated'

alert='{"text":"%s"}'%msg
responce=requests.post(url,alert)
