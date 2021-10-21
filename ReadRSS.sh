#############################################################
# ReadRSS v. 1.0 by Dawid Labudda
# 
# MIT License
# 
# Copyright (c) 2021 Dawid Labudda
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#############################################################

#!/bin/bash

. config.rc # wczytanie konfiguracji

add_url() {
	echo "${OPTARG}" >> saved.txt # dopisanie adresu do listy
	echo "Zapisano: ${OPTARG}"
	echo_savedrss
}

echo_help() {
	echo "Użycie:"
	echo "  ./ReadRSS [-h/-v/-s]"
	echo "  ./ReadRSS -r {r/raw/s/simple/e/extended} [-l] {limit} [-n/-u] {numer/url}"
	echo "  ./ReadRSS -a {url}"
	echo "  ./ReadRSS -d [-n/-u] {numer/url}"
	echo
	echo "  -h	wyświetla tę oto pomoc."
	echo "  -v	wyświetla numer wersji oraz autora."
	echo "  -s	wyświetla listę zapisanych adresów RSS wraz z ich numerami id."
	echo "  -r	wyświetla wybrany RSS feed w formie surowej (r/raw), prostej (s/simple) lub rozszerzonej (e/extended)."
	echo "  -l	ustawia limit wyświetlanych wiadomości."
	echo "  -n	wybiera RSS feed zapisany pod wybranym numerem na liście."
	echo "  -u	wybiera wpisany adres RSS."
	echo "  -a	dodaje nowy adres RSS do listy zapisanych."
	echo "  -d	usuwa wybrany RSS feed z listy zapisanych."
}

echo_version() {
	echo "Wersja: 1.0"
	echo "Autor: Dawid Labudda"
}

echo_savedrss() {
	if [[ -s saved.txt ]]; then # czy plik ma zawartość
		echo "Zapisane linki:"
		i=1
		while read line; do
			echo "$i. $line"
			i=$(( $i + 1 ))
		done <<<$(cat saved.txt)
	else
		echo "Brak zapisanych linków."
		exit
	fi
}

get_url_at_number() {
	if [[ -s saved.txt ]]; then # czy plik ma zawartość
		url=''
		i=1
		while read line; do
			if [[ "$i" = "$number" ]]; then # wybrany adres
				url=$line
			fi
			i=$(( $i + 1 ))
		done <<<$(cat saved.txt)
		if [ -z "$url" ]; then # czy adres jest pusty
			echo "Nie znaleziono wybranego numeru."
			exit
		fi
	else
		echo "Brak zapisanych linków."
		exit
	fi
}

delete_url() {
	>tmp/url.tmp
	while read line; do
		if ! [[ "$line" = "$url" ]]; then # pominięcie usuwanego adresu
			echo "$line" >> tmp/url.tmp
		fi
	done <<<$(cat saved.txt)
	cat tmp/url.tmp > saved.txt
	rm tmp/url.tmp # usnunięcie pliku tymczasowego
	echo "Usunięto: $url"
	echo_savedrss
}

get_raw_rss() {
	curl -A "$agent" "$url" > tmp/raw.tmp # pobranie pliku xml
}

get_simple_rss() {
	get_raw_rss
	>tmp/simple.tmp
	inside='false'
	insidedesc='false'
	while read line; do
		if [[ "$inside" == 'true' ]]; then # środek artykułu
			if [[ "$line" == *"</${itemtag}>"* ]]; then # koniec artykułu
				inside='false'
			else
				if [[ "$line" == *"<${titletag}>"* ]]; then # tytuł
					echo $line |
					sed $sedtitlepattern1 |
					sed $sedtitlepattern2 |
					sed $sedpattern1 |
					sed $sedpattern2 >> tmp/simple.tmp
				elif [[ "$line" == *"<${descriptiontag}>"* ]]; then # opis
					if [[ "$line" == *"</${descriptiontag}>"* ]]; then # w jednej lini
						echo $line |
						sed $seddescriptionpattern1 |
						sed $seddescriptionpattern2 |
						sed $sedpattern1 |
						sed $sedpattern2 |
						sed $sedpattern3 >> tmp/simple.tmp
					else # w kilku liniach
						insidedesc='true'
					fi
				elif [[ "$insidedesc" == 'true' ]]; then # środek opisu
					echo $line |
					sed $sedpattern1 |
					sed $sedpattern2 |
					sed $sedpattern3 >> tmp/simple.tmp
					insidedesc='false'
				fi
			fi
		else
			if [[ "$line" == *"<${itemtag}>"* ]]; then # początek artykułu
				inside='true'
			fi
		fi
	done <<<$(cat tmp/raw.tmp)
	rm tmp/raw.tmp # usnunięcie pliku tymczasowego
}

articles=0 # liczba wyświetlonych artykułów
articleno=0 # numer wyświetlonego artykułu

