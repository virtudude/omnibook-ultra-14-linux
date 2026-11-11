# SPDX-License-Identifier: BSD-3-Clause
"""Read calibration records out of a Qualcomm AudioReach ACDB file (acdb_cal.acdb).

The layout follows the public ACDB reader in audioreach-graphservices
(acdb/src/acdb_file_mgr.c, acdb_parser.c): a 12 byte file header, then
chunks of {char id[4]; u32 length; u8 data[length]}.
  SGIT  subgraph -> modules (module id, instance id)
  CSLU  subgraph -> calibration key tables (CAKT) and lookup tables (CDLU)
  CDLU  key values -> CDDE (instance id, param id pairs) + CDDO (POOL offsets)
  POOL  {u32 size; u8 payload[size]}
"""
import struct


class Acdb:
    def __init__(self, path):
        self.data = open(path, "rb").read()
        self.chunks = {}
        off = 12
        while off + 8 <= len(self.data):
            cid = self.data[off:off + 4].decode("ascii", "replace")
            size = struct.unpack_from("<I", self.data, off + 4)[0]
            self.chunks[cid] = self.data[off + 8:off + 8 + size]
            off += 8 + size
        missing = {"SGIT", "CSLU", "CAKT", "CDLU", "CDDE", "CDDO", "POOL"} - set(self.chunks)
        if missing:
            raise SystemExit("%s: not an AudioReach ACDB (no %s)" % (path, ", ".join(sorted(missing))))
        self.iid2mid = self._modules()
        self.rows = list(self._rows())

    def _modules(self):
        b = self.chunks["SGIT"]
        iid2mid = {}
        n, = struct.unpack_from("<I", b, 0)
        o = 4
        for _ in range(n):
            _, _, size = struct.unpack_from("<3I", b, o)
            o += 12
            end = o + size
            while o < end:
                _, count = struct.unpack_from("<2I", b, o)
                o += 8
                for _ in range(count):
                    mid, iid = struct.unpack_from("<2I", b, o)
                    o += 8
                    iid2mid[iid] = mid
        return iid2mid

    def _rows(self):
        """Yield (subgraph, ckv, iid, module id, param id, payload)."""
        c = self.chunks
        u = lambda b, o, n=1: struct.unpack_from("<%dI" % n, b, o)
        nsg, = u(c["CSLU"], 0)
        o = 4
        for _ in range(nsg):
            sg, nck = u(c["CSLU"], o, 2)
            o += 8
            for _ in range(nck):
                okt, olut = u(c["CSLU"], o, 2)
                o += 8
                nk, = u(c["CAKT"], okt)
                keys = u(c["CAKT"], okt + 4, nk)
                hk, entries = u(c["CDLU"], olut, 2)
                p = olut + 8
                for _ in range(entries):
                    vals = u(c["CDLU"], p, hk)
                    p += 4 * hk
                    ode, odo, _ = u(c["CDLU"], p, 3)
                    p += 12
                    nd, = u(c["CDDE"], ode)
                    pairs = u(c["CDDE"], ode + 4, 2 * nd)
                    no, = u(c["CDDO"], odo)
                    offs = u(c["CDDO"], odo + 4, no)
                    ckv = tuple(zip(keys, vals))
                    for k in range(min(nd, no)):
                        iid, pid = pairs[2 * k], pairs[2 * k + 1]
                        po = offs[k]
                        size, = u(c["POOL"], po)
                        yield sg, ckv, iid, self.iid2mid.get(iid, 0), pid, c["POOL"][po + 4:po + 4 + size]

    def module_records(self, sg, mid):
        """{param id: payload} of every instance of module mid in subgraph sg."""
        out = {}
        for rsg, _, _, rmid, pid, data in self.rows:
            if rsg != sg or rmid != mid:
                continue
            if pid in out and out[pid] != data:
                raise SystemExit("ACDB: conflicting records for module 0x%08x param 0x%08x" % (mid, pid))
            out[pid] = data
        if not out:
            raise SystemExit("ACDB: no records for module 0x%08x in subgraph 0x%08x" % (mid, sg))
        return out

    def record(self, sg, iid, mid, pid):
        for rsg, _, riid, rmid, rpid, data in self.rows:
            if (rsg, riid, rpid) == (sg, iid, pid):
                if rmid != mid:
                    raise SystemExit("ACDB: instance 0x%x is module 0x%08x, expected 0x%08x" % (iid, rmid, mid))
                return data
        raise SystemExit("ACDB: no record subgraph 0x%08x iid 0x%x param 0x%08x" % (sg, iid, pid))
