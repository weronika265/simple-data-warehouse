CREATE TABLE Czas (
	id_czas SERIAL PRIMARY KEY,
	rok SMALLINT UNIQUE NOT NULL
);

COPY Czas FROM 'D:/PostgreSQL_e/dane/Czas.txt' WITH (DELIMITER ';');

-- --------------------------------------------------------------------

CREATE TABLE Wojewodztwo (
	id_wojewodztwo SERIAL PRIMARY KEY,
	nazwa VARCHAR(20) UNIQUE NOT NULL
);

COPY Wojewodztwo FROM 'D:/PostgreSQL_e/dane/Wojewodztwo.txt' WITH (DELIMITER ';');

-- --------------------------------------------------------------------

CREATE TABLE ZgonPrzyczyna (
	id_zgon SERIAL PRIMARY KEY,
	zaburzenia_psychiczne INT NOT NULL,
	samobojstwo INT NOT NULL
);

COPY ZgonPrzyczyna FROM 'D:/PostgreSQL_e/dane/ZgonPrzyczyna.txt' WITH (DELIMITER ';');

-- --------------------------------------------------------------------

CREATE TABLE SzpitalLeczeni (
	id_szpitalLeczeni SERIAL PRIMARY KEY,
	liczba_leczonych INT NOT NULL,
	liczba_szpitali_psychiatrycznych INT NOT NULL
);

COPY SzpitalLeczeni FROM 'D:/PostgreSQL_e/dane/SzpitalLeczeni.txt' WITH (DELIMITER ';');

-- --------------------------------------------------------------------

CREATE TABLE SzpitalLozka (
	id_szpitalLozka SERIAL PRIMARY KEY,
	szpital_typ VARCHAR(20) NOT NULL,
	liczba_lozek INT NOT NULL,
	ludnosc_na_lozko INT NOT NULL
);

COPY SzpitalLozka FROM 'D:/PostgreSQL_e/dane/SzpitalLozka.txt' WITH (DELIMITER ';');

-- --------------------------------------------------------------------

CREATE TABLE ChorobaAbsencjeZwolnienia (
	id_absencje SERIAL PRIMARY KEY,
	ICD10_KOD VARCHAR(3) NOT NULL,
	ICD10 VARCHAR(100) NOT NULL,
	dni_absencji INT NOT NULL,
	liczba_zaswiadczen INT NOT NULL
);

COPY ChorobaAbsencjeZwolnienia FROM 'D:/PostgreSQL_e/dane/ChorobaAbsencjeZwolnienia.txt' WITH (DELIMITER ';');

-- --------------------------------------------------------------------

CREATE TABLE ZdrowiePsychiczne (
	id_fakt SERIAL PRIMARY KEY,
	id_czas INT NOT NULL,
	id_wojewodztwo INT NOT NULL,
	id_zgon INT NOT NULL,
	id_szpitalLeczeni INT NOT NULL,
	CONSTRAINT fk_id_czas
		FOREIGN KEY(id_czas)
		REFERENCES Czas(id_czas),
	CONSTRAINT fk_id_wojewodztwo
		FOREIGN KEY(id_wojewodztwo)
		REFERENCES Wojewodztwo(id_wojewodztwo),
	CONSTRAINT fk_id_zgon
		FOREIGN KEY(id_zgon)
		REFERENCES ZgonPrzyczyna(id_zgon),
	CONSTRAINT fk_id_szpitalLeczeni
		FOREIGN KEY(id_szpitalLeczeni)
		REFERENCES SzpitalLeczeni(id_szpitalLeczeni)
);

COPY ZdrowiePsychiczne FROM 'D:/PostgreSQL_e/dane/ZdrowiePsychiczne.txt' WITH (DELIMITER ';');

-- --------------------------------------------------------------------

CREATE TABLE Fakt_SzpitalLozka (
	id_fakt INT,
	id_szpitalLozka INT,
	PRIMARY KEY (id_fakt, id_szpitalLozka),
	CONSTRAINT fk_id_fakt
		FOREIGN KEY(id_fakt)
		REFERENCES ZdrowiePsychiczne(id_fakt),
	CONSTRAINT fk_id_szpitalLozka
		FOREIGN KEY(id_szpitalLozka)
		REFERENCES SzpitalLozka(id_szpitalLozka)
);

COPY Fakt_SzpitalLozka FROM 'D:/PostgreSQL_e/dane/Fakt_SzpitalLozka.txt' WITH (DELIMITER ';');

-- --------------------------------------------------------------------

CREATE TABLE Fakt_ChorobaAbsencjeZwolnienia (
	id_fakt INT,
	id_absencje INT,
	PRIMARY KEY (id_fakt, id_absencje),
	CONSTRAINT fk_id_fakt
		FOREIGN KEY(id_fakt)
		REFERENCES ZdrowiePsychiczne(id_fakt),
	CONSTRAINT fk_id_absencje
		FOREIGN KEY(id_absencje)
		REFERENCES ChorobaAbsencjeZwolnienia(id_absencje)
);

COPY Fakt_ChorobaAbsencjeZwolnienia FROM 'D:/PostgreSQL_e/dane/Fakt_ChorobaAbsencjeZwolnienia.txt' WITH (DELIMITER ';');