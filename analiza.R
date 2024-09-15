library(RPostgres)
library(DBI)
library(dplyr)
library(ggplot2)

library(readxl)


# Łączenie z bazą
con <- dbConnect(RPostgres::Postgres(),
                 dbname = "zdrowie_psychiczne",
                 host = "localhost",
                 port = 5432,
                 user = "postgres",
                 password = "admin")


query_ChorobaAbsencjeZwolnienia <- "SELECT chaz.ICD10_kod, chaz.ICD10, chaz.dni_absencji, chaz.liczba_zaswiadczen, c.rok, w.nazwa
                                    FROM ChorobaAbsencjeZwolnienia chaz
                                    JOIN Fakt_ChorobaAbsencjeZwolnienia f_chaz ON chaz.id_absencje = f_chaz.id_absencje
                                    JOIN ZdrowiePsychiczne zp ON zp.id_fakt = f_chaz.id_fakt
                                    JOIN Czas c ON zp.id_czas = c.id_czas
                                    JOIN Wojewodztwo w ON zp.id_wojewodztwo = w.id_wojewodztwo;"
ChorobaAbsencjeZwolnienia <- dbGetQuery(con, query_ChorobaAbsencjeZwolnienia)

query_SzpitalLeczeni <- "SELECT sl.liczba_leczonych, sl.liczba_szpitali_psychiatrycznych, c.rok, w.nazwa
                         FROM SzpitalLeczeni sl
                         JOIN ZdrowiePsychiczne zp ON zp.id_szpitalLeczeni = sl.id_szpitalLeczeni
                         JOIN Czas c ON zp.id_czas = c.id_czas
                         JOIN Wojewodztwo w ON zp.id_wojewodztwo = w.id_wojewodztwo;"
SzpitalLeczeni <- dbGetQuery(con, query_SzpitalLeczeni)

query_SzpitalLozka <- "SELECT sl.szpital_typ, sl.liczba_lozek, sl.ludnosc_na_lozko, c.rok, w.nazwa
                       FROM SzpitalLozka sl
                       JOIN Fakt_SzpitalLozka f_sl ON sl.id_szpitalLozka = f_sl.id_szpitalLozka
                       JOIN ZdrowiePsychiczne zp ON zp.id_fakt = f_sl.id_fakt
                       JOIN Czas c ON zp.id_czas = c.id_czas
                       JOIN Wojewodztwo w ON zp.id_wojewodztwo = w.id_wojewodztwo;"
SzpitalLozka <- dbGetQuery(con, query_SzpitalLozka)

query_ZgonPrzyczyna <- "SELECT zprz.zaburzenia_psychiczne, zprz.samobojstwo, c.rok, w.nazwa
                        FROM ZgonPrzyczyna zprz
                        JOIN ZdrowiePsychiczne zp ON zp.id_zgon = zprz.id_zgon
                        JOIN Czas c ON zp.id_czas = c.id_czas
                        JOIN Wojewodztwo w ON zp.id_wojewodztwo = w.id_wojewodztwo;"
ZgonPrzyczyna <- dbGetQuery(con, query_ZgonPrzyczyna)

# Niezrealizowane dane w hurtowni (byli mocnymi kandydatami, ale ostatecznie wyeliminowanymi), chociaż ciekawe
# Doszłyśmy do wniosku, że jeśli zostały mimo wszysko przetworzone, to czemu by nie skorzystać
PoradyHospitalizacje <- read_excel("PoradyHospitalizacje.xlsx")
ChorobaPacjenciPobyt <- read_excel("ChorobaPacjenciPobyt.xlsx")

colnames(ChorobaAbsencjeZwolnienia)
colnames(SzpitalLeczeni)
colnames(SzpitalLozka)
colnames(ZgonPrzyczyna)

colnames(PoradyHospitalizacje)
colnames(ChorobaPacjenciPobyt)

# Zależność rodzaju schorzenia psychicznego od miejsca zamieszkania
# Grupowanie danych i obliczanie procentów (poprawiony kod)
dane_procentowe <- ChorobaAbsencjeZwolnienia %>%
  group_by(nazwa, icd10) %>%
  summarise(liczba_pacjentow = sum(dni_absencji)) %>%
  group_by(nazwa) %>%
  mutate(procent = liczba_pacjentow / sum(liczba_pacjentow) * 100) %>%
  arrange(desc(procent))

# Tworzenie wykresu
ggplot(dane_procentowe, aes(x = factor(nazwa, levels = nazwa), y = procent, fill = icd10)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(title = "Rodzaj schorzenia psychicznego a województwo", x = "Województwo", y = "Procent pacjentów", fill = "ICD10") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))


