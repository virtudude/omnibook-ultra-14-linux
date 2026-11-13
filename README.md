# omnibook-ultra-14-linux

Linux support for the HP OmniBook Ultra 14-kg0xxx (board 8F03, Snapdragon X2 Elite).

**Use at your own risk.** Provided as is, without warranty. The speaker limits were measured on one unit and may not suit yours. Driving the speakers or other hardware outside the vendor's software can damage them.

| Directory | Contents |
|---|---|
| `kernel/` | Patch series against v7.4-rc2, a provenance table and a config fragment |
| `ucm2/` | ALSA UCM files, laid out like `/usr/share/alsa/ucm2` |
| `audioreach-topology/` | Generator for the speaker DSP topology, run against HP's driver pack |

`kernel/` is GPL-2.0; `ucm2/` and `audioreach-topology/` are BSD-3-Clause, as their upstreams are. The texts are in `LICENSES/`.

## Status

Working:
- Display (eDP, 10 bpc), touchscreen, GPU
- Wi-Fi 7 (MLO), Bluetooth, USB, webcam
- Keyboard, touchpad, internal microphones
- Speakers, with speaker protection and HP's speaker processing in the DSP ([Audio](#audio))
- Hardware video decode: H.264, HEVC, VP9, AV1
- NPU, through ONNX Runtime's QNN execution provider ([NPU](#npu))
- Battery status and charge limits (`charge_control_start_threshold` and `charge_control_end_threshold` on `qcom-battmgr-bat`)
- CPU frequency scaling
- Embedded controller (`hp-omnibook-ec`): fan speed, EC temperatures (hwmon and thermal zones `ec-therm1..3`), keyboard backlight level and timeout, mute LED state
- RTC with wake alarm (`rtc-qcom-tad`, usually `rtc1`)
- s2idle suspend and resume, reaching CX collapse and DDR self-refresh

Not working: headphone jack, EFI variable writes, TPM, external DisplayPort over USB-C, wake from USB devices.

Known issues:
- If the laptop is suspended with the lid open, closing and opening the lid doesn't wake it; press a key.
- AV1 hardware decode output isn't bit-exact.
- Suspending while audio plays keeps the audio DSP and speaker amplifiers awake.
- Minimum display brightness is higher than on Windows: below about 17 % of the backlight range the panel doesn't get dimmer.

## Kernel

Apply `kernel/` to v7.4-rc2 as described in `kernel/README.md` and merge `kernel/omnibook.config` into your config. The device tree is `qcom/glymur-hp-omnibook-ultra-kg0xxx.dtb`.

Recommended kernel command line:

| Option | Why |
|---|---|
| `mem_sleep_default=s2idle` | `deep` (PSCI SYSTEM_SUSPEND) fails on this firmware |
| `fw_devlink.sync_state=timeout` | The GPU's GMU node has no driver, so the GCC and GPU clock controllers never sync and leave boot-on power domains on |
| `deferred_probe_timeout=30` | Makes the previous option take effect on kernels built with `CONFIG_DRIVER_DEFERRED_PROBE_TIMEOUT=-1`, such as Fedora's |

## Firmware

### From linux-firmware

These come from your distribution's linux-firmware packages:

| Files | Used by |
|---|---|
| `qcom/gen80100_sqe.fw`, `qcom/gen80100_gmu.bin`, `qcom/gen80100_aqe.fw` | GPU |
| `ath12k/WCN7850/hw2.0/*` | Wi-Fi |
| `qca/hmtbtfw20.tlv`, `qca/hmtnv20.*` | Bluetooth |

If drm/msm is in your initramfs, put the GPU files in it too.

The Wi-Fi card (subsystem `103c:8e64`) has no entry in linux-firmware's `board-2.bin`, so ath12k falls back to generic board data.

### From HP's driver pack

The audio and compute DSPs and the video codec need firmware from HP's driver pack, which isn't included here. It is in HP's Qualcomm driver pack for this model (SoftPaq sp174082, tested; later packs are unverified), or under `C:\Windows\System32\DriverStore\FileRepository` on the laptop's Windows install.

