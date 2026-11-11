# Speaker topology

Builds `GLYMUR-HP-OmniBook-Ultra-14-kg0xxx-tplg.bin`, the AudioReach DSP topology for the speakers. The playback graph runs:

1. HP's Windows speaker processing: MSPP v5, two SAL limiters and the "Speaker Playback Volume" control.
2. A 1.5 kHz tweeter high-pass.
3. Speaker protection with V/I feedback for all four speakers.

The tuning comes from HP's ACDB, which isn't included. This directory holds only the generator: run it against your own copy of HP's driver pack.

## Usage

```
./build.sh [-u AUDIOREACH_TOPOLOGY_DIR] INPUT [OUTDIR]
```

`INPUT` is one of:
- HP's Qualcomm driver pack SoftPaq (`sp174082.exe`, tested; later packs are unverified; unpacking it needs `7z`);
- a directory it was extracted to;
- the ACDB file itself.

The generator reads `src/Driver/qcacsp_crd8480_KS_Position_WHQL/acdb_cal.acdb`.

The upstream m4 tree is [Srinivas-Kandagatla/audioreach-topology](https://github.com/Srinivas-Kandagatla/audioreach-topology), branch `glymur`, pinned at commit `b94d118dff5f334b8633338268ccf148a482b1d2`. Without `-u`, `build.sh` clones it into `OUTDIR`.

The tools needed are `python3`, `m4`, `alsatplg` (alsa-utils) and `git`.

The output is `OUTDIR/GLYMUR-HP-OmniBook-Ultra-14-kg0xxx-tplg.bin` (`OUTDIR` defaults to `./out`). Install it as `/lib/firmware/qcom/glymur/GLYMUR-HP-OmniBook-Ultra-14-kg0xxx-tplg.bin`. The `.bin` contains HP's tuning data: keep it local.

Built from the sp174082 ACDB, the output's sha256 is `bb0fb3e0fbdbc1c26962f9214fe40b044d89d1148d79ebfb273552b8428432d0`.

## Fixed parameters

These are in `tools/gen_m4.py`:
- **Thermal targets:** 90 °C for the woofers and 80 °C for the tweeters. HP uses 100 °C and 90 °C.
- **Speaker full scale:** 3.246, 3.387, 3.283 and 3.234 V, in the order woofer left, tweeter left, woofer right, tweeter right. These values must match `qcom,speaker-full-scale-microvolt` in the device tree. The kernel refuses the graph if any speaker differs by more than 1 %.
- **Changes to HP's records:** the tuning-mode flags are off, and SP records 0x08001AEB and 0x08001AEC are left out.

The topology needs HP's DSP modules `spv5_module.so.1`, `msppv5_module.so.1` and `SAPlusCmnModule.so.1` in `/usr/lib/dsp/adsp/`. They come from the same driver pack, folder `qcsubsys_ext_adsp8480_fix_listen_WHQL/ADSP`.
