-- phpMyAdmin SQL Dump
-- version 5.0.4
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Czas generowania: 05 Lut 2021, 18:52
-- Wersja serwera: 8.0.23
-- Wersja PHP: 7.3.22-(to be removed in future macOS)

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Baza danych: `tenis3`
--

DELIMITER $$
--
-- Procedury
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `DodajWynik` (IN `turniej` INT, IN `numer_meczu` INT, IN `wynik` VARCHAR(10))  BEGIN
        UPDATE ATP_MECZ
        SET MECZ_WYNIK = wynik
        WHERE TUR_ID = turniej AND MECZ_NR = numer_meczu;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `GetMecze` (IN `turniej` INT)  BEGIN

SELECT COUNT(MECZ_NR) INTO @counter FROM ATP_MECZ WHERE TUR_ID = turniej;
SET @v4 = 1;


WHILE @v4 < (@counter + 1) DO
      SELECT Z.ZAW_NAZWISKO INTO @zaw1 FROM ATP_ZAWODNIK Z, ATP_MECZ M WHERE M.MECZ_ZAWODNIK1 = Z.ZAW_ID AND M.MECZ_NR = @v4 AND M.TUR_ID = turniej ORDER BY M.MECZ_NR ASC LIMIT 1;
      SELECT Z.ZAW_NAZWISKO INTO @zaw2 FROM ATP_ZAWODNIK Z, ATP_MECZ M WHERE M.MECZ_ZAWODNIK2 = Z.ZAW_ID AND M.MECZ_NR = @v4 AND M.TUR_ID = turniej ORDER BY M.MECZ_NR ASC LIMIT 1;
      SELECT MECZ_RUDNA, MECZ_DATA, MECZ_WYNIK INTO @runda, @data, @wynik FROM ATP_MECZ WHERE MECZ_NR = @v4 AND TUR_ID = turniej;
      SELECT @zaw1 as 'ZAWODNIK1', @zaw2 as 'ZAWODNIK2', @wynik as 'WYNIK', @runda as 'RUNDA', @data as 'DATA';
      SET @v4 = @v4 + 1;
END WHILE;


