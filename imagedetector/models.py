from django.db import models

# Create your models here.
class Image(models.Model):
    name = models.CharField(max_length=500)
    imagefile = models.FileField(upload_to="images/", null=True, verbose_name="")

    def __str__(self):
        return self.name + ": " + str(self.imagefile)

