#!/bin/sh
#
# build-pkg.sh — Costruisce SpliX-macOS.pkg (filtro universale arm64+x86_64 + PPD
# di tutti i modelli SpliX) partendo dai sorgenti.
#
# Uso:   ./build-pkg.sh
# Variabili opzionali:
#   PKG_ID       identificativo del pacchetto (default io.github.splix-macos.driver)
#   PKG_VERSION  versione del pacchetto      (default 2.0.0.1)
#   SIGN_APP     "Developer ID Application: ..." per firmare il filtro (opzionale)
#   SIGN_PKG     "Developer ID Installer: ..."   per firmare il .pkg   (opzionale)
#
# Requisiti: Xcode Command Line Tools, git, curl. Nessun sudo.
#
set -eu

HERE=$(cd "$(dirname "$0")" && pwd)
SPLIX="$HERE/../splix"
WORK="$HERE/build"
OUT="$HERE/dist"
PKG_ID=${PKG_ID:-io.github.splix-macos.driver}
PKG_VERSION=${PKG_VERSION:-2.0.0.1}
ARCHFLAGS="-arch arm64 -arch x86_64 -mmacosx-version-min=11.0"

JBIG_URL=https://www.cl.cam.ac.uk/~mgk25/jbigkit/download/jbigkit-2.1.tar.gz
JBIG_SHA=de7106b6bfaf495d6865c7dd7ac6ca1381bd12e0d81405ea81e7f2167263d932

# Percorsi di installazione sul Mac dell'utente
FILTER_DIR=/Library/Printers/SpliX/Filters
PPD_DIR=/Library/Printers/PPDs/Contents/Resources

rm -rf "$WORK" "$OUT"
mkdir -p "$WORK" "$OUT"

echo "==> 1/5 jbigkit (libjbig85.a universale)"
cd "$WORK"
curl -fsSL -o jbigkit.tar.gz "$JBIG_URL"
echo "$JBIG_SHA  jbigkit.tar.gz" | shasum -a 256 -c -
tar xzf jbigkit.tar.gz
mkdir -p jbig/lib jbig/include
(cd jbigkit-2.1/libjbig &&
    clang -O2 $ARCHFLAGS -c jbig85.c jbig_ar.c &&
    ar crs "$WORK/jbig/lib/libjbig85.a" jbig85.o jbig_ar.o 2>/dev/null &&
    cp jbig85.h jbig_ar.h "$WORK/jbig/include/")

echo "==> 2/5 SpliX (rastertoqpdl universale)"
cd "$SPLIX"
make clean >/dev/null 2>&1 || true
make CC=clang CXX=clang++ JBIGDIR="$WORK/jbig" ARCHFLAGS="$ARCHFLAGS" >/dev/null
lipo "$SPLIX/optimized/rastertoqpdl" -verify_arch arm64 x86_64

echo "==> 3/5 PPD (tutti i modelli, da file .drv)"
mkdir -p "$WORK/ppd"
(cd "$SPLIX/ppd" && make drv >/dev/null && for d in *.drv; do ppdc -d "$WORK/ppd" "$d"; done)

ROOT="$WORK/root"
mkdir -p "$ROOT$FILTER_DIR" "$ROOT$PPD_DIR"
cp "$SPLIX/optimized/rastertoqpdl" "$ROOT$FILTER_DIR/"
chmod 755 "$ROOT$FILTER_DIR/rastertoqpdl"
cp "$HERE/uninstall.sh" "$ROOT/Library/Printers/SpliX/uninstall.sh"
chmod 755 "$ROOT/Library/Printers/SpliX/uninstall.sh"
cp "$SPLIX/COPYING" "$ROOT/Library/Printers/SpliX/COPYING"

# Ogni PPD: percorso assoluto del filtro + "(SpliX)" nel nome mostrato da macOS,
# per distinguerlo dai driver del produttore. Nome file con prefisso SpliX-.
COUNT=0
for f in "$WORK"/ppd/*.ppd; do
    name=$(basename "$f" .ppd)
    sed -e "s|^\*cupsFilter: \"application/vnd.cups-raster 0 rastertoqpdl\"|*cupsFilter: \"application/vnd.cups-raster 0 $FILTER_DIR/rastertoqpdl\"|" \
        -e 's|^\*NickName: "\(.*\), [0-9.]*"$|*NickName: "\1 (SpliX)"|' \
        "$f" | gzip -9n > "$ROOT$PPD_DIR/SpliX-$name.ppd.gz"
    COUNT=$((COUNT + 1))
done
# Controllo: nessun PPD deve puntare al filtro con percorso relativo
if gzcat "$ROOT$PPD_DIR"/SpliX-*.ppd.gz | grep -q '^\*cupsFilter: .* 0 rastertoqpdl"'; then
    echo "ERRORE: cupsFilter non sostituito" >&2; exit 1
fi
echo "    $COUNT PPD"

echo "==> 4/5 Firma del filtro"
if [ -n "${SIGN_APP:-}" ]; then
    codesign --force --options runtime --timestamp -s "$SIGN_APP" "$ROOT$FILTER_DIR/rastertoqpdl"
else
    codesign --force -s - "$ROOT$FILTER_DIR/rastertoqpdl"   # firma ad-hoc
    echo "    (firma ad-hoc: nessun Developer ID impostato)"
fi

echo "==> 5/5 Pacchetto"
pkgbuild --root "$ROOT" --install-location / \
    --identifier "$PKG_ID" --version "$PKG_VERSION" \
    --scripts "$HERE/scripts" \
    "$WORK/SpliX-core.pkg" >/dev/null

sed -e "s|@PKG_ID@|$PKG_ID|g" -e "s|@PKG_VERSION@|$PKG_VERSION|g" \
    "$HERE/distribution.xml" > "$WORK/distribution.xml"
cp "$SPLIX/COPYING" "$HERE/resources/COPYING.txt"

if [ -n "${SIGN_PKG:-}" ]; then
    productbuild --distribution "$WORK/distribution.xml" --resources "$HERE/resources" \
        --package-path "$WORK" --sign "$SIGN_PKG" "$OUT/SpliX-macOS-$PKG_VERSION.pkg" >/dev/null
else
    productbuild --distribution "$WORK/distribution.xml" --resources "$HERE/resources" \
        --package-path "$WORK" "$OUT/SpliX-macOS-$PKG_VERSION.pkg" >/dev/null
fi

cd "$OUT"
shasum -a 256 "SpliX-macOS-$PKG_VERSION.pkg" > "SpliX-macOS-$PKG_VERSION.pkg.sha256"
echo
echo "Fatto: $OUT/SpliX-macOS-$PKG_VERSION.pkg"
cat "SpliX-macOS-$PKG_VERSION.pkg.sha256"
