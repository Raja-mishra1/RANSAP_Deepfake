from django.urls import path

from . import views

urlpatterns = [
    # ex: /polls/
    path("", views.image_detection, name="image_detection"),
    path("results",views.predict,name="results")

]
