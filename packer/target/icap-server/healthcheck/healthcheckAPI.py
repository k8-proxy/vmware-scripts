from fastapi import FastAPI , status
from fastapi.responses import JSONResponse , FileResponse
import os , requests
app = FastAPI()


@app.get("/status")
async def root():
    instanceId = requests.get('http://169.254.169.254/latest/meta-data/instance-id')
    publicIp=requests.get('http://169.254.169.254/latest/meta-data/public-ipv4')
    if os.path.exists("/home/ubuntu/healthcheck/status.ok"):
        data = {"message" : "Status OK","instanceId": instanceId.text,"publicIp":publicIp.text }
        return JSONResponse(status_code=status.HTTP_200_OK, content=data)
    else:
        data = {"message" : "status Fail" }
        return JSONResponse(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, content=data)