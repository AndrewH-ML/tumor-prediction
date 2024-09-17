import sys
from flask import Flask
from flask import jsonify
from service.common import log_handlers
from flask_talisman import Talisman
from flask_cors import CORS


# Create Flask application
app = Flask(__name__)
# Import your routes after the app is created
from service import routes
# # talisman = Talisman(app)
# cors = CORS(app)
# talisman.force_https = False
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16 MB limit
from service import routes
log_handlers.init_logging(app, "gunicorn.error")


app.logger.info(70 * "*")
app.logger.info("  TUMOR PREDICTION SERVICE RUNNING ".center(70, "*"))
app.logger.info(70 * "*")
app.logger.info("Service Initialized")


@app.errorhandler(404)
def not_found(error):
    return jsonify({"error": "Not Found"}), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({"error": "Internal Server Error"}), 500