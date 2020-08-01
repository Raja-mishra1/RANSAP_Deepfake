from django.contrib import admin
from .models import *

# Register your models here.


class Image_admin(admin.ModelAdmin):
    pass


admin.site.register(Image, Image_admin)
