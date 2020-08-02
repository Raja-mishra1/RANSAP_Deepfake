from django.http import HttpResponse
from django.shortcuts import render, redirect
from django.contrib.auth.forms import UserCreationForm
from .forms import UsernamePassword, RegistrationForm
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.models import User
from django.contrib import messages


def signup(request):
    if request.method == "POST":

        form = RegistrationForm(request.POST)

        if form.is_valid():
            user = form.save()
            return redirect("/")
    else:
        form = RegistrationForm()

    print(form.errors)
    return render(request, "account/signup.html", {"form": form})


def login_user(request):
    print(request.get_full_path())

    redirect_path = request.get_full_path().split("?next=")
    if len(redirect_path) > 1:
        redirect_path = redirect_path[1]
    else:
        redirect_path = "/"

    if request.method == "POST":

        username = request.POST["username"]
        password = request.POST["password"]
        user = authenticate(request, username=username, password=password)
        print(user)
        if user is not None:
            # login successfull
            login(request, user)
            redirect_url = request.GET.get("next", "/")
            return redirect(redirect_url)
        else:
            form = UserCreationForm()
            args = {"form": form}

            return redirect("/accounts/signup/")
    else:
        return render(request, "account/login.html", {"redirect": redirect_path})
    # else:
    #     # Return an 'invalid login' error message.


def logout_user(request):
    logout(request)
    messages.info(request, "login again ")
    return redirect("/")