END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `KolejnaRunda` (IN `turniej` INT)  BEGIN


    IF NOT EXISTS (SELECT * FROM ATP_MECZ M WHERE M.TUR_ID = turniej) THEN

        SELECT Z.ZAS_LICZBA INTO @PLAYERS_NR FROM ATP_ZASADY Z WHERE Z.ZAS_RANGA = (SELECT ZAS_RANGA FROM ATP_TURNIEJ WHERE TUR_ID = turniej);
        SET @runda = RUNDA_FUNC(@PLAYERS_NR);

        SET @V1 = 0;
        WHILE @V1 < @PLAYERS_NR DO
          SELECT RANK() OVER( ORDER BY Z.ZGL_PUNKTY DESC),  Z.ZAW_ID into @rank, @zawodnik FROM ATP_ZGLOSZENIA Z WHERE Z.TUR_ID = turniej AND Z.ZGL_RANK is NULL LIMIT 1;
          UPDATE ATP_ZGLOSZENIA Z SET Z.ZGL_RANK = (@rank + @V1) WHERE Z.ZAW_ID = @zawodnik AND Z.TUR_ID = turniej;

          SET @V1 = @V1 + 1;
        END WHILE;
        COMMIT;

        SET @V2 = 0;
        SET @nr = 1;
        WHILE @V2 < (@PLAYERS_NR / 4) DO
          SELECT Z.ZAW_ID INTO @zaw1 FROM ATP_ZGLOSZENIA Z WHERE Z.ZGL_RANK = @V2 + 1 AND Z.TUR_ID = turniej;
          SELECT Z.ZAW_ID INTO @zaw2 FROM ATP_ZGLOSZENIA Z WHERE Z.ZAW_ID NOT IN (SELECT M.MECZ_ZAWODNIK2 FROM ATP_MECZ M WHERE M.TUR_ID = turniej) AND Z.TUR_ID = turniej AND Z.ZGL_RANK > (@PLAYERS_NR / 2) ORDER BY RAND() LIMIT 1;
          SELECT T.TUR_DATA INTO @data FROM ATP_TURNIEJ T WHERE T.TUR_ID = turniej;
          INSERT INTO ATP_MECZ(TUR_ID, MECZ_NR, MECZ_ZAWODNIK1, MECZ_ZAWODNIK2, MECZ_RUDNA, MECZ_DATA)
          VALUES (turniej, @nr, @zaw1, @zaw2, @runda, @data);
          SET @nr = @nr + 1;
          SELECT Z.ZAW_ID INTO @zaw3 FROM ATP_ZGLOSZENIA Z WHERE Z.ZGL_RANK = (@PLAYERS_NR / 2) - @V2 and Z.TUR_ID = turniej;
          SELECT Z.ZAW_ID INTO @zaw4 FROM ATP_ZGLOSZENIA Z WHERE Z.ZAW_ID NOT IN (SELECT M.MECZ_ZAWODNIK2 FROM ATP_MECZ M WHERE M.TUR_ID = turniej) AND Z.TUR_ID = turniej AND Z.ZGL_RANK > (@PLAYERS_NR / 2) ORDER BY RAND() LIMIT 1;
          INSERT INTO ATP_MECZ(TUR_ID, MECZ_NR, MECZ_ZAWODNIK1, MECZ_ZAWODNIK2, MECZ_RUDNA, MECZ_DATA)
          VALUES (turniej, @nr, @zaw3, @zaw4, @runda, @data);
          SET @nr = @nr + 1;
          SET @V2 = @V2 + 1;
          COMMIT;
        END WHILE;

        ELSE
            SELECT M.MECZ_RUDNA INTO @RUNDA FROM ATP_MECZ M  WHERE M.TUR_ID = turniej ORDER BY M.MECZ_NR DESC LIMIT 1;
            SELECT M.MECZ_NR INTO @i FROM ATP_MECZ M  WHERE M.TUR_ID = turniej AND M.MECZ_RUDNA = @RUNDA ORDER BY M.MECZ_NR ASC LIMIT 1;
            SELECT COUNT(M.MECZ_NR) INTO @PLAYERS_NR FROM ATP_MECZ M WHERE TUR_ID = turniej AND M.MECZ_RUDNA = @RUNDA;

            IF EXISTS (SELECT M.MECZ_WYNIK FROM ATP_MECZ M WHERE M.TUR_ID = turniej and M.MECZ_WYNIK is NULL) THEN
                  SELECT 'NIEDOKOŃCZONE MECZE' AS ' ';
            ELSEIF @RUNDA = 'FINAL' AND (SELECT T.TUR_ZWYCIEZCA FROM ATP_TURNIEJ T WHERE T.TUR_ID = turniej) IS NULL THEN
                  SELECT 'TURNIEJ ZAKOŃCZONY' AS ' ';
                  SELECT COUNT(Z.ZAW_ID) INTO @counter FROM ATP_ZGLOSZENIA Z WHERE Z.TUR_ID = turniej AND Z.ZGL_RANK IS NOT NULL;
                  SET @V3 = 0;
                  SET @POPRZEDNI_ZAWODNIK = 0;
                  SELECT T.TUR_NAZWA INTO @NAZWA FROM ATP_TURNIEJ T WHERE T.TUR_ID = turniej;
                  SELECT REGEXP_SUBSTR(@NAZWA, "[a-zA-z ]*") into @nazwa_ogolna;
                  SELECT T.TUR_ID INTO @ID_POPRZEDNIEGO_TURNIEJU FROM ATP_TURNIEJ T WHERE T.TUR_NAZWA REGEXP @nazwa_ogolna AND T.TUR_ID <> turniej ORDER BY T.TUR_DATA DESC LIMIT 1;
                  WHILE @V3 <  @counter DO
                      SELECT Z.ZAW_ID INTO @zawodnik FROM ATP_ZGLOSZENIA Z WHERE Z.TUR_ID = turniej AND Z.ZGL_RANK IS NOT NULL AND Z.ZAW_ID > @POPRZEDNI_ZAWODNIK ORDER BY Z.ZAW_ID ASC LIMIT 1;
                      SELECT M.MECZ_RUDNA INTO @RUNDA FROM ATP_MECZ M WHERE M.TUR_ID = turniej AND (M.MECZ_ZAWODNIK1= @zawodnik OR M.MECZ_ZAWODNIK2 = @zawodnik) ORDER BY M.MECZ_NR DESC LIMIT 1;
                      CASE @RUNDA
                            WHEN 'FINAL' THEN
                                  SELECT  ZAS_FINAL INTO @punkty FROM ATP_ZASADY WHERE ZAS_RANGA = (SELECT T.ZAS_RANGA FROM ATP_TURNIEJ T WHERE T.TUR_ID = turniej);
                                  IF (SELECT M.MECZ_ZWYCIEZCA FROM ATP_MECZ M WHERE TUR_ID = turniej AND M.MECZ_RUDNA = 'FINAL') = @zawodnik THEN
                                       SET @punkty = @punkty / 0.6;
                                       UPDATE ATP_TURNIEJ T SET T.TUR_ZWYCIEZCA = @zawodnik WHERE T.TUR_ID = turniej;
                                  ELSE
                                      SELECT  ZAS_FINAL INTO @punkty FROM ATP_ZASADY WHERE ZAS_RANGA = (SELECT T.ZAS_RANGA FROM ATP_TURNIEJ T WHERE T.TUR_ID = turniej);
                                  END IF;
                            WHEN 'SEMI' THEN
                                  SELECT  ZAS_SEMI INTO @punkty FROM ATP_ZASADY WHERE ZAS_RANGA = (SELECT T.ZAS_RANGA FROM ATP_TURNIEJ T WHERE T.TUR_ID = turniej);
                            WHEN 'QUARTER' THEN
                                  SELECT  ZAS_QUARTER INTO @punkty FROM ATP_ZASADY WHERE ZAS_RANGA = (SELECT T.ZAS_RANGA FROM ATP_TURNIEJ T WHERE T.TUR_ID = turniej);
                            WHEN '4R' THEN
                                  SELECT  ZAS_4R INTO @punkty FROM ATP_ZASADY WHERE ZAS_RANGA = (SELECT T.ZAS_RANGA FROM ATP_TURNIEJ T WHERE T.TUR_ID = turniej);
                            WHEN '3R' THEN
                                  SELECT  ZAS_3R INTO @punkty FROM ATP_ZASADY WHERE ZAS_RANGA = (SELECT T.ZAS_RANGA FROM ATP_TURNIEJ T WHERE T.TUR_ID = turniej);
                            WHEN '2R' THEN
                                  SELECT  ZAS_2R INTO @punkty FROM ATP_ZASADY WHERE ZAS_RANGA = (SELECT T.ZAS_RANGA FROM ATP_TURNIEJ T WHERE T.TUR_ID = turniej);
                            WHEN '1R' THEN
                                  SELECT  ZAS_1R INTO @punkty FROM ATP_ZASADY WHERE ZAS_RANGA = (SELECT T.ZAS_RANGA FROM ATP_TURNIEJ T WHERE T.TUR_ID = turniej);
                            END CASE;

                      SELECT O.OSI_PUNKTY INTO @PUNKTY_OGOLNIE FROM ATP_OSIAGNIECIA O WHERE O.ZAW_ID = @zawodnik;
                      UPDATE ATP_PUNKTY P SET P.PKT_SUMA = @punkty WHERE P.ZAW_ID = @zawodnik AND P.TUR_ID = turniej;
                      UPDATE ATP_OSIAGNIECIA O SET O.OSI_PUNKTY = @PUNKTY_OGOLNIE + @punkty  WHERE O.ZAW_ID = @zawodnik;
                      SET @POPRZEDNI_ZAWODNIK = @zawodnik;
                      SET @V3 = @V3 + 1;
                END WHILE;

                SET @V5 = 0;
                SET @POPRZEDNI_ZAWODNIK2 = 0;
                SELECT COUNT(Z.ZAW_ID) INTO @counter2 FROM ATP_ZGLOSZENIA Z WHERE Z.TUR_ID = @ID_POPRZEDNIEGO_TURNIEJU AND Z.ZGL_RANK IS NOT NULL;
                WHILE @V5 < @counter2 Do
                      SELECT Z.ZAW_ID INTO @zawodnikk2 FROM ATP_ZGLOSZENIA Z WHERE Z.TUR_ID = @ID_POPRZEDNIEGO_TURNIEJU AND Z.ZGL_RANK IS NOT NULL AND Z.ZAW_ID > @POPRZEDNI_ZAWODNIK2 ORDER BY Z.ZAW_ID ASC LIMIT 1;
                      SELECT O.OSI_PUNKTY INTO @PUNKTY_OGOLNIE FROM ATP_OSIAGNIECIA O WHERE O.ZAW_ID = @zawodnikk2;
                      IF (SELECT P.PKT_SUMA FROM ATP_PUNKTY P WHERE P.TUR_ID = @ID_POPRZEDNIEGO_TURNIEJU AND P.ZAW_ID = @zawodnikk2) IS NOT NULL THEN

                          SELECT P.PKT_SUMA INTO @stare_punkty FROM ATP_PUNKTY P WHERE P.TUR_ID = @ID_POPRZEDNIEGO_TURNIEJU AND P.ZAW_ID = @zawodnikk2;
                      ELSE
                          SET @stare_punkty = 0;
                      END IF;
                      UPDATE ATP_OSIAGNIECIA O SET O.OSI_PUNKTY = (@PUNKTY_OGOLNIE - @stare_punkty) WHERE O.ZAW_ID = @zawodnikk2;
                      SET @POPRZEDNI_ZAWODNIK2 = @zawodnikk2;
                      SET @V5 = @v5 + 1;
              END WHILE;


            ELSEIF @RUNDA = 'FINAL' AND (SELECT T.TUR_ZWYCIEZCA FROM ATP_TURNIEJ T WHERE T.TUR_ID = turniej )IS NOT NULL THEN
                    SELECT "TURNIEJ JUŻ ROZEGRANO" AS " ";
            ELSE
                SET @runda_new = RUNDA_FUNC(@PLAYERS_NR);
                SELECT COUNT(M.MECZ_NR) INTO @COUNTER FROM ATP_MECZ M WHERE TUR_ID = turniej AND M.MECZ_RUDNA = @RUNDA;
                SELECT M.MECZ_NR INTO @nr FROM ATP_MECZ M WHERE M.TUR_ID = turniej ORDER BY M.MECZ_NR DESC LIMIT 1;
                SET @V1 = 0;
                SET @v2 = 0;

                WHILE @V1 < (@COUNTER / 2) DO

                    SELECT M.MECZ_ZWYCIEZCA INTO @zaw1 FROM ATP_MECZ M WHERE M.TUR_ID = turniej AND M.MECZ_RUDNA = @RUNDA AND M.MECZ_NR = @i + @v2;
                    SET @V2 = @v2 + 1;
                    SELECT M.MECZ_ZWYCIEZCA INTO @zaw2 FROM ATP_MECZ M WHERE M.TUR_ID = turniej AND M.MECZ_RUDNA = @RUNDA AND M.MECZ_NR = @i + @v2;
                    SELECT M.MECZ_DATA INTO @data FROM ATP_MECZ M WHERE M.TUR_ID = turniej AND M.MECZ_RUDNA = @RUNDA ORDER BY M.MECZ_DATA DESC LIMIT 1;
                    SELECT DATE_ADD(@data, INTERVAL 1 DAY) INTO @data;
                    INSERT INTO ATP_MECZ(TUR_ID, MECZ_NR, MECZ_ZAWODNIK1, MECZ_ZAWODNIK2, MECZ_RUDNA, MECZ_DATA)
                    VALUES (turniej, @nr + 1 + @v1, @zaw1, @zaw2, @runda_new, @data);
                    SET @V1 = @V1 + 1;
                    SET @V2 = @v2 + 1;
                END WHILE;
          END IF;

    END IF;


