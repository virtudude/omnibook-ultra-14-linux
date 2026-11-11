#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
"""Check the module cfg blobs in a built topology .conf the way the kernel
walks them: a 4-word header {size, SND_SOC_AR_TPLG_MODULE_CFG_TYPE, 0, 0},
then {iid, param id, size, 0, payload} records, all for one instance."""
import re
import sys

CFG_TYPE = 0x01001006


def fail(msg):
    raise SystemExit("check_blobs: " + msg)


def walk(name, body):
    iid, pos, recs = body[0], 0, []
    while pos < len(body):
        if body[pos] != iid or len(body) - pos < 4:
            fail("%s: bad record at word %d" % (name, pos))
        psize = body[pos + 2]
        avail = (len(body) - pos - 4) * 4
        if psize < 4 and avail and body[pos + 4] == iid:
            words = 0
        elif psize > avail:
            fail("%s: param 0x%08x size %d overruns the blob" % (name, body[pos + 1], psize))
        else:
            words = (psize + 3) // 4
        recs.append((body[pos + 1], psize))
        pos += 4 + words
        while pos < len(body) and not body[pos]:
            pos += 1
    return iid, recs


def main():
    conf = open(sys.argv[1]).read()
    # A blob longer than one SectionData continues in "<name>1", "<name>2", ...
    sections = {}
    for m in re.finditer(r'SectionData\."([^"]*cfg_data)(\d*)"\s*\{\s*words "([^"]*)"', conf):
        w = [int(x, 16) for x in re.sub(r"\s", "", m.group(3)).split(",") if x]
        sections.setdefault(m.group(1), []).append((int(m.group(2) or 0), w))
    if not sections:
        fail("no module cfg blobs")
    for name, parts in sorted(sections.items()):
        w = [x for _, part in sorted(parts) for x in part]
        if w[1] != CFG_TYPE:
            fail("%s: type 0x%08x" % (name, w[1]))
        if w[0] != 4 * len(w[4:]):
            fail("%s: header size %d, blob %d" % (name, w[0], 4 * len(w[4:])))
        iid, recs = walk(name, w[4:])
        print("%s iid 0x%x: %d records, %d B" % (name, iid, len(recs), w[0]))


if __name__ == "__main__":
    main()
