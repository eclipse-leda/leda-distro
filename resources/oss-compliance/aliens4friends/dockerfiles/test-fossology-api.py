from uuid import uuid4
from fossology import Fossology, fossology_token
from fossology.obj import ReportFormat, TokenScope, Upload
from fossology.folders import Folder
from fossology.jobs import Jobs

FOSSOLOGY_SERVER = "http://fossology/repo"
FOSSOLOGY_USER = "fossy"
FOSSOLOGY_PASSWORD = "fossy"
TOKEN_NAME = f"{uuid4()}"

token = fossology_token(
      FOSSOLOGY_SERVER,
      FOSSOLOGY_USER,
      FOSSOLOGY_PASSWORD,
      TOKEN_NAME,
      TokenScope.WRITE
)

print(token)