extended_menu() {
	echo "Wybierz operacje:"
	echo "liczba) otwórz wybrany artykuł"
	echo "n) otwórz następny artykuł"
	echo "p) otwórz poprzedni artykuł"
	echo "*) zakończ"
	read choice
	if [[ $choice =~ $reliczba ]]; then # czy liczba
		articleno=$choice
		read_extended_article
	elif [[ "$choice" = "n" ]]; then # następny
		articleno=$(( $articleno + 1 ))
		if [ "$articleno" -gt "$articles" ]; then # przewiń na początek
			articleno=1
		fi
		read_extended_article
	elif [[ "$choice" = "p" ]]; then # poprzedni
		articleno=$(( $articleno - 1 ))
		if [ "$articleno" -lt 1 ]; then # przewiń na koniec
			articleno=$articles
		fi
		read_extended_article
	else #zakończ
		rm tmp/simple.tmp # usnunięcie pliku tymczasowego
		exit
	fi
}

read_extended_article() {
	if [[ "$articleno" -lt 1 || "$articleno" -gt "$articles" ]]; then
		echo "Nie ma artykułu o takim numerze!"
		echo
	else
		i=1 # numer lini
		no=1 # numer artykułu
		while read line; do
			if (( $i % 2 == 0 )); then # linie parzyste
				if (( $no == $articleno )); then # opis wybranego artykułu
					echo "$line"
					echo
					break
				fi
				no=$(( $no + 1 ))
			elif (( $no == $articleno )); then # tytuł wybranego artykułu
				echo
				echo "$no. $line"
				echo
			fi
			i=$(( $i + 1 ))
		done <<<$(cat tmp/simple.tmp)
	fi
	extended_menu
}

read_raw() {
	get_raw_rss
	echo "Pobrany plik:"
	echo
	cat tmp/raw.tmp
	echo
	echo
	rm tmp/raw.tmp # usnunięcie pliku tymczasowego
}

read_simple() {
	get_simple_rss
	echo "Artykuły w formie prostej:"
	echo
	i=1 # numer lini
	while read line; do
		echo "$line"
		echo
		if (( $i % 2 == 0 )); then # linie parzyste
			echo
			if [[ -v limit ]]; then # czy ustawiono limit
				if (( $(( $i / 2 )) == $limit )); then # ostatni artykuł
					break
				fi
			fi
		fi
		i=$(( $i + 1 ))
	done <<<$(cat tmp/simple.tmp)
	rm tmp/simple.tmp # usnunięcie pliku tymczasowego
}

read_extended() {
	get_simple_rss
	echo "Artykuły w formie rozszerzonej:"
	echo
	i=1 # numer lini
	no=1 # numer artykułu
	while read line; do
		if (( $i % 2 == 0 )); then # linie parzyste - tytuły
			if [[ -v limit ]]; then # czy ustawiono limit
				if (( $no == $limit )); then # ostatni artykuł
					break
				fi
			fi
			no=$(( $no + 1 ))
		else # linie nieparzyste - opisy
			articles=$no # aktualizacja liczby artykułów
			echo "$no. $line"
		fi
		i=$(( $i + 1 ))
	done <<<$(cat tmp/simple.tmp)
	echo
	extended_menu
}

# obsługa poleceń
while getopts 'a:dhl:n:r:su:v' flag; do
	case "${flag}" in
		a) add_url # dodawanie adresu
			exit ;;
		d) del='true' ;; # usuwanie adresu
		h) echo_help 
			exit ;;
		l) limit="${OPTARG}" ;; # ustawianie limitu
		n) number="${OPTARG}" ;; # wybranie numeru
		r) readmode="${OPTARG}" ;; # wybranie trybu wyświetlania
		s) echo_savedrss # wyświetlenie listy zapisanych adresów
			exit ;;
		u) url="${OPTARG}" ;; # wybranie adresu
		v) echo_version # wyświetlenie informacji o wersji i autorze
			exit ;;
		*) echo_help # wyświetlenie pomocy
			exit ;;
	esac
done

if [[ -v limit ]]; then # czy ustawiono limit
	if ! [[ $limit =~ $reliczba ]]; then # czy liczba
		echo "Limit musi być liczbą!"
		exit
	elif (( $limit == 0 )); then
		echo "Limit musi być większy od 0!"
		exit
	fi
fi
if [[ -v number ]]; then # czy wybrano numer
	if ! [[ $number =~ $reliczba ]]; then # czy liczba
		echo "Numer musi być liczbą!"
		exit
	else # zamiana numeru na adres
		get_url_at_number
	fi
fi

if [ "$del" = 'true' ]; then # usuwanie
	if [[ -v url ]]; then # czy istnieje adres do usunięcia
		delete_url
	else
		echo_help
	fi
	exit
fi

if [[ -v readmode ]]; then # wyświetlanie
	if [[ -v url ]]; then # czy istnieje adres
		case "${readmode}" in # tryby wyświetlania
			r|raw) read_raw ;; # surowy
			s|simple) read_simple ;; # prosty
			e|extended) read_extended ;; # rozszerzony
			*) echo_help ;;
		esac
	else
		echo "Należy podać adres lub numer zapisanego!"
	fi
	exit
fi
