import unittest
from service import app
import io
from PIL import Image

class TestRoutes(unittest.TestCase):
    def setUp(self):
        app.config['TESTING'] = True
        app.config['DEBUG'] = True
        self.client = app.test_client()

    def test_index(self):
        response = self.client.get('/')
        self.assertEqual(response.status_code, 200)
        self.assertIn(b'Upload MRI Image', response.data)

    def test_predict_no_file(self):
        response = self.client.post('/predict', data={})
        self.assertEqual(response.status_code, 400)
        self.assertIn(b'No file part', response.data)

    def test_predict_invalid_file(self):
        response = self.client.post(
            '/predict',
            data={'file': (io.BytesIO(b"fake data"), 'test.txt')}
        )
        self.assertEqual(response.status_code, 400)
        self.assertIn(b'File type not allowed', response.data)

    def test_predict_valid_image(self):
        # Create a simple test image
        img = Image.new('RGB', (100, 100), color='red')
        img_bytes = io.BytesIO()
        img.save(img_bytes, format='PNG')
        img_bytes.seek(0)

        response = self.client.post(
            '/predict',
            data={'file': (img_bytes, 'test_image.png')},
            content_type='multipart/form-data'
        )
        self.assertEqual(response.status_code, 200)  # Assuming prediction would fail without model

if __name__ == '__main__':
    unittest.main()
