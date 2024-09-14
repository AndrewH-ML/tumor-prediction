import numpy as np 
from PIL import Image

def preprocess_image(image):
    im = np.array(image.resize((200, 200)).convert('RGB'))
    print(im.shape)
    im = im.reshape(1, 200, 200, 3)
    print(im.shape)
    im = im.reshape(1, -1)
    print(im.shape)
    im = im/255.
    processed_image = im.T
    print(processed_image.shape)
    return processed_image
    