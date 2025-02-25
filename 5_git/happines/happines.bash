#!/bin/bash

generate(){
python -c "import random;print(''.join(random.choice('"${2}"') for _ in range("${1}")), end='')"
}

generate_content(){
generate ${1} "АПОЖ" 
}

generate_dot(){
generate ${1} "." 
}

gitrebase(){
FEATURE_BRANCH=${1}
git checkout master
git checkout ${FEATURE_BRANCH}
git rebase master


if [ $2 ]; then
START=$2
END=$3
FILE=`git status | grep modified | awk '{print $3}'`
sed -i '/<<<<<<.*/d' ${FILE}
sed -i '/======.*/d' ${FILE}
sed -i '/>>>>>>>.*/d' ${FILE}
sed -i '/^'${START}'$/,/^'${END}'$/d' main.happines

git add .
git commit -a -m "${FEATURE_BRANCH}: add string $END"
git rebase --continue 
fi

git checkout master
git merge ${FEATURE_BRANCH} --no-ff -m "merge feature '${FEATURE_BRANCH}'"
git branch -D ${FEATURE_BRANCH}
}


gitmerge(){
FEATURE_BRANCH=${1}
git checkout "${FEATURE_BRANCH}"
git merge --no-ff master -m "Merge master into ${FEATURE_BRANCH}"


if [ $2 ]; then
START=1
END="${2}"
SHIFT="${3}"
echo $SHIFT
FILE=`git status | grep modified | awk '{print $3}'`
sed -i '/<<<<<<.*/d' ${FILE}
sed -i '/======.*/d' ${FILE}
sed -i '/>>>>>>>.*/d' ${FILE}
sed -i '/^'${START}'$/,/^'${END}'$/d' ${FILE}

head $FILE -n $((8 + ${END} + ${SHIFT})) | tail -n ${END} > /tmp/master_head
head $FILE -n $((8 + ${SHIFT})) > /tmp/merge_buffer
cat $FILE  | tail -n $((67 - $((${END} + 8 + ${SHIFT} - 1)) )) > /tmp/master_tail

cat /tmp/master_head /tmp/merge_buffer /tmp/master_tail > ${FILE}


git add .
GIT_EDITOR=/bin/true git merge --continue
fi

git checkout master
git merge ${FEATURE_BRANCH} --no-ff -m "merge feature '${FEATURE_BRANCH}'"
git branch -D ${FEATURE_BRANCH}
}


PROJECT_DIR="./happines_project/"
FILE="./main.happines"

mkdir -p "${PROJECT_DIR}"
pushd "${PROJECT_DIR}"
rm -f "./${FILE}"
rm -rf ./.git

git init .

git config user.name "Mona Lisa"
git config user.email "mona.lisa@louvre.fr"
printf " " > ${FILE}
seq 67 | while read STRING_ID;do sed -i "${STRING_ID}i ${STRING_ID}" ${FILE};done

git add .
git commit -m 'Init happines'

git checkout -b 'happines-1'

sleep 1
#C #1
sed -i -e "1s/.*/`generate_dot 12`/" "${FILE}"
sed -i -e "2s/.*/`generate_content 12`/" "${FILE}"
git commit -a -m 'happines-1: add string 2'
sed -i -e "3s/.*/`generate_content 12`/" "${FILE}"
git commit -a -m 'happines-1: add string 3'
sed -i -e "4s/.*/`generate_content 4; generate_dot 8`/" "${FILE}"
git commit -a -m 'happines-1: add string 4'
sed -i -e "5s/.*/`generate_content 4; generate_dot 8`/" "${FILE}"
git commit -a -m 'happines-1: add string 5'
sed -i -e "6s/.*/`generate_content 4; generate_dot 8 `/" "${FILE}"
git commit -a -m 'happines-1: add string 6'
sed -i -e "7s/.*/`generate_content 12`/" "${FILE}"
git commit -a -m 'happines-1: add string 7'
sed -i -e "8s/.*/`generate_content 12`/" "${FILE}"
git commit -a -m 'happines-1: add string 8'
git config user.name "Apollo Belvedere"
git config user.email "apollo.belvedere@pavlovskmuseum.ru"
sed -i -e "9s/.*/`generate_dot 12 `/" "${FILE}"
git commit -a -m 'refactor'

