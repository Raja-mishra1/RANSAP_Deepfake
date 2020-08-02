from django.urls import path

from . import views

urlpatterns = [
    # ex: /polls/
    path("", views.video_detection, name="video_detection"),
    path("results",views.predict_video,name="results")
]
