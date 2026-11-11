#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
# Build GLYMUR-HP-OmniBook-Ultra-14-kg0xxx-tplg.bin from HP's ACDB.
#   build.sh [-u AUDIOREACH_TOPOLOGY_DIR] INPUT [OUTDIR]
# INPUT: HP's SoftPaq .exe, its extracted directory, or acdb_cal.acdb itself.
# Without -u, the pinned audioreach-topology is cloned into OUTDIR.
set -euo pipefail

UPSTREAM_URL=https://github.com/Srinivas-Kandagatla/audioreach-topology.git
UPSTREAM_BRANCH=glymur
UPSTREAM_COMMIT=b94d118dff5f334b8633338268ccf148a482b1d2
ACDB_PATH=src/Driver/qcacsp_crd8480_KS_Position_WHQL/acdb_cal.acdb
ACDB_SHA256=91b63fa52808922cf372af626a7c390a21bfdd4b44b3d0746757e4cb815e66c1
NAME=GLYMUR-HP-OmniBook-Ultra-14-kg0xxx

usage() { echo "usage: $0 [-u AUDIOREACH_TOPOLOGY_DIR] INPUT [OUTDIR]" >&2; exit 2; }
HERE=$(cd "$(dirname "$0")" && pwd)
UPSTREAM=
while getopts u: opt; do
	case $opt in
	u) UPSTREAM=$(cd "$OPTARG" && pwd) ;;
	*) usage ;;
	esac
done
shift $((OPTIND - 1))
[ $# -ge 1 ] && [ $# -le 2 ] || usage
INPUT=$1
OUT=${2:-$PWD/out}

for tool in m4 alsatplg python3 git; do
	command -v "$tool" > /dev/null || { echo "missing: $tool" >&2; exit 1; }
done

mkdir -p "$OUT"
OUT=$(cd "$OUT" && pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

if [ -d "$INPUT" ]; then
	ACDB=$(find "$INPUT" -path "*/qcacsp_crd8480_KS_Position_WHQL/acdb_cal.acdb" -print -quit)
	[ -n "$ACDB" ] || { echo "$INPUT: no qcacsp_crd8480_KS_Position_WHQL/acdb_cal.acdb" >&2; exit 1; }
elif [[ $INPUT == *.exe ]]; then
	command -v 7z > /dev/null || { echo "missing: 7z (to unpack $INPUT)" >&2; exit 1; }
	ACDB=$WORK/acdb_cal.acdb
	7z e -so "$INPUT" "$ACDB_PATH" > "$ACDB"
	[ -s "$ACDB" ] || { echo "$INPUT: no $ACDB_PATH" >&2; exit 1; }
else
	ACDB=$INPUT
fi
if [ "$(sha256sum < "$ACDB" | cut -d' ' -f1)" != "$ACDB_SHA256" ]; then
	echo "warning: $ACDB is not the tested ACDB (SoftPaq sp174082); building anyway" >&2
fi

if [ -z "$UPSTREAM" ]; then
	UPSTREAM=$OUT/audioreach-topology
	[ -d "$UPSTREAM/.git" ] ||
		git clone -q --branch "$UPSTREAM_BRANCH" "$UPSTREAM_URL" "$UPSTREAM"
	git -C "$UPSTREAM" checkout -q "$UPSTREAM_COMMIT"
fi
if [ "$(git -C "$UPSTREAM" rev-parse HEAD 2>/dev/null)" != "$UPSTREAM_COMMIT" ]; then
	echo "warning: $UPSTREAM is not at $UPSTREAM_COMMIT" >&2
fi

mkdir -p "$WORK/gen"
python3 -I "$HERE/tools/gen_m4.py" "$ACDB" "$WORK/gen"
m4 -I "$WORK/gen" -I "$HERE/m4" -I "$UPSTREAM" "$HERE/m4/$NAME.m4" > "$WORK/$NAME.conf"
alsatplg -c "$WORK/$NAME.conf" -o "$WORK/$NAME-tplg.bin" > "$WORK/alsatplg.log" 2>&1 ||
	{ cat "$WORK/alsatplg.log" >&2; exit 1; }
# upstream's shared mixers name widgets this topology does not instantiate
grep -v "undefined s\(ink\|ource\) widget/stream" "$WORK/alsatplg.log" >&2 || true
python3 -I "$HERE/tools/check_blobs.py" "$WORK/$NAME.conf"
mv "$WORK/$NAME-tplg.bin" "$OUT/"
sha256sum "$OUT/$NAME-tplg.bin"
echo "install as /lib/firmware/qcom/glymur/$NAME-tplg.bin"
