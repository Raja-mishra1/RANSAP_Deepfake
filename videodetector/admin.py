from django.contrib import admin
from .models import *

# Register your models here.


class Video_admin(admin.ModelAdmin):
    pass

admin.site.register(Video, Video_admin)

