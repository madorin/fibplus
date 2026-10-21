# Localization

FIBPlus raises its own errors (`EFIBClientError`) with texts from a table of messages, and shows a login dialog with its own captions. Both exist in several languages, and you choose one when you build FIBPlus. This article shows which texts are translated, how to choose the language, how to handle errors without depending on their text, and how to add a new language.

## What is translated

| Text | File in `Locales\<code>` | Translated |
|------|--------------------------|------------|
| Errors raised by FIBPlus itself (`EFIBClientError`) | `Errors.inc` | Yes, in the languages below |
| Login dialog, VCL (`FIBDBLoginDlg`) and FMX (`FIB_FMX_DBLoginDlg`) | `LoginDlg.inc` | Yes, in the languages below |
| Other FIBPlus exceptions: update errors, connection and parameter errors, event alerter, scripter, SQL parser details and others | none, `resourcestring` in `FIBConsts`, `SIBGlobals`, `FIBEventAlerter`, or the code of the units | No, English; see [Other texts](#other-texts) |
| Server errors (`EFIBInterBaseError`) | none, from Firebird | No: Firebird has only English messages; see [Server messages](#server-messages) |
| Design time editors and IDE tools | none, `dclFIB`, `dclFIBTools` | No, English |

## Languages

| Language | Code |
|----------|------|
| English (the default) | `en` |
| Czech | `cs` |
| German | `de` |
| Spanish | `es` |
| Polish | `pl` |
| Portuguese (Brazil) | `pt-BR` |
| Romanian | `ro` |
| Russian | `ru` |
| Ukrainian | `uk` |

The code is the [ISO 639-1](https://en.wikipedia.org/wiki/List_of_ISO_639_language_codes) code of the language, with the country after a hyphen when the language differs by country (`pt-BR`), like the locale names of Windows (`ro-RO`, `pt-BR`). It is also the name of the folder of the language in `Locales`.

Technical names stay in English in every language: component, property and method names (`CachedUpdates`, `ExecQuery`), dataset states (`Edit`, `Insert`) and operations (`post`, `refresh`).

## Choose the language

1. Open `Source\FIBLocale.inc` and set `FIBLocale` to the code of the language, for example:

   ```delphi
   FIBLocale = 'ro';
   ```

2. Rebuild the FIBPlus packages and your application with **Build**, so `FIB.pas` and `FIBConsts.pas` are compiled again.

With the value above, `TFIBQuery.FieldByName` with a missing field raises:

```
Câmpul "NAME" nu a fost găsit.
```

and the login dialog has the caption **Conectare la baza de date**, with the fields **Utilizator**, **Parolă** and **Rol**.

### Requirements and limits

- One language per build. The language is chosen at compile time; an application can't switch it at run time.
- A code that is not in the table, for example `'rus'`, stops the build with `Unknown FIBLocale in FIBLocale.inc`. The code is case-sensitive: `'RO'` is not `'ro'`.
- `FIB.pas` and `FIBConsts.pas` include the files from `..\Locales`, relative to their own folder. Keep the `Locales` folder next to `Source`; without it the build stops with `F1026 File not found`.
- `FIBLocale.inc` is part of FIBPlus: when you update FIBPlus, set the value again if the new copy overwrote it, as for `FIB.inc`.
- Every translation is in UTF-8 and compiles to the same text on any Windows code page.

### Read the locale at run time

`FIBLocale` is a public constant of the unit `FIB`, so an application can show or log the language it was built with:

```delphi
Writeln('FIBPlus messages: ', FIBLocale);
```

## Handle errors without the text

Don't compare the message of an exception with a string: it changes with the language. Test the class and the code instead. For an error raised by FIBPlus, `SQLCode` is the ordinal of its `TFIBClientError` value (unit `FIB`). In the sample, `Query` is a `TFIBQuery`.

```delphi
try
  Value := Query.FieldByName('NAME').AsString;
except
  on E: EFIBClientError do
    if E.SQLCode = Ord(feFieldNotFound) then
      Value := ''
    else
      raise;
end;
```

For server errors, use `EFIBError.HasErrorCode`, `SQLCode` or `SQLState`, or the error kinds of `TFIBErrorHandler`; see [Error handling](events-and-monitoring.md#error-handling).

## Server messages

Firebird ships its error messages only in English. To show them in the language of the application, replace them with `TFIBErrorHandler`:

- `OnFIBErrorEvent` gets every server error with its kind (`keUniqueViolation`, `keForeignKey`, `keStatementTimeout` and others) and can change `ErrorValue.Message`; see [Handle errors by kind](events-and-monitoring.md#handle-errors-by-kind).
- The table `FIB$ERROR_MESSAGES` stores your own text for each constraint, in any language; see [Custom messages for constraints](events-and-monitoring.md#custom-messages-for-constraints).

## Other texts

The other exceptions of FIBPlus are in English, and some translated messages contain an English part from their caller: the detail of a SQL parse error (`feSQLParseError`) and the name of an operation such as `Prepare` (`feEmptyQuery`). Most of these texts are `resourcestring` constants. Translate them as you translate the `resourcestring` constants of the VCL and of your own units: with resource DLLs (the standard localization of Delphi, loaded by the RTL for the user's language) or with a third-party translation tool. These texts don't depend on `FIBLocale`.

The texts of `LoginDlg.inc` are `resourcestring` constants too (`SLoginDlgCaption`, `SLoginDlgUserName` and the others, in `FIBConsts`), so a resource DLL can still replace them.

## Add a language

1. Copy `Locales\en` to `Locales\<code>`, with the code of the language as the folder name, as described in [Languages](#languages).
2. Translate the strings of `Errors.inc` and `LoginDlg.inc`. Keep:
   - the order and the number of the messages in `Errors.inc`: there is one for each value of `TFIBClientError`, and the compiler stops when the count differs;
   - every `%s`, `%d` and `%.8x`, in the same order as in English: `Format` fills them by position: an extra one or one of another type raises `EConvertError` instead of the message, and a missing one drops its value from the text;
   - in `LoginDlg.inc`, one `&` before a different letter in each caption of the dialog: it marks the hotkey of the field or button;
   - `''` for an apostrophe inside a string;
   - the files in UTF-8 with BOM and CRLF line ends.
3. Add a `{$ELSEIF FIBLocale = '<code>'}` branch with the include of the file to `Source\FIB.pas` (`Errors.inc`) and to `Source\FIBConsts.pas` (`LoginDlg.inc`), in the alphabetical order of the codes. Add the code to the list in the comment above `FIBLocale` in `Source\FIBLocale.inc`, to the [Languages](#languages) table of this article and to the language note of `README.md`.
4. Set `FIBLocale` to the new code, build and check a few messages and the login dialog, then send a pull request to the [FIBPlus repository](https://github.com/madorin/fibplus) with `FIBLocale` set back to `'en'`.

A native speaker who uses FIBPlus is the best reviewer of a translation; corrections to the existing ones are welcome the same way.

## See also

- [Events and monitoring](events-and-monitoring.md#error-handling): `TFIBErrorHandler` and server errors
- [Upgrading](upgrading.md#800): `Source\FIB_MESSAGES.INC` moved to `Locales\en\Errors.inc`, renamed constants of the login dialog
