import sys
from flask import Flask
from service import config
from service.common import log_handlers
from flask_talisman import Talisman
from flask_cors import CORS

# Create Flask application
app = Flask(__name__)
talisman = Talisman(app)
cors = CORS(app)
app.config.from_object(config)

from service import routes

log_handlers.init_logging(app, "gunicorn.error")

app.logger.info(70 * "*")
app.logger.info("  TUMOR PREDICTION SERVICE RUNNING ".center(70, "*"))
app.logger.info(70 * "*")

app.logger.info("Service Initialized")