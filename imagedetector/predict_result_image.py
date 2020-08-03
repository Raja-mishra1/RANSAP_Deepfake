import os
os.environ["TF_CPP_MIN_LOG_LEVEL"] = "3"
import cv2
import pandas as pd
import numpy as np
import tensorflow as tf
import matplotlib.pyplot as plt
from sklearn import metrics
from keras.models import Sequential, Model
from keras.layers import Dense, Flatten, Dropout
from keras.callbacks import ReduceLROnPlateau
from keras.optimizers import Adam, RMSprop
from keras.preprocessing.image import ImageDataGenerator
import numpy as np
from keras.models import load_model
from keras.preprocessing import image
from keras_vggface.vggface import VGGFace



def create_model():
    vgg_model = VGGFace(include_top=False, input_shape=(224, 224, 3))

    last_layer = vgg_model.get_layer('pool5').output
    flat_layer = Flatten(name='flatten')(last_layer)
    fc1 = Dense(2048, activation='relu', name='fc1')(flat_layer)
    dense2 = Dense(2, activation='softmax', name='dense2')(fc1)

    custom_vgg_model = Model(vgg_model.input, dense2)
    custom_vgg_model.load_weights('/home/raja/Documents/SIH/branch/new-ui/ransap-web/imagedetector/vggface_deep_v3_both_final.h5')

    return custom_vgg_model


def predict_img(image_):


    img = image.load_img(image_, target_size=(224, 224))
    x = image.img_to_array(img)
    x = np.expand_dims(x, axis=0)
    x /= 255.
    images = np.vstack([x])
    print("\nPredicting !! ")
    model = create_model()



    classes = model.predict(images, batch_size=10)


    print("Fake", f'{classes[0][0]:f}')
    print("Real", f'{classes[0][1]:f}')

    if classes[0][0] > classes[0][1]:
        return True,classes[0][0]
    else:
        return False, classes[0][1]