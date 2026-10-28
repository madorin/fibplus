{***************************************************************}
{ FIBPlus - component library for direct access to Firebird and }
{ InterBase databases                                           }
{                                                               }
{  German error messages.                                       }
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
    'Unbekannter Fehler.',
    'Nicht unterstützte Funktion.',
    'Nicht zulässig.',
    'Fehler beim Zugriff auf die temporäre Datei.',
    'Zeitüberschreitung der Datenbankverbindung.',
    'Die Datenbank kann nicht gesetzt werden.',
    'Die Transaktion kann nicht gesetzt werden.',
    'Vorgang auf Wunsch des Benutzers abgebrochen.',
    'DPB-Konstante (isc_dpb_%s) wird nicht unterstützt.',
    'DPB-Konstante (%s) ist unbekannt.',
    'TPB-Konstante (isc_tpb_%s) wird nicht unterstützt.',
    'TPB-Konstante (%s) ist unbekannt.',
    '%s: Vorgang nicht möglich -- die Datenbank ist nicht geöffnet.',
    'Vorgang nicht möglich -- die Datenbank ist geöffnet.',
    'Der Datenbankname fehlt.',
    '%s: Die Transaktion ist nicht aktiv.',
    '%s: Die Transaktion ist aktiv.',
    'Timeout-Werte dürfen nicht negativ sein.',
    '%s: In der Transaktionskomponente sind keine Datenbanken angegeben.',
    '%s: Aktualisierung der falschen Datenbank.',
    '%s: Aktualisierung der falschen Transaktion.',
    'Keine Datenbank für %s zugewiesen.',
    'Keine Transaktion für %s zugewiesen.',
    'XSQLDA-Index außerhalb des gültigen Bereichs.',
    'XSQLDA-Name existiert nicht (%s).',
    'Dateiende.',
    'Dateianfang.',
    '%s: Ungültiges Anweisungs-Handle.',
    '%s nicht möglich, weil die Datenmenge %s geöffnet ist.',
    '%s nicht möglich, weil die Datenmenge %s geschlossen ist.',
    'Unbekannter SQL-Datentyp (%d).',
    'Ungültiger Spaltenindex (Index außerhalb des zulässigen Bereichs).',
    'Ungültiger Parameterindex (Index außerhalb des zulässigen Bereichs).',
    'Ungültige Datenkonvertierung.',
    'Die Spalte darf nicht auf NULL gesetzt werden (%s)',
    'Der Blob-Stream kann nicht gelesen werden.',
    'Der Blob-Stream kann nicht geschrieben werden.',
    '%s nicht möglich, weil die Abfrage leer ist.',
    '"Open" ist für eine Anweisung ohne SELECT nicht möglich. Verwenden Sie ExecQuery.',
    'Kein Zugriff auf das Feld "%s".',
    'Das Feld "%s" ist schreibgeschützt.',
    'Das Feld "%s" wurde nicht gefunden.',
    'Die Datenmenge ist nicht im Modus Edit oder Insert. (%s)',
    'Keine Bearbeitung aktiv.',
    'Einfügen in die Datenmenge nicht möglich. (%s)',
    'Speichern (Post) nicht möglich. (%s)',
    'Aktualisieren (Update) nicht möglich. (%s)',
    'Löschen aus der Datenmenge nicht möglich. (%s)',
    'Der Datensatz kann nicht neu gelesen werden (Refresh). (%s)',
    'Puffer nicht gesetzt.',
    'Zirkuläre Verweise sind nicht zulässig. (%s)',
    'SQL-Analysefehler in '+':%s ' + CRLF + CRLF + '%s',
    'Abbruch durch den Benutzer.',
    'Die Datenmenge ist unidirektional.',
    'Die gemeinsame Ressource kann nicht erstellt werden. (Windows-Fehler %d)',
    'Windows-API-Fehler. (Windows-Fehler %d [$%.8x])',
    'Die Spaltenlisten stimmen nicht überein.',
    'Die Spaltentypen stimmen nicht überein. (Von Index: %d, nach Index: %d)',
    'Eine gemeinsame Transaktion kann nur erzwungen und mit einer Aktion gleich ihrer TimeoutAction beendet werden.',
    'Die Spalte "%s" ist kein Array-Feld', // feNotIsArrayField
    'Die Dimension %d existiert nicht in "%s"', // feWrongDimension
    'Ungültiger SQL-Dialekt', // feSQLDialectInvalid
    'Firebird-Clientbibliothek nicht gefunden. Installieren Sie den Firebird-Client, um diese Funktion zu verwenden', // feIBMissing
    '%s ist eine Funktion von InterBase 6. Aktualisieren Sie auf InterBase 6, um diese Funktion zu verwenden',
    'Vorgang nicht möglich -- der Dienst ist nicht verbunden',
    'Vorgang nicht möglich -- der Dienst ist verbunden',
    'Der Servername fehlt',
    'Abfrageparameter fehlen oder sind falsch',
    'Startparameter fehlen oder sind falsch',
    'Unerwarteter Wert im Ausgabepuffer',
    'Allgemeines ServiceStart nicht anwendbar: Verwenden Sie die spezifischen Prozeduren, um die Konfigurationsparameter zu setzen',
    'SPB-Konstante wird nicht unterstützt',
    'Unbekannte SPB-Konstante',
    'Feldgröße zu klein. Feld %s.%s',
    '%s. Der begrenzte Cache kann nicht verwendet werden. '#13#10 +
      'CachedUpdates muss False sein,'#13#10 +
      'Select muss eine "Order by"-Klausel haben,'#13#10 +
      'Alle Sortierfelder müssen im Feldbereich vorhanden sein'#13#10 +
      'Select darf keine Parameter mit dem Präfix "NEW_" verwenden'#13#10 +
      'UpdateTransaction muss gleich Transaction sein oder AutoCommit=True',
    'Fehler in %s. FieldList ist leer.',
    '%s kann das Feld "%s" nicht verwenden',
    '%s ist eine Funktion von Firebird 2. Aktualisieren Sie auf Firebird 2, um diese Funktion zu verwenden',
    '%s wird von %s nicht unterstützt',
    '%s wird von der Clientbibliothek %s nicht unterstützt',
    'Array-Spalte %s.%s nicht gefunden',
    'Array %s.%s: der Name %s ist zu lang',
    'Array %s.%s hat %d Dimension(en), %d Index(e) angegeben',
    'Array %s.%s: "%s" kann nicht in den Elementtyp konvertiert werden',
    'Array %s.%s: Elementtyp %d wird nicht unterstützt',
    'Array %s.%s: die Zeichenkette "%s" ist länger als %d Bytes',
    'Array %s.%s: der Wert ist kein Array',
    'Array %s.%s hat %d Dimension(en), der Wert hat %d',
    'Array %s.%s: der Wert hat %d Bytes statt %d',
    'Array %s.%s: Index %d liegt außerhalb der Grenzen %d:%d der Dimension %d',
    'Array %s.%s: die Grenzen %d:%d der Dimension %d passen nicht in TISC_ARRAY_BOUND',
    'Array %s.%s: Dimension %d hat %d Element(e), der Wert hat %d',
    'Parameter %s ist kein Array',
    'Codepage %d ist auf diesem System nicht verfügbar',
    'Zeichen kann nicht zwischen Zeichensätzen umgewandelt werden: "%s" in Codepage %d',
    '%s: Die ORDER BY-Klausel wurde nicht gefunden oder kann nicht analysiert werden.',
    '%s.' + CRLF + 'Das Feld %s wird in der Sortierung verwendet, ist aber nicht in den Feldern von SelectSQL',
    '%s: Die Metadaten können nicht geladen werden.',
    'Der Wert von %s hat %d Bytes, das Maximum ist %d',
    'Ungültiger Wert "%s" in %s',
    'Blob-Datei %s, Parameter %s: %s'
  );
