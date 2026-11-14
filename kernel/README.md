# Kernel patches

Patches for the HP OmniBook Ultra 14-kg0xxx on top of v7.4-rc2 (`7475ea8b5861`), and
`omnibook.config`, the options this board needs on top of `defconfig` or a distro arm64
config.

## Apply

From a fresh clone:

```
git clone --depth 1 --branch v7.4-rc2 https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
cd linux
git am --empty=drop /path/to/kernel/[0-9]*.patch
make defconfig        # or copy your distro's arm64 config to .config
scripts/kconfig/merge_config.sh -m .config /path/to/kernel/omnibook.config
make olddefconfig
```

`--empty=drop` skips the cover letter at the top of each multi-patch file. Without git,
`for p in /path/to/kernel/[0-9]*.patch; do patch -p1 --fuzz=0 < "$p" || break; done` gives
the same tree.

## Layout

The number is the apply order, and the range says the subsystem:

| Range | Band |
|---|---|
| `0000-0099` | clk, pmdomain, power supply, powercap, irqchip |
| `0100-0199` | phy, USB |
| `0200-0299` | soc, firmware, misc, mfd, crypto, efi, rtc, input, platform |
| `0300-0399` | drm/msm |
| `0400-0499` | wifi, Bluetooth power sequencing |
| `0500-0799` | SoundWire and ASoC: mostly posted and community work in the `0500s`, ours from `0600` |
| `0800-0899` | media and iommu (iris video) |
| `0900-0999` | arm64 DTS and the board binding |

A dt-binding goes in the band of the driver that reads it.

Two patches carry DTS changes outside the
DTS band, so that their series stay whole: `0060` (the glymur videocc sleep clock, with its
binding) and `0530` (the RFC ends with glymur-crd and ThinkPad T14s Gen 7 changes).

Each file is an mbox written by `git format-patch`. It holds one commit, or several
consecutive commits from one upstream series; then it starts with a `[PATCH 0/N]` cover
that lists each patch's author and Message-ID or source, and each commit keeps its own
author, message and trailers. Our own commits are grouped the same way where they build one
feature (`0297`, `0298`, `0680`, `0720`, `0740`, `0770`, `0790`, `0795`, `0797`, `0798`, `0870`, `0970`). A
fix that would be sent upstream on its own keeps its own file.

## Provenance

- `mainline`: the change is in a mainline tag newer than our base. The row goes at the next
  rebase.
- `posted`: on a kernel mailing list, not in mainline. This includes RFCs and patches
  queued in a maintainer tree; Source says which.
- `community`: carried in another public tree, never posted.
- `ours`: written for this laptop, not posted.

Audited 2026-11-12 against v7.4-rc2. Merge state was looked up in git by subject and
patch-id, in mainline and in the maintainer trees named in Source; posting state comes
from lore. Recheck the Drop when column at each rebase.

