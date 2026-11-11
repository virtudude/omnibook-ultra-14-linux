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
the same tree. When cross-compiling, export `ARCH=arm64` and `CROSS_COMPILE` first.

## Layout

The number is the apply order, and the range says the subsystem:

| Range | Band |
|---|---|
| `0000-0099` | clk, pmdomain, power supply, powercap |
| `0100-0199` | phy |
| `0200-0299` | soc, firmware, misc, efi |
| `0300-0399` | drm/msm |
| `0400-0499` | wifi, Bluetooth power sequencing |
| `0500-0799` | SoundWire and ASoC: posted and community work in the `0500s`, ours from `0600` |
| `0800-0899` | arm64 DTS and the board binding |

A dt-binding goes in the band of the driver that reads it. Numbers step by 10, so a new
patch fits between two old ones without renumbering.

Two patches that touch a common file must keep their relative order. Nothing else
constrains the order. Every file applies with `--fuzz=0`, so a wrong order fails instead of
landing a hunk in the wrong place. The one patch outside its band is `0530`: the RFC ends
with two DTS patches (glymur-crd, ThinkPad T14s Gen 7), kept in it so the series stays
whole. No other patch touches those files.

Each file is an mbox written by `git format-patch`. It holds one commit, or several
consecutive commits from one upstream series; then it starts with a `[PATCH 0/N]` cover
that lists each patch's author and Message-ID, and each commit keeps its own author,
message and trailers. Our own commits are grouped the same way where they build one
feature (`0660`, `0680`, `0710`, `0720`, `0740`, `0770`, `0880`). A fix that would be sent
upstream on its own keeps its own file.

## Provenance

- `mainline`: the change is in a mainline tag newer than our base. The row goes at the next
  rebase.
- `posted`: on a kernel mailing list, not in mainline. This includes RFCs and patches
  queued in a maintainer tree; Source says which.
- `community`: carried in another public tree, never posted.
- `ours`: written for this laptop, not posted.

Audited 2026-11-11 against v7.4-rc2. Merge state was looked up in git by subject and
patch-id, in mainline and in the maintainer trees named in Source; posting state comes
from lore. Recheck the Drop when column at each rebase.

