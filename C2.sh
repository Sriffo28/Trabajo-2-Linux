# Paso 1: Descarga del archivo
curl -sL "https://www.dropbox.com/scl/fi/d4ror2587jug3h4n6howo/mcdonalds_menu.zip?rlkey=s9qe77iqsvko12xae163aqrab&e=1&st=u1g2d7ms&dl=0" -o mcdonalds_menu.zip

# Paso 2: Descomprimir el archivo
unzip mcdonalds_menu.zip

# Paso 3: Valores unicos en la columa "Category"
awk -F',' '{print $1}' mcdonalds_menu.csv | sort | uniq > categories.txt

# Paso 4: Extraer gramos columna "Serving Size" y eliminar aquellos solo en Oz
< mcdonalds_menu.csv csvcut -c "Serving Size" | nl -v 0 -w 2| grep 'g' | cut -d '(' -f 2 | tr 'g)' ' ' | header -d > values.txt
< mcdonalds_menu.csv csvcut -c "Serving Size" | nl -v 0 | awk '{print $1}' | header -d > index.txt

# Paso 5: Codigo R para sanitizar base de datos
./script1.R

# Paso 6: Clasificacion con Vowpal Wabbit
csv2vw mcdonalds_menu_2.csv --label Category |
shuf |
split -d -n r/5 - wine-part-
wc -l wine-part-*

mv wine-part-00 wine-test.vw
cat wine-part-* > wine-train.vw
rm wine-part-*
wc -l wine-*.vw

vw \
--oaa 7 \
--data wine-train.vw \
--final_regressor wine.model \
--passes 10 \
--cache_file wine.cache \
--nn 3 \
--quadratic :: \
--l2 0.000005 \
--bit_precision 25

vw \
--data wine-test.vw \
--initial_regressor wine.model \
--testonly \
--predictions predictions \
--quiet
bat predictions | trim

paste -d, predictions <(cut -d '|' -f 1 wine-test.vw) |
tee results.csv |
awk -F, '{E+=$1==$2} END {print "Bien Clasificados: " E/NR}' |
cowsay

# Paso 7: Clasificacion con SciKit-Learn
cat mcdonalds_menu_2.csv |
body shuf |
nl -s, -w1 -v0 |
sed '1s/0,/id,/' |
tee wine-balanced.csv | csvlook

mkdir -p {train,test}
HEADER="$(< wine-balanced.csv header)"
< wine-balanced.csv header -d | shuf | split -d -n r/5 - wine-part-
wc -l wine-part-*
cat wine-part-00 | header -a $HEADER > test/features.csv && rm wine-part-00
cat wine-part-* | header -a $HEADER > train/features.csv && rm wine-part-*
wc -l t*/features.csv

bat classify.cfg
skll -l classify.cfg 2>/dev/null

cat output/wine_summary.tsv |
  csvsql --query "SELECT learner_name, accuracy FROM stdin ORDER BY accuracy DESC" |
  csvlook -I

jq -r '.[] | "\(.learner_name):\n\(.result_table)\n"' output/*.json # matrices de confusion


# Paso 7: Clasificacion con R
./script2.R