| Driver pack folder | Files | Install to |
|---|---|---|
| `qcsubsys_ext_adsp8480_fix_listen_WHQL` | `qcadsp8480.mbn`, `adsp_dtbs.elf`, `adspr.jsn`, `adsps.jsn`, `adspua.jsn` | `/lib/firmware/qcom/glymur/hp/omnibook-ultra-14-kg0xxx/` |
| `qcnspmcdm8480` | `qccdsp8480.mbn`, `cdsp_dtbs.elf` | `/lib/firmware/qcom/glymur/hp/omnibook-ultra-14-kg0xxx/` |
| `qcnspmcdm8480/CDSP` | the CDSP shells and libraries (`fastrpc_shell_3`, ...) | `/usr/share/hexagon-dsp/glymur/HP/OmniBook-Ultra-14-kg0xxx/dsp/cdsp/` |
| `qcdx8480_5000` | `qcvss8480.mbn` | `/lib/firmware/qcom/glymur/hp/omnibook-ultra-14-kg0xxx/` |
| `qcsubsys_ext_adsp8480_fix_listen_WHQL/ADSP` | `spv5_module.so.1`, `msppv5_module.so.1`, `SAPlusCmnModule.so.1` | `/usr/lib/dsp/adsp/` |

linux-firmware's `qcom/vpu/vpu36_p4_s7.mbn` is signed with a test key for Qualcomm's reference board, so use HP's.

The three `.so` files are DSP modules for speaker protection and HP's speaker processing. The DSP loads them through the FastRPC audio PD, so `adsprpcd` from [fastrpc](https://github.com/qualcomm/fastrpc) must run as `adsprpcd audiopd adsp` with `DSP_LIBRARY_PATH=/usr/lib/dsp/adsp`.

### Built from HP's tuning data

The speaker topology `qcom/glymur/GLYMUR-HP-OmniBook-Ultra-14-kg0xxx-tplg.bin` is generated from HP's ACDB in the same driver pack. See `audioreach-topology/README.md`.

## Audio

1. Install the firmware above and start `adsprpcd`.
2. Build and install the topology.
3. With alsa-ucm-conf installed, copy the UCM files in: `sudo cp -a ucm2/. /usr/share/alsa/ucm2/`. This only adds files, plus one `conf.d` link.

With the full patch series and this device tree, the kernel takes the amplifier gain limit and the speakers' full scale from the device tree and makes those controls read-only. It won't play through the speakers unless the topology carries speaker protection with its feedback loop, a tweeter high-pass and a full scale that matches the device tree. If a DSP error leaves the protection state unknown, it switches the amplifiers off. The limits were measured on one unit. Speaker support is experimental: use the kernel, device tree, topology and UCM from this repo together.

## NPU

The NPU runs ONNX models through the QNN execution provider, on the CDSP firmware and shells above.

1. Install Fedora's `fastrpc` and `fastrpc-devel` (1.0.8), or build [fastrpc](https://github.com/qualcomm/fastrpc) with the same paths.
2. Add a FastRPC machine config, `/usr/share/hexagon-dsp/conf.d/hp-omnibook-ultra-14-kg0xxx.yaml`:

   ```
   machines:
     HP OmniBook Ultra Laptop 14-kg0xxx:
       DSP_LIBRARY_PATH: glymur/HP/OmniBook-Ultra-14-kg0xxx/dsp
   ```

3. Give the user access to `/dev/fastrpc-cdsp` (group `fastrpc`) and `/dev/dma_heap/system` (group `video`).
4. Install `onnxruntime-qnn` 2.5.0 (QAIRT 2.49.40) with `onnxruntime` 1.29.0 (wheels exist for Python 3.11 to 3.14), and register the EP with `ort.register_execution_provider_library`. Set `ADSP_LIBRARY_PATH` to the `onnxruntime_qnn` package directory, then the shell directory above, separated by `;`.

`onnxruntime-qnn` 2.7.0 and later (QAIRT 2.51 and later) fail with HP's CDSP firmware: graph execution returns `QNN_GRAPH_ERROR_INVALID_HANDLE`.
