{***************************************************************}
{ FIBPlus - component library for direct access to Firebird and }
{ InterBase databases                                           }
{                                                               }
{  Romanian error messages.                                     }
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
    'Eroare necunoscută.',
    'Funcționalitate nesuportată.',
    'Operație nepermisă.',
    'Eroare de acces la fișierul temporar.',
    'Conexiunea la baza de date a expirat.',
    'Baza de date nu poate fi setată.',
    'Tranzacția nu poate fi setată.',
    'Operație anulată la cererea utilizatorului.',
    'Constanta DPB (isc_dpb_%s) nu este suportată.',
    'Constanta DPB (%s) este necunoscută.',
    'Constanta TPB (isc_tpb_%s) nu este suportată.',
    'Constanta TPB (%s) este necunoscută.',
    '%s: Operația nu poate fi executată -- baza de date nu este deschisă.',
    'Operația nu poate fi executată -- baza de date este deschisă.',
    'Lipsește numele bazei de date.',
    '%s: Tranzacția nu este activă.',
    '%s: Tranzacția este activă.',
    'Valorile Timeout nu pot fi negative.',
    '%s: Componenta de tranzacție nu are nicio bază de date în listă.',
    '%s: Actualizare în baza de date greșită.',
    '%s: Actualizare în tranzacția greșită.',
    'Baza de date nu este atribuită pentru %s.',
    'Tranzacția nu este atribuită pentru %s.',
    'Indexul XSQLDA este în afara limitelor.',
    'Numele XSQLDA nu există (%s).',
    'Sfârșitul fișierului.',
    'Începutul fișierului.',
    '%s: Handle de instrucțiune invalid.',
    'Nu se poate %s deoarece setul de date %s este deschis.',
    'Nu se poate %s deoarece setul de date %s este închis.',
    'Tip de date SQL necunoscut (%d).',
    'Index de coloană invalid (indexul depășește limitele permise).',
    'Index de parametru invalid (indexul depășește limitele permise).',
    'Conversie de date invalidă.',
    'Coloana nu poate primi valoarea null (%s)',
    'Fluxul Blob nu poate fi citit.',
    'Fluxul Blob nu poate fi scris.',
    'Nu se poate %s deoarece interogarea este goală.',
    'Comanda "open" nu se poate executa pentru o instrucțiune care nu este SELECT. Folosiți ExecQuery.',
    'Nu există acces la câmpul "%s".',
    'Câmpul "%s" este doar pentru citire.',
    'Câmpul "%s" nu a fost găsit.',
    'Setul de date nu este în modul Edit sau Insert. (%s)',
    'Nu este în modul de editare.',
    'Nu se poate insera în setul de date. (%s)',
    'Nu se poate salva (post). (%s)',
    'Nu se poate actualiza (update). (%s)',
    'Nu se poate șterge din setul de date. (%s)',
    'Înregistrarea nu poate fi reîmprospătată (refresh). (%s)',
    'Bufferul nu este setat.',
    'Referințele circulare nu sunt permise. (%s)',
    'Eroare de analiză SQL în '+':%s ' + CRLF + CRLF + '%s',
    'Întrerupt de utilizator.',
    'Setul de date este unidirecțional.',
    'Resursa partajată nu poate fi creată. (eroare Windows %d)',
    'Eroare Windows API. (eroare Windows %d [$%.8x])',
    'Listele de coloane nu corespund.',
    'Tipurile coloanelor nu corespund. (De la indexul: %d, la indexul: %d)',
    'O tranzacție partajată poate fi încheiată doar forțat și cu acțiunea egală cu TimeoutAction a tranzacției.',
    'Coloana "%s" nu este un câmp de tip array', // feNotIsArrayField
    'Dimensiunea %d nu există în "%s"', // feWrongDimension
    'Dialect SQL invalid', // feSQLDialectInvalid
    'Biblioteca client Firebird nu a fost găsită. Instalați clientul Firebird pentru a folosi această funcționalitate', // feIBMissing
    '%s este o funcție InterBase 6. Actualizați la InterBase 6 pentru a folosi această funcționalitate',
    'Operația nu poate fi executată -- serviciul nu este conectat',
    'Operația nu poate fi executată -- serviciul este conectat',
    'Lipsește numele serverului',
    'Parametrii interogării lipsesc sau sunt incorecți',
    'Parametrii de pornire lipsesc sau sunt incorecți',
    'Valoare neașteptată în bufferul de ieșire',
    'ServiceStart generic nu se aplică: folosiți procedurile specifice pentru a seta parametrii de configurare',
    'Constanta SPB nu este suportată',
    'Constantă SPB necunoscută',
    'Dimensiunea câmpului este prea mică. Câmpul %s.%s',
    '%s. Cache-ul limitat nu poate fi folosit. '#13#10 +
      'CachedUpdates trebuie să fie False,'#13#10 +
      'Select trebuie să aibă clauza "Order by",'#13#10 +
      'Toate câmpurile de sortare trebuie să existe în secțiunea de câmpuri'#13#10 +
      'Select nu poate folosi parametri cu prefixul "NEW_"'#13#10 +
      'UpdateTransaction trebuie să fie egală cu Transaction sau AutoCommit=True',
    'Eroare în %s. FieldList este gol.',
    '%s nu poate folosi câmpul "%s"',
    '%s este o funcție Firebird 2. Actualizați la Firebird 2 pentru a folosi această funcționalitate',
    '%s nu este suportat de %s',
    '%s nu este suportat de biblioteca client %s',
    'Coloana array %s.%s nu a fost găsită',
    'Array %s.%s: numele %s este prea lung',
    'Array %s.%s: numărul de dimensiuni este %d, numărul de indecși dați este %d',
    'Array %s.%s: "%s" nu poate fi convertit la tipul elementelor',
    'Array %s.%s: tipul de element %d nu este suportat',
    'Array %s.%s: șirul "%s" depășește numărul permis de octeți (%d)',
    'Array %s.%s: valoarea nu este un array',
    'Array %s.%s: numărul de dimensiuni este %d, al valorii este %d',
    'Array %s.%s: dimensiunea valorii în octeți este %d în loc de %d',
    'Array %s.%s: indexul %d este în afara limitelor %d:%d ale dimensiunii %d',
    'Array %s.%s: limitele %d:%d ale dimensiunii %d nu încap în TISC_ARRAY_BOUND',
    'Array %s.%s: numărul de elemente al dimensiunii %d este %d, al valorii este %d',
    'Parametrul %s nu este un array',
    'Pagina de cod %d nu este disponibilă în acest sistem',
    'Caracterul nu poate fi convertit între seturile de caractere: "%s" în pagina de cod %d',
    '%s: Clauza ORDER BY nu a fost găsită sau nu a putut fi analizată.',
    '%s.' + CRLF + 'Câmpul %s este folosit în sortare, dar nu se află în câmpurile din SelectSQL',
    '%s: Metadatele nu au putut fi încărcate.',
    'Valoarea %s are %d octeți, maximul este %d',
    'Valoare nevalidă "%s" în %s',
    'Fișierul de blob-uri %s, parametrul %s: %s',
    '%s: datele lotului au setul de caractere %s, conexiunea are setul de caractere %s',
    'Valoarea %s conține un caracter pe care pagina de cod %d nu îl are'
  );
