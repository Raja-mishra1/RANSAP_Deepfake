import os
from django.shortcuts import render
from .models import Video
from .forms import VideoForm
from django.contrib.auth.decorators import login_required
from .predict_forgery import *


@login_required(login_url="/accounts/login/")
def video_detection(request):

    lastvideo = Video.objects.last()

    videofile = lastvideo.videofile

    form = VideoForm(request.POST or None, request.FILES or None)
    if form.is_valid():
        form.save()

    context = {"videofile": videofile, "form": form}

    return render(request, "videodetector/videos.html", context)



def predict_video(request):
    arr = os.listdir("media/videos")
    video = arr[-1]
    #op = predict(video)
    op = 1
    output = {"data":op}
    return render(request,"videodetector/results.html",output)