END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `NoweZgloszenieDoTurnieju` (IN `turniej` INT, IN `zawodnik` INT)  BEGIN
        INSERT INTO ATP_ZGLOSZENIA(TUR_ID, ZAW_ID)
        VALUES(turniej, zawodnik);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `NowyTurniej` (IN `nazwa` VARCHAR(100), IN `data` DATE, IN `ranga` VARCHAR(20), IN `nawierzchnia` CHAR(1), IN `nagrody` INT)  BEGIN
        INSERT INTO ATP_TURNIEJ(TUR_NAZWA, TUR_DATA, ZAS_RANGA, TUR_NAWIERCHNIA, TUR_NAGRODY) 
        VALUES (nazwa, data, ranga, nawierzchnia, nagrody);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `NowyZawodnik` (IN `imie` VARCHAR(20), IN `nazwisko` VARCHAR(20), IN `data_urodzenia` DATE, IN `punkty_rankingu` INT, IN `waga` INT, IN `wzrost` INT, IN `reka` CHAR(1), IN `backhand` CHAR(3), IN `narodowsc` VARCHAR(20), IN `zamieszkanie` VARCHAR(20), IN `kraj_zamieszkania` VARCHAR(20))  BEGIN
        INSERT INTO ATP_ZAWODNIK(ZAW_IMIE, ZAW_NAZWISKO, ZAW_DATA) 
        VALUES (imie, nazwisko, data_urodzenia);
        COMMIT;
        SELECT ZAW_ID into @id from ATP_ZAWODNIK where ZAW_IMIE = imie and ZAW_NAZWISKO = nazwisko and ZAW_DATA = data_urodzenia ORDER BY ZAW_ID DESC LIMIT 1;
        UPDATE ATP_ADRESY SET ADR_NARODOWOŚĆ = narodowsc, ADR_ZAMIESZKANIE = zamieszkanie, ADR_ZAMKRAJ = kraj_zamieszkania WHERE ZAW_ID = @id;
        UPDATE ATP_OSIAGNIECIA SET OSI_PUNKTY = punkty_rankingu WHERE ZAW_ID = @id;
        UPDATE ATP_PARAMETRY SET PAR_WAGA = waga, PAR_WZROST = wzrost, PAR_REKA = reka, PAR_BEK = backhand WHERE ZAW_ID = @id;
        
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `PunktyTurnieju` (IN `turniej` INT)  BEGIN
  SELECT Z.ZAW_NAZWISKO as 'NAZWISKO',
  P.PKT_SUMA as 'PUNKTY ZDOBYTE'
  FROM ATP_PUNKTY P, ATP_ZAWODNIK Z
  WHERE Z.ZAW_ID = P.ZAW_ID
  AND P.TUR_ID = turniej;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `RankingATP` ()  BEGIN
      SELECT RANK() OVER( ORDER BY O.OSI_PUNKTY DESC) AS 'RANKING',
      Z.ZAW_IMIE as 'IMIE',
      Z.ZAW_NAZWISKO as 'NAZWISKO',
      O.OSI_PUNKTY as 'LICZBA PUNKTÓW'
      FROM ATP_ZAWODNIK Z, ATP_OSIAGNIECIA O
      WHERE Z.ZAW_ID = O.ZAW_ID
      ORDER BY O.OSI_PUNKTY DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Terminarz` ()  BEGIN
      SELECT T.TUR_ID as 'ID',
      T.TUR_NAZWA as 'NAZWA',
      T.TUR_DATA as 'DATA',
      T.ZAS_RANGA as 'RANGA',
      CASE
        WHEN T.TUR_NAWIERCHNIA = 'g' THEN 'trawa'
        WHEN T.TUR_NAWIERCHNIA = 'h' THEN 'twarda'
        WHEN T.TUR_NAWIERCHNIA = 'i' THEN 'hala'
        WHEN T.TUR_NAWIERCHNIA = 'c' THEN 'ziemna'
      END
      AS 'NAWIERZCHNIA',
      R.TER_MIES as 'MIESIAC',
      R.TER_TYDZ as 'TYDZIEN'
      FROM ATP_TURNIEJ T, ATP_TERMINARZ R
      WHERE T.TUR_ID = R.TUR_ID;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Trenerzy` ()  BEGIN
  SELECT * FROM ATP_TRENER;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Zasady` ()  BEGIN
  SELECT * FROM ATP_ZASADY;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ZawodnikInfo` (IN `nazwisko` VARCHAR(20))  BEGIN  
      SELECT
      Z.ZAW_ID as 'ID',
      Z.ZAW_IMIE as 'IMIE',
      Z.ZAW_NAZWISKO as 'NAZWISKO',
      P.PAR_WAGA as 'WAGA', P.PAR_WZROST as 'WZROST',
      CASE
        WHEN P.PAR_REKA = 'p' then 'prawa'
        WHEN P.PAR_REKA = 'l' then 'lewa'
        WHEN P.PAR_REKA is null then 'brak danych'
      END
      AS 'REKA',
      CASE
        WHEN P.PAR_BEK = 'one' then 'jednoręczny'
        WHEN P.PAR_BEK = 'two' then 'oburęczny'
        WHEN P.PAR_BEK is null then 'brak danych'
      END
      AS 'BACKHAND',
      A.ADR_NARODOWOŚĆ AS 'NARODOWOŚĆ',
      A.ADR_ZAMIESZKANIE AS 'ZAMIESZKANIE',
      O.OSI_PUNKTY AS 'SUMA PUNKTÓW',
      O.OSI_ZAROBKI AS 'ZAROBKI W $'
      FROM ATP_ZAWODNIK Z, ATP_PARAMETRY P, ATP_ADRESY A, ATP_OSIAGNIECIA O
      WHERE Z.ZAW_ID = P.ZAW_ID
      AND Z.ZAW_ID = O.ZAW_ID
      AND Z.ZAW_ID = A.ZAW_ID
      AND Z.ZAW_NAZWISKO = nazwisko;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ZgloszeniaDoTurnieju` (IN `turniej` INT)  BEGIN
  SELECT Z.ZAW_NAZWISKO as 'NAZWISKO',
  ZA.ZGL_PUNKTY as 'PUNKTY ZGŁOSZONE',
  ZA.ZGL_RANK as 'NR ROZSTAWIENIA'
  FROM ATP_ZAWODNIK Z, ATP_ZGLOSZENIA ZA
  WHERE Z.ZAW_ID = ZA.ZAW_ID
  AND ZA.TUR_ID = turniej
  ORDER BY ZA.ZGL_RANK ASC;
END$$

--
-- Funkcje
--
CREATE DEFINER=`root`@`localhost` FUNCTION `RUNDA_FUNC` (`liczba_zawodnikow` INT) RETURNS VARCHAR(10) CHARSET utf8 COLLATE utf8_bin BEGIN
  CASE liczba_zawodnikow
      WHEN '2' THEN
            SET @MY_RUNDA = 'FINAL';
      WHEN '4' THEN
            SET @MY_RUNDA = 'SEMI';
      WHEN '8' THEN
            SET @MY_RUNDA = 'QUARTER';
      WHEN '16' THEN
            SET @MY_RUNDA = '4R';
      WHEN '32' THEN
            SET @MY_RUNDA = '3R';
      WHEN '64' THEN
            SET @MY_RUNDA = '2R';
			WHEN '128' THEN
			      SET @MY_RUNDA = '1R';
			END CASE;

			RETURN @MY_RUNDA;

END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `ATP_ADRESY`
--

CREATE TABLE `ATP_ADRESY` (
  `ADR_ID` int NOT NULL,
  `ZAW_ID` int NOT NULL,
  `ADR_NARODOWOŚĆ` varchar(50) COLLATE utf8_bin DEFAULT NULL,
  `ADR_ZAMIESZKANIE` varchar(50) COLLATE utf8_bin DEFAULT NULL,
  `ADR_ZAMKRAJ` varchar(50) COLLATE utf8_bin DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

--
-- Zrzut danych tabeli `ATP_ADRESY`
--

INSERT INTO `ATP_ADRESY` (`ADR_ID`, `ZAW_ID`, `ADR_NARODOWOŚĆ`, `ADR_ZAMIESZKANIE`, `ADR_ZAMKRAJ`) VALUES
(1, 1, 'Serbia', 'Monte Carlo', 'Monaco'),
(2, 2, 'Hiszpania', 'Mallorca', 'Hiszpania'),
(3, 3, 'Austria', 'Lichtenworth', 'Austria'),
(4, 4, 'Szwajcaria', 'Bazylea', 'Szwajcaria'),
(5, 5, 'Grecja', 'Monte Carlo', 'Monaco'),
(6, 6, 'Polska', 'Wrocław', 'Polska'),
(7, 7, 'Japonia', 'Bradenton', 'Stany Zjednoczone'),
(8, 8, 'Australia', 'Nassau', 'Bahamy'),
(9, 9, 'Stany Zjednoczone', 'Boynton Beach', 'Stany Zjednoczone'),
(10, 10, 'Kanada', 'Nassau', 'Bahamy'),
(11, 11, 'Niemcy', 'Monte Carlo', 'Monaco');

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `ATP_MECZ`
--

CREATE TABLE `ATP_MECZ` (
  `MECZ_ID` int NOT NULL,
  `MECZ_NR` int NOT NULL,
  `TUR_ID` int NOT NULL,
  `MECZ_ZAWODNIK1` int DEFAULT NULL,
  `MECZ_ZAWODNIK2` int DEFAULT NULL,
  `MECZ_WYNIK` varchar(10) COLLATE utf8_bin DEFAULT NULL,
  `MECZ_RUDNA` varchar(10) COLLATE utf8_bin DEFAULT NULL,
  `MECZ_DATA` date NOT NULL,
  `MECZ_ZWYCIEZCA` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

--
-- Zrzut danych tabeli `ATP_MECZ`
--

INSERT INTO `ATP_MECZ` (`MECZ_ID`, `MECZ_NR`, `TUR_ID`, `MECZ_ZAWODNIK1`, `MECZ_ZAWODNIK2`, `MECZ_WYNIK`, `MECZ_RUDNA`, `MECZ_DATA`, `MECZ_ZWYCIEZCA`) VALUES
(1, 1, 1, 1, 7, '2-0', 'QUARTER', '2020-02-05', 1),
(2, 2, 1, 4, 5, '0-2', 'QUARTER', '2020-02-05', 5),
(3, 3, 1, 3, 10, '1-2', 'QUARTER', '2020-02-05', 10),
(4, 4, 1, 2, 6, '2-1', 'QUARTER', '2020-02-05', 2),
(5, 5, 1, 1, 5, '2-1', 'SEMI', '2020-02-06', 1),
(6, 6, 1, 10, 2, '1-2', 'SEMI', '2020-02-06', 2),
(7, 7, 1, 1, 2, '2-0', 'FINAL', '2020-02-07', 1),
(8, 1, 2, 2, 7, '2-1', 'QUARTER', '2021-02-05', 2),
(9, 2, 2, 10, 6, '0-2', 'QUARTER', '2021-02-05', 6),
(10, 3, 2, 3, 9, '2-0', 'QUARTER', '2021-02-05', 3),
(11, 4, 2, 4, 8, '2-1', 'QUARTER', '2021-02-05', 4),
(12, 5, 2, 2, 6, '2-1', 'SEMI', '2021-02-06', 2),
(13, 6, 2, 3, 4, '1-2', 'SEMI', '2021-02-06', 4),
(14, 7, 2, 2, 4, '2-1', 'FINAL', '2021-02-07', 2);

--
-- Wyzwalacze `ATP_MECZ`
--
DELIMITER $$
CREATE TRIGGER `mecz_trigger` BEFORE UPDATE ON `ATP_MECZ` FOR EACH ROW BEGIN
    	  SELECT T.ZAS_RANGA INTO @ranga FROM ATP_TURNIEJ T WHERE T.TUR_ID = NEW.TUR_ID;
        IF @ranga <> 'Szlem' THEN
          IF (NEW.MECZ_WYNIK NOT REGEXP '2-[0-1]' AND NEW.MECZ_WYNIK NOT REGEXP '[0-1]-2')THEN
            signal sqlstate '45000'
              SET MESSAGE_TEXT = "NIEPRAWIDŁOWY WYNIK";
            END IF;
        END IF;
        IF @ranga = 'Szlem' THEN
          IF (NEW.MECZ_WYNIK NOT REGEXP '3-[0-2]' AND NEW.MECZ_WYNIK NOT REGEXP '[0-2]-3')THEN
            signal sqlstate '45000'
              SET MESSAGE_TEXT = "NIEPRAWIDŁOWY WYNIK";
            END IF;
          END IF;
          IF (NEW.MECZ_WYNIK REGEXP '[2-3]-[0-2]') THEN
              SET NEW.MECZ_ZWYCIEZCA = (SELECT M.MECZ_ZAWODNIK1 FROM ATP_MECZ M WHERE M.MECZ_ID = NEW.MECZ_ID);
          ELSE
              SET NEW.MECZ_ZWYCIEZCA = (SELECT M.MECZ_ZAWODNIK2 FROM ATP_MECZ M WHERE M.MECZ_ID = NEW.MECZ_ID);
          END IF;
    END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `ATP_OSIAGNIECIA`
--

CREATE TABLE `ATP_OSIAGNIECIA` (
  `OSI_ID` int NOT NULL,
  `ZAW_ID` int DEFAULT NULL,
  `OSI_PUNKTY` int UNSIGNED DEFAULT '0',
  `OSI_ZAROBKI` int UNSIGNED DEFAULT '0',
  `OSI_SUKCES` varchar(255) COLLATE utf8_bin DEFAULT 'brak danych'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

--
-- Zrzut danych tabeli `ATP_OSIAGNIECIA`
--

INSERT INTO `ATP_OSIAGNIECIA` (`OSI_ID`, `ZAW_ID`, `OSI_PUNKTY`, `OSI_ZAROBKI`, `OSI_SUKCES`) VALUES
(1, 1, 10390, 145656177, '17 zwycięstw w Szlemie'),
(2, 2, 33010, 123482764, '20 zwycięstw w Szlemie'),
(3, 3, 12845, 28163125, '1 zwycięstwo w Szlemie'),
(4, 4, 11430, 129946683, '20 zwycięstw w Szlemie'),
(5, 5, 5580, 12532057, 'brak danych'),
(6, 6, 4975, 2626860, 'brak danych'),
(7, 7, 3145, 24020635, 'brązowy medalista Igrzysk Olimpijskich'),
(8, 8, 2610, 8557848, 'brak danych'),
(9, 9, 2445, 3863233, 'brak danych'),
(10, 10, 5950, 5879155, 'brak danych'),
(11, 11, 5615, 0, 'brak danych');

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `ATP_PARAMETRY`
--

CREATE TABLE `ATP_PARAMETRY` (
  `PAR_ID` int NOT NULL,
  `ZAW_ID` int DEFAULT NULL,
  `PAR_WAGA` int DEFAULT NULL,
  `PAR_WZROST` float DEFAULT NULL,
  `PAR_REKA` char(1) COLLATE utf8_bin DEFAULT 'n',
  `PAR_BEK` char(3) COLLATE utf8_bin DEFAULT 'n'
) ;

--
-- Zrzut danych tabeli `ATP_PARAMETRY`
--

INSERT INTO `ATP_PARAMETRY` (`PAR_ID`, `ZAW_ID`, `PAR_WAGA`, `PAR_WZROST`, `PAR_REKA`, `PAR_BEK`) VALUES
(1, 1, 77, 188, 'p', 'two'),
(2, 2, 85, 185, 'l', 'two'),
(3, 3, 79, 185, 'p', 'one'),
(4, 4, 85, 185, 'p', 'one'),
(5, 5, 89, 193, 'p', 'one'),
(6, 6, 81, 196, 'p', 'two'),
(7, 7, 73, 178, 'p', 'two'),
(8, 8, 85, 193, 'p', 'two'),
(9, 9, 86, 188, 'p', 'two'),
(10, 10, 75, 185, 'l', 'one'),
(11, 11, 90, 198, 'p', 'two');

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `ATP_PUNKTY`
--

CREATE TABLE `ATP_PUNKTY` (
  `PKT_ID` int NOT NULL,
  `ZAW_ID` int DEFAULT NULL,
  `TUR_ID` int DEFAULT NULL,
  `PKT_SUMA` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

--
-- Zrzut danych tabeli `ATP_PUNKTY`
--

INSERT INTO `ATP_PUNKTY` (`PKT_ID`, `ZAW_ID`, `TUR_ID`, `PKT_SUMA`) VALUES
(1, 10, 1, 720),
(2, 3, 1, 360),
(3, 9, 1, 0),
(4, 6, 1, 360),
(5, 7, 1, 360),
(6, 8, 1, 0),
(7, 1, 1, 2000),
(8, 2, 1, 1200),
(9, 4, 1, 360),
(10, 5, 1, 720),
(11, 10, 2, 360),
(12, 3, 2, 720),
(13, 9, 2, 360),
(14, 6, 2, 720),
(15, 7, 2, 360),
(16, 8, 2, 360),
(17, 2, 2, 2000),
(18, 4, 2, 1200);

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `ATP_TERMINARZ`
--

CREATE TABLE `ATP_TERMINARZ` (
  `TER_ID` int NOT NULL,
  `TER_MIES` varchar(20) COLLATE utf8_bin DEFAULT NULL,
  `TER_TYDZ` int DEFAULT NULL,
  `TER_ROK` int DEFAULT NULL,
  `TER_DATA` date NOT NULL,
  `TUR_ID` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

--
-- Zrzut danych tabeli `ATP_TERMINARZ`
--

INSERT INTO `ATP_TERMINARZ` (`TER_ID`, `TER_MIES`, `TER_TYDZ`, `TER_ROK`, `TER_DATA`, `TUR_ID`) VALUES
(1, 'February', 5, 2020, '2020-02-05', 1),
(2, 'February', 5, 2021, '2021-02-05', 2),
(3, 'February', 7, 2021, '2021-02-14', 3);

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `ATP_TRENER`
--

CREATE TABLE `ATP_TRENER` (
  `TRE_ID` int NOT NULL,
  `TRE_IMIE` varchar(50) COLLATE utf8_bin NOT NULL,
  `TRE_NAZWISKO` varchar(50) COLLATE utf8_bin NOT NULL,
  `TRE_NARODOWOŚĆ` varchar(50) COLLATE utf8_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

--
-- Zrzut danych tabeli `ATP_TRENER`
--

INSERT INTO `ATP_TRENER` (`TRE_ID`, `TRE_IMIE`, `TRE_NAZWISKO`, `TRE_NARODOWOŚĆ`) VALUES
(1, 'Marian', 'Vajda', 'Słowacja'),
(2, 'Goran', 'Ivanisević', 'Chorwacja'),
(3, 'Carlos', 'Moya', 'Hiszpania'),
(4, 'Francisco', 'Roig', 'Hiszpania'),
(5, 'Nicolas', 'Massu', 'Chile'),
(6, 'Ivan', 'Ljubicic', 'Chorwacja'),
(7, 'Severin', 'Luthi', 'Szwajcaria'),
(8, 'Apostolos', 'Tsitsipas', 'Grecja'),
(9, 'Craig', 'Boynton', 'Stany Zjednoczone'),
(10, 'Michael', 'Chang', 'Stany Zjednoczone'),
(11, 'Wayne', 'Ferreira', 'RPA'),
(12, 'Mikhail', 'Youzhny', 'Rosja');

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `ATP_TURNIEJ`
--

CREATE TABLE `ATP_TURNIEJ` (
  `TUR_ID` int NOT NULL,
  `TUR_NAZWA` varchar(100) COLLATE utf8_bin DEFAULT NULL,
  `TUR_DATA` date NOT NULL,
  `ZAS_RANGA` varchar(10) COLLATE utf8_bin NOT NULL,
  `TUR_NAWIERCHNIA` char(1) COLLATE utf8_bin NOT NULL,
  `TUR_NAGRODY` int UNSIGNED DEFAULT NULL,
  `TUR_PUNKTY` int UNSIGNED DEFAULT NULL,
  `TUR_ZWYCIEZCA` int DEFAULT NULL
) ;

--
-- Zrzut danych tabeli `ATP_TURNIEJ`
--

INSERT INTO `ATP_TURNIEJ` (`TUR_ID`, `TUR_NAZWA`, `TUR_DATA`, `ZAS_RANGA`, `TUR_NAWIERCHNIA`, `TUR_NAGRODY`, `TUR_PUNKTY`, `TUR_ZWYCIEZCA`) VALUES
(1, 'Turniej testowy 2020', '2020-02-05', 'Test', 'h', NULL, 2000, 1),
(2, 'Turniej testowy 2021', '2021-02-05', 'Test', 'h', NULL, 2000, 2),
(3, 'Australian Open 2021', '2021-02-14', 'Szlem', 'h', 100000, 2000, NULL);

--
-- Wyzwalacze `ATP_TURNIEJ`
--
DELIMITER $$
CREATE TRIGGER `terminarz_trigger` AFTER INSERT ON `ATP_TURNIEJ` FOR EACH ROW BEGIN
      INSERT INTO ATP_TERMINARZ (TER_MIES, TER_TYDZ, TER_ROK, TER_DATA, TUR_ID)
      VALUES (MONTHNAME(NEW.TUR_DATA), WEEK(NEW.TUR_DATA), YEAR(NEW.TUR_DATA), NEW.TUR_DATA, NEW.TUR_ID);
  END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `turniej_trigger` BEFORE INSERT ON `ATP_TURNIEJ` FOR EACH ROW BEGIN
    	IF NEW.TUR_PUNKTY is NULL THEN
        SET NEW.TUR_PUNKTY = (select Z.ZAS_WINNER from ATP_ZASADY Z where Z.ZAS_RANGA = NEW.ZAS_RANGA);
        END IF;
    END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `ATP_ZASADY`
--

CREATE TABLE `ATP_ZASADY` (
  `ZAS_RANGA` varchar(10) COLLATE utf8_bin NOT NULL,
  `ZAS_WINNER` int DEFAULT NULL,
  `ZAS_FINAL` int DEFAULT NULL,
  `ZAS_SEMI` int DEFAULT NULL,
  `ZAS_QUARTER` int DEFAULT NULL,
  `ZAS_4R` int DEFAULT NULL,
  `ZAS_3R` int DEFAULT NULL,
  `ZAS_2R` int DEFAULT NULL,
  `ZAS_1R` int DEFAULT NULL,
  `ZAS_LICZBA` int NOT NULL
) ;

--
-- Zrzut danych tabeli `ATP_ZASADY`
--

INSERT INTO `ATP_ZASADY` (`ZAS_RANGA`, `ZAS_WINNER`, `ZAS_FINAL`, `ZAS_SEMI`, `ZAS_QUARTER`, `ZAS_4R`, `ZAS_3R`, `ZAS_2R`, `ZAS_1R`, `ZAS_LICZBA`) VALUES
('250', 150, 90, 45, 20, 5, 2, NULL, NULL, 32),
('500', 500, 300, 180, 90, 45, 20, NULL, NULL, 32),
('Challenger', 125, 75, 45, 25, 10, 5, NULL, NULL, 32),
('Masters', 1000, 600, 360, 180, 90, 45, 25, 10, 128),
('Szlem', 2000, 1200, 720, 360, 180, 90, 45, 10, 128),
('Test', 2000, 1200, 720, 360, NULL, NULL, NULL, NULL, 8);

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `ATP_ZAWODNIK`
--

CREATE TABLE `ATP_ZAWODNIK` (
  `ZAW_ID` int NOT NULL,
  `ZAW_IMIE` varchar(50) COLLATE utf8_bin NOT NULL,
  `ZAW_NAZWISKO` varchar(50) COLLATE utf8_bin NOT NULL,
  `ZAW_DATA` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

--
-- Zrzut danych tabeli `ATP_ZAWODNIK`
--

INSERT INTO `ATP_ZAWODNIK` (`ZAW_ID`, `ZAW_IMIE`, `ZAW_NAZWISKO`, `ZAW_DATA`) VALUES
(1, 'Novak', 'Djokovic', '1987-05-22'),
(2, 'Rafael', 'Nadal', '1986-06-03'),
(3, 'Dominic', 'Thiem', '1993-09-03'),
(4, 'Roger', 'Federer', '1981-08-08'),
(5, 'Stefanos', 'Tsitsipas', '1998-08-12'),
(6, 'Hubert', 'Hurkacz', '1997-02-11'),
(7, 'Kei', 'Nishikori', '1989-12-29'),
(8, 'Nick', 'Kyrgios', '1995-04-27'),
(9, 'Frances', 'Tiafoe', '1998-01-20'),
(10, 'Denis', 'Shapovalov', '1999-04-15'),
(11, 'Alexander', 'Zverev', '1997-04-20');

--
-- Wyzwalacze `ATP_ZAWODNIK`
--
DELIMITER $$
CREATE TRIGGER `osiagniecia_trigger` AFTER INSERT ON `ATP_ZAWODNIK` FOR EACH ROW BEGIN
            INSERT INTO ATP_OSIAGNIECIA (ZAW_ID) VALUES(NEW.ZAW_ID);
            INSERT INTO ATP_PARAMETRY (ZAW_ID) VALUES(NEW.ZAW_ID);
            INSERT INTO ATP_ADRESY (ZAW_ID) VALUES(NEW.ZAW_ID);
    END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `ATP_ZAWTRE`
--

CREATE TABLE `ATP_ZAWTRE` (
  `ZT_ID` int NOT NULL,
  `ZAW_ID` int DEFAULT NULL,
  `TRE_ID` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

--
-- Zrzut danych tabeli `ATP_ZAWTRE`
--

INSERT INTO `ATP_ZAWTRE` (`ZT_ID`, `ZAW_ID`, `TRE_ID`) VALUES
(1, 1, 1),
(2, 1, 2),
(3, 2, 3),
(4, 2, 4),
(5, 3, 5),
(6, 4, 6),
(7, 4, 7),
(8, 5, 8),
(9, 7, 10),
(10, 6, 9),
(11, 9, 11),
(12, 10, 12);

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `ATP_ZGLOSZENIA`
--

CREATE TABLE `ATP_ZGLOSZENIA` (
  `ZGL_ID` int NOT NULL,
  `ZAW_ID` int DEFAULT NULL,
  `TUR_ID` int DEFAULT NULL,
  `ZGL_PUNKTY` int DEFAULT NULL,
  `ZGL_RANK` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

--
-- Zrzut danych tabeli `ATP_ZGLOSZENIA`
--

INSERT INTO `ATP_ZGLOSZENIA` (`ZGL_ID`, `ZAW_ID`, `TUR_ID`, `ZGL_PUNKTY`, `ZGL_RANK`) VALUES
(1, 10, 1, 5230, 6),
(2, 3, 1, 10325, 2),
(3, 9, 1, 1005, NULL),
(4, 6, 1, 2455, 7),
(5, 7, 1, 2065, 8),
(6, 8, 1, 1170, NULL),
(7, 1, 1, 12390, 1),
(8, 2, 1, 10210, 3),
(9, 4, 1, 6990, 4),
(10, 5, 1, 6300, 5),
(11, 10, 2, 5950, 4),
(12, 3, 2, 10685, 2),
(13, 9, 2, 1005, 8),
(14, 6, 2, 2815, 5),
(15, 7, 2, 2425, 6),
(16, 8, 2, 1170, 7),
(17, 2, 2, 11410, 1),
(18, 4, 2, 7350, 3);

--
-- Wyzwalacze `ATP_ZGLOSZENIA`
--
DELIMITER $$
CREATE TRIGGER `punkty_trigger` AFTER INSERT ON `ATP_ZGLOSZENIA` FOR EACH ROW BEGIN
			IF NEW.ZAW_ID NOT IN (SELECT ZAW_ID FROM ATP_PUNKTY WHERE TUR_ID = NEW.TUR_ID) THEN
            INSERT INTO ATP_PUNKTY (ZAW_ID, TUR_ID, PKT_SUMA) VALUES(NEW.ZAW_ID, NEW.TUR_ID, 0);
            END IF;
    END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `zgloszenie_trigger_before` BEFORE INSERT ON `ATP_ZGLOSZENIA` FOR EACH ROW BEGIN

        IF (NEW.ZAW_ID not in (select ZA.ZAW_ID from ATP_ZAWODNIK ZA where NEW.ZAW_ID = ZA.ZAW_ID)) THEN
        	signal sqlstate '45000'
            SET MESSAGE_TEXT = "Zawodnik nie istnieje";
        END IF;
              IF (NEW.ZAW_ID in (select Z.ZAW_ID from ATP_ZGLOSZENIA Z WHERE Z.TUR_ID = NEW.TUR_ID)) THEN
        	signal sqlstate '45000'
            SET MESSAGE_TEXT = "Zawodnik już zgłoszony";
        END IF;
          IF NEW.ZGL_PUNKTY is NULL
              THEN
                SET NEW.ZGL_PUNKTY = (SELECT O.OSI_PUNKTY FROM ATP_OSIAGNIECIA O WHERE O.ZAW_ID = NEW.ZAW_ID);
          END IF;
              SELECT COUNT(Z.ZGL_ID) INTO @liczba FROM ATP_ZGLOSZENIA Z WHERE Z.TUR_ID = NEW.TUR_ID;
              SELECT ZA.ZAS_LICZBA INTO @liczba_max FROM ATP_ZASADY ZA WHERE ZA.ZAS_RANGA = (SELECT T.ZAS_RANGA FROM ATP_TURNIEJ T WHERE T.TUR_ID = NEW.TUR_ID);
              IF @liczba >= @liczba_max
                THEN
                   IF NEW.ZGL_PUNKTY <= (SELECT MIN(Z.ZGL_PUNKTY) FROM ATP_ZGLOSZENIA Z WHERE Z.TUR_ID = NEW.TUR_ID)
                     THEN
                     signal sqlstate '45000'
                       SET MESSAGE_TEXT = "NIEUPOWAŻNIONY WYSTĘP";
                       
                    END IF;
                END IF;
        END
$$
DELIMITER ;

--
-- Indeksy dla zrzutów tabel
--

--
-- Indeksy dla tabeli `ATP_ADRESY`
--
ALTER TABLE `ATP_ADRESY`
  ADD PRIMARY KEY (`ADR_ID`),
  ADD KEY `ZAW_ID` (`ZAW_ID`);

--
-- Indeksy dla tabeli `ATP_MECZ`
--
ALTER TABLE `ATP_MECZ`
  ADD PRIMARY KEY (`MECZ_ID`),
  ADD KEY `TUR_ID` (`TUR_ID`);

--
-- Indeksy dla tabeli `ATP_OSIAGNIECIA`
--
ALTER TABLE `ATP_OSIAGNIECIA`
  ADD PRIMARY KEY (`OSI_ID`),
  ADD KEY `ZAW_ID` (`ZAW_ID`);

--
-- Indeksy dla tabeli `ATP_PARAMETRY`
--
ALTER TABLE `ATP_PARAMETRY`
  ADD PRIMARY KEY (`PAR_ID`),
  ADD KEY `ZAW_ID` (`ZAW_ID`);

--
-- Indeksy dla tabeli `ATP_PUNKTY`
--
ALTER TABLE `ATP_PUNKTY`
  ADD PRIMARY KEY (`PKT_ID`),
  ADD KEY `ZAW_ID` (`ZAW_ID`),
  ADD KEY `TUR_ID` (`TUR_ID`);

--
-- Indeksy dla tabeli `ATP_TERMINARZ`
--
ALTER TABLE `ATP_TERMINARZ`
  ADD PRIMARY KEY (`TER_ID`),
  ADD KEY `TUR_ID` (`TUR_ID`);

--
-- Indeksy dla tabeli `ATP_TRENER`
--
ALTER TABLE `ATP_TRENER`
  ADD PRIMARY KEY (`TRE_ID`);

--
-- Indeksy dla tabeli `ATP_TURNIEJ`
--
ALTER TABLE `ATP_TURNIEJ`
  ADD PRIMARY KEY (`TUR_ID`),
  ADD UNIQUE KEY `TUR_NAZWA` (`TUR_NAZWA`),
  ADD KEY `ZAS_RANGA` (`ZAS_RANGA`);

--
-- Indeksy dla tabeli `ATP_ZASADY`
--
ALTER TABLE `ATP_ZASADY`
  ADD PRIMARY KEY (`ZAS_RANGA`);

--
-- Indeksy dla tabeli `ATP_ZAWODNIK`
--
ALTER TABLE `ATP_ZAWODNIK`
  ADD PRIMARY KEY (`ZAW_ID`);

--
-- Indeksy dla tabeli `ATP_ZAWTRE`
--
ALTER TABLE `ATP_ZAWTRE`
  ADD PRIMARY KEY (`ZT_ID`),
  ADD KEY `TRE_ID` (`TRE_ID`),
  ADD KEY `ZAW_ID` (`ZAW_ID`);

--
-- Indeksy dla tabeli `ATP_ZGLOSZENIA`
--
ALTER TABLE `ATP_ZGLOSZENIA`
  ADD PRIMARY KEY (`ZGL_ID`),
  ADD KEY `ZAW_ID` (`ZAW_ID`),
  ADD KEY `TUR_ID` (`TUR_ID`);

--
-- AUTO_INCREMENT dla zrzuconych tabel
--

--
-- AUTO_INCREMENT dla tabeli `ATP_ADRESY`
--
ALTER TABLE `ATP_ADRESY`
  MODIFY `ADR_ID` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT dla tabeli `ATP_MECZ`
--
ALTER TABLE `ATP_MECZ`
  MODIFY `MECZ_ID` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT dla tabeli `ATP_OSIAGNIECIA`
--
ALTER TABLE `ATP_OSIAGNIECIA`
  MODIFY `OSI_ID` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT dla tabeli `ATP_PARAMETRY`
--
ALTER TABLE `ATP_PARAMETRY`
  MODIFY `PAR_ID` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT dla tabeli `ATP_PUNKTY`
--
ALTER TABLE `ATP_PUNKTY`
  MODIFY `PKT_ID` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;

--
-- AUTO_INCREMENT dla tabeli `ATP_TERMINARZ`
--
ALTER TABLE `ATP_TERMINARZ`
  MODIFY `TER_ID` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT dla tabeli `ATP_TRENER`
--
ALTER TABLE `ATP_TRENER`
  MODIFY `TRE_ID` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT dla tabeli `ATP_TURNIEJ`
--
ALTER TABLE `ATP_TURNIEJ`
  MODIFY `TUR_ID` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT dla tabeli `ATP_ZAWODNIK`
--
ALTER TABLE `ATP_ZAWODNIK`
  MODIFY `ZAW_ID` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT dla tabeli `ATP_ZAWTRE`
--
ALTER TABLE `ATP_ZAWTRE`
  MODIFY `ZT_ID` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT dla tabeli `ATP_ZGLOSZENIA`
--
ALTER TABLE `ATP_ZGLOSZENIA`
  MODIFY `ZGL_ID` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;

--
-- Ograniczenia dla zrzutów tabel
--

--
-- Ograniczenia dla tabeli `ATP_ADRESY`
--
ALTER TABLE `ATP_ADRESY`
  ADD CONSTRAINT `atp_adresy_ibfk_1` FOREIGN KEY (`ZAW_ID`) REFERENCES `ATP_ZAWODNIK` (`ZAW_ID`) ON DELETE RESTRICT ON UPDATE RESTRICT;

--
-- Ograniczenia dla tabeli `ATP_MECZ`
--
ALTER TABLE `ATP_MECZ`
  ADD CONSTRAINT `atp_mecz_ibfk_1` FOREIGN KEY (`TUR_ID`) REFERENCES `ATP_TURNIEJ` (`TUR_ID`) ON DELETE RESTRICT ON UPDATE RESTRICT;

--
-- Ograniczenia dla tabeli `ATP_OSIAGNIECIA`
--
ALTER TABLE `ATP_OSIAGNIECIA`
  ADD CONSTRAINT `atp_osiagniecia_ibfk_1` FOREIGN KEY (`ZAW_ID`) REFERENCES `ATP_ZAWODNIK` (`ZAW_ID`) ON DELETE RESTRICT ON UPDATE RESTRICT;

--
-- Ograniczenia dla tabeli `ATP_PARAMETRY`
--
ALTER TABLE `ATP_PARAMETRY`
  ADD CONSTRAINT `atp_parametry_ibfk_1` FOREIGN KEY (`ZAW_ID`) REFERENCES `ATP_ZAWODNIK` (`ZAW_ID`) ON DELETE RESTRICT ON UPDATE RESTRICT;

--
-- Ograniczenia dla tabeli `ATP_PUNKTY`
--
ALTER TABLE `ATP_PUNKTY`
  ADD CONSTRAINT `atp_punkty_ibfk_1` FOREIGN KEY (`ZAW_ID`) REFERENCES `ATP_ZAWODNIK` (`ZAW_ID`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  ADD CONSTRAINT `atp_punkty_ibfk_2` FOREIGN KEY (`TUR_ID`) REFERENCES `ATP_TURNIEJ` (`TUR_ID`) ON DELETE RESTRICT ON UPDATE RESTRICT;

--
-- Ograniczenia dla tabeli `ATP_TERMINARZ`
--
ALTER TABLE `ATP_TERMINARZ`
  ADD CONSTRAINT `atp_terminarz_ibfk_1` FOREIGN KEY (`TUR_ID`) REFERENCES `ATP_TURNIEJ` (`TUR_ID`) ON DELETE RESTRICT ON UPDATE RESTRICT;

--
-- Ograniczenia dla tabeli `ATP_TURNIEJ`
--
ALTER TABLE `ATP_TURNIEJ`
  ADD CONSTRAINT `atp_turniej_ibfk_1` FOREIGN KEY (`ZAS_RANGA`) REFERENCES `ATP_ZASADY` (`ZAS_RANGA`) ON DELETE RESTRICT ON UPDATE RESTRICT;

--
-- Ograniczenia dla tabeli `ATP_ZAWTRE`
--
ALTER TABLE `ATP_ZAWTRE`
  ADD CONSTRAINT `atp_zawtre_ibfk_1` FOREIGN KEY (`TRE_ID`) REFERENCES `ATP_TRENER` (`TRE_ID`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  ADD CONSTRAINT `atp_zawtre_ibfk_2` FOREIGN KEY (`ZAW_ID`) REFERENCES `ATP_ZAWODNIK` (`ZAW_ID`) ON DELETE RESTRICT ON UPDATE RESTRICT;

--
-- Ograniczenia dla tabeli `ATP_ZGLOSZENIA`
--
ALTER TABLE `ATP_ZGLOSZENIA`
  ADD CONSTRAINT `atp_zgloszenia_ibfk_1` FOREIGN KEY (`ZAW_ID`) REFERENCES `ATP_ZAWODNIK` (`ZAW_ID`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  ADD CONSTRAINT `atp_zgloszenia_ibfk_2` FOREIGN KEY (`TUR_ID`) REFERENCES `ATP_TURNIEJ` (`TUR_ID`) ON DELETE RESTRICT ON UPDATE RESTRICT;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