sleep 1
#4
git config user.name "Mona Lisa Prado"
git config user.email "mona.lisa.prado@museodelprado.es"
git checkout master
git checkout -b 'happines-3'
sed -i -e "10s/.*/`generate_content 4; generate_dot 3; generate_content 5`/" "${FILE}"
git commit -a -m 'happines-3: add string 10'
sed -i -e "11s/.*/`generate_content 4; generate_dot 3; generate_content 5`/" "${FILE}"
git commit -a -m 'happines-3: add string 11'
sed -i -e "12s/.*/`generate_content 4; generate_dot 3; generate_content 5`/" "${FILE}"
git commit -a -m 'happines-3: add string 12'
sed -i -e "13s/.*/`generate_content 12`/" "${FILE}"
git commit -a -m 'happines-3: add string 13'
sed -i -e "14s/.*/`generate_dot 7; generate_content 5`/" "${FILE}"
git commit -a -m 'happines-3: add string 14'
sed -i -e "15s/.*/`generate_dot 7; generate_content 5`/" "${FILE}"
git commit -a -m 'happines-3: add string 15'
sed -i -e "16s/.*/`generate_dot 7; generate_content 5`/" "${FILE}"
git commit -a -m 'happines-3: add string 16'
sed -i -e "17s/.*/`generate_dot 12 `/" "${FILE}"
git commit -a -m 'happines-3: add string 17. Review, tested and approved'

sleep 1
#A
git checkout master
git config user.name "Elizabeth Conyngham"
git config user.email "lady.elizabeth.conyngham@gulbenkian.pt"
git checkout -b 'happines-4'
sed -i -e "18s/.*/`generate_content 12`/" "${FILE}"
git commit -a -m 'happines-4: add string 18'
sed -i -e "19s/.*/`generate_content 4; generate_dot 3; generate_content 5`/" "${FILE}"
git commit -a -m 'happines-4: add string 19'
sed -i -e "20s/.*/`generate_content 4; generate_dot 3; generate_content 5`/" "${FILE}"
git commit -a -m 'happines-4: add string 20'
sed -i -e "21s/.*/`generate_content 12`/" "${FILE}"
git commit -a -m 'happines-4: add string 21'
sed -i -e "22s/.*/`generate_content 4; generate_dot 3; generate_content 5`/" "${FILE}"
git commit -a -m 'happines-4: add string 22'
sed -i -e "23s/.*/`generate_content 4; generate_dot 3; generate_content 5`/" "${FILE}"
git commit -a -m 'happines-4: add string 23'
sed -i -e "24s/.*/`generate_content 4; generate_dot 3; generate_content 5`/" "${FILE}"
git commit -a -m 'happines-4: add string 24'
sed -i -e "25s/.*/`generate_dot 12 `/" "${FILE}"
git commit -a -m 'happines-4: add string 25. Review, tested and approved'

sleep 1
#C #2
git checkout master
git checkout -b 'happines-1_the_same_code'
git config user.name "Mona Lisa"
git config user.email "mona.lisa@louvre.fr"
sed -i -e "26s/.*/`generate_content 12`/" "${FILE}"
sed -i -e "27s/.*/`generate_content 12`/" "${FILE}"
sed -i -e "28s/.*/`generate_content 4; generate_dot 8`/" "${FILE}"
sed -i -e "29s/.*/`generate_content 4; generate_dot 8`/" "${FILE}"
sed -i -e "30s/.*/`generate_content 4; generate_dot 8`/" "${FILE}"
sed -i -e "31s/.*/`generate_content 12`/" "${FILE}"
sed -i -e "32s/.*/`generate_content 12`/" "${FILE}"
git commit -a -m 'happines-1: add another "C" simple based on previous expertise'

