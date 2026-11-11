# Based on audioreach-topology subgraph-device-codec-sp-dma-playback-4spkr.m4,
# Copyright, Linaro Ltd, 2025. Adds HP's speaker post-processing (2->4 mixer,
# SAL, volume, MSPP v5, SAL, lane mixer) and a tweeter high-pass ahead of SP.
# SPDX-License-Identifier: BSD-3-Clause
include(`audioreach/audioreach.m4') dnl
include(`util/pcm.m4') dnl
include(`audioreach/subgraph.m4') dnl
include(`audioreach/subgraph-control-link.m4') dnl
include(`audioreach/container.m4') dnl
include(`audioreach/control_link.m4') dnl
include(`audioreach/module_mfc.m4') dnl
include(`audioreach/module_mfc_post_sp_hp8f03.m4') dnl
include(`audioreach/module_log.m4') dnl
include(`audioreach/module_codec_dma.m4') dnl
include(`audioreach/module_speaker_protection_hp8f03.m4') dnl
include(`audioreach/module_msiir_hpf_hp8f03.m4') dnl
include(`audioreach/module_hp_pp_hp8f03.m4') dnl
include(`util/mixer.m4') dnl
dnl
#
# SubGraph for Device Backend
#
#  ______________________
# |   Sub Graph          |
# | [LOG] -> [DEVICE EP] |
# |______________________|

undefine(`CDC_DMA_MODULE_IID') dnl
undefine(`LOG_MODULE_IID') dnl
undefine(`SP_MODULE_IID') dnl
undefine(`MSIIR_MODULE_IID') dnl
undefine(`SG_INDEX') dnl
undefine(`CONTAINER_INDEX') dnl

undefine(`DEVICE_PERF_MODE') dnl
undefine(`DEVICE_DIRECTION') dnl
undefine(`CONT_SENARIO_ID') dnl
undefine(`CONT_CAP') dnl
undefine(`CONT_POSITION') dnl
undefine(`DEVICE_DOMAIN_ID') dnl
undefine(`CONT_STACK_SIZE') dnl

define(`PCM_PERF_MODE', APM_SG_PERF_MODE_LOW_LATENCY) dnl'
define(`PCM_DIRECTION', APM_SUB_GRAPH_DIRECTION_RX) dnl'
define(`DEVICE_PERF_MODE', APM_SG_PERF_MODE_LOW_LATENCY) dnl'
define(`DEVICE_DIRECTION', APM_SUB_GRAPH_DIRECTION_TX) dnl'
define(`CONT_SENARIO_ID', APM_SUB_GRAPH_SID_AUDIO_PLAYBACK) dnl'
define(`CONT_CAP', `ifelse(LPASS_VER_COMPAT, 110000, APM_CONTAINER_TYPE_ID_GC, APM_CONTAINER_CAP_ID_EP)') dnl'
define(`CONT_POSITION', APM_CONT_GRAPH_POS_STREAM)dnl'
define(`DEVICE_DOMAIN_ID', APM_PROC_DOMAIN_ID_ADSP) dnl'
define(`CONT_STACK_SIZE', 8192) dnl'
dnl
define(`LOG_MODULE_IID', MOD_IID_START) dnl
define(`MFC_MODULE_IID', eval(MOD_IID_START + 1)) dnl
define(`SP_MODULE_IID', eval(MOD_IID_START + 2)) dnl
define(`CDC_DMA_MODULE_IID', eval(MOD_IID_START + 3)) dnl
define(`CONTROL_LINK_IID', eval(MOD_IID_START + 4)) dnl
define(`MFC_POST_MODULE_IID', eval(MOD_IID_START + 5)) dnl
define(`MSIIR_MODULE_IID', eval(MOD_IID_START + 6)) dnl
define(`CHSPLIT_MODULE_IID', eval(MOD_IID_START + 7)) dnl
define(`SAL_IN_MODULE_IID', eval(MOD_IID_START + 8)) dnl
define(`SPKVOL_MODULE_IID', eval(MOD_IID_START + 9)) dnl
define(`MSPP_MODULE_IID', eval(MOD_IID_START + 10)) dnl
define(`SAL_OUT_MODULE_IID', eval(MOD_IID_START + 11)) dnl
define(`CHLANES_MODULE_IID', eval(MOD_IID_START + 12)) dnl
define(`SG_INDEX', 1) dnl
define(`CONTAINER_INDEX', 1) dnl
define(`MOD_INDEX', 1) dnl
dnl
dnl DEVICE_PLAYBACK_ROUTE(stream-index, dai-id)
define(`DEVICE_PLAYBACK_ROUTE',
`'
`SectionGraph."NAME_PREFIX.$1 $2 Graph" {'
`        index STR($1)'
`        lines ['
`                "NAME_PREFIX.chsplit$1, , $2 Audio Mixer"'
`                "NAME_PREFIX.salin$1, , NAME_PREFIX.chsplit$1"'
`                "NAME_PREFIX.spkvol$1, , NAME_PREFIX.salin$1"'
`                "NAME_PREFIX.mspp$1, , NAME_PREFIX.spkvol$1"'
`                "NAME_PREFIX.salout$1, , NAME_PREFIX.mspp$1"'
`                "NAME_PREFIX.chlanes$1, , NAME_PREFIX.salout$1"'
`                "NAME_PREFIX.mfc$1, , NAME_PREFIX.chlanes$1"'
`                "NAME_PREFIX.msiir$1, , NAME_PREFIX.mfc$1"'
`                "NAME_PREFIX.sp$1, , NAME_PREFIX.msiir$1"'
`                "NAME_PREFIX.mfcpost$1, , NAME_PREFIX.sp$1"'
`                "NAME_PREFIX.logger$1, , NAME_PREFIX.mfcpost$1"'
`                "NAME_PREFIX.codec_dma_rx$1, , NAME_PREFIX.logger$1"'
`                "$2 Playback, , NAME_PREFIX.codec_dma_rx$1"'
`        ]'
`}')

# Depends on SP_VI_MODULE_IID (eval(0x00006190 + 1)) defined in other subgraph
dnl AR_CONTROL_LINK(index, iid, peer1-iid, peer1-port, peer2-iid, peer2-port, intent0, intent1, intent2, intent3)
AR_CONTROL_LINK(SG_INDEX, CONTROL_LINK_IID, eval(0x00006190 + 1), 0x80000000, SP_MODULE_IID, 0x80000000, 0x8001204, 0, 0, 0)

AR_SUBGRAPH_CONTROL_LINK(SG_INDEX, DEVICE_DAI_ID, SG_IID_START, DEVICE_PERF_MODE, DEVICE_DIRECTION, CONT_SENARIO_ID)

AR_CONTAINER(CONTAINER_INDEX, CONT_IID_START, CONT_CAP, CONT_STACK_SIZE, CONT_POSITION, DEVICE_DOMAIN_ID)
dnl HP's post-processing runs in its own container, as on Windows: MSPP sets
dnl its own frame size, which the codec DMA endpoint container must not take
AR_CONTAINER(2, eval(CONT_IID_START + 1), APM_CONTAINER_TYPE_ID_SC, 16384, APM_CONT_GRAPH_POS_STR_DEV, DEVICE_DOMAIN_ID)
AR_MODULE_CHMIX_SPLIT_HP8F03(MOD_INDEX, SG_INDEX, 2, CHSPLIT_MODULE_IID, 1, 1, 1, 2, SAL_IN_MODULE_IID)
AR_MODULE_SAL_IN_HP8F03(MOD_INDEX, SG_INDEX, 2, SAL_IN_MODULE_IID, 1, 1, 1, 2, SPKVOL_MODULE_IID)
AR_MODULE_SPK_VOL_HP8F03(MOD_INDEX, SG_INDEX, 2, SPKVOL_MODULE_IID, 1, 1, 1, 2, MSPP_MODULE_IID)
AR_MODULE_MSPP_HP8F03(MOD_INDEX, SG_INDEX, 2, MSPP_MODULE_IID, 1, 1, 1, 2, SAL_OUT_MODULE_IID)
AR_MODULE_SAL_OUT_HP8F03(MOD_INDEX, SG_INDEX, 2, SAL_OUT_MODULE_IID, 1, 1, 1, 2, CHLANES_MODULE_IID)
AR_MODULE_CHMIX_LANES_HP8F03(MOD_INDEX, SG_INDEX, 2, CHLANES_MODULE_IID, 1, 1, 1, 2, MFC_MODULE_IID)
AR_MODULE_MFC(MOD_INDEX, SG_INDEX, CONTAINER_INDEX, MFC_MODULE_IID, 1, 1, 1, 2, MSIIR_MODULE_IID)
dnl Tweeter high-pass on the MFC's speaker-order channel types, ahead of SP (and of its pilot)
AR_MODULE_MSIIR_HPF_HP8F03(MOD_INDEX, SG_INDEX, CONTAINER_INDEX, MSIIR_MODULE_IID, 1, 1, 2, 1, 1, 2, SP_MODULE_IID)
AR_MODULE_SP_HP8F03(MOD_INDEX, SG_INDEX, CONTAINER_INDEX,   SP_MODULE_IID, 1, 1, 2, 1, 1, 2, MFC_POST_MODULE_IID)
dnl Puts the SP module's speaker order back into codec DMA lane order
AR_MODULE_MFC_POST_SP(MOD_INDEX, SG_INDEX, CONTAINER_INDEX, MFC_POST_MODULE_IID, 1, 1, 1, 2, LOG_MODULE_IID)
AR_MODULE_LOG(MOD_INDEX, SG_INDEX, CONTAINER_INDEX, 		LOG_MODULE_IID,     1, 1, 1, 2, 0x00001586, 1, 0, CDC_DMA_MODULE_IID)
AR_MODULE_CODEC_DMA_RX(MOD_INDEX, SG_INDEX, CONTAINER_INDEX, CDC_DMA_MODULE_IID, 1, 0, 1, 0, DEVICE_INTF_TYPE, DEVICE_INTF_INDEX, DEVICE_DATA_FORMAT, `DEVICE_NAME', NONE_IID)
DEVICE_PLAYBACK_ROUTE(MOD_INDEX, `DEVICE_NAME')
