from django.contrib import admin
from .models import *

# Register your models here.
class Profile_admin(admin.ModelAdmin):
    pass


admin.site.register(Profile, Profile_admin)

