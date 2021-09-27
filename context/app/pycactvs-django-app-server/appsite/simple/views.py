from django.shortcuts import render
from pycactvs import Ens


def resolver(request, smiles):
    e = Ens(smiles)
    context = {'hashisy': e.get("E_HASHISY")}
    return render(request, "simple.html", context)
