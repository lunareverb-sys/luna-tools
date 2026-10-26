#!/bin/sh
# Testes de fumaça e de regressão das 6 ferramentas. Uso (na raiz do repositório): sh tests/run.sh
R=$(cd "$(dirname "$0")/.." && pwd)
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
FALHAS=0
ok() { echo "ok   $1"; }
falha() { echo "FALHA $1"; FALHAS=$((FALHAS+1)); }
checa() { if [ "$2" = "$3" ]; then ok "$1"; else falha "$1 (esperado '$3', veio '$2')"; fi; }

# sintaxe
for f in buscar/buscar olhar/olhar pre-commit-segredo/pre-commit-segredo; do
  sh -n "$R/$f" && ok "sintaxe $f" || falha "sintaxe $f"
done
python3 -I -m py_compile "$R/ficha/ficha" "$R/resumir/resumir" "$R/risco/risco" && ok "sintaxe python" || falha "sintaxe python"
find "$R" -name __pycache__ -exec rm -rf {} + 2>/dev/null

# ficha: nada interno sai da máquina (achado F1); domínio e IP públicos continuam consultando
for a in 192.168.1.5 192.168.1.5:8080 http://192.168.1.5:8080/x user@10.0.0.7 "[::1]" "[fd00::1]:443" 10.0.0.7. 3232235781 ::ffff:10.0.0.1 100.64.0.1 nas.corp host-interno localhost; do
  checa "ficha não consulta '$a'" "$(python3 -I "$R/tests/ficha_sonda.py" "$R/ficha/ficha" "$a")" 0
done
for a in algo.lan algo.local a.b.internal x.corp casa.home h.localdomain host-interno; do
  checa "ficha '$a': mensagem de nome interno" "$(python3 -I "$R/ficha/ficha" "$a" 2>&1 | grep -c '^nome interno: nenhuma consulta externa feita$')" 1
  checa "ficha '$a': zero consultas" "$(python3 -I "$R/tests/ficha_sonda.py" "$R/ficha/ficha" "$a")" 0
done
[ "$(python3 -I "$R/tests/ficha_sonda.py" "$R/ficha/ficha" example.com)" -gt 0 ] && ok "ficha consulta domínio público" || falha "ficha consulta domínio público"
checa "ficha limpa URL com usuário e porta" "$(python3 -I "$R/tests/ficha_sonda.py" "$R/ficha/ficha" 'https://U@Example.com:8443/a?b#c')" 8
[ "$(python3 -I "$R/tests/ficha_sonda.py" "$R/ficha/ficha" 8.8.8.8)" -gt 0 ] && ok "ficha consulta IP público" || falha "ficha consulta IP público"

# resumir: saída só do dono (F2)
TMPDIR=$T python3 -I "$R/resumir/resumir" -- sh -c 'echo ola' >/dev/null
D=$(ls -d "$T"/resumir-*); checa "resumir: pasta 700" "$(stat -c %a "$D")" 700
checa "resumir: arquivo 600" "$(stat -c %a "$D"/*.txt)" 600
mkdir -m 755 "$T/antiga"; RESUMIR_DIR=$T/antiga python3 -I "$R/resumir/resumir" -- sh -c 'echo ola' >/dev/null
checa "resumir: pasta que já existia vira 700" "$(stat -c %a "$T/antiga")" 700
checa "resumir preserva código de saída" "$(python3 -I "$R/resumir/resumir" -- sh -c 'exit 3' >/dev/null; echo $?)" 3

# hook (F3): token comum, token em linha que começa com "++", arquivo limpo
H="$R/pre-commit-segredo/pre-commit-segredo"
G="$T/repo"; mkdir "$G"; (cd "$G" && git init -q && git config user.email t@t && git config user.name t)
seg() { printf '%s\n' "$1" > "$G/a.txt"; (cd "$G" && git add a.txt && sh "$H" >/dev/null 2>&1; echo $?); }
FALSO="$(printf 'tok%s' 'en')=ABCDEFGHIJKLMNOPQRSTUV123"  # montado aqui para o próprio hook não barrar este arquivo
checa "hook barra token" "$(seg "$FALSO")" 1
checa "hook barra token em linha '++'" "$(seg "++$FALSO")" 1
checa "hook deixa passar texto limpo" "$(seg 'ola mundo')" 0
(cd "$G" && git reset -q)

# risco (F4): arquivo patológico e byte nulo não derrubam
Q="$T/rep2"; mkdir "$Q"; (cd "$Q" && git init -q && git config user.email t@t && git config user.name t
  python3 -I -c "print('x = ' + '+'.join(['a']*100000))" > g.py; printf 'a=1\0\n' > n.py; echo 'a=1' > ok.py
  git add . && git commit -qm x)
python3 -I "$R/risco/risco" "$Q" > "$T/risco.txt" 2>&1; checa "risco termina com 0" "$?" 0
grep -q 'g.py' "$T/risco.txt" && grep -q 'ok.py' "$T/risco.txt" && ok "risco lista todos os arquivos" || falha "risco lista todos os arquivos"

# olhar (F5): com Chromium falso, nenhum perfil sobra
cat > "$T/chromium" <<'EOS'
#!/bin/sh
for a; do case "$a" in --user-data-dir=*) echo x > "${a#*=}/Cookies" ;; --screenshot=*) echo png > "${a#*=}" ;; esac; done
EOS
chmod +x "$T/chromium"; echo '<p>x</p>' > "$T/p.html"; mkdir "$T/tmpo"
TMPDIR=$T/tmpo CHROME=$T/chromium sh "$R/olhar/olhar" "$T/p.html" "$T/saida" >/dev/null 2>&1
checa "olhar gera 2 prints" "$(ls "$T/saida" | wc -l)" 2
checa "olhar não deixa perfil em TMPDIR" "$(ls "$T/tmpo" | wc -l)" 0

[ "$FALHAS" = 0 ] && echo "TUDO OK" || { echo "$FALHAS falha(s)"; exit 1; }
