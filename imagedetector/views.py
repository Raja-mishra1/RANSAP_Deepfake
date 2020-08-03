import os
import glob
from django.shortcuts import render,redirect
from .models import Image
from .forms import ImageForm
from django.contrib.auth.decorators import login_required
from .predict_result_image import *
import requests
import sys
import os
from PIL import Image as pil_img
from io import BytesIO
from matplotlib import pyplot
from .models import* 



def download(url):
    response = requests.get(url)
    print(response.content)
    img = pil_img.open(BytesIO(response.content))
    img.save('new_.png')
    # image_ = 'new.png'
    # img = Image.objects.create(name="new",imagefile=image_)
    return "/home/raja/Desktop/123.jpeg"
    


@login_required(login_url="/accounts/login/")
def image_detection(request):

    lastimage = Image.objects.last()

    imagefile = lastimage.imagefile

    form = ImageForm(request.POST or None, request.FILES or None)
    if form.is_valid():
        form.save()

    context = {"imagefile": imagefile, "form": form}
    if request.method == "POST":
        url = request.POST.get("imageupload")
        print(len(url))
        if len(url) == 0:
            request.session['image_url'] = None
        else:
            request.session['image_url'] = url
        return redirect("/image/results")

    return render(request, "imagedetector/images.html", context)

def predict(request):
    arr = glob.glob('media/images/*.png')
    if request.session['image_url']!=None:
        img = download(request.session['image_url'])
    else:  
        img = list(Image.objects.all())
        

        img = img[-1].imagefile.url
        img = img[1:]
        img = img
    print(img)

    
    origin,per = predict_img(img)
    context = {"origin":origin,"pers":per,"image":img}
    return render(request,"imagedetector/results.html",context)