## ReadRSS

# Opis funkcjonalności:
Zaprezentowanie użytkownikowi informacji z wybranych przez niego lub
predefiniowanych list RSS feed w formie:
- surowej - surowy plik xml,
- prostej - wyświetlanie tekstu nagłówków i opisów wiadomości,
- rozbudowanej - wyświetlanie nagłówków wiadomości z możliwością
odczytania ich opisu i nawigacją pomiędzy nimi.
Możliwość ustalenia limitu wyświetlanych wiadomości.
Możliwość wyświetlenia listy zapisanych linków.
Możliwość dodawania i usuwania linków z listy zapisanych RSS.

# Opis działania:
Uruchomienie skryptu z poziomu terminala z określonym przez parametry
działaniem: wyświetlenia listy linków, dodawania/usuwania zapisanych linków,
wyświetlenia informacji z RSS feed.
Dodawanie polega na dopisaniu nowego własnego linku. Usuwanie polega na
wybraniu numeru lub wpisaniu linku do usunięcia.
Przy wyświetlaniu informacji z RSS feed należy podać w parametrze źródło z
wpisanego linku lub numeru z listy zapisanych oraz formę prezentacji. Można też
podać limit wyświetlanych wiadomości.
Skrypt pobiera plik xml z wybranego linku RSS, a następnie w zależnie od
formy prezentacji przetwarza go i wyświetla w terminalu w postaci czytelnej dla
użytkownika.
W formie rozbudowanej skrypt odczytuje wejście od użytkownika i wykonuje
działania: wyświetlenia wybranej wiadomości, przejścia do następnej/poprzedniej
wiadomości, zakończenia działania skryptu
