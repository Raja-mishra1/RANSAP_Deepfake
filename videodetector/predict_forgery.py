import os

#os.environ["TF_CPP_MIN_LOG_LEVEL"] = "3"

import cv2
import matplotlib.pyplot as plt
import numpy as np
from pathlib import Path

import tensorflow as tf
from keras.models import load_model


def predict(video):
    
    vid_src = "/home/raja/Documents/SIH/Video_Forgery_Detection_Using_Machine_Learning/Input_Videos/01_forged.mp4"
    vid = []

    sumFrames = 0
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
    print(Xtest.shape)

    print("\nPredicting !! ")
    model = load_model("videodetector/forgery_model.hdf5_dl=0")
    print("model loaded sucessfully")
    output = model.predict(Xtest)
    #print("hello")
    output = output.reshape((-1))
    results = []
   
    for i in output:
        if i > 0.5:
            results.append(1)
        else:
            results.append(0)

    no_of_forged = sum(results)
    print(no_of_forged)
    forge_flag = 0
    for i in results:
        if i == 1:
            forge_flag = 1
            break
    if forge_flag == 0:
        print("video not forged")
    else:
        print("video is forged")
        per = (no_of_forged/sumFrames)*100
        print(per)

    return per
    

   