| Patch | Origin | Source | Drop when |
|---|---|---|---|
| `0010` | posted | Jagadeesh Kona, [lore](https://lore.kernel.org/r/20261016-glymur-usb-ret-on-v1-1-1790a523fd9c@oss.qualcomm.com). Applied to qcom `clk-fixes-for-7.4` as 39477c344da4. USB resume from suspend. | in mainline |
| `0020` | posted | Taniya Das, [lore](https://lore.kernel.org/r/20261028-gcc_glymur_pcie-v1-1-a2163e1d2b9b@oss.qualcomm.com). Applied to qcom `clk-fixes-for-7.4` as 60521e4ff9e7. | in mainline |
| `0030` | posted | Oleg Keri, v1 [lore](https://lore.kernel.org/r/20261021080517.2161-1-okerixx@gmail.com). Without it the first GPU init times out. | in mainline |
| `0040` | community | Tyler Baker, from [EmbeddedAndroid/linux 0473e2eaf749](https://github.com/EmbeddedAndroid/linux/commit/0473e2eaf7499349316736611f95c8e0953c545c); also in [linux-msm/laptops-kernel 0964933967e8](https://github.com/linux-msm/laptops-kernel/commit/0964933967e8e343d50fd6a8a38b4fa8897be0f6). Not posted. Charger state updates. | merged upstream, or the firmware sends battery notifications |
| `0050` | posted | Manaf Meethalavalappu Pallikunhi, SPEL v3 1-3/4 [lore](https://lore.kernel.org/r/20260702-qcom_spel_driver_upstream-v3-1-434d50f0c5b0@oss.qualcomm.com), taken from linux-msm/laptops-kernel [555f3506cb34](https://github.com/linux-msm/laptops-kernel/commit/555f3506cb3474162d74d79501a4bc05124dc9d8), [75b451099ead](https://github.com/linux-msm/laptops-kernel/commit/75b451099eadcd05913f686521617f894c25cd32), [2feba0bac1ec](https://github.com/linux-msm/laptops-kernel/commit/2feba0bac1ec762580d11a21a6fc50affd6d1549). We dropped the MAINTAINERS hunks of 2/4 and 3/4. 4/4 is `0930`. SoC power readings. | merged upstream, or v4 replaces it |
| `0060` | posted | Shawn Guo, v3 1-2/4 [lore](https://lore.kernel.org/r/20261017045817.1506961-2-shengchao.guo@oss.qualcomm.com), taken from linux-msm/laptops-kernel [4e6ae5c4bdce](https://github.com/linux-msm/laptops-kernel/commit/4e6ae5c4bdce5cefaffb28d98f67b3f0ee111322), [1e7ba0bb6bdd](https://github.com/linux-msm/laptops-kernel/commit/1e7ba0bb6bdda859025fd0b42fd94eb97853286f). | in mainline |
| `0070` | ours | Based on Konrad Dybcio's v2 [lore](https://lore.kernel.org/r/20261102-topic-pdc_map_espi-v2-1-64431c8f8ac3@oss.qualcomm.com), which maps these pins 32 INTIDs too low. Hands PDC pins past the SPI range, such as the lid's, to the GIC as extended SPIs, and the GIC doesn't warn `SPI 4115 out of range`. | upstream equivalent |
| `0110` | posted | Konrad Dybcio, v1 1/2 [lore](https://lore.kernel.org/r/20261102-topic-usb3_sequence-v1-1-5b144f5e6865@oss.qualcomm.com). We carry 1/2 only. USB SuperSpeed. | in mainline, or a later version replaces it |
| `0120` | posted | Elson Serrao, v2 posted by Peter Chen, [lore](https://lore.kernel.org/r/20261027015545.2758784-1-peter.chen@oss.qualcomm.com). | in mainline |
| `0130` | ours | dwc3 tells xhci-plat when it reinitialised the core on resume (`power_lost`), as cdns3 does, so the webcam's xHCI resets instead of failing when its controller loses power in sleep. | upstream equivalent |
| `0210` | posted | Krzysztof Kozlowski, three patches [lore](https://lore.kernel.org/r/20261103145635.309032-4-krzysztof.kozlowski@oss.qualcomm.com). Applied to qcom `drivers-for-7.5` as e6f64f9b76d5, a5d51dee5f57, 85fadab9958b. | base ≥ v7.5-rc1 |
| `0220` | posted | Mohit Sharma, v1 2/2 [lore](https://lore.kernel.org/r/20261022144130.2443667-3-mohit.sharma@oss.qualcomm.com); 1/2 is in v7.4-rc2. Removes a 5 s audio stall at boot. | in mainline |
| `0230` | posted | Jason Pettit, [lore](https://lore.kernel.org/r/20261101-hp-omnibook-v2-v2-3-1b99767deda0@oss.qualcomm.com). Applied to qcom `drivers-for-7.5` as 72bd92c0115f. UEFI variables. | base ≥ v7.5-rc1 |
| `0240` | posted | Anandu Krishnan E, v3 [lore](https://lore.kernel.org/r/20261027-fastrpc-kvm-iommu-v3-v3-1-f3cd5c030c78@oss.qualcomm.com). Lets the audio PD load the speaker protection module. Never carry without `0960`. | in mainline |
| `0250` | ours | NULL dereference when uefisecapp unbinds. `0690` reads EFI variables through it. | upstream equivalent |
| `0260` | posted | Anandu Krishnan E, v3 [lore](https://lore.kernel.org/r/20261002-anandu-fastrpc-interrupted-invoke-v3-v3-1-31e90439d2ba@oss.qualcomm.com). Without it the audio DSP can crash on resume: the freezer interrupts `adsprpcd`'s pending call, and the retry sends it to the DSP a second time. Carried with four fixes squashed in: no `fl->lock` in the hard IRQ callback, no use of a context after `cctx->lock` is dropped, resume only with the same arguments, park only a call the DSP received. | `0260` lands with equivalent fixes |
| `0280` | ours | Stops the TCSR syscon holding the RPMh XO clock prepared, which blocks sleep. Idea from [justririll/x1e-sleep](https://github.com/justririll/x1e-sleep). | upstream equivalent |
| `0290` | posted | Bartosz Golaszewski, v11 1-2/2 [lore](https://lore.kernel.org/r/20261022-qce-fixes-broken-label-v11-1-0d33c34fd0c3@oss.qualcomm.com). The crypto node binds without registering algorithms, so the interconnects reach sync_state. | in mainline |
| `0295` | posted | Kamal Wadhwa, v2 1/2 [lore](https://lore.kernel.org/r/20261103-rtc-glink-cleanup-v2-1-895eb6e8d890@qti.qualcomm.com). Creates the RTC device that `0296` binds. We don't carry 2/2 (rtc-glink): it needs opcodes this firmware doesn't answer. | in mainline |
| `0296` | ours | RTC time, alarms and wake from s2idle through the SoCCP's ACPI Time and Alarm Device service, the path Windows uses. | upstream equivalent |
| `0297` | ours | Two patches: `wakeup-on-state-change` for gpio-keys and its binding. A switch's wakeup stays unarmed while the switch is already in the state it wakes on. `0997` uses it for the lid. | upstream equivalent |
| `0298` | ours | Three patches: the binding, a driver for the embedded controller based on Rahul Pon's [HP OmniBook 5 16 EC driver](https://github.com/theflyingrahul/linux-hp-omnibook-5-glymur), and mute LED control. Fan speed and EC thermistors (hwmon and thermal sensors), keyboard backlight level and timeout, mute LEDs, function-key lock and the F9/F11 hotkeys. `0998` describes the EC. | upstream equivalent |
| `0310` | posted | Connor Abbott, v2 [lore](https://lore.kernel.org/r/20261029-drm-msm-gmem-base-fix-v2-1-26b338471b46@gmail.com). Queued in drm/msm `msm-fixes`. | in mainline |
| `0320` | posted | Akhil P Oommen, Jie Zhang, "assorted-fixes-oct" v1 1-8/8 [lore](https://lore.kernel.org/r/20261024-assorted-fixes-oct-v1-1-2977f974ddb7@oss.qualcomm.com). Queued in drm/msm `msm-fixes`. 8/8 needs `qcom/gen80100_aqe.fw`. | in mainline |
| `0330` | posted | Rob Clark, [lore](https://lore.kernel.org/r/20261029001601.82269-1-robin.clark@oss.qualcomm.com). Queued in drm/msm `msm-fixes`. | in mainline |
| `0340` | posted | Rob Clark, four VM_BIND fixes [lore](https://lore.kernel.org/r/20261102172001.508440-2-robin.clark@oss.qualcomm.com). Queued in drm/msm `msm-fixes`. | in mainline |
| `0350` | posted | Rob Clark, [lore](https://lore.kernel.org/r/20261104212048.21010-1-robin.clark@oss.qualcomm.com). Queued in drm/msm `msm-fixes`. | in mainline |
| `0360` | posted | Bart Van Assche, [lore](https://lore.kernel.org/r/9671164f87138a0caf5c69b66129bbd6faf932f8.1793044688.git.bvanassche@acm.org). Queued in drm/msm `msm-fixes`. | in mainline |
| `0370` | posted | Burke Cates, v1 [lore](https://lore.kernel.org/r/20261104072048.3486286-1-burke.cates@gmail.com). After a failed link training, the next blank doesn't reset the SoC. | in mainline |
| `0380` | posted | Michael Burch, v2 [lore](https://lore.kernel.org/r/20261013172703.12273-1-me@michaelburch.net). Idle power. | in mainline |
| `0390` | ours | 10 bpc eDP at boot instead of 6 bpc. | an upstream fix lands |
| `0410` | posted | Miaoqing Pan, [lore](https://lore.kernel.org/r/20260915080053.918500-1-miaoqing.pan@oss.qualcomm.com). Applied to ath `ath-current` as 843a011534b0. | in mainline |
| `0420` | posted | Lorenzo Bianconi, v2 [lore](https://lore.kernel.org/r/20261015-ath12k-fix-descap-multiple-rx-buf-v2-1-4cde055677ed@oss.qualcomm.com). Applied to ath `ath-current` as 1e678e37ff13. | in mainline |
| `0430` | posted | Baochen Qiang, [lore](https://lore.kernel.org/r/20261029-ath12k-mcs15-v1-1-3bcfab101f00@oss.qualcomm.com). Applied to ath `ath-current` as 83d689bbe8f9. | in mainline |
| `0440` | posted | Aishwarya R, two patches [lore](https://lore.kernel.org/r/20260925051036.2838210-2-aishwarya.r@oss.qualcomm.com). Applied to ath `ath-next` as c752394249f8, 02121aa4a012. `0450` is written on top of them. | base ≥ v7.5-rc1 |
| `0450` | posted | Baochen Qiang, logical link id v5 1-11/11 [lore](https://lore.kernel.org/r/20261110-ath12k-logical-link-id-v5-1-26a3ed38db09@oss.qualcomm.com). Queued in ath `ath-next`. Fixes WPA3-SAE with MLO. | base ≥ v7.5-rc1 |
| `0460` | posted | Shuai Zhang, [lore](https://lore.kernel.org/r/20261102094800.3225454-1-shuai.zhang@oss.qualcomm.com). In linux-next through the pwrseq tree. Bluetooth power-up. | in mainline |
| `0510` | posted | Oleg Keri, [lore](https://lore.kernel.org/r/20261009082639.22662-1-okerixx@gmail.com). Applied to soundwire `fixes` as 6c067677192f. | in mainline |
| `0520` | ours | Fixes a v7.4-rc2 regression: without it the sound card does not bind. ASoC `for-7.4` has an equivalent fix, d00ba321499c. | in mainline |
| `0530` | posted | Srinivas Kandagatla and Ravi Hothi, RFC 01-23/23 [lore](https://lore.kernel.org/r/20261023171433.820092-2-srinivas.kandagatla@oss.qualcomm.com). WSA speaker protection with V/I feedback. | a non-RFC version is merged |
| `0540` | community | Ravi Hothi, from Srinivas Kandagatla's `glymur` tree, [65aca3ef0d1f](https://github.com/Srinivas-Kandagatla/linux/commit/65aca3ef0d1fb2f6b20892f0d1a3a1ef391ccf7f). Not seen on a list. Without it the V/I ports clash on the bus. | merged upstream |
| `0600` | ours | PA Volume TLV matches the measured WSA8845 gain. | upstream equivalent |
| `0610` | ours | Negative temperatures wrapped. | upstream equivalent |
| `0620` | ours | GRAPH_OPEN errors were ignored. | upstream equivalent |
| `0630` | ours | Speaker protection never runs half configured. | upstream equivalent |
| `0650` | ours | A volume limit that failed left the speakers at reset gain, and the mix-path digital volumes had no limit. | upstream equivalent |
| `0670` | ours | Out-of-bounds read on a module with too many output ports. | upstream equivalent |
| `0680` | ours | Ten patches: lane order (Glymur lanes alternate between the two WSA macros), the V/I guard, calibration results reported but never applied, one checked SP RX/SP VI pass, `qcom,speaker-protection-required`, and their bindings (the WSA link has 18 DAIs). | upstream equivalent |
| `0690` | ours | Factory R0/T0 from the `SmartAmpCalibrationData` UEFI variable. Needs `0250`. | upstream equivalent |
| `0700` | ours | 2S battery settings, based on Jens Glathe's Surface Pro 11 change. | upstream equivalent |
| `0710` | ours | DSP high-pass for the tweeters: SP RX only runs behind the one qualified high-pass profile, and nothing after SP RX may remix or amplify. | upstream equivalent |
| `0720` | ours | Four patches: APM transaction tokens, large SET_CFG payloads through shared memory, release of those buffers once the DSP lets go of them, and teardown of failed graphs, set up again at the next start. | upstream equivalent |
| `0730` | ours | Bounds checks on topology private data. | upstream equivalent |
| `0740` | ours | Three patches: large records out of band, MSPP/SAL/channel mixer parameters from the topology, `Speaker Playback Volume` in dB mirrored into MSPP. | upstream equivalent |
| `0750` | ours | Stereo front end, split to the four speakers in the DSP. | upstream equivalent |
| `0770` | ours | Three patches: the per-amp gain ceiling from DT enforced by wsa884x, the SP VI full scale checked against DT, and the card running the speakers there. | upstream equivalent |
| `0780` | ours | Refuses a WSA RX graph unless SP RX and SP VI form one feedback loop fed by the V/I sense. | upstream equivalent |
| `0790` | ours | Two patches: a failed dB volume write latches a protection fault, and the card then switches the amplifiers off and stops the streams. | upstream equivalent |
| `0792` | ours | Playback buffers go to the DSP only while the stream runs. Without it, buffers written after a stop by a protection fault fill the GPR channel and the audio DSP stops answering until reboot. | upstream equivalent |
| `0795` | ours | Four patches: the wsa884x regmap leaves the SoundWire core registers alone, the WSA buses resume through a full reset and re-enumeration, an amplifier waits until it is really initialised again on resume, and the amplifiers' shared reset line is asserted while all of them are suspended. With them the speaker buses runtime-suspend, which lets the audio DSP drop its votes in sleep. | upstream equivalent |
| `0796` | ours | A DAI that unmutes on trigger stays muted at resume until its stream starts again, instead of being unmuted by the card resume. | upstream equivalent |
| `0797` | ours, based on armada | Two patches, based on armada [0530](https://github.com/armada-os/armada/blob/456a9afa94dea7d8c5362943572549e442602e91/packages/kernel/patches/0530-ASoC-qdsp6-release-AudioReach-graphs-across-system-suspend.patch) and [0528](https://github.com/armada-os/armada/blob/456a9afa94dea7d8c5362943572549e442602e91/packages/kernel/patches/0528-ASoC-qcom-sc8280xp-suspend-the-card-and-its-streams.patch): open PCMs release their AudioReach graphs across system suspend, and the x1e80100 card suspends its PCMs and releases their SoundWire streams. Without them a PCM left open at suspend keeps the audio DSP and speaker amplifiers awake. Needs `0796`. | upstream equivalent |
| `0798` | ours, based on armada | Four patches, three based on armada [0564](https://github.com/armada-os/armada/blob/50361d799946d7568f47f3ae90aae06298c1141d/packages/kernel/patches/0564-soundwire-qcom-force-runtime-suspend-across-system-sleep.patch), [0563](https://github.com/armada-os/armada/blob/98e87a10155988d4577d8e3397035bd698727196/packages/kernel/patches/0563-ASoC-codecs-lpass-macro-force-runtime-suspend-across-system-sleep.patch) and [0565](https://github.com/armada-os/armada/blob/98e87a10155988d4577d8e3397035bd698727196/packages/kernel/patches/0565-pinctrl-qcom-sm8650-lpass-lpi-force-runtime-suspend-across-system-sleep.patch): the SoundWire controllers, WSA amplifiers, WSA and VA macros and LPI pin controller force their runtime suspend across system sleep, so that an open stream no longer keeps them, and the SoC out of CX collapse, up. Needs `0797`. | upstream equivalent |
| `0810` | posted | Vikash Garodia, migrate-iommus v5 1-7/13 [lore](https://lore.kernel.org/r/20260926-vpu_iommu_iova_handling-v5-1-0322ca5dc10c@oss.qualcomm.com), taken from linux-msm/laptops-kernel [23e003ccce2d](https://github.com/linux-msm/laptops-kernel/commit/23e003ccce2dce3e4576e2a4e0d02595e9ef4c23) to [d175a83f3227](https://github.com/linux-msm/laptops-kernel/commit/d175a83f32271fad65be690d7e853cdf9d0f315c). v6 is posted. | merged upstream, or a later version replaces it |
| `0820` | posted | Vishnu Reddy, glymur v11 1-7/9 [lore](https://lore.kernel.org/r/20260917-glymur-v11-1-e0c8bc914742@oss.qualcomm.com), taken from linux-msm/laptops-kernel [689d6a290c39](https://github.com/linux-msm/laptops-kernel/commit/689d6a290c392768303c4a9d42077f066b6b8d7d) to [67d691c34989](https://github.com/linux-msm/laptops-kernel/commit/67d691c34989917a689b32ae09b06a9a3fda6135). 8/9 and 9/9 are `0980`. Needs `0810`. | merged upstream, or a later version replaces it |
| `0830` | posted | Vishnu Reddy, v1 1-2/3 [lore](https://lore.kernel.org/r/20261017-iris-handle-unbind-v1-1-7809148eb90f@oss.qualcomm.com). | in mainline |
| `0840` | posted | Vishnu Reddy, [lore](https://lore.kernel.org/r/20261017-fix-oob-tss-v1-1-fb86f4cabf65@oss.qualcomm.com). | in mainline |
| `0850` | posted | Vishnu Reddy, v1 1/2 [lore](https://lore.kernel.org/r/20261007-fix-disable-irq-safely-v1-1-45746f9a92de@oss.qualcomm.com). We don't carry 2/2, which has an open locking question. | in mainline |
| `0860` | community | Diogo Trindade, from armada [1030](https://github.com/armada-os/armada/blob/b031deef99a095104ef234c5a0705850152dffe1/packages/kernel/patches/1030-media-iris-send-the-stream-POC-type.patch) and [1031](https://github.com/armada-os/armada/blob/b031deef99a095104ef234c5a0705850152dffe1/packages/kernel/patches/1031-media-iris-stop-AV1-tier-overwriting-HEVC-tier.patch). Not posted. | merged upstream |
| `0870` | ours | Four patches, also carried in armada (1032-1037): low latency decode for game streaming. Off by default here (on in armada); `qcom_iris.low_latency=1` turns it on. | upstream equivalent |
| `0880` | community | Kettle Linux, from [kettlelinux 2b7661b4](https://github.com/kettlelinux/kettlelinux/blob/2b7661b4d937d7efbb487c4bba84f8705be7cc5d/kernel/patches/40-kettle/1370-media-iris-a-resolution-change-last-buffer-is-not-an-error.patch). Not posted. | merged upstream |
| `0890` | ours | Releases the PAS metadata that `0820` leaks on every firmware load. | fixed in the glymur series |
| `0910` | posted | Krishna Kurapati, v1 [lore](https://lore.kernel.org/r/20260803-glymur-dt-usb-fixes-v1-1-0f5f52853102@oss.qualcomm.com), taken from [linux-msm/laptops-kernel eab4913e40d5](https://github.com/linux-msm/laptops-kernel/commit/eab4913e40d5a219b1cb68d101426daef0be633d). `dtbs_check` warns until the snps,dwc3 binding update lands. | merged upstream |
| `0920` | posted | Peter Chen, [lore](https://lore.kernel.org/r/20261016091336.2715717-1-peter.chen@oss.qualcomm.com). Applied to qcom `arm64-for-7.5` as 45cf7caf5439. | base ≥ v7.5-rc1 |
| `0930` | posted | Manaf Meethalavalappu Pallikunhi, SPEL v3 4/4 [lore](https://lore.kernel.org/r/20260702-qcom_spel_driver_upstream-v3-4-434d50f0c5b0@oss.qualcomm.com), taken from linux-msm/laptops-kernel [7dd6f2dc1378](https://github.com/linux-msm/laptops-kernel/commit/7dd6f2dc13787e2847874392e4597c30a824a32e). Needs `0050`. | merged upstream, or v4 replaces it |
| `0940` | posted | Jason Pettit, v3 1/2 and 2/2 [lore](https://lore.kernel.org/r/20261108-hp-omnibook-v2-v3-1-f489fd0bdf33@oss.qualcomm.com), verbatim. 1/2 (binding) applied to qcom `arm64-for-7.5` as 9756ff591. | 2/2 merged upstream |
| `0950` | ours | SCMI polls for completions on this board. A glymur-wide version was proposed in [lore](https://lore.kernel.org/r/20260808172211.137577-1-jesse.casco@gmail.com). | the cause of the missed SCMI completions is fixed upstream, or the board DTS keeps the property |
| `0960` | posted | Jianping Li, v1 2/4 [lore](https://lore.kernel.org/r/20261015071511.977-3-jianping.li@oss.qualcomm.com). Reported applied to qcom as bcd702e52ae0. Required with `0240`. | in mainline |
| `0965` | posted | Ekansh Gupta, v5 2/2 [lore](https://lore.kernel.org/r/20261016-glymur-dtfix-v5-2-f56a8b94b4a9@oss.qualcomm.com). Applied to qcom `arm64-fixes-for-7.4` as 59cfafdd4. The CDSP's FastRPC context banks match their SIDs, which the NPU needs. `dtbs_check` warns about the hex unit addresses until the fastrpc binding accepts them. | in mainline |
| `0970` | ours | Two patches: V/I feedback on the WSA link with the woofer/tweeter names that match the hardware, and required protection with the measured operating point: PA gain ceiling +12 dB (PA Volume 25), full scale 5.4-5.7 V peak. The topology must carry the same full scale. | merged upstream |
| `0980` | posted | Vishnu Reddy, glymur v11 8-9/9 [lore](https://lore.kernel.org/r/20260917-glymur-v11-8-e0c8bc914742@oss.qualcomm.com), taken from linux-msm/laptops-kernel [f90e924adbf6](https://github.com/linux-msm/laptops-kernel/commit/f90e924adbf6db39cb06933765e1eb3dc5dd7b11), [484f23a89926](https://github.com/linux-msm/laptops-kernel/commit/484f23a89926b8f4402f3f630f85ff981d3e0dd6). | merged upstream, or a later version replaces it |
| `0990` | ours | Iris with HP's video firmware; the firmware stream (SID 0x19e2) is described for Linux to manage, as on the CRD. | merged upstream |
| `0995` | ours | No wake from the USB controllers: their PHY lines fire at every exit from CX collapse. | a fix for the PHY line glitch lands |
| `0997` | ours | The lid's wakeup is armed only if the lid is closed at suspend: its line also fires at every exit from CX collapse. Needs `0297`. | a fix for the lid line glitch lands |
| `0998` | ours | The embedded controller on I2C at 0x76 with its event line, and thermal zones for its three thermistors. Needs `0298`. | merged upstream |
