# omnibook-ultra-14-linux

Linux support for the HP OmniBook Ultra 14-kg0xxx (board 8F03, Snapdragon X2 Elite).

| Directory | Contents |
|---|---|
| `kernel/` | Patch series against v7.4-rc2, a provenance table and a config fragment |
| `ucm2/` | ALSA UCM files, laid out like `/usr/share/alsa/ucm2` |
| `audioreach-topology/` | Generator for the speaker DSP topology, run against HP's driver pack |

`kernel/` is GPL-2.0; `ucm2/` and `audioreach-topology/` are BSD-3-Clause, as their upstreams are. The texts are in `LICENSES/`.

## Status

Working: display (eDP, 10 bpc), touchscreen, GPU, Wi-Fi 7 (MLO), Bluetooth, USB, webcam, keyboard and touchpad, battery status, CPU frequency scaling, s2idle suspend, internal mics, and the four speakers with speaker protection and HP's speaker processing running in the DSP.

Not tested yet: charge limits.

Not working yet: headphone jack (no codec in the device tree yet), RTC (use NTP), EFI variable writes, TPM, hardware video decode, external DisplayPort over USB-C, NPU.

## Kernel

Apply `kernel/` to v7.4-rc2 as described in `kernel/README.md` and merge `kernel/omnibook.config` into your config. The device tree is `qcom/glymur-hp-omnibook-ultra-kg0xxx.dtb`.

## Firmware

### From linux-firmware

These come from your distribution's linux-firmware packages:

| Files | Used by |
|---|---|
| `qcom/gen80100_sqe.fw`, `qcom/gen80100_gmu.bin`, `qcom/gen80100_aqe.fw` | GPU |
| `ath12k/WCN7850/hw2.0/*` | Wi-Fi |
| `qca/hmtbtfw20.tlv`, `qca/hmtnv20.*` | Bluetooth |

If drm/msm is in your initramfs, put the GPU files in it too.

The Wi-Fi card (subsystem `103c:8e64`) has no entry in linux-firmware's `board-2.bin` yet, so ath12k needs board data from another entry until one is added. The exact entry tested here isn't documented yet.

### From HP's driver pack

The audio and compute DSPs need HP-signed firmware, which isn't included here. It is in HP's Qualcomm driver pack for this model (SoftPaq sp174082, tested; later packs are unverified), or under `C:\Windows\System32\DriverStore\FileRepository` on the laptop's Windows install.

| Driver pack folder | Files | Install to |
|---|---|---|
| `qcsubsys_ext_adsp8480_fix_listen_WHQL` | `qcadsp8480.mbn`, `adsp_dtbs.elf`, `adspr.jsn`, `adsps.jsn`, `adspua.jsn` | `/lib/firmware/qcom/glymur/hp/omnibook-ultra-14-kg0xxx/` |
| `qcnspmcdm8480` | `qccdsp8480.mbn`, `cdsp_dtbs.elf` | `/lib/firmware/qcom/glymur/hp/omnibook-ultra-14-kg0xxx/` |
| `qcsubsys_ext_adsp8480_fix_listen_WHQL/ADSP` | `spv5_module.so.1`, `msppv5_module.so.1`, `SAPlusCmnModule.so.1` | `/usr/lib/dsp/adsp/` |

The three `.so` files are DSP modules for speaker protection and HP's speaker processing. The DSP loads them through the FastRPC audio PD, so `adsprpcd` from [fastrpc](https://github.com/qualcomm/fastrpc) must run as `adsprpcd audiopd adsp` with `DSP_LIBRARY_PATH=/usr/lib/dsp/adsp`.

### Built from HP's tuning data

The speaker topology `qcom/glymur/GLYMUR-HP-OmniBook-Ultra-14-kg0xxx-tplg.bin` is generated from HP's ACDB in the same driver pack. See `audioreach-topology/README.md`.

## Audio

1. Install the firmware above and start `adsprpcd`.
2. Build and install the topology.
3. With alsa-ucm-conf installed, copy the UCM files in: `sudo cp -a ucm2/. /usr/share/alsa/ucm2/`. This only adds files, plus one `conf.d` link.

With the full patch series and this device tree, the kernel takes the amplifier gain limit and the speakers' full scale from the device tree and makes those controls read-only. It won't play through the speakers unless the topology carries speaker protection, a tweeter high-pass and a full scale that matches the device tree. The limits were measured on one unit. Speaker support is experimental: use the kernel, device tree, topology and UCM from this repo together.

Runtime PM must stay off on the SoundWire controllers. With it on, V/I sense doesn't restart after the bus resumes, and the kernel keeps those amplifiers muted. Save these rules as `/etc/udev/rules.d/90-omnibook-soundwire.rules` (and rebuild your initramfs if it includes udev rules):

```
ACTION=="add|change", SUBSYSTEM=="platform", KERNEL=="6c80000.soundwire|6ca0000.soundwire", ATTR{power/control}="on"
ACTION=="add|bind|change", SUBSYSTEM=="soundwire", KERNEL=="sdw:*:0217:0204:*", ATTR{power/control}="on"
```
