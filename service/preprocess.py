import numpy as np 
from PIL import Image

def preprocess_image(image):
    im = np.array(image.resize((200, 200)).convert('RGB'))
    im = im.reshape(1, 200, 200, 3)
    im = im.reshape(1, -1)
    im = im/255.
    processed_image = im.T
    
    return processed_image
    