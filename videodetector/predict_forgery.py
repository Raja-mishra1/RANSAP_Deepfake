import os

os.environ["TF_CPP_MIN_LOG_LEVEL"] = "3"

import cv2
import numpy as np
from keras.models import load_model


def predict(video):
    vid_src = "media/videos/" + video
    vid = []

    sumFrames = 0
    fps = 0
    cap = cv2.VideoCapture(vid_src)
    while cap.isOpened():
        ret, frame = cap.read()
        if ret == False:
            # fps = cap.get(cv2.CAP_PROP_FPS)
            break
        sumFrames += 1
        vid.append(frame)
    cap.release()

    print("\nNo. Of Frames in the Video: ", sumFrames)

    Xtest = np.array(vid)

    print("\nPredicting !! ")
    model = load_model(
        "/home/raja/Documents/SIH/Video_Forgery_Detection_Using_Machine_Learning/ResNet50_Model/forgery_model.hdf5_dl=0"
    )
    output = model.predict(Xtest)

    output = output.reshape((-1))
    results = []
    for i in output:
        if i > 0.5:
            results.append(1)
        else:
            results.append(0)

    no_of_forged = sum(results)

    if no_of_forged < fps:
        return False

    else:
        return True, no_of_forged

