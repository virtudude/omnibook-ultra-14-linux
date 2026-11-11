# SPDX-License-Identifier: BSD-3-Clause
# Splitter-renderer (SPR) at the end of the stream subgraph, as in HP's Windows
# graph; module defaults, no parameters.
include(`util/util.m4') dnl
define(`MODULE_ID_SPR', `0x07001032') dnl
dnl AR_MODULE_SPR(index, sgidx, container-idx, iid, maxip-ports, max-op-ports, src-port, dst-port, dst-iid)
define(`AR_MODULE_SPR',
`SectionVendorTuples."NAME_PREFIX.spr$1_tuples" {'
`        tokens "audioreach_tokens"'
`'
`        tuples."word.u32_data" {'
`                AR_TKN_U32_MODULE_INSTANCE_ID STR($4)'
`                AR_TKN_U32_MODULE_ID STR(MODULE_ID_SPR)'
`                AR_TKN_U32_MODULE_MAX_IP_PORTS STR($5)'
`                AR_TKN_U32_MODULE_MAX_OP_PORTS STR($6)'
`                AR_TKN_U32_MODULE_SRC_OP_PORT_ID STR($7)'
`                AR_TKN_U32_MODULE_DST_IN_PORT_ID STR($8)'
`                AR_TKN_U32_MODULE_SRC_INSTANCE_ID STR($4)'
`                AR_TKN_U32_MODULE_DST_INSTANCE_ID STR($9)'
`        }'
`}'
`'
`SectionData."NAME_PREFIX.spr$1_data" {'
`        tuples "NAME_PREFIX.spr$1_tuples"'
`}'
`'
`SectionWidget."NAME_PREFIX.spr$1" {'
`        index STR($1)'
`        type "src"'
`        no_pm "true"'
`        subseq "10"'
`        data ['
`                "NAME_PREFIX.sub_graph$2_data"'
`                "NAME_PREFIX.container$3_data"'
`                "NAME_PREFIX.spr$1_data"'
`        ]'
`}') dnl