| Patch | Origin | Source | Drop when |
|---|---|---|---|
| `0010` | posted | Jagadeesh Kona, [lore](https://lore.kernel.org/r/20261016-glymur-usb-ret-on-v1-1-1790a523fd9c@oss.qualcomm.com). Applied to qcom `clk-fixes-for-7.4` as 39477c344da4. USB resume from suspend. | in mainline |
| `0020` | posted | Taniya Das, [lore](https://lore.kernel.org/r/20261028-gcc_glymur_pcie-v1-1-a2163e1d2b9b@oss.qualcomm.com). Applied to qcom `clk-fixes-for-7.4` as 60521e4ff9e7. | in mainline |
| `0030` | posted | Oleg Keri, v1 [lore](https://lore.kernel.org/r/20261021080517.2161-1-okerixx@gmail.com). Without it the first GPU init times out. | in mainline |
| `0040` | community | Tyler Baker, from [EmbeddedAndroid/linux 0473e2eaf749](https://github.com/EmbeddedAndroid/linux/commit/0473e2eaf7499349316736611f95c8e0953c545c); also in [linux-msm/laptops-kernel 0964933967e8](https://github.com/linux-msm/laptops-kernel/commit/0964933967e8e343d50fd6a8a38b4fa8897be0f6). Not posted. Charger state updates. | merged upstream, or the firmware sends battery notifications |
| `0050` | posted | Manaf Meethalavalappu Pallikunhi, SPEL v3 1-3/4 [lore](https://lore.kernel.org/r/20260702-qcom_spel_driver_upstream-v3-1-434d50f0c5b0@oss.qualcomm.com), taken from linux-msm/laptops-kernel [555f3506cb34](https://github.com/linux-msm/laptops-kernel/commit/555f3506cb3474162d74d79501a4bc05124dc9d8), [75b451099ead](https://github.com/linux-msm/laptops-kernel/commit/75b451099eadcd05913f686521617f894c25cd32), [2feba0bac1ec](https://github.com/linux-msm/laptops-kernel/commit/2feba0bac1ec762580d11a21a6fc50affd6d1549). We dropped the MAINTAINERS hunks of 2/4 and 3/4. 4/4 is `0840`. SoC power readings. | merged upstream, or v4 replaces it |
| `0110` | posted | Konrad Dybcio, v1 1/2 [lore](https://lore.kernel.org/r/20261102-topic-usb3_sequence-v1-1-5b144f5e6865@oss.qualcomm.com). We carry 1/2 only. USB SuperSpeed. | in mainline, or a later version replaces it |
| `0120` | posted | Elson Serrao, v2 posted by Peter Chen, [lore](https://lore.kernel.org/r/20261027015545.2758784-1-peter.chen@oss.qualcomm.com). | in mainline |
| `0210` | posted | Krzysztof Kozlowski, three patches [lore](https://lore.kernel.org/r/20261103145635.309032-4-krzysztof.kozlowski@oss.qualcomm.com). Applied to qcom `drivers-for-7.5` as e6f64f9b76d5, a5d51dee5f57, 85fadab9958b. | base ≥ v7.5-rc1 |
| `0220` | posted | Mohit Sharma, v1 2/2 [lore](https://lore.kernel.org/r/20261022144130.2443667-3-mohit.sharma@oss.qualcomm.com); 1/2 is in v7.4-rc2. Removes a 5 s audio stall at boot. | in mainline |
| `0230` | posted | Jason Pettit, [lore](https://lore.kernel.org/r/20261101-hp-omnibook-v2-v2-3-1b99767deda0@oss.qualcomm.com). Applied to qcom `drivers-for-7.5` as 72bd92c0115f. UEFI variables. | base ≥ v7.5-rc1 |
| `0240` | posted | Anandu Krishnan E, v3 [lore](https://lore.kernel.org/r/20261027-fastrpc-kvm-iommu-v3-v3-1-f3cd5c030c78@oss.qualcomm.com). Lets the audio PD load the speaker protection module. Never carry without `0870`. | in mainline |
| `0250` | ours | NULL dereference when uefisecapp unbinds. `0690` reads EFI variables through it. | upstream equivalent |
| `0310` | posted | Connor Abbott, v2 [lore](https://lore.kernel.org/r/20261029-drm-msm-gmem-base-fix-v2-1-26b338471b46@gmail.com). Queued in drm/msm `msm-fixes`. | in mainline |
| `0320` | posted | Akhil P Oommen, Jie Zhang, "assorted-fixes-oct" v1 1-8/8 [lore](https://lore.kernel.org/r/20261024-assorted-fixes-oct-v1-1-2977f974ddb7@oss.qualcomm.com). Queued in drm/msm `msm-fixes`. 8/8 needs `qcom/gen80100_aqe.fw`. | in mainline |
| `0330` | posted | Rob Clark, [lore](https://lore.kernel.org/r/20261029001601.82269-1-robin.clark@oss.qualcomm.com). Queued in drm/msm `msm-fixes`. | in mainline |
| `0340` | posted | Rob Clark, four VM_BIND fixes [lore](https://lore.kernel.org/r/20261102172001.508440-2-robin.clark@oss.qualcomm.com). Queued in drm/msm `msm-fixes`. | in mainline |
| `0350` | posted | Rob Clark, [lore](https://lore.kernel.org/r/20261104212048.21010-1-robin.clark@oss.qualcomm.com). Queued in drm/msm `msm-fixes`. | in mainline |
| `0360` | posted | Bart Van Assche, [lore](https://lore.kernel.org/r/9671164f87138a0caf5c69b66129bbd6faf932f8.1793044688.git.bvanassche@acm.org). Queued in drm/msm `msm-fixes`. | in mainline |
| `0370` | posted | Burke Cates, v1 [lore](https://lore.kernel.org/r/20261104072048.3486286-1-burke.cates@gmail.com). A failed link training no longer resets the SoC on the next blank. | in mainline |
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
| `0640` | ours | The calibration state control showed the previous run. | upstream equivalent |
| `0650` | ours | A volume limit that failed left the speakers at reset gain. | upstream equivalent |
| `0660` | ours | Two patches: raw V/I sense capture at 8 kHz S32_LE, channel labels the MFC passes through. | upstream equivalent |
| `0670` | ours | Out-of-bounds read on a module with too many output ports. | upstream equivalent |
| `0680` | ours | Eleven patches: lane order (Glymur lanes alternate between the two WSA macros), the V/I guard, checked calibration results, one checked SP RX/SP VI pass, `qcom,speaker-protection-required`, and their bindings (the WSA link has 18 DAIs). | upstream equivalent |
| `0690` | ours | Factory R0/T0 from the `SmartAmpCalibrationData` UEFI variable. Needs `0250`. | upstream equivalent |
| `0700` | ours | 2S battery settings, based on Jens Glathe's Surface Pro 11 change. | upstream equivalent |
| `0710` | ours | Three patches: DSP high-pass for the tweeters, mix-path volume limit, nothing after SP RX may remix or amplify. | upstream equivalent |
| `0720` | ours | Three patches: APM transaction tokens, large SET_CFG payloads through shared memory, teardown of failed graphs. | upstream equivalent |
| `0730` | ours | Bounds checks on topology private data. | upstream equivalent |
| `0740` | ours | Three patches: large records out of band, MSPP/SAL/channel mixer parameters from the topology, `Speaker Playback Volume` in dB mirrored into MSPP. | upstream equivalent |
| `0750` | ours | Stereo front end, split to the four speakers in the DSP. | upstream equivalent |
| `0760` | ours | Off unless `snd_q6apm.sp_vi_tap_debug=1`. | upstream equivalent |
| `0770` | ours | Five patches: per-amp gain ceiling and full scale in DT, enforced by wsa884x, checked against SP VI, applied by the card. | upstream equivalent |
| `0810` | community | Birk Skyum, from [omarchy-pkgs 4ec454cb](https://github.com/omacom/omarchy-pkgs/blob/4ec454cbc3623eb8b096612655407594e6bb7adf/pkgbuilds/linux-omarchy-aarch64/2210-arm64-dts-qcom-hamoa-glymur-Disable-the-crypto-engine.patch). We keep the glymur hunk only. Lets the interconnects reach sync_state, needed for s2idle. | the crypto engine works upstream, or a DT patch is merged |
| `0820` | posted | Krishna Kurapati, v1 [lore](https://lore.kernel.org/r/20260803-glymur-dt-usb-fixes-v1-1-0f5f52853102@oss.qualcomm.com), taken from [linux-msm/laptops-kernel eab4913e40d5](https://github.com/linux-msm/laptops-kernel/commit/eab4913e40d5a219b1cb68d101426daef0be633d). `dtbs_check` warns until the snps,dwc3 binding update lands. | merged upstream |
| `0830` | posted | Peter Chen, [lore](https://lore.kernel.org/r/20261016091336.2715717-1-peter.chen@oss.qualcomm.com). Applied to qcom `arm64-for-7.5` as 45cf7caf5439. | base ≥ v7.5-rc1 |
| `0840` | posted | Manaf Meethalavalappu Pallikunhi, SPEL v3 4/4 [lore](https://lore.kernel.org/r/20260702-qcom_spel_driver_upstream-v3-4-434d50f0c5b0@oss.qualcomm.com), taken from linux-msm/laptops-kernel [7dd6f2dc1378](https://github.com/linux-msm/laptops-kernel/commit/7dd6f2dc13787e2847874392e4597c30a824a32e). Needs `0050`. | merged upstream, or v4 replaces it |
| `0850` | posted | Jason Pettit, v3 1/2 and 2/2 [lore](https://lore.kernel.org/r/20261108-hp-omnibook-v2-v3-1-f489fd0bdf33@oss.qualcomm.com), verbatim. 1/2 (binding) applied to qcom `arm64-for-7.5` as 9756ff591. | 2/2 merged upstream |
| `0860` | ours | SCMI polls for completions on this board. A glymur-wide version was proposed in [lore](https://lore.kernel.org/r/20260808172211.137577-1-jesse.casco@gmail.com). | CPUCP mailbox/SCMI probe ordering fixed upstream, or the board DTS keeps the property |
| `0870` | posted | Jianping Li, v1 2/4 [lore](https://lore.kernel.org/r/20261015071511.977-3-jianping.li@oss.qualcomm.com). Reported applied to qcom as bcd702e52ae0. Required with `0240`. | in mainline |
| `0880` | ours | Four patches: V/I feedback on the WSA link, woofer/tweeter names swapped to match the hardware, required protection, and the measured operating point. | merged upstream |
