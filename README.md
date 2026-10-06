# SpliX for macOS

**Printer driver for Samsung, Xerox, Dell, HP, Lexmark and Toshiba SPL laser printers, built natively for Apple Silicon and Intel Macs.**

🇮🇹 [Versione italiana più sotto](#italiano)

Many older Samsung laser printers stopped working on Apple Silicon Macs: the vendor driver (Samsung UPD, `rastertosec`) is Intel-only and crashes under Rosetta, so every job ends with **"Filter failed"**. This project packages the open source [SpliX](https://github.com/OpenPrinting/splix) driver from OpenPrinting as a native macOS installer, so these printers work again with the standard print dialog (⌘P).

- Universal binary (Apple Silicon + Intel), macOS 11 Big Sur or later
- 104 printer models, see the [list below](#supported-printers)
- Works over Wi-Fi/network (Bonjour) and USB

## Install

1. Download `SpliX-macOS-<version>.pkg` from the [latest release](https://github.com/zeddapuras/splix-macos/releases/latest).
2. Double-click it. The package is not signed with an Apple Developer ID, so macOS will block it the first time:
   open **System Settings → Privacy & Security**, scroll down and click **Open Anyway** next to the SpliX message, then confirm.
3. Follow the installer.

## Add your printer

1. If you already have a queue for this printer using the vendor driver, remove it first
   (**System Settings → Printers & Scanners**, select it, click **−**).
2. Click **Add Printer, Scanner or Fax…** and select your printer.
3. Under **Use**, choose **Select Software…** and pick your model ending with **(SpliX)**,
   e.g. *Samsung ML-2160 (SpliX)*.
4. Click **Add**.
5. Optional: on the same page set **Default printer** to your printer instead of *Last Printer Used*.

In the print dialog, always pick the **(SpliX)** printer. Do not pick the same printer under *Nearby Printers*: macOS would create a new queue with the old vendor driver.

## Troubleshooting

| Problem | Fix |
|---|---|
| A page with `INTERNAL ERROR: ILLEGALMEDIASIZE` comes out | The selected paper size is larger than the printer supports (e.g. A3). Use A4/Letter. This package already removes A3, Ledger and B4 from the paper list. |
| "Filter failed" | Check that the queue uses the *(SpliX)* driver: **Printers & Scanners → your printer → Options & Supplies → General**. |
| Nothing prints | Make sure the printer is on the same network. For details: `sudo cupsctl --debug-logging`, print again, then read `/var/log/cups/error_log`. |

## Uninstall

Remove the SpliX printer queues in **Printers & Scanners**, then run:

```sh
sudo /Library/Printers/SpliX/uninstall.sh
```

## What gets installed

- `/Library/Printers/SpliX/Filters/rastertoqpdl`, the SpliX CUPS filter
- `/Library/Printers/PPDs/Contents/Resources/SpliX-*.ppd.gz`, one printer description per model
- `/Library/Printers/SpliX/uninstall.sh` and the license

## Build from source

Requires the Xcode Command Line Tools (`xcode-select --install`). No Homebrew or sudo needed.

```sh
git clone https://github.com/zeddapuras/splix-macos.git
cd splix-macos/pkg
./build-pkg.sh
```

The script downloads and verifies jbigkit, builds a universal `rastertoqpdl`, generates all PPDs with `ppdc` and writes `pkg/dist/SpliX-macOS-<version>.pkg`. Set `SIGN_APP` / `SIGN_PKG` to Developer ID identities to sign it.

### Changes from upstream SpliX

The `splix/` folder is [OpenPrinting/splix @ 7a80218](https://github.com/OpenPrinting/splix/commit/7a80218) with one commit on top (see the git history):

- `module.mk`: on macOS, use `cups-config` and link `libcups` only (the raster API lives in libcups and there is no `cups.pc`), link jbigkit statically, allow universal builds through `ARCHFLAGS`.
- `ppd/spl2basic.defs`: remove the Ledger, A3 and B4 paper sizes. These printers go up to Legal and the firmware rejects bigger sizes.

## Supported printers

Tested on a **Samsung ML-2160** over Wi-Fi (macOS 26, Apple Silicon). The other models use the same SpliX driver as on Linux but have not been tested on macOS. Reports are welcome in [Issues](https://github.com/zeddapuras/splix-macos/issues).

- **Dell**: 1100, 1110
- **HP**: Laser 1003-1008, Laser 10x Series, Laser MFP 1136-1139 1188, Laser MFP 13x Series, LaserJet MFP M433, LaserJet MFP M436
- **Lexmark**: X215 MFP
- **Samsung**: CLP-200, CLP-300, CLP-310, CLP-310N, CLP-315, CLP-500, CLP-510, CLP-550, CLP-600, CLX-216X, CLX-2170, CLX-3160, M2020 Series, M2070 Series, M262x 282x Series, M267x 287x Series, M283x Series, ML-1510, ML-1520, ML-1610, ML-1630, ML-1640, ML-1660, ML-1670, ML-1710, ML-1740, ML-1750, ML-1860, ML-1865, ML-1865W Series, ML-1910, ML-1915, ML-2010, ML-2015, ML-2150, ML-2160, ML-2165, ML-2240, ML-2250, ML-2251, ML-2510, ML-2525, ML-2525W, ML-2550, ML-2571, ML-2580, ML-2580N, ML-3050, ML-3051, ML-3051ND, ML-3310, ML-3310ND, ML-3471ND, ML-3560, SCX-3200, SCX-3400, SCX-4100, SCX-4200, SCX-4216F, SCX-4300, SCX-4500, SCX-4521F, SCX-4600, SCX-4623f, SCX-4623fw, SCX-5330N, SCX-5530FN, SF-565P
- **Toshiba**: eSTUDIO180S
- **Xerox**: Phaser 3020, Phaser 3052, Phaser 3115, Phaser 3116, Phaser 3117, Phaser 3120, Phaser 3121, Phaser 3122, Phaser 3124, Phaser 3130, Phaser 3140, Phaser 3150, Phaser 3155, Phaser 3160, Phaser 3260, Phaser 3420, Phaser 3425, Phaser 5500, Phaser 6100, Phaser 6110, WorkCentre 3025, WorkCentre 3119, WorkCentre 3215, WorkCentre 3225, WorkCentre PE114e, WorkCentre PE16

Color models (CLP/CLX, Phaser 6100/6110) may need color profile files that this package does not include.

## License and credits

[GNU GPL v2](COPYING). SpliX is by Aurélien Croc and contributors, maintained by [OpenPrinting](https://github.com/OpenPrinting/splix). jbigkit is by Markus Kuhn (GPL v2+).
This is an unofficial build, not affiliated with Samsung, HP, Xerox or any other printer manufacturer.

---

## Italiano

**Driver per stampanti laser SPL di Samsung, Xerox, Dell, HP, Lexmark e Toshiba, compilato nativamente per Mac Apple Silicon e Intel.**

Molte stampanti laser Samsung non funzionano più sui Mac Apple Silicon: il driver del produttore (Samsung UPD, `rastertosec`) esiste solo per Intel e va in crash sotto Rosetta, così ogni stampa finisce con **"Filter failed"**. Questo progetto confeziona il driver open source [SpliX](https://github.com/OpenPrinting/splix) di OpenPrinting come installer per macOS: queste stampanti tornano a funzionare dal normale dialogo di stampa (⌘P).

### Installazione

1. Scarica `SpliX-macOS-<versione>.pkg` dall'[ultima release](https://github.com/zeddapuras/splix-macos/releases/latest).
2. Fai doppio clic. Il pacchetto non è firmato con un Developer ID Apple, quindi la prima volta macOS lo blocca:
   apri **Impostazioni di Sistema → Privacy e sicurezza**, scorri in basso e fai clic su **Apri comunque** accanto al messaggio su SpliX, poi conferma.
3. Segui l'installer.

### Aggiungere la stampante

1. Se hai già una coda per questa stampante con il driver del produttore, rimuovila
   (**Impostazioni di Sistema → Stampanti e scanner**, selezionala, fai clic su **−**).
2. Fai clic su **Aggiungi stampante, scanner o fax…** e seleziona la stampante.
3. Alla voce **Usa**, scegli **Seleziona software…** e il tuo modello che termina con **(SpliX)**,
   es. *Samsung ML-2160 (SpliX)*.
4. Fai clic su **Aggiungi**.
5. Facoltativo: nella stessa pagina imposta **Stampante di default** sulla tua stampante invece di *Ultima stampante utilizzata*.

Nel dialogo di stampa scegli sempre la stampante **(SpliX)**. Non scegliere la stessa stampante sotto *Stampanti vicine*: macOS creerebbe una nuova coda con il vecchio driver del produttore.

### Problemi comuni

- **Esce un foglio con `INTERNAL ERROR: ILLEGALMEDIASIZE`**: il formato scelto è più grande di quello supportato (es. A3). Usa A4.
- **"Filter failed"**: controlla che la coda usi il driver *(SpliX)*.
- **Non stampa nulla**: verifica che la stampante sia sulla stessa rete. Per i dettagli: `sudo cupsctl --debug-logging`, ristampa e leggi `/var/log/cups/error_log`.

### Disinstallazione

Rimuovi le code SpliX da **Stampanti e scanner**, poi esegui:

```sh
sudo /Library/Printers/SpliX/uninstall.sh
```

Le istruzioni per compilare dai sorgenti e l'elenco dei modelli sono nella parte inglese qui sopra.