# Liczba szpitali psychiatrycznych a liczba zgonów
ggplot(SzpitalLeczeni, aes(x = liczba_szpitali_psychiatrycznych, y = ZgonPrzyczyna$zgony_zaburzenia_psychiczne)) +
  geom_bar() +
  labs(title = "Liczba szpitali psychiatrycznych a liczba zgonów", x = "Liczba szpitali psychiatrycznych", y = "Liczba zgonów z powodu zaburzeń psychicznych")

# laczenie danych
dane_polaczone <- merge(SzpitalLeczeni, ZgonPrzyczyna, by = c("nazwa", "rok"))

# grupowanie+suma
dane_grupowane <- dane_polaczone %>%
  group_by(liczba_szpitali_psychiatrycznych) %>%
  summarise(laczna_liczba_zgonow = sum(zaburzenia_psychiczne))

# wykres
ggplot(dane_grupowane, aes(x = liczba_szpitali_psychiatrycznych, y = laczna_liczba_zgonow)) +
  geom_bar(stat = "identity", fill = "skyblue") +
  labs(title = "Liczba szpitali psychiatrycznych a liczba zgonów", 
       x = "Liczba szpitali psychiatrycznych", 
       y = "Liczba zgonów z powodu zaburzeń psychicznych") +
  theme_minimal()



# Ilość samobójstw a ilość zdiagnozowanych, poddanych leczeniu osób
ggplot(SzpitalLeczeni, aes(x = liczba_leczonych, y = ZgonPrzyczyna$samobojstwo)) +
  geom_point() +
  labs(title = "Ilość samobójstw a ilość zdiagnozowanych, poddanych leczeniu osób", x = "Liczba leczonych", y = "Liczba samobójstw")

# Typ szpitala a liczba poddanych leczeniu osób
ggplot(SzpitalLozka, aes(x = szpital_typ, y = liczba_lozek)) +
  geom_bar(stat = "identity") +
  labs(title = "Typ szpitala a liczba łóżek", x = "Typ szpitala", y = "Liczba łóżek")+
  scale_y_continuous(labels = function(x) format(x, big.mark = " ", scientific = FALSE))

# Rodzaj schorzenia a liczba zaświadczeń
ggplot(ChorobaAbsencjeZwolnienia, aes(x = icd10, y = liczba_zaswiadczen)) +
  geom_bar(stat = "identity",fill = "skyblue") +
  labs(title = "Rodzaj schorzenia a liczba zaświadczeń", x = "Rodzaj schorzenia (ICD10)", y = "Liczba zaświadczeń") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))+
  scale_y_continuous(labels = function(x) format(x, big.mark = " ", scientific = FALSE))

# Wojewodztwo z największą liczbą zgonów
library(forcats)

ZgonPrzyczyna_clean <- ZgonPrzyczyna %>%
  distinct() %>%
  arrange(desc(zaburzenia_psychiczne))  # Sortowanie malejąco wg liczby zgonów

ggplot(ZgonPrzyczyna_clean, aes(x = fct_inorder(nazwa), y = zaburzenia_psychiczne)) +
  geom_bar(stat = "identity", fill = "skyblue") +
  labs(title = "Liczba zgonów w poszczególnych województwach",
       x = "Województwo",
       y = "Liczba zgonów z powodu zaburzeń psychicznych") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))



# Wzrost liczby osób z zaburzeniami psychicznymi podczas pandemii
ggplot(PoradyHospitalizacje, aes(x = as.factor(rok), y = liczba_hospitalizacji)) +
  geom_bar(stat = "identity", fill = "skyblue") +  # Wykres słupkowy
  labs(title = "Wzrost liczby osób z zaburzeniami psychicznymi podczas pandemii", x = "Rok", y = "Liczba hospitalizacji")+
  scale_y_continuous(labels = function(x) format(x, big.mark = " ", scientific = FALSE))


# Zależność liczby łóżek w szpitalu od liczby samobójstw
#ggplot(SzpitalLozka, aes(x = ludnosc_na_lozko, y = ZgonPrzyczyna$samobojstwo)) +
  #geom_point() +
  #labs(title = "Liczba łóżek w szpitalu a liczba samobójstw", x = "Liczba ludności na jedno łóżko", y = "Liczba samobójstw")


# Wpływ płci na liczbę zachorowań
ggplot(PoradyHospitalizacje, aes(x = plec, y = liczba_hospitalizacji)) +
  geom_bar(stat = "identity") +
  labs(title = "Wpływ płci na liczbę zachorowań", x = "Płeć", y = "Liczba hospitalizacji") +
  scale_y_continuous(labels = function(x) format(x, big.mark = " ", scientific = FALSE))


# Zależność wieku od liczby osób cierpiących na zaburzenia psychiczne
ggplot(PoradyHospitalizacje, aes(x = wiek_min, y = liczba_hospitalizacji)) +
  geom_point() +
  labs(title = "Zależność wieku od liczby osób cierpiących na zaburzenia psychiczne", x = "Minimalny wiek", y = "Liczba hospitalizacji")


# Rozłączenie z bazą
dbDisconnect(con)
