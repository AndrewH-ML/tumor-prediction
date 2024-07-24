from flask import request, jsonify
from service import app
import boto3
from service.preprocessing import preprocess_image
import neural_net  # Assuming this is your custom neural network module

s3 = boto3.client(
    's3',
    aws_access_key_id=app.config['AWS_ACCESS_KEY_ID'],
    aws_secret_access_key=app.config['AWS_SECRET_ACCESS_KEY'],
    region_name=app.config['AWS_REGION']
)

@app.route('/predict', methods=['POST'])
def predict():
    if 'file' not in request.files:
        return jsonify({"error": "No file part"}), 400

    file = request.files['file']

    if file.filename == '':
        return jsonify({"error": "No selected file"}), 400

    if file:
        # Save the image to S3
        s3_key = f"uploads/{file.filename}"
        s3.upload_fileobj(file, app.config['S3_BUCKET'], s3_key)
        image_url = f"https://{app.config['S3_BUCKET']}.s3.amazonaws.com/{s3_key}"

        # Preprocess the image and make a prediction
        image = Image.open(file.stream)
        processed_image = preprocess_image(image)
        prediction = neural_net.predict(processed_image)

        return jsonify({"prediction": prediction.tolist(), "image_url": image_url})

    return jsonify({"error": "Failed to process the image"}), 500