import os
import glob
from django.shortcuts import render
from .models import Image
from .forms import ImageForm
from django.contrib.auth.decorators import login_required
from .predict_result_image import *


@login_required(login_url="/accounts/login/")
def image_detection(request):

    lastimage = Image.objects.last()

    imagefile = lastimage.imagefile

    form = ImageForm(request.POST or None, request.FILES or None)
    if form.is_valid():
        form.save()

    context = {"imagefile": imagefile, "form": form}

    return render(request, "imagedetector/images.html", context)

def predict(request):
    arr = glob.glob('media/images/*.png')
    print(arr)
    img = arr[0]
    origin,per = predict_img(img)
    context = {"origin":origin,"pers":per}
    return render(request,"imagedetector/results.html",context)