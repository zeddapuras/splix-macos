#!/bin/sh
# Rimuove SpliX per macOS. Uso: sudo /Library/Printers/SpliX/uninstall.sh
# Le code di stampa create con SpliX NON vengono cancellate: rimuovile prima da
# Impostazioni di Sistema > Stampanti e scanner, altrimenti smetteranno di funzionare.
set -e
if [ "$(id -u)" != 0 ]; then echo "Esegui con sudo." >&2; exit 1; fi
rm -f /Library/Printers/PPDs/Contents/Resources/SpliX-*.ppd.gz
rm -rf /Library/Printers/SpliX
pkgutil --forget io.github.splix-macos.driver >/dev/null 2>&1 || true
echo "SpliX rimosso."
