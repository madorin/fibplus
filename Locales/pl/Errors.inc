{***************************************************************}
{ FIBPlus - component library for direct access to Firebird and }
{ InterBase databases                                           }
{                                                               }
{  Polish error messages.                                       }
{                                                               }
{    FIBPlus is based in part on the product                    }
{    Free IB Components, written by Gregory H. Deatz for        }
{    Hoagland, Longo, Moran, Dunst & Doukas Company.            }
{    mailto:gdeatz@hlmdd.com                                    }
{                                                               }
{    Copyright (c) 1998-2007 Devrace Ltd.                       }
{    Written by Serge Buzadzhy                                  }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}

  FIBErrorMessages: array[TFIBClientError] of string = (
    'Nieznany błąd.',
    'Nieobsługiwana funkcja.',
    'Niedozwolone.',
    'Błąd dostępu do pliku tymczasowego.',
    'Upłynął limit czasu połączenia z bazą danych.',
    'Nie można ustawić bazy danych.',
    'Nie można ustawić transakcji.',
    'Operacja anulowana na żądanie użytkownika.',
    'Stała DPB (isc_dpb_%s) nie jest obsługiwana.',
    'Stała DPB (%s) jest nieznana.',
    'Stała TPB (isc_tpb_%s) nie jest obsługiwana.',
    'Stała TPB (%s) jest nieznana.',
    '%s: Nie można wykonać operacji -- baza danych nie jest otwarta.',
    'Nie można wykonać operacji -- baza danych jest otwarta.',
    'Brak nazwy bazy danych.',
    '%s: Transakcja nie jest aktywna.',
    '%s: Transakcja jest aktywna.',
    'Wartości Timeout nie mogą być ujemne.',
    '%s: W komponencie transakcji nie podano żadnej bazy danych.',
    '%s: Aktualizacja niewłaściwej bazy danych.',
    '%s: Aktualizacja niewłaściwej transakcji.',
    'Nie przypisano bazy danych dla %s.',
    'Nie przypisano transakcji dla %s.',
    'Indeks XSQLDA poza zakresem.',
    'Nazwa XSQLDA nie istnieje (%s).',
    'Koniec pliku.',
    'Początek pliku.',
    '%s: Nieprawidłowy uchwyt (handle) polecenia.',
    'Nie można wykonać %s, ponieważ zbiór danych %s jest otwarty.',
    'Nie można wykonać %s, ponieważ zbiór danych %s jest zamknięty.',
    'Nieznany typ danych SQL (%d).',
    'Nieprawidłowy indeks kolumny (indeks przekracza dozwolony zakres).',
    'Nieprawidłowy indeks parametru (indeks przekracza dozwolony zakres).',
    'Nieprawidłowa konwersja danych.',
    'Kolumna nie może mieć wartości null (%s)',
    'Nie można odczytać strumienia Blob.',
    'Nie można zapisać strumienia Blob.',
    'Nie można wykonać %s, ponieważ zapytanie jest puste.',
    'Nie można wykonać "open" dla polecenia, które nie jest SELECT. Użyj ExecQuery.',
    'Brak dostępu do pola "%s".',
    'Pole "%s" jest tylko do odczytu.',
    'Nie znaleziono pola "%s".',
    'Zbiór danych nie jest w trybie Edit ani Insert. (%s)',
    'Brak trybu edycji.',
    'Nie można wstawić do zbioru danych. (%s)',
    'Nie można zapisać (post). (%s)',
    'Nie można zaktualizować (update). (%s)',
    'Nie można usunąć ze zbioru danych. (%s)',
    'Nie można odświeżyć rekordu (refresh). (%s)',
    'Bufor nie jest ustawiony.',
    'Odwołania cykliczne są niedozwolone. (%s)',
    'Błąd analizy składni SQL w '+':%s ' + CRLF + CRLF + '%s',
    'Przerwane przez użytkownika.',
    'Zbiór danych jest jednokierunkowy.',
    'Nie można utworzyć zasobu współdzielonego. (błąd Windows %d)',
    'Błąd Windows API. (błąd Windows %d [$%.8x])',
    'Listy kolumn nie są zgodne.',
    'Typy kolumn nie są zgodne. (Z indeksu: %d, do indeksu: %d)',
    'Transakcję współdzieloną można zakończyć tylko w sposób wymuszony i z akcją równą jej TimeoutAction.',
    'Kolumna "%s" nie jest polem typu array', // feNotIsArrayField
    'Wymiar %d nie istnieje w "%s"', // feWrongDimension
    'Nieprawidłowy dialekt SQL', // feSQLDialectInvalid
    'Nie znaleziono biblioteki klienckiej Firebird. Zainstaluj klienta Firebird, aby korzystać z tej funkcji', // feIBMissing
    '%s jest funkcją InterBase 6. Zaktualizuj do InterBase 6, aby korzystać z tej funkcji',
    'Nie można wykonać operacji -- usługa nie jest podłączona',
    'Nie można wykonać operacji -- usługa jest podłączona',
    'Brak nazwy serwera',
    'Brak parametrów zapytania lub są nieprawidłowe',
    'Brak parametrów uruchomienia lub są nieprawidłowe',
    'Nieoczekiwana wartość w buforze wyjściowym',
    'Ogólne ServiceStart nie ma zastosowania: użyj odpowiednich procedur, aby ustawić parametry konfiguracji',
    'Stała SPB nie jest obsługiwana',
    'Nieznana stała SPB',
    'Za mały rozmiar pola. Pole %s.%s',
    '%s. Nie można użyć ograniczonej pamięci podręcznej. '#13#10 +
      'CachedUpdates musi mieć wartość False,'#13#10 +
      'Select musi mieć klauzulę "Order by",'#13#10 +
      'Wszystkie pola sortowania muszą istnieć w sekcji pól'#13#10 +
      'Select nie może używać parametrów z prefiksem "NEW_"'#13#10 +
      'UpdateTransaction musi być równa Transaction lub AutoCommit=True',
    'Błąd w %s. FieldList jest pusta.',
    '%s nie może użyć pola "%s"',
    '%s jest funkcją Firebird 2. Zaktualizuj do Firebird 2, aby korzystać z tej funkcji',
    '%s nie jest obsługiwane przez %s',
    '%s nie jest obsługiwane przez bibliotekę kliencką %s',
    'Nie znaleziono kolumny typu array %s.%s',
    'Array %s.%s: nazwa %s jest za długa',
    'Array %s.%s: liczba wymiarów wynosi %d, liczba podanych indeksów wynosi %d',
    'Array %s.%s: nie można przekonwertować "%s" na typ elementów',
    'Array %s.%s: typ elementu %d nie jest obsługiwany',
    'Array %s.%s: ciąg "%s" przekracza dozwoloną liczbę bajtów (%d)',
    'Array %s.%s: wartość nie jest tablicą',
    'Array %s.%s: liczba wymiarów wynosi %d, a wartości %d',
    'Array %s.%s: rozmiar wartości w bajtach wynosi %d zamiast %d',
    'Array %s.%s: indeks %d jest poza granicami %d:%d wymiaru %d',
    'Array %s.%s: granice %d:%d wymiaru %d nie mieszczą się w TISC_ARRAY_BOUND',
    'Array %s.%s: liczba elementów wymiaru %d wynosi %d, a wartości %d',
    'Parametr %s nie jest tablicą',
    'Strona kodowa %d nie jest dostępna w tym systemie',
    'Nie można przekonwertować znaku między zestawami znaków: "%s" na stronę kodową %d',
    '%s: Nie można znaleźć lub przeanalizować klauzuli ORDER BY.',
    '%s.' + CRLF + 'Pole %s jest użyte w sortowaniu, ale nie ma go w polach SelectSQL',
    '%s: Nie można załadować metadanych.',
    'Wartość %s ma %d bajtów, maksimum to %d',
    'Nieprawidłowa wartość "%s" w %s',
    'Plik blobów %s, parametr %s: %s',
    '%s: dane wsadowe mają zestaw znaków %s, połączenie zestaw znaków %s',
    'Wartość %s zawiera znak, którego nie ma strona kodowa %d',
    '%s: wersja formatu %d nie jest obsługiwana, maksymalna to %d'
  );