sleep 1
#Belvedere
git config user.name "Apollo Belvedere"
git config user.email "apollo.belvedere@pavlovskmuseum.ru"
sed -i -e "33s/.*/`generate_dot 12 `/" "${FILE}"
git commit -a -m 'fix'


sleep 1
#T
git checkout master
git config user.name "Venus De Milo"
git config user.email "la.venus.de.milo@louvre.fr"
git checkout -b 'happines-5'
sed -i -e "34s/.*/`generate_content 12`/" "${FILE}"
git commit -a -m 'happines-5: add string 34'
sed -i -e "35s/.*/`generate_content 12`/" "${FILE}"
git commit -a -m 'happines-5: add string 35'
sed -i -e "36s/.*/`generate_dot 4; generate_content 4; generate_dot 4`/" "${FILE}"
git commit -a -m 'happines-5: add string 36'
sed -i -e "37s/.*/`generate_dot 4; generate_content 4; generate_dot 4`/" "${FILE}"
git commit -a -m 'happines-5: add string 37'
sed -i -e "38s/.*/`generate_dot 4; generate_content 4; generate_dot 4`/" "${FILE}"
git commit -a -m 'happines-5: add string 38'
sed -i -e "39s/.*/`generate_dot 4; generate_content 4; generate_dot 4`/" "${FILE}"
git commit -a -m 'happines-5: add string 39'
sed -i -e "40s/.*/`generate_dot 4; generate_content 4; generate_dot 4`/" "${FILE}"
git commit -a -m 'happines-5: add string 40'
sed -i -e "41s/.*/`generate_dot 12 `/" "${FILE}"
git commit -a -m 'happines-5: add string 41. Review, tested and approved'

sleep 1
#Ь
git checkout master
git config user.name "Diana"
git config user.email "diana@gulbenkian.pt"
git checkout -b 'happines-6'
sed -i -e "42s/.*/`generate_content 5; generate_dot 7`/" "${FILE}"
git commit -a -m 'happines-6: add string 42'
sed -i -e "43s/.*/`generate_content 5; generate_dot 7`/" "${FILE}"
git commit -a -m 'happines-6: add string 43'
sed -i -e "44s/.*/`generate_content 5; generate_dot 7`/" "${FILE}"
git commit -a -m 'happines-6: add string 44'
sed -i -e "45s/.*/`generate_content 12 `/" "${FILE}"
git commit -a -m 'happines-6: add string 45'
sed -i -e "46s/.*/`generate_content 4; generate_dot 3; generate_content 5`/" "${FILE}"
git commit -a -m 'happines-6: add string 46'
sed -i -e "47s/.*/`generate_content 4; generate_dot 3; generate_content 5`/" "${FILE}"
git commit -a -m 'happines-6: add string 47'
sed -i -e "48s/.*/`generate_content 12`/" "${FILE}"
git commit -a -m 'happines-6: add string 48'
sed -i -e "49s/.*/`generate_dot 12 `/" "${FILE}"
git commit -a -m 'happines-6: add string 49. Review, tested and approved'


sleep 1
#E
git checkout master
git config user.name "Woman In Blue"
git config user.email "woman.in.blue@﻿﻿hermitagemuseum.org"
git checkout -b 'happines-7'
sed -i -e "50s/.*/`generate_content 12`/" "${FILE}"
git commit -a -m 'happines-7: add string 50'
sed -i -e "51s/.*/`generate_content 12`/" "${FILE}"
git commit -a -m 'happines-7: add string 51'
sed -i -e "52s/.*/`generate_content 5; generate_dot 7`/" "${FILE}"
git commit -a -m 'happines-7: add string 52'
sed -i -e "53s/.*/`generate_content 12`/" "${FILE}"
git commit -a -m 'happines-7: add string 53'
sed -i -e "54s/.*/`generate_content 5; generate_dot 7 `/" "${FILE}"
git commit -a -m 'happines-7: add string 54'
sed -i -e "55s/.*/`generate_content 12`/" "${FILE}"
git commit -a -m 'happines-7: add string 55'
sed -i -e "56s/.*/`generate_content 12`/" "${FILE}"
git commit -a -m 'happines-7: add string 56'
sed -i -e "57s/.*/`generate_dot 12 `/" "${FILE}"
git commit -a -m 'happines-7: add string 57. Review, tested and approved'


