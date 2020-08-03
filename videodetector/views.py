import os
from django.shortcuts import render,redirect
from .models import Video
from .forms import VideoForm
from django.contrib.auth.decorators import login_required
from .predict_forgery import *
from django.core.files import File


@login_required(login_url="/accounts/login/")
def video_detection(request):

    lastvideo = Video.objects.last()

    videofile = lastvideo.videofile

    form = VideoForm(request.POST or None, request.FILES or None)
    if form.is_valid():
        form.save()

    context = {"videofile": videofile, "form": form}
    if request.method == "POST":
        url = request.POST.get("imageupload")
        print(len(url))
        return redirect("/video/results")

    return render(request, "videodetector/videos.html", context)



def predict_video(request):
    arr = os.listdir("media/videos")
    video = list(Video.objects.all())
    lastvideo = Video.objects.last()
    print(lastvideo.videofile.url)
    print(request.method)
    video = lastvideo.videofile.url

    op = predict(video)

    output = {"pers":op}
    return render(request,"videodetector/results.html",output)