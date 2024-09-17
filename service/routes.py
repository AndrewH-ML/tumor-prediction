from flask import request, jsonify, render_template
from service import app
from service.preprocess import preprocess_image
import os
from werkzeug.utils import secure_filename
from PIL import Image
import pickle
from service import neural_net


UPLOAD_FOLDER = '/tmp/uploads'  # Temporary folder
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
service_dir = os.path.dirname(os.path.abspath(__file__))
weights_path = os.path.join(service_dir, 'weights', 'nn_weights.pkl')
with open(weights_path, 'rb') as f:
    weights = pickle.load(f)


@app.route('/')
def index():
    return render_template('index.html'), 200


@app.route('/predict', methods=['POST'])
def predict():
    if 'file' not in request.files:
        return jsonify({"error": "No file part"}), 400

    file = request.files['file']

    if file.filename == '':
        return jsonify({"error": "No selected file"}), 400

    if file:
        # store image locally
        filename = secure_filename(file.filename)
        file_path = os.path.join(UPLOAD_FOLDER, filename)
        file.save(file_path)
   
        try:
            # Preprocess the image and make a prediction
            image = Image.open(file_path)
            processed_image = preprocess_image(image)
            prediction = neural_net.predict(processed_image, weights)

            # Return the prediction result
            return jsonify({"prediction": prediction.tolist()}), 200
        except Exception as e:
            return jsonify({"error": "Failed to process the image", "details": str(e)}), 500  # Handle processing errors

        finally:
            # Delete the file after processing to free memory
            if os.path.exists(file_path):
                os.remove(file_path)

    return jsonify({"error": "Failed to process the image"}), 500
