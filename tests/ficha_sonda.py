"""Roda o `ficha` com a rede bloqueada e diz quantas consultas externas ele tentou. Uso: ficha_sonda.py <ficha> <alvo>"""
import contextlib, io, runpy, sys, urllib.request

urls = []


def falso(req, timeout=0):
    urls.append(req.full_url)
    raise OSError("bloqueado na sonda")


urllib.request.urlopen = falso
caminho, sys.argv = sys.argv[1], ["ficha", sys.argv[2]]
with contextlib.redirect_stdout(io.StringIO()):
    try:
        runpy.run_path(caminho, run_name="__main__")
    except SystemExit:
        pass
print(len(urls))
