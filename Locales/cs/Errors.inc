{***************************************************************}
{ FIBPlus - component library for direct access to Firebird and }
{ InterBase databases                                           }
{                                                               }
{  Czech error messages.                                        }
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
    'Neznámá chyba.',
    'Nepodporovaná funkce.',
    'Nepovoleno.',
    'Chyba přístupu k dočasnému souboru.',
    'Vypršel časový limit připojení k databázi.',
    'Databázi nelze nastavit.',
    'Transakci nelze nastavit.',
    'Operace byla zrušena na žádost uživatele.',
    'Konstanta DPB (isc_dpb_%s) není podporována.',
    'Konstanta DPB (%s) je neznámá.',
    'Konstanta TPB (isc_tpb_%s) není podporována.',
    'Konstanta TPB (%s) je neznámá.',
    '%s: Operaci nelze provést -- databáze není otevřena.',
    'Operaci nelze provést -- databáze je otevřena.',
    'Chybí název databáze.',
    '%s: Transakce není aktivní.',
    '%s: Transakce je aktivní.',
    'Hodnoty Timeout nemohou být záporné.',
    '%s: Komponenta transakce nemá uvedenu žádnou databázi.',
    '%s: Aktualizace nesprávné databáze.',
    '%s: Aktualizace nesprávné transakce.',
    'Pro %s není přiřazena databáze.',
    'Pro %s není přiřazena transakce.',
    'Index XSQLDA je mimo rozsah.',
    'Název XSQLDA neexistuje (%s).',
    'Konec souboru.',
    'Začátek souboru.',
    '%s: Neplatný handle příkazu.',
    'Nelze provést %s, protože dataset %s je otevřen.',
    'Nelze provést %s, protože dataset %s je zavřen.',
    'Neznámý datový typ SQL (%d).',
    'Neplatný index sloupce (index je mimo povolený rozsah).',
    'Neplatný index parametru (index je mimo povolený rozsah).',
    'Neplatný převod dat.',
    'Sloupec nemůže mít hodnotu null (%s)',
    'Blob stream nelze číst.',
    'Do Blob streamu nelze zapisovat.',
    'Nelze provést %s, protože dotaz je prázdný.',
    'Příkaz, který není SELECT, nelze otevřít ("open"). Použijte ExecQuery.',
    'Není přístup k poli "%s".',
    'Pole "%s" je pouze pro čtení.',
    'Pole "%s" nebylo nalezeno.',
    'Dataset není v režimu Edit nebo Insert. (%s)',
    'Neprobíhá editace.',
    'Do datasetu nelze vložit záznam. (%s)',
    'Nelze uložit (post). (%s)',
    'Nelze aktualizovat (update). (%s)',
    'Z datasetu nelze mazat. (%s)',
    'Záznam nelze znovu načíst (refresh). (%s)',
    'Buffer není nastaven.',
    'Cyklické odkazy nejsou povoleny. (%s)',
    'Chyba syntaktické analýzy SQL v '+':%s ' + CRLF + CRLF + '%s',
    'Přerušeno uživatelem.',
    'Dataset je jednosměrný.',
    'Sdílený prostředek nelze vytvořit. (chyba Windows %d)',
    'Chyba Windows API. (chyba Windows %d [$%.8x])',
    'Seznamy sloupců si neodpovídají.',
    'Typy sloupců si neodpovídají. (Z indexu: %d, do indexu: %d)',
    'Sdílenou transakci lze ukončit jen vynuceně a s akcí rovnou její TimeoutAction.',
    'Sloupec "%s" není pole typu array', // feNotIsArrayField
    'Rozměr %d v "%s" neexistuje', // feWrongDimension
    'Neplatný dialekt SQL', // feSQLDialectInvalid
    'Klientská knihovna Firebird nebyla nalezena. Pro použití této funkce nainstalujte klienta Firebird', // feIBMissing
    '%s je funkce InterBase 6. Pro použití této funkce přejděte na InterBase 6',
    'Operaci nelze provést -- služba není připojena',
    'Operaci nelze provést -- služba je připojena',
    'Chybí název serveru',
    'Parametry dotazu chybí nebo jsou nesprávné',
    'Parametry spuštění chybí nebo jsou nesprávné',
    'Neočekávaná hodnota ve výstupním bufferu',
    'Obecný ServiceStart nelze použít: pro nastavení konfiguračních parametrů použijte specifické procedury',
    'Konstanta SPB není podporována',
    'Neznámá konstanta SPB',
    'Velikost pole je příliš malá. Pole %s.%s',
    '%s. Omezenou cache nelze použít. '#13#10 +
      'CachedUpdates musí být False,'#13#10 +
      'Select musí mít klauzuli "Order by",'#13#10 +
      'Všechna pole řazení musí existovat v sekci polí'#13#10 +
      'Select nemůže používat parametry s předponou "NEW_"'#13#10 +
      'UpdateTransaction musí být rovna Transaction nebo AutoCommit=True',
    'Chyba v %s. FieldList je prázdný.',
    '%s nemůže použít pole "%s"',
    '%s je funkce Firebird 2. Pro použití této funkce přejděte na Firebird 2',
    '%s není podporováno v %s',
    '%s není podporováno klientskou knihovnou %s',
    'Sloupec typu array %s.%s nebyl nalezen',
    'Array %s.%s: název %s je příliš dlouhý',
    'Array %s.%s: počet rozměrů je %d, počet zadaných indexů je %d',
    'Array %s.%s: "%s" nelze převést na typ prvků',
    'Array %s.%s: typ prvku %d není podporován',
    'Array %s.%s: řetězec "%s" je delší než povolený počet bajtů (%d)',
    'Array %s.%s: hodnota není typu array',
    'Array %s.%s: počet rozměrů je %d, hodnota jich má %d',
    'Array %s.%s: velikost hodnoty v bajtech je %d místo %d',
    'Array %s.%s: index %d je mimo meze %d:%d rozměru %d',
    'Array %s.%s: meze %d:%d rozměru %d se nevejdou do TISC_ARRAY_BOUND',
    'Array %s.%s: počet prvků rozměru %d je %d, hodnota jich má %d',
    'Parametr %s není typu array',
    'Kódová stránka %d není v tomto systému k dispozici',
    'Znak nelze převést mezi znakovými sadami: "%s" do kódové stránky %d',
    '%s: Klauzuli ORDER BY nelze najít nebo zpracovat.',
    '%s.' + CRLF + 'Pole %s je použito v řazení, ale není v polích SelectSQL',
    '%s: Metadata nelze načíst.',
    'Hodnota %s má %d bajtů, maximum je %d',
    'Neplatná hodnota "%s" v %s',
    'Soubor blobů %s, parametr %s: %s',
    '%s: dávková data mají znakovou sadu %s, připojení má znakovou sadu %s'
  );
