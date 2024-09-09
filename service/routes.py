from flask import request, jsonify, render_template
from service import app
from service.preprocess import preprocess_image
import os 
from werkzeug.utils import secure_filename
from PIL import Image
from service.neural_net import predict


UPLOAD_FOLDER = '/tmp/uploads'  # Temporary folder
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

@app.route('/')
def index():
    return render_template('index.html')

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
            prediction = predict(processed_image)

            # Return the prediction result
            return jsonify({"prediction": prediction.tolist()})

        finally:
            # Delete the file after processing to free memory
            if os.path.exists(file_path):
                os.remove(file_path)

    return jsonify({"error": "Failed to process the image"}), 500