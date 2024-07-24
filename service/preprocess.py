import numpy as np 
from PIL import Image

def preprocess_image(image):
    im = np.array(Image.open(file).resize((200, 200)).convert('RGB'))
    im = im/255.
    im = im.reshape(im.shape[0], -1)
    return im