sleep 1
#!
git checkout master
git config user.name "Mona Lisa"
git config user.email "mona.lisa@louvre.fr"
git checkout -b 'happines-final-before-mighty-release'
sed -i -e "58s/.*/`generate_dot 4; generate_content 4; generate_dot 4`/" "${FILE}"
git commit -a -m 'happines-final: add string 58. Valuable comment with tech info'
git config user.name "Mona Lisa Prado"
git config user.email "mona.lisa.prado@museodelprado.es"
sed -i -e "59s/.*/`generate_dot 4; generate_content 4; generate_dot 4`/" "${FILE}"
git commit -a -m 'happines-final: add string 59. Valuable comment with tech info'
git config user.name "Elizabeth Conyngham"
git config user.email "lady.elizabeth.conyngham@gulbenkian.pt"
sed -i -e "60s/.*/`generate_dot 4; generate_content 4; generate_dot 4`/" "${FILE}"
git commit -a -m 'happines-final: add string 60. Valuable comment with tech info'
git config user.name "Venus De Milo"
git config user.email "la.venus.de.milo@louvre.fr"
sed -i -e "61s/.*/`generate_dot 4; generate_content 4; generate_dot 4`/" "${FILE}"
git commit -a -m 'happines-final: add string 61. Valuable comment with tech info'
git config user.name "Diana"
git config user.email "diana@gulbenkian.pt"
sed -i -e "62s/.*/`generate_dot 4; generate_content 4; generate_dot 4`/" "${FILE}"
git commit -a -m 'happines-final: add string 62. Valuable comment with tech info'
git config user.name "Woman In Blue"
git config user.email "woman.in.blue@﻿﻿hermitagemuseum.org"
sed -i -e "63s/.*/`generate_dot 4; generate_content 4; generate_dot 4`/" "${FILE}"
git commit -a -m 'happines-final: add string 63. Valuable comment with tech info'
git config user.name "Mona Lisa"
git config user.email "mona.lisa@louvre.fr"
sed -i -e "65s/.*/`generate_dot 4; generate_content 4; generate_dot 4`/" "${FILE}"
git commit -a -m 'happines-final: add string 65. Valuable comment with tech info'
git config user.name "Apollo Belvedere"
git config user.email "apollo.belvedere@pavlovskmuseum.ru"
sed -i -e "64s/.*/`generate_dot 12 `/" "${FILE}"
git commit -a -m 'refactor'
git config user.name "Diana"
git config user.email "diana@gulbenkian.pt"
sed -i -e "66s/.*/`generate_dot 4; generate_content 4; generate_dot 4`/" "${FILE}"
git commit -a -m 'happines-final: add string 66. Valuable comment with tech info'
git config user.name "Apollo Belvedere"
git config user.email "apollo.belvedere@pavlovskmuseum.ru"
sed -i -e "67s/.*/`generate_dot 12 `/" "${FILE}"
git commit -a -m 'happines fixed'

rm -rf ../merge_rebase_happines_project
rm -rf ../merge_happines_project
rm -rf ../merge_with_squash_happines_project

cp -r ../happines_project ../merge_rebase_happines_project
cp -r ../happines_project ../merge_happines_project
cp -r ../happines_project ../merge_with_squash_happines_project

pushd ../merge_rebase_happines_project
gitrebase happines-1
gitrebase happines-3 10 9
gitrebase happines-4 18 17
gitrebase happines-1_the_same_code 26 25
gitrebase happines-5 34 33
gitrebase happines-6 42 41
gitrebase happines-7 50 49
gitrebase happines-final-before-mighty-release 58 57

pushd ../merge_happines_project
gitmerge happines-1
gitmerge happines-3 9 0
gitmerge happines-4 17 0
gitmerge happines-1_the_same_code 25 0
gitmerge happines-5 33 0
gitmerge happines-6 41 0
gitmerge happines-7 49 0
gitmerge happines-final-before-mighty-release 57 2
