from .models import *
from django.forms import ModelForm


class ImageForm(ModelForm):
    class Meta:
        model = Image
        fields = ["name", "imagefile"]

