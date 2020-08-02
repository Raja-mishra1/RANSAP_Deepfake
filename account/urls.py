from django.urls import path, include

from django.contrib.auth import views as auth_views


from . import views

urlpatterns = [
    path("signup/", views.signup, name="index"),
    path("login/", views.login_user, name="login"),
    path("logout/", views.logout_user, name="logout"),
    path(
        "password_change_done/",
        auth_views.PasswordChangeDoneView.as_view(
            template_name="account/password_change_done.html"
        ),
        name="password_change_done",
    ),
    path(
        "password_reset_done/",
        auth_views.PasswordResetCompleteView.as_view(
            template_name="account/password_reset_done.html"
        ),
        name="password_reset_done",
    ),
    path(
        "reset/<uidb64>/<token>/",
        auth_views.PasswordResetConfirmView.as_view(
            template_name="account/password_change.html"
        ),
        name="password_reset_confirm",
    ),
    path(
        "password_reset/",
        auth_views.PasswordResetView.as_view(
            template_name="account/password_reset.html"
        ),
        name="password_reset",
    ),
    path(
        "reset/done/",
        auth_views.PasswordResetCompleteView.as_view(
            template_name="account/password_change_complete.html"
        ),
        name="password_reset_complete",
    ),
]

