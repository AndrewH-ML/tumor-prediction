# routes.py

from flask import request, jsonify, render_template
from service import app
from service.preprocess import preprocess_image
import os
from werkzeug.utils import secure_filename
from PIL import Image
import pickle
from service import neural_net

ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}

service_dir = os.path.dirname(os.path.abspath(__file__))
weights_path = os.path.join(service_dir, 'weights', 'nn_weights.pkl')
with open(weights_path, 'rb') as f:
    weights = pickle.load(f)


def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS


@app.route('/')
def index():
    app.logger.info("Rendering index page")
    return render_template('index.html'), 200


@app.route('/predict', methods=['POST'])
def predict():
    app.logger.info("Received prediction request")
    
    if 'file' not in request.files:
        app.logger.warning("No file part in the request")
        return jsonify({"error": "No file part"}), 400

    file = request.files['file']

    if file.filename == '':
        app.logger.warning("No file selected")
        return jsonify({"error": "No selected file"}), 400

    if not allowed_file(file.filename):
        app.logger.warning(f"File type not allowed: {file.filename}")
        return jsonify({"error": "File type not allowed"}), 400
    
    try:

        filename = secure_filename(file.filename)
        app.logger.info(f"Processing file: {filename}")
        
        file_extension = filename.rsplit('.', 1)[1].lower()
        app.logger.info(f"Reading image file with extension: {file_extension}")
        
        image = Image.open(file)
        app.logger.info(f"Preprocessing image")
        processed_image = preprocess_image(image)

        app.logger.info("Making prediction")
        prediction = neural_net.predict(processed_image, weights)
        
        prediction_text = "tumor present" if prediction == 1 else "no tumor"
        app.logger.info(f"Prediction result: {prediction_text}")
        # Return the prediction result
        return jsonify({"prediction": prediction_text}), 200
    
    except Exception as e:
        app.logger.error(f"Failed to process the image: {e}", exc_info=True)
        return jsonify({"error": "Failed to process the image", "details": str(e)}), 500

