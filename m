From: Dave Airlie <airlied@redhat.com>
Date: Thu, 12 Nov 2026 11:43:48 +1000
Subject: [PATCH 13/19] drm/amd/display: Move struct dc out of the public
 dc.h
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-amdgpu-dc-cleanup-v1-13-0fae41718ad2@redhat.com>
References: <20261112-amdgpu-dc-cleanup-v1-0-0fae41718ad2@redhat.com>
In-Reply-To: <20261112-amdgpu-dc-cleanup-v1-0-0fae41718ad2@redhat.com>
To: Harry Wentland <harry.wentland@amd.com>, Leo Li <sunpeng.li@amd.com>, 
 Rodrigo Siqueira <siqueira@igalia.com>, 
 Alex Deucher <alexander.deucher@amd.com>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 David Airlie <airlied@gmail.com>, Austin Zheng <austin.zheng@amd.com>, 
 Jun Lei <jun.lei@amd.com>, Kenneth Feng <kenneth.feng@amd.com>
Cc: amd-gfx@lists.freedesktop.org, dri-devel@lists.freedesktop.org, 
 Dave Airlie <airlied@redhat.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=167431; i=airlied@redhat.com;
 h=from:subject:message-id; bh=M4lkQB2nKFz3I1ZZ/8K2WMcXyvZB218QHE1AB5Hf+W0=;
 b=owEBbQKS/ZANAwAKAQx081l5xIa+AcsmYgBq9RnQrKgUPkQftc0jBHL/ZTcQY4D231adIFiKQ
 niqbyAm5DmJAjMEAAEKAB0WIQQQptkdobBb0p9t66wMdPNZecSGvgUCavUZ0AAKCRAMdPNZecSG
 vj/CEACss5qyb+z+S2aWa2oZdiwSAdnH7pNNSLmyR28ZSYPtvKyQbT4/Whb+HOfYiXxCGpzuddA
 jJ6XYcZChLpq25axpxgw0VNSw+FT86BO56h+yhozH+aGTL1OZOMRxmhw2mMwgfpMyQDUvftR3cf
 YYvD7sfWYJiqTS5ts5aAjwzLb4/rIFeYiBfdEjP8LR+DaiqyuhKYXMiuhhxuRuioUlW3HknENcm
 WQKJiYQ8P0hKMT5QG48vp0YemCsXOCsOIbO+toDNs/V7sin9E2Mxj1O1j8dw7yd0zVlwznKrOBo
 jhjENy07gp19ej2dyulItgkW2UXI5FyxzmayHK0wH2kbF3MpGUjewwiluxuxmwbNEzinLsK+GhC
 3jQUJ6darWAWDv/hBnADCwgHVSCJXP7D7RiJ99eMvmKwKios/s+Td7WSNEBEzM5HWB+aYcko0ol
 QjxmQTI2Cms4J+GnXCjkqxP92/LDEFC/N7MI1Jhgg0darfc+Xui251rprlHqCEBDdGadxI76z6j
 a6SmFmjQcKZB4DAByFvFBzEjvhtQlzBKB019dua96ys6JbmsnfWkK+OO5DTcAhP5H0kaDw8AVNw
 sRr79gLxlLef4qlt/K/66qq/xHQQ9t6/OcOttY2lR8GopF+Vin12Mi2H8bdWYOgszgxoBgm9EWk
 wsHZXKkmbILnRjQ==
X-Developer-Key: i=airlied@redhat.com; a=openpgp;
 fpr=10A6D91DA1B05BD29F6DEBAC0C74F35979C486BE
X-Endpoint-Received: by B4 Relay for airlied@redhat.com/default with auth_id=1321
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

struct dc is now defined in the new dc/dc_priv.h, which must only be
included from inside the dc directory. dc.h keeps the public API and
public types and forward-declares struct dc; consumers outside DC hold
opaque pointers and go through the accessor layer.

Also move the BW_VAL_TRACE_* macros, which dereference a dc-local
variable, from dc.h into dc_priv.h.

Update DC-internal includes accordingly (~300 files gain an include of
dc_priv.h next to their existing dc.h include or at the end of their
include block). With this, code outside the dc directory can no
longer compile against struct dc members: the compiler enforces the
boundary.

Signed-off-by: Dave Airlie <airlied@redhat.com>
---
 .../display/amdgpu_dm/tests/amdgpu_dm_audio_test.c |   6 +-
 .../display/amdgpu_dm/tests/amdgpu_dm_color_test.c |   4 +-
 .../amdgpu_dm/tests/amdgpu_dm_connector_test.c     |  12 +-
 .../display/amdgpu_dm/tests/amdgpu_dm_crc_test.c   |   2 +-
 .../amdgpu_dm/tests/amdgpu_dm_freesync_test.c      |   2 +-
 .../amdgpu_dm/tests/amdgpu_dm_helpers_test.c       |   4 +-
 .../display/amdgpu_dm/tests/amdgpu_dm_plane_test.c |   2 +-
 drivers/gpu/drm/amd/display/dc/basics/dce_calcs.c  |   1 +
 drivers/gpu/drm/amd/display/dc/bios/bios_parser2.c |   1 +
 .../gpu/drm/amd/display/dc/bios/command_table2.c   |   1 +
 .../drm/amd/display/dc/bls_builder/bls_builder.c   |   1 +
 .../display/dc/bls_builder/dcn401_init_builder.c   |   1 +
 .../dc/bls_builder/dcn401_init_builder_legacy.c    |   1 +
 .../drm/amd/display/dc/bls_executor/bls_executor.c |   1 +
 drivers/gpu/drm/amd/display/dc/clk_mgr/clk_mgr.c   |   1 +
 .../amd/display/dc/clk_mgr/dce100/dce_clk_mgr.c    |   1 +
 .../amd/display/dc/clk_mgr/dce110/dce110_clk_mgr.c |   1 +
 .../amd/display/dc/clk_mgr/dce112/dce112_clk_mgr.c |   1 +
 .../amd/display/dc/clk_mgr/dce120/dce120_clk_mgr.c |   1 +
 .../amd/display/dc/clk_mgr/dcn10/dcn10_clk_mgr.c   |   1 +
 .../drm/amd/display/dc/clk_mgr/dcn10/rv1_clk_mgr.c |   1 +
 .../dc/clk_mgr/dcn10/rv1_clk_mgr_vbios_smu.c       |   1 +
 .../amd/display/dc/clk_mgr/dcn20/dcn20_clk_mgr.c   |   1 +
 .../amd/display/dc/clk_mgr/dcn201/dcn201_clk_mgr.c |   1 +
 .../drm/amd/display/dc/clk_mgr/dcn21/rn_clk_mgr.c  |   1 +
 .../dc/clk_mgr/dcn21/rn_clk_mgr_vbios_smu.c        |   1 +
 .../amd/display/dc/clk_mgr/dcn30/dcn30_clk_mgr.c   |   1 +
 .../drm/amd/display/dc/clk_mgr/dcn301/vg_clk_mgr.c |   1 +
 .../amd/display/dc/clk_mgr/dcn31/dcn31_clk_mgr.c   |   1 +
 .../drm/amd/display/dc/clk_mgr/dcn31/dcn31_smu.c   |   1 +
 .../amd/display/dc/clk_mgr/dcn314/dcn314_clk_mgr.c |   1 +
 .../drm/amd/display/dc/clk_mgr/dcn314/dcn314_smu.c |   1 +
 .../amd/display/dc/clk_mgr/dcn315/dcn315_clk_mgr.c |   1 +
 .../drm/amd/display/dc/clk_mgr/dcn315/dcn315_smu.c |   1 +
 .../amd/display/dc/clk_mgr/dcn316/dcn316_clk_mgr.c |   1 +
 .../drm/amd/display/dc/clk_mgr/dcn316/dcn316_smu.c |   1 +
 .../amd/display/dc/clk_mgr/dcn32/dcn32_clk_mgr.c   |   1 +
 .../amd/display/dc/clk_mgr/dcn35/dcn35_clk_mgr.c   |   1 +
 .../drm/amd/display/dc/clk_mgr/dcn35/dcn35_smu.c   |   1 +
 .../amd/display/dc/clk_mgr/dcn401/dcn401_clk_mgr.c |   1 +
 .../amd/display/dc/clk_mgr/dcn42/dcn42_clk_mgr.c   |   1 +
 .../drm/amd/display/dc/clk_mgr/dcn42/dcn42_smu.c   |   1 +
 .../amd/display/dc/clk_mgr/dcn42b/dcn42b_clk_mgr.c |   1 +
 .../amd/display/dc/clk_mgr/dcn60/dcn60_clk_mgr.c   |   1 +
 drivers/gpu/drm/amd/display/dc/core/dc_accessors.c |   1 +
 drivers/gpu/drm/amd/display/dc/core/dc_debug.c     |   1 +
 .../gpu/drm/amd/display/dc/core/dc_hw_sequencer.c  |   1 +
 .../gpu/drm/amd/display/dc/core/dc_link_enc_cfg.c  |   1 +
 .../gpu/drm/amd/display/dc/core/dc_link_exports.c  |   1 +
 drivers/gpu/drm/amd/display/dc/core/dc_resource.c  |   1 +
 drivers/gpu/drm/amd/display/dc/core/dc_stat.c      |   1 +
 drivers/gpu/drm/amd/display/dc/core/dc_state.c     |   1 +
 drivers/gpu/drm/amd/display/dc/core/dc_stream.c    |   1 +
 drivers/gpu/drm/amd/display/dc/core/dc_surface.c   |   1 +
 drivers/gpu/drm/amd/display/dc/core/dc_test.c      |   1 +
 drivers/gpu/drm/amd/display/dc/core/dc_vm_helper.c |   1 +
 drivers/gpu/drm/amd/display/dc/dc.h                | 131 ---------------
 .../drm/amd/display/dc/dc_api_dispatch/api_shim.h  |   1 +
 drivers/gpu/drm/amd/display/dc/dc_dmub_srv.c       |   1 +
 drivers/gpu/drm/amd/display/dc/dc_priv.h           | 186 +++++++++++++++++++++
 drivers/gpu/drm/amd/display/dc/dc_spl_translate.c  |   1 +
 .../gpu/drm/amd/display/dc/dccg/dcn31/dcn31_dccg.c |   1 +
 .../drm/amd/display/dc/dccg/dcn314/dcn314_dccg.c   |   1 +
 .../gpu/drm/amd/display/dc/dccg/dcn35/dcn35_dccg.c |   1 +
 .../drm/amd/display/dc/dccg/dcn401/dcn401_dccg.c   |   1 +
 .../gpu/drm/amd/display/dc/dccg/dcn42/dcn42_dccg.c |   1 +
 drivers/gpu/drm/amd/display/dc/dce/dce_aux.c       |   1 +
 .../gpu/drm/amd/display/dc/dce/dce_clock_source.c  |   1 +
 drivers/gpu/drm/amd/display/dc/dce/dce_dmcu.c      |   1 +
 drivers/gpu/drm/amd/display/dc/dce/dce_i2c.c       |   1 +
 drivers/gpu/drm/amd/display/dc/dce/dce_i2c_hw.c    |   1 +
 .../gpu/drm/amd/display/dc/dce/dce_link_encoder.c  |   1 +
 drivers/gpu/drm/amd/display/dc/dce/dce_mem_input.c |   1 +
 drivers/gpu/drm/amd/display/dc/dce/dce_transform.c |   1 +
 drivers/gpu/drm/amd/display/dc/dce/dmub_abm.c      |   1 +
 drivers/gpu/drm/amd/display/dc/dce/dmub_abm_cacp.c |   1 +
 drivers/gpu/drm/amd/display/dc/dce/dmub_abm_lcd.c  |   1 +
 .../gpu/drm/amd/display/dc/dce/dmub_hw_lock_mgr.c  |   1 +
 drivers/gpu/drm/amd/display/dc/dce/dmub_psr.c      |   1 +
 drivers/gpu/drm/amd/display/dc/dce/dmub_replay.c   |   1 +
 .../drm/amd/display/dc/dce110/dce110_mem_input_v.c |   1 +
 .../drm/amd/display/dc/dce110/dce110_transform_v.c |   1 +
 .../display/dc/dcn10/dcn10_hw_sequencer_debug.c    |   1 +
 .../amd/display/dc/dcn201/dcn201_link_encoder.c    |   1 +
 .../drm/amd/display/dc/dcn21/dcn21_link_encoder.c  |   1 +
 drivers/gpu/drm/amd/display/dc/dcn31/dcn31_afmt.c  |   1 +
 .../drm/amd/display/dc/dcn31/dcn31_panel_cntl.c    |   1 +
 drivers/gpu/drm/amd/display/dc/dcn31/dcn31_vpg.c   |   1 +
 .../amd/display/dc/dio/dcn10/dcn10_link_encoder.c  |   1 +
 .../display/dc/dio/dcn10/dcn10_stream_encoder.c    |   1 +
 .../amd/display/dc/dio/dcn20/dcn20_link_encoder.c  |   1 +
 .../display/dc/dio/dcn20/dcn20_stream_encoder.c    |   1 +
 .../display/dc/dio/dcn30/dcn30_dio_link_encoder.c  |   1 +
 .../dc/dio/dcn30/dcn30_dio_stream_encoder.c        |   1 +
 .../dc/dio/dcn301/dcn301_dio_link_encoder.c        |   1 +
 .../display/dc/dio/dcn31/dcn31_dio_link_encoder.c  |   1 +
 .../dc/dio/dcn314/dcn314_dio_stream_encoder.c      |   1 +
 .../display/dc/dio/dcn32/dcn32_dio_link_encoder.c  |   1 +
 .../dc/dio/dcn32/dcn32_dio_stream_encoder.c        |   1 +
 .../dc/dio/dcn321/dcn321_dio_link_encoder.c        |   1 +
 .../display/dc/dio/dcn35/dcn35_dio_link_encoder.c  |   1 +
 .../dc/dio/dcn35/dcn35_dio_stream_encoder.c        |   1 +
 .../dc/dio/dcn401/dcn401_dio_link_encoder.c        |   1 +
 .../dc/dio/dcn401/dcn401_dio_stream_encoder.c      |   1 +
 .../display/dc/dio/dcn42/dcn42_dio_link_encoder.c  |   1 +
 .../dc/dio/dcn42/dcn42_dio_stream_encoder.c        |   1 +
 .../display/dc/dio/dcn60/dcn60_dio_link_encoder.c  |   1 +
 .../dc/dio/dcn60/dcn60_dio_stream_encoder.c        |   1 +
 .../gpu/drm/amd/display/dc/dml/calcs/dcn_calcs.c   |   1 +
 .../gpu/drm/amd/display/dc/dml/dcn10/dcn10_fpu.c   |   1 +
 .../gpu/drm/amd/display/dc/dml/dcn20/dcn20_fpu.c   |   1 +
 .../gpu/drm/amd/display/dc/dml/dcn30/dcn30_fpu.c   |   1 +
 .../gpu/drm/amd/display/dc/dml/dcn301/dcn301_fpu.c |   1 +
 .../gpu/drm/amd/display/dc/dml/dcn302/dcn302_fpu.c |   1 +
 .../gpu/drm/amd/display/dc/dml/dcn303/dcn303_fpu.c |   1 +
 .../gpu/drm/amd/display/dc/dml/dcn31/dcn31_fpu.c   |   1 +
 .../gpu/drm/amd/display/dc/dml/dcn314/dcn314_fpu.c |   1 +
 .../gpu/drm/amd/display/dc/dml/dcn32/dcn32_fpu.c   |   1 +
 .../gpu/drm/amd/display/dc/dml/dcn321/dcn321_fpu.c |   1 +
 .../gpu/drm/amd/display/dc/dml/dcn35/dcn35_fpu.c   |   1 +
 .../gpu/drm/amd/display/dc/dml/dcn351/dcn351_fpu.c |   1 +
 .../dml21_wrapper/dml21_translation_helper.c       |   1 +
 .../dc/dml2_wrapper/dml21_wrapper/dml21_utils.c    |   1 +
 .../dml2_wrapper/dml21_wrapper/dml21_wrapper_fpu.c |   1 +
 .../dc/dml2_wrapper/dml2_dc_resource_mgmt.c        |   1 +
 .../display/dc/dml2_wrapper/dml2_mall_phantom.c    |   1 +
 .../dc/dml2_wrapper/dml2_translation_helper.c      |   1 +
 .../drm/amd/display/dc/dml2_wrapper/dml2_utils.c   |   1 +
 .../drm/amd/display/dc/dml2_wrapper/dml2_wrapper.c |   1 +
 .../amd/display/dc/dml2_wrapper/dml2_wrapper_fpu.c |   1 +
 .../gpu/drm/amd/display/dc/dpp/dcn10/dcn10_dpp.c   |   1 +
 .../drm/amd/display/dc/dpp/dcn10/dcn10_dpp_dscl.c  |   1 +
 .../drm/amd/display/dc/dpp/dcn20/dcn20_dpp_cm.c    |   1 +
 .../gpu/drm/amd/display/dc/dpp/dcn201/dcn201_dpp.c |   1 +
 .../gpu/drm/amd/display/dc/dpp/dcn30/dcn30_dpp.c   |   1 +
 .../drm/amd/display/dc/dpp/dcn30/dcn30_dpp_cm.c    |   1 +
 .../amd/display/dc/dpp/dcn401/dcn401_dpp_dscl.c    |   1 +
 .../drm/amd/display/dc/dpp/dcn60/dcn60_dpp_cm.c    |   1 +
 .../drm/amd/display/dc/dpp/dcn60/dcn60_dpp_dscl.c  |   1 +
 drivers/gpu/drm/amd/display/dc/dsc/dc_dsc.c        |   1 +
 drivers/gpu/drm/amd/display/dc/hdcp/hdcp_msg.c     |   1 +
 .../dc/hpo/dcn30/dcn30_hpo_frl_link_encoder.c      |   1 +
 .../drm/amd/display/dc/hubbub/dcn10/dcn10_hubbub.c |   1 +
 .../drm/amd/display/dc/hubbub/dcn20/dcn20_hubbub.c |   1 +
 .../amd/display/dc/hubbub/dcn201/dcn201_hubbub.c   |   1 +
 .../drm/amd/display/dc/hubbub/dcn21/dcn21_hubbub.c |   1 +
 .../drm/amd/display/dc/hubbub/dcn30/dcn30_hubbub.c |   1 +
 .../drm/amd/display/dc/hubbub/dcn31/dcn31_hubbub.c |   1 +
 .../drm/amd/display/dc/hubbub/dcn32/dcn32_hubbub.c |   1 +
 .../drm/amd/display/dc/hubbub/dcn35/dcn35_hubbub.c |   1 +
 .../amd/display/dc/hubbub/dcn401/dcn401_hubbub.c   |   1 +
 .../drm/amd/display/dc/hubbub/dcn42/dcn42_hubbub.c |   1 +
 .../drm/amd/display/dc/hubbub/dcn60/dcn60_hubbub.c |   1 +
 .../gpu/drm/amd/display/dc/hubp/dcn21/dcn21_hubp.c |   1 +
 .../gpu/drm/amd/display/dc/hubp/dcn35/dcn35_hubp.c |   1 +
 .../gpu/drm/amd/display/dc/hubp/dcn42/dcn42_hubp.c |   1 +
 .../gpu/drm/amd/display/dc/hwss/dce/dce_hwseq.c    |   1 +
 .../drm/amd/display/dc/hwss/dce100/dce100_hwseq.c  |   1 +
 .../drm/amd/display/dc/hwss/dce110/dce110_hwseq.c  |   1 +
 .../drm/amd/display/dc/hwss/dce112/dce112_hwseq.c  |   1 +
 .../drm/amd/display/dc/hwss/dce120/dce120_hwseq.c  |   1 +
 .../drm/amd/display/dc/hwss/dce60/dce60_hwseq.c    |   1 +
 .../drm/amd/display/dc/hwss/dce80/dce80_hwseq.c    |   1 +
 .../drm/amd/display/dc/hwss/dcn10/dcn10_hwseq.c    |   1 +
 .../gpu/drm/amd/display/dc/hwss/dcn10/dcn10_init.c |   1 +
 .../drm/amd/display/dc/hwss/dcn20/dcn20_hwseq.c    |   1 +
 .../gpu/drm/amd/display/dc/hwss/dcn20/dcn20_init.c |   1 +
 .../drm/amd/display/dc/hwss/dcn201/dcn201_hwseq.c  |   1 +
 .../drm/amd/display/dc/hwss/dcn201/dcn201_init.c   |   1 +
 .../drm/amd/display/dc/hwss/dcn21/dcn21_hwseq.c    |   1 +
 .../gpu/drm/amd/display/dc/hwss/dcn21/dcn21_init.c |   1 +
 .../drm/amd/display/dc/hwss/dcn30/dcn30_hwseq.c    |   1 +
 .../gpu/drm/amd/display/dc/hwss/dcn30/dcn30_init.c |   1 +
 .../drm/amd/display/dc/hwss/dcn301/dcn301_init.c   |   1 +
 .../drm/amd/display/dc/hwss/dcn302/dcn302_hwseq.c  |   1 +
 .../drm/amd/display/dc/hwss/dcn302/dcn302_init.c   |   1 +
 .../drm/amd/display/dc/hwss/dcn303/dcn303_init.c   |   1 +
 .../drm/amd/display/dc/hwss/dcn31/dcn31_hwseq.c    |   1 +
 .../gpu/drm/amd/display/dc/hwss/dcn31/dcn31_init.c |   1 +
 .../drm/amd/display/dc/hwss/dcn314/dcn314_hwseq.c  |   1 +
 .../drm/amd/display/dc/hwss/dcn314/dcn314_init.c   |   1 +
 .../drm/amd/display/dc/hwss/dcn32/dcn32_hwseq.c    |   1 +
 .../gpu/drm/amd/display/dc/hwss/dcn32/dcn32_init.c |   1 +
 .../drm/amd/display/dc/hwss/dcn35/dcn35_hwseq.c    |   1 +
 .../gpu/drm/amd/display/dc/hwss/dcn35/dcn35_init.c |   1 +
 .../drm/amd/display/dc/hwss/dcn351/dcn351_hwseq.c  |   1 +
 .../drm/amd/display/dc/hwss/dcn351/dcn351_init.c   |   1 +
 .../drm/amd/display/dc/hwss/dcn401/dcn401_hwseq.c  |   1 +
 .../drm/amd/display/dc/hwss/dcn401/dcn401_init.c   |   1 +
 .../drm/amd/display/dc/hwss/dcn42/dcn42_hwseq.c    |   1 +
 .../gpu/drm/amd/display/dc/hwss/dcn42/dcn42_init.c |   1 +
 .../drm/amd/display/dc/hwss/dcn42b/dcn42b_hwseq.c  |   1 +
 .../drm/amd/display/dc/hwss/dcn42b/dcn42b_init.c   |   1 +
 .../drm/amd/display/dc/hwss/dcn50/dcn50_hwseq.c    |   1 +
 .../drm/amd/display/dc/hwss/dcn60/dcn60_hwseq.c    |   1 +
 .../gpu/drm/amd/display/dc/hwss/dcn60/dcn60_init.c |   1 +
 .../amd/display/dc/irq/dce110/irq_service_dce110.c |   1 +
 .../amd/display/dc/link/accessories/link_dp_cts.c  |   1 +
 .../display/dc/link/accessories/link_dp_trace.c    |   1 +
 .../drm/amd/display/dc/link/hwss/link_hwss_dio.c   |   1 +
 .../link/hwss/link_hwss_dio_fixed_vs_pe_retimer.c  |   1 +
 .../drm/amd/display/dc/link/hwss/link_hwss_dpia.c  |   1 +
 .../amd/display/dc/link/hwss/link_hwss_hpo_dp.c    |   1 +
 .../hwss/link_hwss_hpo_fixed_vs_pe_retimer_dp.c    |   1 +
 .../amd/display/dc/link/hwss/link_hwss_hpo_frl.c   |   1 +
 .../gpu/drm/amd/display/dc/link/link_detection.c   |   1 +
 drivers/gpu/drm/amd/display/dc/link/link_dpms.c    |   1 +
 drivers/gpu/drm/amd/display/dc/link/link_factory.c |   1 +
 .../gpu/drm/amd/display/dc/link/link_resource.c    |   1 +
 .../gpu/drm/amd/display/dc/link/link_validation.c  |   1 +
 .../drm/amd/display/dc/link/protocols/link_ddc.c   |   1 +
 .../display/dc/link/protocols/link_dp_capability.c |   1 +
 .../display/dc/link/protocols/link_dp_dpia_bw.c    |   1 +
 .../dc/link/protocols/link_dp_irq_handler.c        |   1 +
 .../dc/link/protocols/link_dp_panel_replay.c       |   1 +
 .../amd/display/dc/link/protocols/link_dp_phy.c    |   1 +
 .../display/dc/link/protocols/link_dp_training.c   |   1 +
 .../dc/link/protocols/link_dp_training_128b_132b.c |   1 +
 .../dc/link/protocols/link_dp_training_8b_10b.c    |   1 +
 .../dc/link/protocols/link_dp_training_dpia.c      |   1 +
 .../link_dp_training_fixed_vs_pe_retimer.c         |   1 +
 .../dc/link/protocols/link_edp_panel_control.c     |   1 +
 .../amd/display/dc/link/protocols/link_hdmi_frl.c  |   1 +
 .../gpu/drm/amd/display/dc/mpc/dcn20/dcn20_mpc.c   |   1 +
 .../gpu/drm/amd/display/dc/mpc/dcn30/dcn30_mpc.c   |   1 +
 .../gpu/drm/amd/display/dc/mpc/dcn32/dcn32_mpc.c   |   1 +
 .../gpu/drm/amd/display/dc/mpc/dcn401/dcn401_mpc.c |   1 +
 .../gpu/drm/amd/display/dc/mpc/dcn60/dcn60_mpc.c   |   1 +
 .../gpu/drm/amd/display/dc/opp/dcn10/dcn10_opp.c   |   1 +
 .../gpu/drm/amd/display/dc/opp/dcn20/dcn20_opp.c   |   1 +
 .../gpu/drm/amd/display/dc/optc/dcn30/dcn30_optc.c |   1 +
 .../gpu/drm/amd/display/dc/optc/dcn32/dcn32_optc.c |   1 +
 .../gpu/drm/amd/display/dc/optc/dcn35/dcn35_optc.c |   1 +
 .../drm/amd/display/dc/optc/dcn401/dcn401_optc.c   |   1 +
 .../gpu/drm/amd/display/dc/optc/dcn42/dcn42_optc.c |   1 +
 .../drm/amd/display/dc/pg/dcn35/dcn35_pg_cntl.c    |   1 +
 .../drm/amd/display/dc/pg/dcn42/dcn42_pg_cntl.c    |   1 +
 .../display/dc/resource/dce100/dce100_resource.c   |   1 +
 .../display/dc/resource/dce110/dce110_resource.c   |   1 +
 .../display/dc/resource/dce112/dce112_resource.c   |   1 +
 .../display/dc/resource/dce120/dce120_resource.c   |   1 +
 .../amd/display/dc/resource/dce60/dce60_resource.c |   1 +
 .../amd/display/dc/resource/dce80/dce80_resource.c |   1 +
 .../amd/display/dc/resource/dcn10/dcn10_resource.c |   1 +
 .../amd/display/dc/resource/dcn20/dcn20_resource.c |   1 +
 .../display/dc/resource/dcn201/dcn201_resource.c   |   1 +
 .../amd/display/dc/resource/dcn21/dcn21_resource.c |   1 +
 .../amd/display/dc/resource/dcn30/dcn30_resource.c |   1 +
 .../display/dc/resource/dcn301/dcn301_resource.c   |   1 +
 .../display/dc/resource/dcn302/dcn302_resource.c   |   1 +
 .../display/dc/resource/dcn303/dcn303_resource.c   |   1 +
 .../amd/display/dc/resource/dcn31/dcn31_resource.c |   1 +
 .../display/dc/resource/dcn314/dcn314_resource.c   |   1 +
 .../display/dc/resource/dcn315/dcn315_resource.c   |   1 +
 .../display/dc/resource/dcn316/dcn316_resource.c   |   1 +
 .../amd/display/dc/resource/dcn32/dcn32_resource.c |   1 +
 .../dc/resource/dcn32/dcn32_resource_helpers.c     |   1 +
 .../display/dc/resource/dcn321/dcn321_resource.c   |   1 +
 .../amd/display/dc/resource/dcn35/dcn35_resource.c |   1 +
 .../display/dc/resource/dcn351/dcn351_resource.c   |   1 +
 .../amd/display/dc/resource/dcn36/dcn36_resource.c |   1 +
 .../display/dc/resource/dcn401/dcn401_resource.c   |   1 +
 .../amd/display/dc/resource/dcn42/dcn42_resource.c |   1 +
 .../display/dc/resource/dcn42/dcn42_resource_fpu.c |   1 +
 .../display/dc/resource/dcn42b/dcn42b_resource.c   |   1 +
 .../amd/display/dc/resource/dcn60/dcn60_resource.c |   1 +
 .../gpu/drm/amd/display/dc/rmcm/dcn42/dcn42_rmcm.c |   1 +
 .../gpu/drm/amd/display/dc/rmcm/dcn60/dcn60_rmcm.c |   1 +
 .../dcn401/dcn401_soc_and_ip_translator.c          |   1 +
 .../dcn42/dcn42_soc_and_ip_translator.c            |   1 +
 .../dcn60/dcn60_soc_and_ip_translator.c            |   1 +
 271 files changed, 464 insertions(+), 147 deletions(-)

diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_audio_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_audio_test.c
index 6d8651047ff7..c2ed369f3ca2 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_audio_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_audio_test.c
@@ -809,7 +809,7 @@ static void dm_test_commit_audio_notifies_added_connector(struct kunit *test)
 	KUNIT_ASSERT_NOT_NULL(test, dm_crtc_state);
 	KUNIT_ASSERT_NOT_NULL(test, stream);
 
-	adev->dm.dc = kunit_kzalloc(test, sizeof(*adev->dm.dc), GFP_KERNEL);
+	adev->dm.dc = dm_kunit_alloc_dc(test);
 	KUNIT_ASSERT_NOT_NULL(test, adev->dm.dc);
 	dc_test_set_current_state(adev->dm.dc, kunit_kzalloc(test,
 							 sizeof(*dc_get_current_state(adev->dm.dc)),
@@ -967,7 +967,7 @@ static void dm_test_commit_audio_skips_without_stream_status(struct kunit *test)
 	KUNIT_ASSERT_NOT_NULL(test, dm_crtc_state);
 	KUNIT_ASSERT_NOT_NULL(test, stream);
 
-	adev->dm.dc = kunit_kzalloc(test, sizeof(*adev->dm.dc), GFP_KERNEL);
+	adev->dm.dc = dm_kunit_alloc_dc(test);
 	KUNIT_ASSERT_NOT_NULL(test, adev->dm.dc);
 	dc_test_set_current_state(adev->dm.dc, kunit_kzalloc(test,
 							 sizeof(*dc_get_current_state(adev->dm.dc)),
@@ -1172,7 +1172,7 @@ static void dm_test_commit_audio_skips_writeback_addition(struct kunit *test)
 	KUNIT_ASSERT_NOT_NULL(test, dm_crtc_state);
 	KUNIT_ASSERT_NOT_NULL(test, stream);
 
-	adev->dm.dc = kunit_kzalloc(test, sizeof(*adev->dm.dc), GFP_KERNEL);
+	adev->dm.dc = dm_kunit_alloc_dc(test);
 	KUNIT_ASSERT_NOT_NULL(test, adev->dm.dc);
 	dc_test_set_current_state(adev->dm.dc, kunit_kzalloc(test,
 							 sizeof(*dc_get_current_state(adev->dm.dc)),
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_color_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_color_test.c
index 56a47809f302..28570f8a82ca 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_color_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_color_test.c
@@ -1758,7 +1758,7 @@ dm_test_verify_lut3d_alloc_adev(struct kunit *test, bool has_3dlut)
 {
 	struct amdgpu_device *adev = dm_kunit_alloc_adev(test);
 
-	adev->dm.dc = kunit_kzalloc(test, sizeof(*adev->dm.dc), GFP_KERNEL);
+	adev->dm.dc = dm_kunit_alloc_dc(test);
 	KUNIT_ASSERT_NOT_NULL(test, adev->dm.dc);
 	dc_test_caps(adev->dm.dc)->color.dpp.hw_3d_lut = has_3dlut;
 
@@ -2060,7 +2060,7 @@ dm_test_color_update_setup(struct kunit *test)
 	struct dm_test_color_update_fixture f = {0};
 
 	f.adev = dm_kunit_alloc_adev(test);
-	f.adev->dm.dc = kunit_kzalloc(test, sizeof(*f.adev->dm.dc), GFP_KERNEL);
+	f.adev->dm.dc = dm_kunit_alloc_dc(test);
 	KUNIT_ASSERT_NOT_NULL(test, f.adev->dm.dc);
 
 	f.state = kunit_kzalloc(test, sizeof(*f.state), GFP_KERNEL);
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_connector_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_connector_test.c
index 204dc86266a3..94bb2181d141 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_connector_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_connector_test.c
@@ -3041,7 +3041,7 @@ static struct dm_test_fbc_ctx *dm_test_fbc_ctx_alloc(struct kunit *test)
 	KUNIT_ASSERT_NOT_NULL(test, ctx->adev);
 	ctx->aconnector = kunit_kzalloc(test, sizeof(*ctx->aconnector), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, ctx->aconnector);
-	ctx->dc = kunit_kzalloc(test, sizeof(*ctx->dc), GFP_KERNEL);
+	ctx->dc = dm_kunit_alloc_dc(test);
 	KUNIT_ASSERT_NOT_NULL(test, ctx->dc);
 	ctx->link = kunit_kzalloc(test, sizeof(*ctx->link), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, ctx->link);
@@ -5073,7 +5073,7 @@ static struct dm_test_poll_ctx *dm_test_poll_ctx_alloc(struct kunit *test)
 				    DRM_MODE_CONNECTOR_VGA, NULL), 0);
 	mutex_init(&ctx->aconnector->hpd_lock);
 
-	ctx->dc = kunit_kzalloc(test, sizeof(*ctx->dc), GFP_KERNEL);
+	ctx->dc = dm_kunit_alloc_dc(test);
 	KUNIT_ASSERT_NOT_NULL(test, ctx->dc);
 	ctx->link_srv = kunit_kzalloc(test, sizeof(*ctx->link_srv), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, ctx->link_srv);
@@ -6458,7 +6458,7 @@ static struct dm_test_i2c_ctx *dm_test_i2c_setup(struct kunit *test)
 	KUNIT_ASSERT_NOT_NULL(test, ctx->ddc);
 	ctx->dc_ctx = kunit_kzalloc(test, sizeof(*ctx->dc_ctx), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, ctx->dc_ctx);
-	ctx->dc = kunit_kzalloc(test, sizeof(*ctx->dc), GFP_KERNEL);
+	ctx->dc = dm_kunit_alloc_dc(test);
 	KUNIT_ASSERT_NOT_NULL(test, ctx->dc);
 	ctx->link = kunit_kzalloc(test, sizeof(*ctx->link), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, ctx->link);
@@ -7382,7 +7382,7 @@ static struct dm_test_cvs_dc *dm_test_cvs_dc_alloc(struct kunit *test)
 	pool->timing_generators[0] = tg;
 	pool->timing_generator_count = 0;
 
-	c->dc = kunit_kzalloc(test, sizeof(*c->dc), GFP_KERNEL);
+	c->dc = dm_kunit_alloc_dc(test);
 	KUNIT_ASSERT_NOT_NULL(test, c->dc);
 	dc_test_set_ctx(c->dc, dcc);
 	dc_test_set_res_pool(c->dc, pool);
@@ -8476,7 +8476,7 @@ dm_test_gm_ctx_alloc(struct kunit *test, int connector_type)
 					   &ctx->aenc->base);
 	KUNIT_ASSERT_EQ(test, ret, 0);
 
-	ctx->dc = kunit_kzalloc(test, sizeof(*ctx->dc), GFP_KERNEL);
+	ctx->dc = dm_kunit_alloc_dc(test);
 	KUNIT_ASSERT_NOT_NULL(test, ctx->dc);
 	ctx->link_srv = kunit_kzalloc(test, sizeof(*ctx->link_srv), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, ctx->link_srv);
@@ -9072,7 +9072,7 @@ static struct dm_test_frl_ctx *dm_test_frl_ctx_alloc(struct kunit *test)
 
 	ctx->dm = kunit_kzalloc(test, sizeof(*ctx->dm), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, ctx->dm);
-	ctx->dc = kunit_kzalloc(test, sizeof(*ctx->dc), GFP_KERNEL);
+	ctx->dc = dm_kunit_alloc_dc(test);
 	KUNIT_ASSERT_NOT_NULL(test, ctx->dc);
 	ctx->link_srv = kunit_kzalloc(test, sizeof(*ctx->link_srv), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, ctx->link_srv);
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_crc_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_crc_test.c
index 8d3123904548..d14912e1e095 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_crc_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_crc_test.c
@@ -121,7 +121,7 @@ static struct dm_test_crc_dc_fixture *dm_test_alloc_crc_dc_fixture(struct kunit
 
 	fixture->dm_state = kunit_kzalloc(test, sizeof(*fixture->dm_state), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, fixture->dm_state);
-	fixture->dc = kunit_kzalloc(test, sizeof(*fixture->dc), GFP_KERNEL);
+	fixture->dc = dm_kunit_alloc_dc(test);
 	KUNIT_ASSERT_NOT_NULL(test, fixture->dc);
 	fixture->dc_ctx = kunit_kzalloc(test, sizeof(*fixture->dc_ctx), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, fixture->dc_ctx);
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_freesync_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_freesync_test.c
index a3b9ee396e5c..b751c64d88aa 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_freesync_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_freesync_test.c
@@ -851,7 +851,7 @@ static void dm_test_handle_vrr_transition_round_trip(struct kunit *test)
 	vblank = drm_crtc_vblank_crtc(&acrtc->base);
 	adev->ddev.vblank[0].enabled = true;
 	adev->dm.adev = adev;
-	adev->dm.dc = kunit_kzalloc(test, sizeof(*adev->dm.dc), GFP_KERNEL);
+	adev->dm.dc = dm_kunit_alloc_dc(test);
 	KUNIT_ASSERT_NOT_NULL(test, adev->dm.dc);
 	mutex_init(&adev->dm.dc_lock);
 
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_helpers_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_helpers_test.c
index 48e30f1936b5..65bffc57ea40 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_helpers_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_helpers_test.c
@@ -2550,7 +2550,7 @@ static void dm_test_dmub_aux_transfer_sync_hpd_connected(struct kunit *test)
 
 	adev = dm_kunit_alloc_adev(test);
 	KUNIT_ASSERT_NOT_NULL(test, adev);
-	ctx = dm_kunit_alloc_dc_with_ctx(test)->ctx;
+	ctx = dc_get_ctx(dm_kunit_alloc_dc_with_ctx(test));
 	link = dm_kunit_alloc_link(test);
 
 	ctx->driver_context = adev;
@@ -4454,7 +4454,7 @@ static struct dm_test_local_edid dm_test_setup_local_edid(struct kunit *test)
 	KUNIT_ASSERT_NOT_NULL(test, fixture.ctx);
 	fixture.sink = kunit_kzalloc(test, sizeof(*fixture.sink), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, fixture.sink);
-	fixture.dc = kunit_kzalloc(test, sizeof(*fixture.dc), GFP_KERNEL);
+	fixture.dc = dm_kunit_alloc_dc(test);
 	KUNIT_ASSERT_NOT_NULL(test, fixture.dc);
 	fixture.link = dm_kunit_alloc_link(test);
 	dc_edid = kunit_kzalloc(test, sizeof(*dc_edid), GFP_KERNEL);
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_plane_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_plane_test.c
index 0d8fd26bb0ac..4be4d1487f11 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_plane_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_plane_test.c
@@ -87,7 +87,7 @@ static void dm_test_init_validate_dcc_inputs(struct amdgpu_device **adev,
 					     struct kunit *test)
 {
 	*adev = kunit_kzalloc(test, sizeof(**adev), GFP_KERNEL);
-	*dc = kunit_kzalloc(test, sizeof(**dc), GFP_KERNEL);
+	*dc = dm_kunit_alloc_dc(test);
 	KUNIT_ASSERT_NOT_NULL(test, *adev);
 	KUNIT_ASSERT_NOT_NULL(test, *dc);
 
diff --git a/drivers/gpu/drm/amd/display/dc/basics/dce_calcs.c b/drivers/gpu/drm/amd/display/dc/basics/dce_calcs.c
index 1b8e843020d6..f2acc582e130 100644
--- a/drivers/gpu/drm/amd/display/dc/basics/dce_calcs.c
+++ b/drivers/gpu/drm/amd/display/dc/basics/dce_calcs.c
@@ -27,6 +27,7 @@
 #include "dm_services.h"
 #include "dce_calcs.h"
 #include "dc.h"
+#include "dc_priv.h"
 #include "core_types.h"
 #include "dal_asic_id.h"
 #include "calcs_logger.h"
diff --git a/drivers/gpu/drm/amd/display/dc/bios/bios_parser2.c b/drivers/gpu/drm/amd/display/dc/bios/bios_parser2.c
index 7a53b49dc4cd..91eb20833d81 100644
--- a/drivers/gpu/drm/amd/display/dc/bios/bios_parser2.c
+++ b/drivers/gpu/drm/amd/display/dc/bios/bios_parser2.c
@@ -43,6 +43,7 @@
 #include "bios_parser_interface.h"
 
 #include "bios_parser_common.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER \
 	bp->base.ctx->logger
diff --git a/drivers/gpu/drm/amd/display/dc/bios/command_table2.c b/drivers/gpu/drm/amd/display/dc/bios/command_table2.c
index 5bca5e534277..00a4a62e8d3f 100644
--- a/drivers/gpu/drm/amd/display/dc/bios/command_table2.c
+++ b/drivers/gpu/drm/amd/display/dc/bios/command_table2.c
@@ -39,6 +39,7 @@
 
 #include "dc_dmub_srv.h"
 #include "dc.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER \
 	bp->base.ctx->logger
diff --git a/drivers/gpu/drm/amd/display/dc/bls_builder/bls_builder.c b/drivers/gpu/drm/amd/display/dc/bls_builder/bls_builder.c
index 8ac202487189..28eeef2f3a73 100644
--- a/drivers/gpu/drm/amd/display/dc/bls_builder/bls_builder.c
+++ b/drivers/gpu/drm/amd/display/dc/bls_builder/bls_builder.c
@@ -5,6 +5,7 @@
 
 #include "dm_services.h"
 #include "bls_builder/bls_builder_internal.h"
+#include "dc_priv.h"
 
 const struct bls_builder *bls_builder_create(struct dc *dc,
 		enum bls_builder_name name)
diff --git a/drivers/gpu/drm/amd/display/dc/bls_builder/dcn401_init_builder.c b/drivers/gpu/drm/amd/display/dc/bls_builder/dcn401_init_builder.c
index 589a950e078b..4622d3d76f25 100644
--- a/drivers/gpu/drm/amd/display/dc/bls_builder/dcn401_init_builder.c
+++ b/drivers/gpu/drm/amd/display/dc/bls_builder/dcn401_init_builder.c
@@ -13,6 +13,7 @@
 #include "bls_builder/bls_builder_internal.h"
 #include "bls_builder/dcn401_init_builder.h"
 #include "bls_builder/dcn401_init_builder_legacy.h"
+#include "dc_priv.h"
 
 static const enum block_sequence_func dcn401_dc2_init_sequence[] = {
 	LEGACY_CLK_MGR_INIT_CLOCKS,
diff --git a/drivers/gpu/drm/amd/display/dc/bls_builder/dcn401_init_builder_legacy.c b/drivers/gpu/drm/amd/display/dc/bls_builder/dcn401_init_builder_legacy.c
index e13c16920a0c..66f708ec709b 100644
--- a/drivers/gpu/drm/amd/display/dc/bls_builder/dcn401_init_builder_legacy.c
+++ b/drivers/gpu/drm/amd/display/dc/bls_builder/dcn401_init_builder_legacy.c
@@ -23,6 +23,7 @@
 #include "dcn32/dcn32_resource.h"
 #include "bls_builder/dcn401_init_builder.h"
 #include "bls_builder/dcn401_init_builder_legacy.h"
+#include "dc_priv.h"
 
 /*
  * DC2_DC1_Wrapped: dcn401_init_hw as BLS entries, built one stage per
diff --git a/drivers/gpu/drm/amd/display/dc/bls_executor/bls_executor.c b/drivers/gpu/drm/amd/display/dc/bls_executor/bls_executor.c
index 7600954c3478..81ea2e294f10 100644
--- a/drivers/gpu/drm/amd/display/dc/bls_executor/bls_executor.c
+++ b/drivers/gpu/drm/amd/display/dc/bls_executor/bls_executor.c
@@ -22,6 +22,7 @@
 #include "hwss/hw_sequencer_private.h"
 #include "bls_executor/bls_executor.h"
 #include "dmub_messenger/dmub_messenger.h"
+#include "dc_priv.h"
 
 static noinline_for_stack bool dc2_bls_step_supported(const struct dc2 *dc2,
 		const struct block_sequence *step)
diff --git a/drivers/gpu/drm/amd/display/dc/clk_mgr/clk_mgr.c b/drivers/gpu/drm/amd/display/dc/clk_mgr/clk_mgr.c
index 7f24433a42c1..4d187bd8d0ad 100644
--- a/drivers/gpu/drm/amd/display/dc/clk_mgr/clk_mgr.c
+++ b/drivers/gpu/drm/amd/display/dc/clk_mgr/clk_mgr.c
@@ -53,6 +53,7 @@
 #include "dcn42/dcn42_clk_mgr.h"
 #include "dcn42b/dcn42b_clk_mgr.h"
 #include "dcn60/dcn60_clk_mgr.h"
+#include "dc_priv.h"
 
 int clk_mgr_helper_get_active_display_cnt(
 		struct dc *dc,
diff --git a/drivers/gpu/drm/amd/display/dc/clk_mgr/dce100/dce_clk_mgr.c b/drivers/gpu/drm/amd/display/dc/clk_mgr/dce100/dce_clk_mgr.c
index d891b3bfe2a1..89858aafb6c7 100644
--- a/drivers/gpu/drm/amd/display/dc/clk_mgr/dce100/dce_clk_mgr.c
+++ b/drivers/gpu/drm/amd/display/dc/clk_mgr/dce100/dce_clk_mgr.c
@@ -42,6 +42,7 @@
  */
 #include "dce/dce_8_0_d.h"
 #include "dce/dce_8_0_sh_mask.h"
+#include "dc_priv.h"
 
 #define REG(reg) \
 	(clk_mgr->regs->reg)
diff --git a/drivers/gpu/drm/amd/display/dc/clk_mgr/dce110/dce110_clk_mgr.c b/drivers/gpu/drm/amd/display/dc/clk_mgr/dce110/dce110_clk_mgr.c
index d52789ba2613..4b3dc1a3b102 100644
--- a/drivers/gpu/drm/amd/display/dc/clk_mgr/dce110/dce110_clk_mgr.c
+++ b/drivers/gpu/drm/amd/display/dc/clk_mgr/dce110/dce110_clk_mgr.c
@@ -30,6 +30,7 @@
 #include "dce/dce_11_0_sh_mask.h"
 #include "dce110_clk_mgr.h"
 #include "../clk_mgr/dce100/dce_clk_mgr.h"
+#include "dc_priv.h"
 
 /* set register offset */
 #define SR(reg_name)\
diff --git a/drivers/gpu/drm/amd/display/dc/clk_mgr/dce112/dce112_clk_mgr.c b/drivers/gpu/drm/amd/display/dc/clk_mgr/dce112/dce112_clk_mgr.c
index 3da0c220d17f..14577c95d376 100644
--- a/drivers/gpu/drm/amd/display/dc/clk_mgr/dce112/dce112_clk_mgr.c
+++ b/drivers/gpu/drm/amd/display/dc/clk_mgr/dce112/dce112_clk_mgr.c
@@ -32,6 +32,7 @@
 #include "dce110/dce110_clk_mgr.h"
 #include "dce112_clk_mgr.h"
 #include "dal_asic_id.h"
+#include "dc_priv.h"
 
 /* set register offset */
 #define SR(reg_name)\
diff --git a/drivers/gpu/drm/amd/display/dc/clk_mgr/dce120/dce120_clk_mgr.c b/drivers/gpu/drm/amd/display/dc/clk_mgr/dce120/dce120_clk_mgr.c
index f8ef3a4710fc..4038dcbf7bfd 100644
--- a/drivers/gpu/drm/amd/display/dc/clk_mgr/dce120/dce120_clk_mgr.c
+++ b/drivers/gpu/drm/amd/display/dc/clk_mgr/dce120/dce120_clk_mgr.c
@@ -31,6 +31,7 @@
 #include "dce120_clk_mgr.h"
 #include "dce100/dce_clk_mgr.h"
 #include "dce120/dce120_hwseq.h"
+#include "dc_priv.h"
 
 /**
  * dce121_clock_patch_xgmi_ss_info() - Save XGMI spread spectrum info
diff --git a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn10/dcn10_clk_mgr.c b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn10/dcn10_clk_mgr.c
index 172bba20a156..0a573753bf9f 100644
--- a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn10/dcn10_clk_mgr.c
+++ b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn10/dcn10_clk_mgr.c
@@ -6,6 +6,7 @@
 #include "core_types.h"
 #include "dal_asic_id.h"
 #include "dcn10_clk_mgr.h"
+#include "dc_priv.h"
 
 unsigned int dcn10_dentist_get_divider_from_did(unsigned int did)
 {
diff --git a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn10/rv1_clk_mgr.c b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn10/rv1_clk_mgr.c
index 9450b1733f60..a8100d895d61 100644
--- a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn10/rv1_clk_mgr.c
+++ b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn10/rv1_clk_mgr.c
@@ -29,6 +29,7 @@
 #include "dcn10/dcn10_clk_mgr.h"
 #include "rv1_clk_mgr_vbios_smu.h"
 #include "rv1_clk_mgr_clk.h"
+#include "dc_priv.h"
 
 static void rv1_init_clocks(struct clk_mgr *clk_mgr)
 {
diff --git a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn10/rv1_clk_mgr_vbios_smu.c b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn10/rv1_clk_mgr_vbios_smu.c
index d82a52319088..823748ee0fc0 100644
--- a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn10/rv1_clk_mgr_vbios_smu.c
+++ b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn10/rv1_clk_mgr_vbios_smu.c
@@ -28,6 +28,7 @@
 #include "reg_helper.h"
 
 #include "rv1_clk_mgr_vbios_smu.h"
+#include "dc_priv.h"
 
 #define MAX_INSTANCE	5
 #define MAX_SEGMENT		5
diff --git a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn20/dcn20_clk_mgr.c b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn20/dcn20_clk_mgr.c
index 86f3f32768e3..56e90db06a3d 100644
--- a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn20/dcn20_clk_mgr.c
+++ b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn20/dcn20_clk_mgr.c
@@ -37,6 +37,7 @@
 #include "dcn/dcn_2_0_0_sh_mask.h"
 #include "clk/clk_11_0_0_offset.h"
 #include "clk/clk_11_0_0_sh_mask.h"
+#include "dc_priv.h"
 
 
 #undef FN
diff --git a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn201/dcn201_clk_mgr.c b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn201/dcn201_clk_mgr.c
index 7ab548e41b40..a04e26720117 100644
--- a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn201/dcn201_clk_mgr.c
+++ b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn201/dcn201_clk_mgr.c
@@ -38,6 +38,7 @@
 #include "dcn/dcn_2_0_1_sh_mask.h"
 #include "clk/clk_11_0_1_offset.h"
 #include "clk/clk_11_0_1_sh_mask.h"
+#include "dc_priv.h"
 
 #define REG(reg) \
 	(clk_mgr->regs->reg)
diff --git a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn21/rn_clk_mgr.c b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn21/rn_clk_mgr.c
index 488ae92d24fa..b31fadd8a86f 100644
--- a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn21/rn_clk_mgr.c
+++ b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn21/rn_clk_mgr.c
@@ -40,6 +40,7 @@
 #include "clk/clk_10_0_2_offset.h"
 #include "clk/clk_10_0_2_sh_mask.h"
 #include "renoir_ip_offset.h"
+#include "dc_priv.h"
 
 
 /* Constants */
diff --git a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn21/rn_clk_mgr_vbios_smu.c b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn21/rn_clk_mgr_vbios_smu.c
index 5a633333dbb5..722f149babe9 100644
--- a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn21/rn_clk_mgr_vbios_smu.c
+++ b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn21/rn_clk_mgr_vbios_smu.c
@@ -44,6 +44,7 @@
 	FD(reg_name##__##field)
 
 #include "logger_types.h"
+#include "dc_priv.h"
 #undef DC_LOGGER
 #define DC_LOGGER \
 	CTX->logger
diff --git a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn30/dcn30_clk_mgr.c b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn30/dcn30_clk_mgr.c
index 80bdaf762a23..f562c5c10ceb 100644
--- a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn30/dcn30_clk_mgr.c
+++ b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn30/dcn30_clk_mgr.c
@@ -44,6 +44,7 @@
 #include "mmhub/mmhub_2_0_0_offset.h"
 #include "mmhub/mmhub_2_0_0_sh_mask.h"
 #include "dcn30_smu11_driver_if.h"
+#include "dc_priv.h"
 
 #undef FN
 #define FN(reg_name, field_name) \
diff --git a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn301/vg_clk_mgr.c b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn301/vg_clk_mgr.c
index ace3ceb228c6..07d2d542b476 100644
--- a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn301/vg_clk_mgr.c
+++ b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn301/vg_clk_mgr.c
@@ -45,6 +45,7 @@
 #include "vangogh_ip_offset.h"
 #include "clk/clk_11_5_0_offset.h"
 #include "clk/clk_11_5_0_sh_mask.h"
+#include "dc_priv.h"
 
 /* Constants */
 
diff --git a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn31/dcn31_clk_mgr.c b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn31/dcn31_clk_mgr.c
index 938bc2bbe6d7..6a74fdd71b4c 100644
--- a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn31/dcn31_clk_mgr.c
+++ b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn31/dcn31_clk_mgr.c
@@ -53,6 +53,7 @@
 
 
 #include "yellow_carp_offset.h"
+#include "dc_priv.h"
 #undef DC_LOGGER
 #define DC_LOGGER \
 	clk_mgr->base.base.ctx->logger
diff --git a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn31/dcn31_smu.c b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn31/dcn31_smu.c
index f201628e4e98..e7af83af1a5c 100644
--- a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn31/dcn31_smu.c
+++ b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn31/dcn31_smu.c
@@ -40,6 +40,7 @@
 	FD(reg_name##__##field)
 
 #include "logger_types.h"
+#include "dc_priv.h"
 #undef DC_LOGGER
 #define DC_LOGGER \
 	CTX->logger
diff --git a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn314/dcn314_clk_mgr.c b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn314/dcn314_clk_mgr.c
index 2aa3e8e66cb7..a62076820bb4 100644
--- a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn314/dcn314_clk_mgr.c
+++ b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn314/dcn314_clk_mgr.c
@@ -53,6 +53,7 @@
 
 
 #include "logger_types.h"
+#include "dc_priv.h"
 
 
 #define MAX_INSTANCE                                        7
diff --git a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn314/dcn314_smu.c b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn314/dcn314_smu.c
index c4af406146b7..c986abfe0531 100644
--- a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn314/dcn314_smu.c
+++ b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn314/dcn314_smu.c
@@ -56,6 +56,7 @@
 	FD(reg_name##__##field)
 
 #include "logger_types.h"
+#include "dc_priv.h"
 #undef DC_LOGGER
 #define DC_LOGGER \
 	CTX->logger
diff --git a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn315/dcn315_clk_mgr.c b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn315/dcn315_clk_mgr.c
index 8ca367b72325..a78082876327 100644
--- a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn315/dcn315_clk_mgr.c
+++ b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn315/dcn315_clk_mgr.c
@@ -47,6 +47,7 @@
 	clk_mgr->base.base.ctx->logger
 
 #include "link_service.h"
+#include "dc_priv.h"
 
 #define TO_CLK_MGR_DCN315(clk_mgr)\
 	container_of(clk_mgr, struct clk_mgr_dcn315, base)
diff --git a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn315/dcn315_smu.c b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn315/dcn315_smu.c
index 478b4d6a3544..4997a45064fa 100644
--- a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn315/dcn315_smu.c
+++ b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn315/dcn315_smu.c
@@ -30,6 +30,7 @@
 #include "dcn315_smu.h"
 #include "mp/mp_13_0_5_offset.h"
 #include "logger_types.h"
+#include "dc_priv.h"
 
 #define MAX_INSTANCE                                        6
 #define MAX_SEGMENT                                         6
diff --git a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn316/dcn316_clk_mgr.c b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn316/dcn316_clk_mgr.c
index 96bd653a9b71..efd83e7a52fb 100644
--- a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn316/dcn316_clk_mgr.c
+++ b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn316/dcn316_clk_mgr.c
@@ -40,6 +40,7 @@
 #include "dm_helpers.h"
 #include "dc_dmub_srv.h"
 #include "link_service.h"
+#include "dc_priv.h"
 
 // DCN316 this is CLK1 instance
 #define MAX_INSTANCE                                        7
diff --git a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn316/dcn316_smu.c b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn316/dcn316_smu.c
index 8b82092b91cd..fd748f347079 100644
--- a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn316/dcn316_smu.c
+++ b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn316/dcn316_smu.c
@@ -57,6 +57,7 @@ static const struct IP_BASE MP0_BASE = { { { { 0x00016000, 0x00DC0000, 0x00E0000
 	FD(reg_name##__##field)
 
 #include "logger_types.h"
+#include "dc_priv.h"
 #undef DC_LOGGER
 #define DC_LOGGER \
 	CTX->logger
diff --git a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn32/dcn32_clk_mgr.c b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn32/dcn32_clk_mgr.c
index 7abb13ffd9f4..0da332914e3b 100644
--- a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn32/dcn32_clk_mgr.c
+++ b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn32/dcn32_clk_mgr.c
@@ -42,6 +42,7 @@
 #include "dcn/dcn_3_2_0_sh_mask.h"
 
 #include "dml/dcn32/dcn32_fpu.h"
+#include "dc_priv.h"
 
 #define DCN_BASE__INST0_SEG1                       0x000000C0
 
diff --git a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn35/dcn35_clk_mgr.c b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn35/dcn35_clk_mgr.c
index 990c362623d8..a7d2076a827c 100644
--- a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn35/dcn35_clk_mgr.c
+++ b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn35/dcn35_clk_mgr.c
@@ -46,6 +46,7 @@
 #include "dc_dmub_srv.h"
 #include "link_service.h"
 #include "logger_types.h"
+#include "dc_priv.h"
 
 #undef DC_LOGGER
 #define DC_LOGGER \
diff --git a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn35/dcn35_smu.c b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn35/dcn35_smu.c
index 9d8f81c3d3f0..faae83f44551 100644
--- a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn35/dcn35_smu.c
+++ b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn35/dcn35_smu.c
@@ -56,6 +56,7 @@
 	FD(reg_name##__##field)
 
 #include "logger_types.h"
+#include "dc_priv.h"
 #undef DC_LOGGER
 #define DC_LOGGER \
 	CTX->logger
diff --git a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn401/dcn401_clk_mgr.c b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn401/dcn401_clk_mgr.c
index 03aec7f4df7b..14af6a336329 100644
--- a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn401/dcn401_clk_mgr.c
+++ b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn401/dcn401_clk_mgr.c
@@ -22,6 +22,7 @@
 
 #include "dcn/dcn_4_1_0_offset.h"
 #include "dcn/dcn_4_1_0_sh_mask.h"
+#include "dc_priv.h"
 
 #define DCN_BASE__INST0_SEG1                       0x000000C0
 
diff --git a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn42/dcn42_clk_mgr.c b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn42/dcn42_clk_mgr.c
index 405145889ba2..2050c6a1ac1e 100644
--- a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn42/dcn42_clk_mgr.c
+++ b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn42/dcn42_clk_mgr.c
@@ -35,6 +35,7 @@
 #include "clk/clk_15_0_0_sh_mask.h"
 #include "dcn/dcn_4_2_0_offset.h"
 #include "dcn/dcn_4_2_0_sh_mask.h"
+#include "dc_priv.h"
 
 
 #undef DC_LOGGER
diff --git a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn42/dcn42_smu.c b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn42/dcn42_smu.c
index 5e8d979f25f0..c225d4000d6a 100644
--- a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn42/dcn42_smu.c
+++ b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn42/dcn42_smu.c
@@ -38,6 +38,7 @@
 	FD(reg_name##__##field)
 
 #include "logger_types.h"
+#include "dc_priv.h"
 #undef DC_LOGGER
 #define DC_LOGGER \
 	CTX->logger
diff --git a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn42b/dcn42b_clk_mgr.c b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn42b/dcn42b_clk_mgr.c
index 33f0099075c0..d577abdc6ea5 100644
--- a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn42b/dcn42b_clk_mgr.c
+++ b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn42b/dcn42b_clk_mgr.c
@@ -36,6 +36,7 @@
 #include "dcn/dcn_4_2_1_sh_mask.h"
 
 #include <linux/power_supply.h>
+#include "dc_priv.h"
 
 #define DCN_BASE__INST0_SEG0                       0x00000012
 #define DCN_BASE__INST0_SEG1                       0x000000C0
diff --git a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn60/dcn60_clk_mgr.c b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn60/dcn60_clk_mgr.c
index efc02ba740f5..53b6c363f747 100644
--- a/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn60/dcn60_clk_mgr.c
+++ b/drivers/gpu/drm/amd/display/dc/clk_mgr/dcn60/dcn60_clk_mgr.c
@@ -25,6 +25,7 @@
 
 #include "dcn/dcn_6_0_0_offset.h"
 #include "dcn/dcn_6_0_0_sh_mask.h"
+#include "dc_priv.h"
 
 #undef DC_LOGGER
 #define DC_LOGGER \
diff --git a/drivers/gpu/drm/amd/display/dc/core/dc_accessors.c b/drivers/gpu/drm/amd/display/dc/core/dc_accessors.c
index 4c583d452446..23aced5d5eef 100644
--- a/drivers/gpu/drm/amd/display/dc/core/dc_accessors.c
+++ b/drivers/gpu/drm/amd/display/dc/core/dc_accessors.c
@@ -31,6 +31,7 @@
  * mapping stays obvious and auditable.
  */
 #include "dc.h"
+#include "dc_priv.h"
 #include "dm_helpers.h"	/* EXPORT_IF_KUNIT */
 
 uint8_t dc_get_link_count(const struct dc *dc)
diff --git a/drivers/gpu/drm/amd/display/dc/core/dc_debug.c b/drivers/gpu/drm/amd/display/dc/core/dc_debug.c
index f3348e0cb1d6..bdc2792d5f88 100644
--- a/drivers/gpu/drm/amd/display/dc/core/dc_debug.c
+++ b/drivers/gpu/drm/amd/display/dc/core/dc_debug.c
@@ -30,6 +30,7 @@
 #include "dm_services.h"
 
 #include "dc.h"
+#include "dc_priv.h"
 
 #include "core_status.h"
 #include "core_types.h"
diff --git a/drivers/gpu/drm/amd/display/dc/core/dc_hw_sequencer.c b/drivers/gpu/drm/amd/display/dc/core/dc_hw_sequencer.c
index 694c425e22b4..9fa2b5a34d2b 100644
--- a/drivers/gpu/drm/amd/display/dc/core/dc_hw_sequencer.c
+++ b/drivers/gpu/drm/amd/display/dc/core/dc_hw_sequencer.c
@@ -42,6 +42,7 @@
 #include "dce/dmub_hw_lock_mgr.h"
 #include "link_service.h"
 #include "custom_float.h"
+#include "dc_priv.h"
 
 static union dmub_inbox0_cmd_lock_hw hwss_build_dmub_lock_command(bool lock)
 {
diff --git a/drivers/gpu/drm/amd/display/dc/core/dc_link_enc_cfg.c b/drivers/gpu/drm/amd/display/dc/core/dc_link_enc_cfg.c
index d2a5e0648fc2..47dc12952f10 100644
--- a/drivers/gpu/drm/amd/display/dc/core/dc_link_enc_cfg.c
+++ b/drivers/gpu/drm/amd/display/dc/core/dc_link_enc_cfg.c
@@ -25,6 +25,7 @@
 #include "link_enc_cfg.h"
 #include "resource.h"
 #include "link_service.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER dc->ctx->logger
 
diff --git a/drivers/gpu/drm/amd/display/dc/core/dc_link_exports.c b/drivers/gpu/drm/amd/display/dc/core/dc_link_exports.c
index d2f52e4839fe..50dc317eed71 100644
--- a/drivers/gpu/drm/amd/display/dc/core/dc_link_exports.c
+++ b/drivers/gpu/drm/amd/display/dc/core/dc_link_exports.c
@@ -35,6 +35,7 @@
  */
 #include "link_service.h"
 #include "dce/dce_i2c.h"
+#include "dc_priv.h"
 
 struct dc_link *dc_get_link_at_index(struct dc *dc, uint32_t link_index)
 {
diff --git a/drivers/gpu/drm/amd/display/dc/core/dc_resource.c b/drivers/gpu/drm/amd/display/dc/core/dc_resource.c
index 832286f0c0b1..d5d53491e91c 100644
--- a/drivers/gpu/drm/amd/display/dc/core/dc_resource.c
+++ b/drivers/gpu/drm/amd/display/dc/core/dc_resource.c
@@ -78,6 +78,7 @@
 #include "dcn321/dcn321_resource.h"
 #include "dcn35/dcn35_resource.h"
 #include "dcn351/dcn351_resource.h"
+#include "dc_priv.h"
 #include "dcn36/dcn36_resource.h"
 #include "dcn401/dcn401_resource.h"
 #include "dcn42/dcn42_resource.h"
diff --git a/drivers/gpu/drm/amd/display/dc/core/dc_stat.c b/drivers/gpu/drm/amd/display/dc/core/dc_stat.c
index f976ffd6d466..1758c0b9390b 100644
--- a/drivers/gpu/drm/amd/display/dc/core/dc_stat.c
+++ b/drivers/gpu/drm/amd/display/dc/core/dc_stat.c
@@ -25,6 +25,7 @@
 #include "dc/dc_stat.h"
 #include "dmub/dmub_srv_stat.h"
 #include "dc_dmub_srv.h"
+#include "dc_priv.h"
 
 /**
  * DOC: DC STAT Interface
diff --git a/drivers/gpu/drm/amd/display/dc/core/dc_state.c b/drivers/gpu/drm/amd/display/dc/core/dc_state.c
index edb50c23ce24..88ee99bd4494 100644
--- a/drivers/gpu/drm/amd/display/dc/core/dc_state.c
+++ b/drivers/gpu/drm/amd/display/dc/core/dc_state.c
@@ -26,6 +26,7 @@
 #include "core_types.h"
 #include "core_status.h"
 #include "dc.h"
+#include "dc_priv.h"
 #include "dc_state.h"
 #include "dc_state_priv.h"
 #include "dc_stream_priv.h"
diff --git a/drivers/gpu/drm/amd/display/dc/core/dc_stream.c b/drivers/gpu/drm/amd/display/dc/core/dc_stream.c
index 56c7d97733a6..65f305b3c15d 100644
--- a/drivers/gpu/drm/amd/display/dc/core/dc_stream.c
+++ b/drivers/gpu/drm/amd/display/dc/core/dc_stream.c
@@ -27,6 +27,7 @@
 #include "dm_helpers.h"
 #include "basics/dc_common.h"
 #include "dc.h"
+#include "dc_priv.h"
 #include "core_types.h"
 #include "resource.h"
 #include "ipp.h"
diff --git a/drivers/gpu/drm/amd/display/dc/core/dc_surface.c b/drivers/gpu/drm/amd/display/dc/core/dc_surface.c
index 0b135a9e6c4f..139a934cbf3d 100644
--- a/drivers/gpu/drm/amd/display/dc/core/dc_surface.c
+++ b/drivers/gpu/drm/amd/display/dc/core/dc_surface.c
@@ -26,6 +26,7 @@
 /* DC interface (public) */
 #include "dm_services.h"
 #include "dc.h"
+#include "dc_priv.h"
 
 /* DC core (private) */
 #include "core_types.h"
diff --git a/drivers/gpu/drm/amd/display/dc/core/dc_test.c b/drivers/gpu/drm/amd/display/dc/core/dc_test.c
index 60fb45f9cfaa..04c799ae33d3 100644
--- a/drivers/gpu/drm/amd/display/dc/core/dc_test.c
+++ b/drivers/gpu/drm/amd/display/dc/core/dc_test.c
@@ -32,6 +32,7 @@
 #include <linux/export.h>
 
 #include "dc.h"
+#include "dc_priv.h"
 #include "dc_test.h"
 
 struct dc *dc_test_create(void)
diff --git a/drivers/gpu/drm/amd/display/dc/core/dc_vm_helper.c b/drivers/gpu/drm/amd/display/dc/core/dc_vm_helper.c
index 3743555133f6..cc0d5ceace5f 100644
--- a/drivers/gpu/drm/amd/display/dc/core/dc_vm_helper.c
+++ b/drivers/gpu/drm/amd/display/dc/core/dc_vm_helper.c
@@ -25,6 +25,7 @@
 
 #include "vm_helper.h"
 #include "dc.h"
+#include "dc_priv.h"
 
 void vm_helper_mark_vmid_used(struct vm_helper *vm_helper, unsigned int pos, uint8_t hubp_idx)
 {
diff --git a/drivers/gpu/drm/amd/display/dc/dc.h b/drivers/gpu/drm/amd/display/dc/dc.h
index 082435846ee9..d976425c190b 100644
--- a/drivers/gpu/drm/amd/display/dc/dc.h
+++ b/drivers/gpu/drm/amd/display/dc/dc.h
@@ -857,43 +857,6 @@ struct dc_bw_validation_profile {
 	unsigned long long skip_fail_count;
 };
 
-#define BW_VAL_TRACE_SETUP() \
-		unsigned long long end_tick = 0; \
-		unsigned long long voltage_level_tick = 0; \
-		unsigned long long watermark_tick = 0; \
-		unsigned long long start_tick = dc->debug.bw_val_profile.enable ? \
-				dm_get_timestamp(dc->ctx) : 0
-
-#define BW_VAL_TRACE_COUNT() \
-		if (dc->debug.bw_val_profile.enable) \
-			dc->debug.bw_val_profile.total_count++
-
-#define BW_VAL_TRACE_SKIP(status) \
-		if (dc->debug.bw_val_profile.enable) { \
-			if (!voltage_level_tick) \
-				voltage_level_tick = dm_get_timestamp(dc->ctx); \
-			dc->debug.bw_val_profile.skip_ ## status ## _count++; \
-		}
-
-#define BW_VAL_TRACE_END_VOLTAGE_LEVEL() \
-		if (dc->debug.bw_val_profile.enable) \
-			voltage_level_tick = dm_get_timestamp(dc->ctx)
-
-#define BW_VAL_TRACE_END_WATERMARKS() \
-		if (dc->debug.bw_val_profile.enable) \
-			watermark_tick = dm_get_timestamp(dc->ctx)
-
-#define BW_VAL_TRACE_FINISH() \
-		if (dc->debug.bw_val_profile.enable) { \
-			end_tick = dm_get_timestamp(dc->ctx); \
-			dc->debug.bw_val_profile.total_ticks += end_tick - start_tick; \
-			dc->debug.bw_val_profile.voltage_level_ticks += voltage_level_tick - start_tick; \
-			if (watermark_tick) { \
-				dc->debug.bw_val_profile.watermark_ticks += watermark_tick - voltage_level_tick; \
-				dc->debug.bw_val_profile.rq_dlg_ticks += end_tick - watermark_tick; \
-			} \
-		}
-
 union mem_low_power_enable_options {
 	struct {
 		bool vga: 1;
@@ -2020,100 +1983,6 @@ struct dc_scratch_space {
 	enum backlight_control_type backlight_control_type;
 };
 
-struct dc {
-	struct dc_debug_options debug;
-	struct dc_versions versions;
-	struct dc_caps caps;
-	struct dc_check_config check_config;
-	struct dc_cap_funcs cap_funcs;
-	struct dc_config config;
-	struct dc_bounding_box_overrides bb_overrides;
-	struct dc_bug_wa work_arounds;
-	struct dc_context *ctx;
-	struct dc_phy_addr_space_config vm_pa_config;
-
-	uint8_t link_count;
-	struct dc_link *links[MAX_LINKS];
-	uint8_t lowest_dpia_link_index;
-	struct link_service *link_srv;
-
-	struct dc_state *current_state;
-	/**
-	 * @scratch_dc_context: Pre-allocated states for the no-allocation update
-	 * path, created only when dc_config.preallocate_scratch_state is set.
-	 * Two are kept because the commit path installs the new context as
-	 * @current_state, so a single buffer would alias it and self-copy.
-	 */
-	struct dc_state *scratch_dc_context[2];
-	struct resource_pool *res_pool;
-
-	/**
-	 * @update_scratch_pool: Per-commit scratch buffers for dc_update_state.
-	 */
-	struct dc_memory_pool *update_scratch_pool;  // MAX_STREAMS + 1
-
-	struct clk_mgr *clk_mgr;
-
-	/* Display Engine Clock levels */
-	struct dm_pp_clock_levels sclk_lvls;
-
-	/* Inputs into BW and WM calculations. */
-	struct bw_calcs_dceip *bw_dceip;
-	struct bw_calcs_vbios *bw_vbios;
-	struct dcn_soc_bounding_box *dcn_soc;
-	struct dcn_ip_params *dcn_ip;
-	struct display_mode_lib dml;
-
-	/* HW functions */
-	struct hw_sequencer_funcs hwss;
-	struct dce_hwseq *hwseq;
-
-	/* Require to optimize clocks and bandwidth for added/removed planes */
-	bool optimized_required;
-	bool idle_optimizations_allowed;
-	bool enable_c20_dtm_b0;
-
-	/* Require to maintain clocks and bandwidth for UEFI enabled HW */
-
-	/* For eDP to know the switching state of SmartMux */
-	bool is_switch_in_progress_orig;
-	bool is_switch_in_progress_dest;
-
-	/* FBC compressor */
-	struct compressor *fbc_compressor;
-
-	struct dc_debug_data debug_data;
-	struct dpcd_vendor_signature vendor_signature;
-
-	const char *build_id;
-	struct vm_helper *vm_helper;
-
-	uint32_t *dcn_reg_offsets;
-	uint32_t *nbio_reg_offsets;
-	uint32_t *clk_reg_offsets;
-
-	/* Scratch memory */
-	struct {
-		struct {
-			/*
-			 * For matching clock_limits table in driver with table
-			 * from PMFW.
-			 */
-			struct _vcs_dpi_voltage_scaling_st clock_limits[DC__VOLTAGE_STATES];
-		} update_bw_bounding_box;
-		struct dc_scratch_space current_state;
-		struct dc_scratch_space new_state;
-		struct dc_stream_state temp_stream; // Used so we don't need to allocate stream on the stack
-		struct dc_link temp_link;
-		bool pipes_to_unlock_first[MAX_PIPES]; /* Any of the pipes indicated here should be unlocked first */
-	} scratch;
-
-	struct dml2_configuration_options dml2_options;
-	struct dml2_configuration_options dml2_dc_power_options;
-	enum dc_acpi_cm_power_state power_state;
-	struct soc_and_ip_translator *soc_and_ip_translator;
-};
-
 struct dc_scaling_info {
 	struct rect src_rect;
 	struct rect dst_rect;
diff --git a/drivers/gpu/drm/amd/display/dc/dc_api_dispatch/api_shim.h b/drivers/gpu/drm/amd/display/dc/dc_api_dispatch/api_shim.h
index b972ae06663d..7802a18b8caa 100644
--- a/drivers/gpu/drm/amd/display/dc/dc_api_dispatch/api_shim.h
+++ b/drivers/gpu/drm/amd/display/dc/dc_api_dispatch/api_shim.h
@@ -6,6 +6,7 @@
 #pragma once
 
 #include "dc.h"
+#include "dc_priv.h"
 #include "inc/dc_core_interface.h"
 #include "bls_builder/dmub_abi.h"
 
diff --git a/drivers/gpu/drm/amd/display/dc/dc_dmub_srv.c b/drivers/gpu/drm/amd/display/dc/dc_dmub_srv.c
index 323e8bec23dc..cde3a6a21de3 100644
--- a/drivers/gpu/drm/amd/display/dc/dc_dmub_srv.c
+++ b/drivers/gpu/drm/amd/display/dc/dc_dmub_srv.c
@@ -25,6 +25,7 @@
 
 #include "dm_services.h"
 #include "dc.h"
+#include "dc_priv.h"
 #include "dc_dmub_srv.h"
 #include "../dmub/dmub_srv.h"
 #include "dm_helpers.h"
diff --git a/drivers/gpu/drm/amd/display/dc/dc_priv.h b/drivers/gpu/drm/amd/display/dc/dc_priv.h
new file mode 100644
index 000000000000..70e4eee9bf0f
--- /dev/null
+++ b/drivers/gpu/drm/amd/display/dc/dc_priv.h
@@ -0,0 +1,186 @@
+/* SPDX-License-Identifier: MIT */
+/*
+ * Copyright 2026 Advanced Micro Devices, Inc.
+ *
+ * Permission is hereby granted, free of charge, to any person obtaining a
+ * copy of this software and associated documentation files (the "Software"),
+ * to deal in the Software without restriction, including without limitation
+ * the rights to use, copy, modify, merge, publish, distribute, sublicense,
+ * and/or sell copies of the Software, and to permit persons to whom the
+ * Software is furnished to do so, subject to the following conditions:
+ *
+ * The above copyright notice and this permission notice shall be included in
+ * all copies or substantial portions of the Software.
+ *
+ * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
+ * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
+ * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
+ * THE COPYRIGHT HOLDER(S) OR AUTHOR(S) BE LIABLE FOR ANY CLAIM, DAMAGES OR
+ * OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
+ * ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
+ * OTHER DEALINGS IN THE SOFTWARE.
+ *
+ */
+
+#ifndef __DC_PRIV_H__
+#define __DC_PRIV_H__
+
+/* FILE POLICY AND INTENDED USAGE:
+ * This header defines struct dc, the DC core state. It is private to the dc
+ * directory and must never be included from DM, DAL modules or any other
+ * code outside DC. Public DC interfaces are declared in dc.h; use the
+ * accessors implemented in dc/core/dc_accessors.c instead of reaching into
+ * struct dc.
+ */
+
+#include "dc.h"
+
+/* Bandwidth validation trace macros. Usable only from DC-internal code
+ * because they dereference the dc-local variable of the including function.
+ */
+#define BW_VAL_TRACE_SETUP() \
+		unsigned long long end_tick = 0; \
+		unsigned long long voltage_level_tick = 0; \
+		unsigned long long watermark_tick = 0; \
+		unsigned long long start_tick = dc->debug.bw_val_profile.enable ? \
+				dm_get_timestamp(dc->ctx) : 0
+
+#define BW_VAL_TRACE_COUNT() \
+		do { \
+			if (dc->debug.bw_val_profile.enable) \
+				dc->debug.bw_val_profile.total_count++; \
+		} while (0)
+
+#define BW_VAL_TRACE_SKIP(status) \
+		do { \
+			if (dc->debug.bw_val_profile.enable) { \
+				if (!voltage_level_tick) \
+					voltage_level_tick = dm_get_timestamp(dc->ctx); \
+				dc->debug.bw_val_profile.skip_ ## status ## _count++; \
+			} \
+		} while (0)
+
+#define BW_VAL_TRACE_END_VOLTAGE_LEVEL() \
+		do { \
+			if (dc->debug.bw_val_profile.enable) \
+				voltage_level_tick = dm_get_timestamp(dc->ctx); \
+		} while (0)
+
+#define BW_VAL_TRACE_END_WATERMARKS() \
+		do { \
+			if (dc->debug.bw_val_profile.enable) \
+				watermark_tick = dm_get_timestamp(dc->ctx); \
+		} while (0)
+
+#define BW_VAL_TRACE_FINISH() \
+		do { \
+			if (dc->debug.bw_val_profile.enable) { \
+				end_tick = dm_get_timestamp(dc->ctx); \
+				dc->debug.bw_val_profile.total_ticks += end_tick - start_tick; \
+				dc->debug.bw_val_profile.voltage_level_ticks += \
+						voltage_level_tick - start_tick; \
+				if (watermark_tick) { \
+					dc->debug.bw_val_profile.watermark_ticks += \
+							watermark_tick - voltage_level_tick; \
+					dc->debug.bw_val_profile.rq_dlg_ticks += \
+							end_tick - watermark_tick; \
+				} \
+			} \
+		} while (0)
+
+struct dc {
+	struct dc_debug_options debug;
+	struct dc_versions versions;
+	struct dc_caps caps;
+	struct dc_check_config check_config;
+	struct dc_cap_funcs cap_funcs;
+	struct dc_config config;
+	struct dc_bounding_box_overrides bb_overrides;
+	struct dc_bug_wa work_arounds;
+	struct dc_context *ctx;
+	struct dc_phy_addr_space_config vm_pa_config;
+
+	uint8_t link_count;
+	struct dc_link *links[MAX_LINKS];
+	uint8_t lowest_dpia_link_index;
+	struct link_service *link_srv;
+
+	struct dc_state *current_state;
+	/**
+	 * @scratch_dc_context: Pre-allocated states for the no-allocation update
+	 * path, created only when dc_config.preallocate_scratch_state is set.
+	 * Two are kept because the commit path installs the new context as
+	 * @current_state, so a single buffer would alias it and self-copy.
+	 */
+	struct dc_state *scratch_dc_context[2];
+	struct resource_pool *res_pool;
+
+	/**
+	 * @update_scratch_pool: Per-commit scratch buffers for dc_update_state.
+	 */
+	struct dc_memory_pool *update_scratch_pool;  // MAX_STREAMS + 1
+
+	struct clk_mgr *clk_mgr;
+
+	/* Display Engine Clock levels */
+	struct dm_pp_clock_levels sclk_lvls;
+
+	/* Inputs into BW and WM calculations. */
+	struct bw_calcs_dceip *bw_dceip;
+	struct bw_calcs_vbios *bw_vbios;
+	struct dcn_soc_bounding_box *dcn_soc;
+	struct dcn_ip_params *dcn_ip;
+	struct display_mode_lib dml;
+
+	/* HW functions */
+	struct hw_sequencer_funcs hwss;
+	struct dce_hwseq *hwseq;
+
+	/* Require to optimize clocks and bandwidth for added/removed planes */
+	bool optimized_required;
+	bool idle_optimizations_allowed;
+	bool enable_c20_dtm_b0;
+
+	/* Require to maintain clocks and bandwidth for UEFI enabled HW */
+
+	/* For eDP to know the switching state of SmartMux */
+	bool is_switch_in_progress_orig;
+	bool is_switch_in_progress_dest;
+
+	/* FBC compressor */
+	struct compressor *fbc_compressor;
+
+	struct dc_debug_data debug_data;
+	struct dpcd_vendor_signature vendor_signature;
+
+	const char *build_id;
+	struct vm_helper *vm_helper;
+
+	uint32_t *dcn_reg_offsets;
+	uint32_t *nbio_reg_offsets;
+	uint32_t *clk_reg_offsets;
+
+	/* Scratch memory */
+	struct {
+		struct {
+			/*
+			 * For matching clock_limits table in driver with table
+			 * from PMFW.
+			 */
+			struct _vcs_dpi_voltage_scaling_st clock_limits[DC__VOLTAGE_STATES];
+		} update_bw_bounding_box;
+		struct dc_scratch_space current_state;
+		struct dc_scratch_space new_state;
+		/* Used so we don't need to allocate stream on the stack */
+		struct dc_stream_state temp_stream;
+		struct dc_link temp_link;
+		/* Any of the pipes indicated here should be unlocked first */
+		bool pipes_to_unlock_first[MAX_PIPES];
+	} scratch;
+
+	struct dml2_configuration_options dml2_options;
+	struct dml2_configuration_options dml2_dc_power_options;
+	enum dc_acpi_cm_power_state power_state;
+	struct soc_and_ip_translator *soc_and_ip_translator;
+};
+#endif /* __DC_PRIV_H__ */
diff --git a/drivers/gpu/drm/amd/display/dc/dc_spl_translate.c b/drivers/gpu/drm/amd/display/dc/dc_spl_translate.c
index 00e121bb8ef7..124deb723064 100644
--- a/drivers/gpu/drm/amd/display/dc/dc_spl_translate.c
+++ b/drivers/gpu/drm/amd/display/dc/dc_spl_translate.c
@@ -6,6 +6,7 @@
 #include "dcn20/dcn20_dpp.h"
 #include "dcn32/dcn32_dpp.h"
 #include "dcn401/dcn401_dpp.h"
+#include "dc_priv.h"
 
 static struct spl_callbacks dcn2_spl_callbacks = {
 	.spl_calc_lb_num_partitions = dscl2_spl_calc_lb_num_partitions,
diff --git a/drivers/gpu/drm/amd/display/dc/dccg/dcn31/dcn31_dccg.c b/drivers/gpu/drm/amd/display/dc/dccg/dcn31/dcn31_dccg.c
index 341509ad6f35..e6ac961c11fb 100644
--- a/drivers/gpu/drm/amd/display/dc/dccg/dcn31/dcn31_dccg.c
+++ b/drivers/gpu/drm/amd/display/dc/dccg/dcn31/dcn31_dccg.c
@@ -28,6 +28,7 @@
 #include "dcn31_dccg.h"
 #include "dcn20/dcn20_dccg.h"
 #include "dal_asic_id.h"
+#include "dc_priv.h"
 
 #define TO_DCN_DCCG(dccg)\
 	container_of(dccg, struct dcn_dccg, base)
diff --git a/drivers/gpu/drm/amd/display/dc/dccg/dcn314/dcn314_dccg.c b/drivers/gpu/drm/amd/display/dc/dccg/dcn314/dcn314_dccg.c
index 7bfe7be2bc1f..4fc1f27e9300 100644
--- a/drivers/gpu/drm/amd/display/dc/dccg/dcn314/dcn314_dccg.c
+++ b/drivers/gpu/drm/amd/display/dc/dccg/dcn314/dcn314_dccg.c
@@ -30,6 +30,7 @@
 #include "dcn31/dcn31_dccg.h"
 #include "dcn314_dccg.h"
 #include "dcn20/dcn20_dccg.h"
+#include "dc_priv.h"
 
 #define TO_DCN_DCCG(dccg)\
 	container_of(dccg, struct dcn_dccg, base)
diff --git a/drivers/gpu/drm/amd/display/dc/dccg/dcn35/dcn35_dccg.c b/drivers/gpu/drm/amd/display/dc/dccg/dcn35/dcn35_dccg.c
index 6dce2a4beca2..a4d05b5a8487 100644
--- a/drivers/gpu/drm/amd/display/dc/dccg/dcn35/dcn35_dccg.c
+++ b/drivers/gpu/drm/amd/display/dc/dccg/dcn35/dcn35_dccg.c
@@ -41,6 +41,7 @@
 #define CTX \
 	dccg_dcn->base.ctx
 #include "logger_types.h"
+#include "dc_priv.h"
 #define DC_LOGGER \
 	dccg->ctx->logger
 
diff --git a/drivers/gpu/drm/amd/display/dc/dccg/dcn401/dcn401_dccg.c b/drivers/gpu/drm/amd/display/dc/dccg/dcn401/dcn401_dccg.c
index a4ece209d600..c827708e8613 100644
--- a/drivers/gpu/drm/amd/display/dc/dccg/dcn401/dcn401_dccg.c
+++ b/drivers/gpu/drm/amd/display/dc/dccg/dcn401/dcn401_dccg.c
@@ -28,6 +28,7 @@
 #include "dcn401_dccg.h"
 #include "dcn31/dcn31_dccg.h"
 #include "dcn20/dcn20_dccg.h"
+#include "dc_priv.h"
 
 /*
 #include "dmub_common.h"
diff --git a/drivers/gpu/drm/amd/display/dc/dccg/dcn42/dcn42_dccg.c b/drivers/gpu/drm/amd/display/dc/dccg/dcn42/dcn42_dccg.c
index b7b84152d623..e4758d48ae12 100644
--- a/drivers/gpu/drm/amd/display/dc/dccg/dcn42/dcn42_dccg.c
+++ b/drivers/gpu/drm/amd/display/dc/dccg/dcn42/dcn42_dccg.c
@@ -7,6 +7,7 @@
 #include "dcn35/dcn35_dccg.h"
 #include "dcn42_dccg.h"
 #include "dcn20/dcn20_dccg.h"
+#include "dc_priv.h"
 
 #define TO_DCN_DCCG(dccg)\
 	container_of(dccg, struct dcn_dccg, base)
diff --git a/drivers/gpu/drm/amd/display/dc/dce/dce_aux.c b/drivers/gpu/drm/amd/display/dc/dce/dce_aux.c
index 4abf51c8ab52..0e367433b3d8 100644
--- a/drivers/gpu/drm/amd/display/dc/dce/dce_aux.c
+++ b/drivers/gpu/drm/amd/display/dc/dce/dce_aux.c
@@ -46,6 +46,7 @@
 #define LOG_FLAG_I2cAux_DceAux LOG_I2C_AUX
 
 #include "reg_helper.h"
+#include "dc_priv.h"
 
 #undef FN
 #define FN(reg_name, field_name) \
diff --git a/drivers/gpu/drm/amd/display/dc/dce/dce_clock_source.c b/drivers/gpu/drm/amd/display/dc/dce/dce_clock_source.c
index 145c993342bd..01a78cc38139 100644
--- a/drivers/gpu/drm/amd/display/dc/dce/dce_clock_source.c
+++ b/drivers/gpu/drm/amd/display/dc/dce/dce_clock_source.c
@@ -38,6 +38,7 @@
 #include "dccg.h"
 
 #include "reg_helper.h"
+#include "dc_priv.h"
 
 #define REG(reg)\
 	(clk_src->regs->reg)
diff --git a/drivers/gpu/drm/amd/display/dc/dce/dce_dmcu.c b/drivers/gpu/drm/amd/display/dc/dce/dce_dmcu.c
index 23de1c793ec3..8de051b1c4f8 100644
--- a/drivers/gpu/drm/amd/display/dc/dce/dce_dmcu.c
+++ b/drivers/gpu/drm/amd/display/dc/dce/dce_dmcu.c
@@ -30,6 +30,7 @@
 #include "reg_helper.h"
 #include "fixed31_32.h"
 #include "dc.h"
+#include "dc_priv.h"
 
 #define TO_DCE_DMCU(dmcu)\
 	container_of(dmcu, struct dce_dmcu, base)
diff --git a/drivers/gpu/drm/amd/display/dc/dce/dce_i2c.c b/drivers/gpu/drm/amd/display/dc/dce/dce_i2c.c
index f5261e8d7678..79c355db22ef 100644
--- a/drivers/gpu/drm/amd/display/dc/dce/dce_i2c.c
+++ b/drivers/gpu/drm/amd/display/dc/dce/dce_i2c.c
@@ -24,6 +24,7 @@
  */
 #include "dce_i2c.h"
 #include "reg_helper.h"
+#include "dc_priv.h"
 
 bool dce_i2c_oem_device_present(
 	struct resource_pool *pool,
diff --git a/drivers/gpu/drm/amd/display/dc/dce/dce_i2c_hw.c b/drivers/gpu/drm/amd/display/dc/dce/dce_i2c_hw.c
index 05892ab4529f..3b4aefc0007e 100644
--- a/drivers/gpu/drm/amd/display/dc/dce/dce_i2c_hw.c
+++ b/drivers/gpu/drm/amd/display/dc/dce/dce_i2c_hw.c
@@ -27,6 +27,7 @@
 #include "dce_i2c_hw.h"
 #include "reg_helper.h"
 #include "include/gpio_service_interface.h"
+#include "dc_priv.h"
 
 #define CTX \
 	dce_i2c_hw->ctx
diff --git a/drivers/gpu/drm/amd/display/dc/dce/dce_link_encoder.c b/drivers/gpu/drm/amd/display/dc/dce/dce_link_encoder.c
index c6a20378121b..5819c508d872 100644
--- a/drivers/gpu/drm/amd/display/dc/dce/dce_link_encoder.c
+++ b/drivers/gpu/drm/amd/display/dc/dce/dce_link_encoder.c
@@ -36,6 +36,7 @@
 #include "dce/dce_11_0_d.h"
 #include "dce/dce_11_0_sh_mask.h"
 #include "dce/dce_11_0_enum.h"
+#include "dc_priv.h"
 
 #ifndef DMU_MEM_PWR_CNTL__DMCU_IRAM_MEM_PWR_STATE__SHIFT
 #define DMU_MEM_PWR_CNTL__DMCU_IRAM_MEM_PWR_STATE__SHIFT 0xa
diff --git a/drivers/gpu/drm/amd/display/dc/dce/dce_mem_input.c b/drivers/gpu/drm/amd/display/dc/dce/dce_mem_input.c
index 168c2d0a5eaa..fe17832f98b8 100644
--- a/drivers/gpu/drm/amd/display/dc/dce/dce_mem_input.c
+++ b/drivers/gpu/drm/amd/display/dc/dce/dce_mem_input.c
@@ -26,6 +26,7 @@
 #include "dce_mem_input.h"
 #include "reg_helper.h"
 #include "basics/conversion.h"
+#include "dc_priv.h"
 
 #define CTX \
 	dce_mi->base.ctx
diff --git a/drivers/gpu/drm/amd/display/dc/dce/dce_transform.c b/drivers/gpu/drm/amd/display/dc/dce/dce_transform.c
index 83f819890020..1c5fcd3c99fb 100644
--- a/drivers/gpu/drm/amd/display/dc/dce/dce_transform.c
+++ b/drivers/gpu/drm/amd/display/dc/dce/dce_transform.c
@@ -28,6 +28,7 @@
 #include "opp.h"
 #include "basics/conversion.h"
 #include "dc.h"
+#include "dc_priv.h"
 
 #define REG(reg) \
 	(xfm_dce->regs->reg)
diff --git a/drivers/gpu/drm/amd/display/dc/dce/dmub_abm.c b/drivers/gpu/drm/amd/display/dc/dce/dmub_abm.c
index 8cca8599b917..da4de4141e96 100644
--- a/drivers/gpu/drm/amd/display/dc/dce/dmub_abm.c
+++ b/drivers/gpu/drm/amd/display/dc/dce/dmub_abm.c
@@ -27,6 +27,7 @@
 #include "dmub_abm_lcd.h"
 #include "dmub_abm_cacp.h"
 #include "dc.h"
+#include "dc_priv.h"
 #include "core_types.h"
 #include "dmub_cmd.h"
 #include "dc_dmub_srv.h"
diff --git a/drivers/gpu/drm/amd/display/dc/dce/dmub_abm_cacp.c b/drivers/gpu/drm/amd/display/dc/dce/dmub_abm_cacp.c
index 9f58fa2e25fd..9b8077726b17 100644
--- a/drivers/gpu/drm/amd/display/dc/dce/dmub_abm_cacp.c
+++ b/drivers/gpu/drm/amd/display/dc/dce/dmub_abm_cacp.c
@@ -4,6 +4,7 @@
 #include "dmub_abm_cacp.h"
 #include "dce_abm.h"
 #include "dc.h"
+#include "dc_priv.h"
 #include "dc_dmub_srv.h"
 #include "dmub/dmub_srv.h"
 #include "core_types.h"
diff --git a/drivers/gpu/drm/amd/display/dc/dce/dmub_abm_lcd.c b/drivers/gpu/drm/amd/display/dc/dce/dmub_abm_lcd.c
index f60e43ba6060..d0107e87b421 100644
--- a/drivers/gpu/drm/amd/display/dc/dce/dmub_abm_lcd.c
+++ b/drivers/gpu/drm/amd/display/dc/dce/dmub_abm_lcd.c
@@ -27,6 +27,7 @@
 #include "dmub_abm_lcd.h"
 #include "dce_abm.h"
 #include "dc.h"
+#include "dc_priv.h"
 #include "dc_dmub_srv.h"
 #include "dmub/dmub_srv.h"
 #include "core_types.h"
diff --git a/drivers/gpu/drm/amd/display/dc/dce/dmub_hw_lock_mgr.c b/drivers/gpu/drm/amd/display/dc/dce/dmub_hw_lock_mgr.c
index f5ff61a2e89e..f9a265ff8317 100644
--- a/drivers/gpu/drm/amd/display/dc/dce/dmub_hw_lock_mgr.c
+++ b/drivers/gpu/drm/amd/display/dc/dce/dmub_hw_lock_mgr.c
@@ -27,6 +27,7 @@
 #include "dc_dmub_srv.h"
 #include "dc_types.h"
 #include "core_types.h"
+#include "dc_priv.h"
 
 static bool dmub_hw_lock_has_inbox0_lock(const struct dc *dc)
 {
diff --git a/drivers/gpu/drm/amd/display/dc/dce/dmub_psr.c b/drivers/gpu/drm/amd/display/dc/dce/dmub_psr.c
index 66d8ba73d38b..64b862a0e358 100644
--- a/drivers/gpu/drm/amd/display/dc/dce/dmub_psr.c
+++ b/drivers/gpu/drm/amd/display/dc/dce/dmub_psr.c
@@ -25,6 +25,7 @@
 
 #include "dmub_psr.h"
 #include "dc.h"
+#include "dc_priv.h"
 #include "dc_dmub_srv.h"
 #include "dmub/dmub_srv.h"
 #include "core_types.h"
diff --git a/drivers/gpu/drm/amd/display/dc/dce/dmub_replay.c b/drivers/gpu/drm/amd/display/dc/dce/dmub_replay.c
index 365c428eae72..e7a7c4d50e01 100644
--- a/drivers/gpu/drm/amd/display/dc/dce/dmub_replay.c
+++ b/drivers/gpu/drm/amd/display/dc/dce/dmub_replay.c
@@ -3,6 +3,7 @@
 // Copyright 2024 Advanced Micro Devices, Inc.
 
 #include "dc.h"
+#include "dc_priv.h"
 #include "link_service.h"
 #include "dc_dmub_srv.h"
 #include "dmub/dmub_srv.h"
diff --git a/drivers/gpu/drm/amd/display/dc/dce110/dce110_mem_input_v.c b/drivers/gpu/drm/amd/display/dc/dce110/dce110_mem_input_v.c
index 095869912c09..277c9e169a1f 100644
--- a/drivers/gpu/drm/amd/display/dc/dce110/dce110_mem_input_v.c
+++ b/drivers/gpu/drm/amd/display/dc/dce110/dce110_mem_input_v.c
@@ -33,6 +33,7 @@
 
 #include "dce/dce_mem_input.h"
 #include "dce110_mem_input_v.h"
+#include "dc_priv.h"
 
 static void set_flip_control(
 	struct dce_mem_input *mem_input110,
diff --git a/drivers/gpu/drm/amd/display/dc/dce110/dce110_transform_v.c b/drivers/gpu/drm/amd/display/dc/dce110/dce110_transform_v.c
index 6be18665b1f7..97562423b43b 100644
--- a/drivers/gpu/drm/amd/display/dc/dce110/dce110_transform_v.c
+++ b/drivers/gpu/drm/amd/display/dc/dce110/dce110_transform_v.c
@@ -26,6 +26,7 @@
 #include "dce110_transform_v.h"
 #include "dm_services.h"
 #include "dc.h"
+#include "dc_priv.h"
 #include "dce/dce_11_0_d.h"
 #include "dce/dce_11_0_sh_mask.h"
 
diff --git a/drivers/gpu/drm/amd/display/dc/dcn10/dcn10_hw_sequencer_debug.c b/drivers/gpu/drm/amd/display/dc/dcn10/dcn10_hw_sequencer_debug.c
index 395bccdd0f1d..ca5803fd2d29 100644
--- a/drivers/gpu/drm/amd/display/dc/dcn10/dcn10_hw_sequencer_debug.c
+++ b/drivers/gpu/drm/amd/display/dc/dcn10/dcn10_hw_sequencer_debug.c
@@ -45,6 +45,7 @@
 #include "dcn10_cm_common.h"
 #include "clk_mgr.h"
 #include "dsc.h"
+#include "dc_priv.h"
 
 __printf(3, 4)
 unsigned int snprintf_count(char *pbuf, unsigned int bufsize, const char *fmt, ...)
diff --git a/drivers/gpu/drm/amd/display/dc/dcn201/dcn201_link_encoder.c b/drivers/gpu/drm/amd/display/dc/dcn201/dcn201_link_encoder.c
index 9459e8f28338..2e6f398a68c1 100644
--- a/drivers/gpu/drm/amd/display/dc/dcn201/dcn201_link_encoder.c
+++ b/drivers/gpu/drm/amd/display/dc/dcn201/dcn201_link_encoder.c
@@ -32,6 +32,7 @@
 #include "dc_bios_types.h"
 
 #include "gpio_service_interface.h"
+#include "dc_priv.h"
 
 #define CTX \
 	enc10->base.ctx
diff --git a/drivers/gpu/drm/amd/display/dc/dcn21/dcn21_link_encoder.c b/drivers/gpu/drm/amd/display/dc/dcn21/dcn21_link_encoder.c
index fcaa3884d705..dda8af8aecfa 100644
--- a/drivers/gpu/drm/amd/display/dc/dcn21/dcn21_link_encoder.c
+++ b/drivers/gpu/drm/amd/display/dc/dcn21/dcn21_link_encoder.c
@@ -34,6 +34,7 @@
 #include "dc_bios_types.h"
 
 #include "gpio_service_interface.h"
+#include "dc_priv.h"
 
 #define CTX \
 	enc10->base.ctx
diff --git a/drivers/gpu/drm/amd/display/dc/dcn31/dcn31_afmt.c b/drivers/gpu/drm/amd/display/dc/dcn31/dcn31_afmt.c
index d380a8ec2184..37b608ee7ca9 100644
--- a/drivers/gpu/drm/amd/display/dc/dcn31/dcn31_afmt.c
+++ b/drivers/gpu/drm/amd/display/dc/dcn31/dcn31_afmt.c
@@ -29,6 +29,7 @@
 #include "dcn31_afmt.h"
 #include "reg_helper.h"
 #include "dc/dc.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER \
 		afmt31->base.ctx->logger
diff --git a/drivers/gpu/drm/amd/display/dc/dcn31/dcn31_panel_cntl.c b/drivers/gpu/drm/amd/display/dc/dcn31/dcn31_panel_cntl.c
index d7c3f26777e3..6943e6df9173 100644
--- a/drivers/gpu/drm/amd/display/dc/dcn31/dcn31_panel_cntl.c
+++ b/drivers/gpu/drm/amd/display/dc/dcn31/dcn31_panel_cntl.c
@@ -29,6 +29,7 @@
 #include "dc_dmub_srv.h"
 #include "dcn31_panel_cntl.h"
 #include "atom.h"
+#include "dc_priv.h"
 
 #define TO_DCN31_PANEL_CNTL(panel_cntl)\
 	container_of(panel_cntl, struct dcn31_panel_cntl, base)
diff --git a/drivers/gpu/drm/amd/display/dc/dcn31/dcn31_vpg.c b/drivers/gpu/drm/amd/display/dc/dcn31/dcn31_vpg.c
index cfb923d85630..a453cc24d82a 100644
--- a/drivers/gpu/drm/amd/display/dc/dcn31/dcn31_vpg.c
+++ b/drivers/gpu/drm/amd/display/dc/dcn31/dcn31_vpg.c
@@ -28,6 +28,7 @@
 #include "dcn31_vpg.h"
 #include "reg_helper.h"
 #include "dc/dc.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER \
 		vpg31->base.ctx->logger
diff --git a/drivers/gpu/drm/amd/display/dc/dio/dcn10/dcn10_link_encoder.c b/drivers/gpu/drm/amd/display/dc/dio/dcn10/dcn10_link_encoder.c
index 32e12d894e31..85d6b7f15e15 100644
--- a/drivers/gpu/drm/amd/display/dc/dio/dcn10/dcn10_link_encoder.c
+++ b/drivers/gpu/drm/amd/display/dc/dio/dcn10/dcn10_link_encoder.c
@@ -32,6 +32,7 @@
 #include "dc_bios_types.h"
 
 #include "gpio_service_interface.h"
+#include "dc_priv.h"
 
 #define CTX \
 	enc10->base.ctx
diff --git a/drivers/gpu/drm/amd/display/dc/dio/dcn10/dcn10_stream_encoder.c b/drivers/gpu/drm/amd/display/dc/dio/dcn10/dcn10_stream_encoder.c
index c937788d0763..de3df77c36a4 100644
--- a/drivers/gpu/drm/amd/display/dc/dio/dcn10/dcn10_stream_encoder.c
+++ b/drivers/gpu/drm/amd/display/dc/dio/dcn10/dcn10_stream_encoder.c
@@ -31,6 +31,7 @@
 #include "link_service.h"
 #include "dpcd_defs.h"
 #include "dcn30/dcn30_afmt.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER \
 		enc1->base.ctx->logger
diff --git a/drivers/gpu/drm/amd/display/dc/dio/dcn20/dcn20_link_encoder.c b/drivers/gpu/drm/amd/display/dc/dio/dcn20/dcn20_link_encoder.c
index dbd4c534c5c3..1596b53d62a8 100644
--- a/drivers/gpu/drm/amd/display/dc/dio/dcn20/dcn20_link_encoder.c
+++ b/drivers/gpu/drm/amd/display/dc/dio/dcn20/dcn20_link_encoder.c
@@ -32,6 +32,7 @@
 #include "dc_bios_types.h"
 
 #include "gpio_service_interface.h"
+#include "dc_priv.h"
 
 #define CTX \
 	enc10->base.ctx
diff --git a/drivers/gpu/drm/amd/display/dc/dio/dcn20/dcn20_stream_encoder.c b/drivers/gpu/drm/amd/display/dc/dio/dcn20/dcn20_stream_encoder.c
index ac6ca7771d2f..052a5d3a65a2 100644
--- a/drivers/gpu/drm/amd/display/dc/dio/dcn20/dcn20_stream_encoder.c
+++ b/drivers/gpu/drm/amd/display/dc/dio/dcn20/dcn20_stream_encoder.c
@@ -31,6 +31,7 @@
 #include "hw_shared.h"
 #include "link_service.h"
 #include "dpcd_defs.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER \
 		enc1->base.ctx->logger
diff --git a/drivers/gpu/drm/amd/display/dc/dio/dcn30/dcn30_dio_link_encoder.c b/drivers/gpu/drm/amd/display/dc/dio/dcn30/dcn30_dio_link_encoder.c
index 5fd5158482ea..adbde44e18a5 100644
--- a/drivers/gpu/drm/amd/display/dc/dio/dcn30/dcn30_dio_link_encoder.c
+++ b/drivers/gpu/drm/amd/display/dc/dio/dcn30/dcn30_dio_link_encoder.c
@@ -31,6 +31,7 @@
 #include "stream_encoder.h"
 #include "dc_bios_types.h"
 #include "gpio_service_interface.h"
+#include "dc_priv.h"
 
 #define CTX \
 	enc10->base.ctx
diff --git a/drivers/gpu/drm/amd/display/dc/dio/dcn30/dcn30_dio_stream_encoder.c b/drivers/gpu/drm/amd/display/dc/dio/dcn30/dcn30_dio_stream_encoder.c
index 9757d3bcdf32..b516f2d9d09b 100644
--- a/drivers/gpu/drm/amd/display/dc/dio/dcn30/dcn30_dio_stream_encoder.c
+++ b/drivers/gpu/drm/amd/display/dc/dio/dcn30/dcn30_dio_stream_encoder.c
@@ -29,6 +29,7 @@
 #include "reg_helper.h"
 #include "hw_shared.h"
 #include "dc.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER \
 		enc1->base.ctx->logger
diff --git a/drivers/gpu/drm/amd/display/dc/dio/dcn301/dcn301_dio_link_encoder.c b/drivers/gpu/drm/amd/display/dc/dio/dcn301/dcn301_dio_link_encoder.c
index 7106669eab5b..79afaae47791 100644
--- a/drivers/gpu/drm/amd/display/dc/dio/dcn301/dcn301_dio_link_encoder.c
+++ b/drivers/gpu/drm/amd/display/dc/dio/dcn301/dcn301_dio_link_encoder.c
@@ -31,6 +31,7 @@
 #include "stream_encoder.h"
 #include "dc_bios_types.h"
 #include "gpio_service_interface.h"
+#include "dc_priv.h"
 
 #define CTX \
 	enc10->base.ctx
diff --git a/drivers/gpu/drm/amd/display/dc/dio/dcn31/dcn31_dio_link_encoder.c b/drivers/gpu/drm/amd/display/dc/dio/dcn31/dcn31_dio_link_encoder.c
index 1b9ba0e9f068..39b97f960da1 100644
--- a/drivers/gpu/drm/amd/display/dc/dio/dcn31/dcn31_dio_link_encoder.c
+++ b/drivers/gpu/drm/amd/display/dc/dio/dcn31/dcn31_dio_link_encoder.c
@@ -38,6 +38,7 @@
 #include "dc_dmub_srv.h"
 #include "dal_asic_id.h"
 #include "link_service.h"
+#include "dc_priv.h"
 
 #define CTX \
 	enc10->base.ctx
diff --git a/drivers/gpu/drm/amd/display/dc/dio/dcn314/dcn314_dio_stream_encoder.c b/drivers/gpu/drm/amd/display/dc/dio/dcn314/dcn314_dio_stream_encoder.c
index 482c52c1d7d6..036704e21dac 100644
--- a/drivers/gpu/drm/amd/display/dc/dio/dcn314/dcn314_dio_stream_encoder.c
+++ b/drivers/gpu/drm/amd/display/dc/dio/dcn314/dcn314_dio_stream_encoder.c
@@ -32,6 +32,7 @@
 #include "hw_shared.h"
 #include "link_service.h"
 #include "dpcd_defs.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER \
 		enc1->base.ctx->logger
diff --git a/drivers/gpu/drm/amd/display/dc/dio/dcn32/dcn32_dio_link_encoder.c b/drivers/gpu/drm/amd/display/dc/dio/dcn32/dcn32_dio_link_encoder.c
index 63990c47ac14..24af37eded70 100644
--- a/drivers/gpu/drm/amd/display/dc/dio/dcn32/dcn32_dio_link_encoder.c
+++ b/drivers/gpu/drm/amd/display/dc/dio/dcn32/dcn32_dio_link_encoder.c
@@ -36,6 +36,7 @@
 
 #include "dc_dmub_srv.h"
 #include "gpio_service_interface.h"
+#include "dc_priv.h"
 
 #ifndef MIN
 #define MIN(X, Y) ((X) < (Y) ? (X) : (Y))
diff --git a/drivers/gpu/drm/amd/display/dc/dio/dcn32/dcn32_dio_stream_encoder.c b/drivers/gpu/drm/amd/display/dc/dio/dcn32/dcn32_dio_stream_encoder.c
index 3dd8fe423232..ca7615dfb11b 100644
--- a/drivers/gpu/drm/amd/display/dc/dio/dcn32/dcn32_dio_stream_encoder.c
+++ b/drivers/gpu/drm/amd/display/dc/dio/dcn32/dcn32_dio_stream_encoder.c
@@ -31,6 +31,7 @@
 #include "hw_shared.h"
 #include "link_service.h"
 #include "dpcd_defs.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER \
 		enc1->base.ctx->logger
diff --git a/drivers/gpu/drm/amd/display/dc/dio/dcn321/dcn321_dio_link_encoder.c b/drivers/gpu/drm/amd/display/dc/dio/dcn321/dcn321_dio_link_encoder.c
index 67d6050d5163..c09932c3fd2c 100644
--- a/drivers/gpu/drm/amd/display/dc/dio/dcn321/dcn321_dio_link_encoder.c
+++ b/drivers/gpu/drm/amd/display/dc/dio/dcn321/dcn321_dio_link_encoder.c
@@ -33,6 +33,7 @@
 #include "dc_bios_types.h"
 
 #include "gpio_service_interface.h"
+#include "dc_priv.h"
 
 #ifndef MIN
 #define MIN(X, Y) ((X) < (Y) ? (X) : (Y))
diff --git a/drivers/gpu/drm/amd/display/dc/dio/dcn35/dcn35_dio_link_encoder.c b/drivers/gpu/drm/amd/display/dc/dio/dcn35/dcn35_dio_link_encoder.c
index 9375c9b939be..25b1e02f1874 100644
--- a/drivers/gpu/drm/amd/display/dc/dio/dcn35/dcn35_dio_link_encoder.c
+++ b/drivers/gpu/drm/amd/display/dc/dio/dcn35/dcn35_dio_link_encoder.c
@@ -29,6 +29,7 @@
 #include "dcn31/dcn31_dio_link_encoder.h"
 #include "dcn35_dio_link_encoder.h"
 #include "dc_dmub_srv.h"
+#include "dc_priv.h"
 #define CTX \
 	enc10->base.ctx
 #define DC_LOGGER \
diff --git a/drivers/gpu/drm/amd/display/dc/dio/dcn35/dcn35_dio_stream_encoder.c b/drivers/gpu/drm/amd/display/dc/dio/dcn35/dcn35_dio_stream_encoder.c
index dabcb45840a7..38eac36b8304 100644
--- a/drivers/gpu/drm/amd/display/dc/dio/dcn35/dcn35_dio_stream_encoder.c
+++ b/drivers/gpu/drm/amd/display/dc/dio/dcn35/dcn35_dio_stream_encoder.c
@@ -31,6 +31,7 @@
 #include "hw_shared.h"
 #include "link_service.h"
 #include "dpcd_defs.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER \
 		enc1->base.ctx->logger
diff --git a/drivers/gpu/drm/amd/display/dc/dio/dcn401/dcn401_dio_link_encoder.c b/drivers/gpu/drm/amd/display/dc/dio/dcn401/dcn401_dio_link_encoder.c
index 6594fbb3fa43..fb9a0c43f599 100644
--- a/drivers/gpu/drm/amd/display/dc/dio/dcn401/dcn401_dio_link_encoder.c
+++ b/drivers/gpu/drm/amd/display/dc/dio/dcn401/dcn401_dio_link_encoder.c
@@ -35,6 +35,7 @@
 #include "dc_bios_types.h"
 
 #include "gpio_service_interface.h"
+#include "dc_priv.h"
 
 #ifndef MIN
 #define MIN(X, Y) ((X) < (Y) ? (X) : (Y))
diff --git a/drivers/gpu/drm/amd/display/dc/dio/dcn401/dcn401_dio_stream_encoder.c b/drivers/gpu/drm/amd/display/dc/dio/dcn401/dcn401_dio_stream_encoder.c
index 4616b6f76aeb..e962c544610e 100644
--- a/drivers/gpu/drm/amd/display/dc/dio/dcn401/dcn401_dio_stream_encoder.c
+++ b/drivers/gpu/drm/amd/display/dc/dio/dcn401/dcn401_dio_stream_encoder.c
@@ -34,6 +34,7 @@
 #include "hw_shared.h"
 #include "link_service.h"
 #include "dpcd_defs.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER \
 		enc1->base.ctx->logger
diff --git a/drivers/gpu/drm/amd/display/dc/dio/dcn42/dcn42_dio_link_encoder.c b/drivers/gpu/drm/amd/display/dc/dio/dcn42/dcn42_dio_link_encoder.c
index 3b11be9991c3..6c64df545aa0 100644
--- a/drivers/gpu/drm/amd/display/dc/dio/dcn42/dcn42_dio_link_encoder.c
+++ b/drivers/gpu/drm/amd/display/dc/dio/dcn42/dcn42_dio_link_encoder.c
@@ -8,6 +8,7 @@
 #include "link_encoder.h"
 #include "dcn35/dcn35_dio_link_encoder.h"
 #include "dcn42_dio_link_encoder.h"
+#include "dc_priv.h"
 
 #ifndef MIN
 #define MIN(X, Y) ((X) < (Y) ? (X) : (Y))
diff --git a/drivers/gpu/drm/amd/display/dc/dio/dcn42/dcn42_dio_stream_encoder.c b/drivers/gpu/drm/amd/display/dc/dio/dcn42/dcn42_dio_stream_encoder.c
index b7671d41ea24..fe8774845186 100644
--- a/drivers/gpu/drm/amd/display/dc/dio/dcn42/dcn42_dio_stream_encoder.c
+++ b/drivers/gpu/drm/amd/display/dc/dio/dcn42/dcn42_dio_stream_encoder.c
@@ -14,6 +14,7 @@
 #include "hw_shared.h"
 #include "link_service.h"
 #include "dpcd_defs.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER \
 		enc1->base.ctx->logger
diff --git a/drivers/gpu/drm/amd/display/dc/dio/dcn60/dcn60_dio_link_encoder.c b/drivers/gpu/drm/amd/display/dc/dio/dcn60/dcn60_dio_link_encoder.c
index f65326a0f6d2..78af49f0e316 100644
--- a/drivers/gpu/drm/amd/display/dc/dio/dcn60/dcn60_dio_link_encoder.c
+++ b/drivers/gpu/drm/amd/display/dc/dio/dcn60/dcn60_dio_link_encoder.c
@@ -15,6 +15,7 @@
 #include "dc_bios_types.h"
 
 #include "gpio_service_interface.h"
+#include "dc_priv.h"
 
 #ifndef MIN
 #define MIN(X, Y) ((X) < (Y) ? (X) : (Y))
diff --git a/drivers/gpu/drm/amd/display/dc/dio/dcn60/dcn60_dio_stream_encoder.c b/drivers/gpu/drm/amd/display/dc/dio/dcn60/dcn60_dio_stream_encoder.c
index b645914c1c71..5df2b7202917 100644
--- a/drivers/gpu/drm/amd/display/dc/dio/dcn60/dcn60_dio_stream_encoder.c
+++ b/drivers/gpu/drm/amd/display/dc/dio/dcn60/dcn60_dio_stream_encoder.c
@@ -13,6 +13,7 @@
 #include "hw_shared.h"
 #include "link_service.h"
 #include "dpcd_defs.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER \
 		enc1->base.ctx->logger
diff --git a/drivers/gpu/drm/amd/display/dc/dml/calcs/dcn_calcs.c b/drivers/gpu/drm/amd/display/dc/dml/calcs/dcn_calcs.c
index 2ad4a2635683..59c93dc3fe63 100644
--- a/drivers/gpu/drm/amd/display/dc/dml/calcs/dcn_calcs.c
+++ b/drivers/gpu/drm/amd/display/dc/dml/calcs/dcn_calcs.c
@@ -26,6 +26,7 @@
 
 #include "dm_services.h"
 #include "dc.h"
+#include "dc_priv.h"
 #include "dcn_calcs.h"
 #include "dcn_calc_auto.h"
 #include "dal_asic_id.h"
diff --git a/drivers/gpu/drm/amd/display/dc/dml/dcn10/dcn10_fpu.c b/drivers/gpu/drm/amd/display/dc/dml/dcn10/dcn10_fpu.c
index ae6b2d47f379..a7fdc0b0a7e9 100644
--- a/drivers/gpu/drm/amd/display/dc/dml/dcn10/dcn10_fpu.c
+++ b/drivers/gpu/drm/amd/display/dc/dml/dcn10/dcn10_fpu.c
@@ -28,6 +28,7 @@
 
 #include "dcn10_fpu.h"
 #include "resource.h"
+#include "dc_priv.h"
 
 /**
  * DOC: DCN10 FPU manipulation Overview
diff --git a/drivers/gpu/drm/amd/display/dc/dml/dcn20/dcn20_fpu.c b/drivers/gpu/drm/amd/display/dc/dml/dcn20/dcn20_fpu.c
index 38c79239004c..458832a2d2df 100644
--- a/drivers/gpu/drm/amd/display/dc/dml/dcn20/dcn20_fpu.c
+++ b/drivers/gpu/drm/amd/display/dc/dml/dcn20/dcn20_fpu.c
@@ -33,6 +33,7 @@
 #include "link_service.h"
 #include "dcn20_fpu.h"
 #include "dc_state_priv.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER \
 	dc->ctx->logger
diff --git a/drivers/gpu/drm/amd/display/dc/dml/dcn30/dcn30_fpu.c b/drivers/gpu/drm/amd/display/dc/dml/dcn30/dcn30_fpu.c
index b8e5985f9307..ac5fcaf96c10 100644
--- a/drivers/gpu/drm/amd/display/dc/dml/dcn30/dcn30_fpu.c
+++ b/drivers/gpu/drm/amd/display/dc/dml/dcn30/dcn30_fpu.c
@@ -34,6 +34,7 @@
 #include "dcn30_fpu.h"
 
 #include "../dml1_frl_cap_chk.h"
+#include "dc_priv.h"
 
 #define REG(reg)\
 	optc1->tg_regs->reg
diff --git a/drivers/gpu/drm/amd/display/dc/dml/dcn301/dcn301_fpu.c b/drivers/gpu/drm/amd/display/dc/dml/dcn301/dcn301_fpu.c
index c4b73acd7140..2849ddd42e39 100644
--- a/drivers/gpu/drm/amd/display/dc/dml/dcn301/dcn301_fpu.c
+++ b/drivers/gpu/drm/amd/display/dc/dml/dcn301/dcn301_fpu.c
@@ -30,6 +30,7 @@
 
 #include "dml/dcn20/dcn20_fpu.h"
 #include "dcn301_fpu.h"
+#include "dc_priv.h"
 
 #define TO_DCN301_RES_POOL(pool)\
 	container_of(pool, struct dcn301_resource_pool, base)
diff --git a/drivers/gpu/drm/amd/display/dc/dml/dcn302/dcn302_fpu.c b/drivers/gpu/drm/amd/display/dc/dml/dcn302/dcn302_fpu.c
index 781bc429807f..6b5ab8940a73 100644
--- a/drivers/gpu/drm/amd/display/dc/dml/dcn302/dcn302_fpu.c
+++ b/drivers/gpu/drm/amd/display/dc/dml/dcn302/dcn302_fpu.c
@@ -30,6 +30,7 @@
 
 #include "dml/dcn20/dcn20_fpu.h"
 #include "dcn302_fpu.h"
+#include "dc_priv.h"
 
 struct _vcs_dpi_ip_params_st dcn3_02_ip = {
 		.use_min_dcfclk = 0,
diff --git a/drivers/gpu/drm/amd/display/dc/dml/dcn303/dcn303_fpu.c b/drivers/gpu/drm/amd/display/dc/dml/dcn303/dcn303_fpu.c
index e6d7d67f06a4..61b2d8e3b7c5 100644
--- a/drivers/gpu/drm/amd/display/dc/dml/dcn303/dcn303_fpu.c
+++ b/drivers/gpu/drm/amd/display/dc/dml/dcn303/dcn303_fpu.c
@@ -29,6 +29,7 @@
 
 #include "dml/dcn20/dcn20_fpu.h"
 #include "dcn303_fpu.h"
+#include "dc_priv.h"
 
 struct _vcs_dpi_ip_params_st dcn3_03_ip = {
 		.use_min_dcfclk = 0,
diff --git a/drivers/gpu/drm/amd/display/dc/dml/dcn31/dcn31_fpu.c b/drivers/gpu/drm/amd/display/dc/dml/dcn31/dcn31_fpu.c
index f9b2da6b2bb8..9289d5ccf5f3 100644
--- a/drivers/gpu/drm/amd/display/dc/dml/dcn31/dcn31_fpu.c
+++ b/drivers/gpu/drm/amd/display/dc/dml/dcn31/dcn31_fpu.c
@@ -31,6 +31,7 @@
 
 #include "dml/dcn20/dcn20_fpu.h"
 #include "dcn31_fpu.h"
+#include "dc_priv.h"
 
 /**
  * DOC: DCN31x FPU manipulation Overview
diff --git a/drivers/gpu/drm/amd/display/dc/dml/dcn314/dcn314_fpu.c b/drivers/gpu/drm/amd/display/dc/dml/dcn314/dcn314_fpu.c
index 1854137d5b9e..bc320383ad56 100644
--- a/drivers/gpu/drm/amd/display/dc/dml/dcn314/dcn314_fpu.c
+++ b/drivers/gpu/drm/amd/display/dc/dml/dcn314/dcn314_fpu.c
@@ -32,6 +32,7 @@
 #include "dml/dcn31/dcn31_fpu.h"
 #include "dml/display_mode_vba.h"
 #include "dml/dml_inline_defs.h"
+#include "dc_priv.h"
 
 struct _vcs_dpi_ip_params_st dcn3_14_ip = {
 	.VBlankNomDefaultUS = 668,
diff --git a/drivers/gpu/drm/amd/display/dc/dml/dcn32/dcn32_fpu.c b/drivers/gpu/drm/amd/display/dc/dml/dcn32/dcn32_fpu.c
index b5bd1358fdfd..f15fe3a76ddb 100644
--- a/drivers/gpu/drm/amd/display/dc/dml/dcn32/dcn32_fpu.c
+++ b/drivers/gpu/drm/amd/display/dc/dml/dcn32/dcn32_fpu.c
@@ -33,6 +33,7 @@
 #include "dcn30/dcn30_resource.h"
 #include "link_service.h"
 #include "dc_state_priv.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER_INIT(logger)
 
diff --git a/drivers/gpu/drm/amd/display/dc/dml/dcn321/dcn321_fpu.c b/drivers/gpu/drm/amd/display/dc/dml/dcn321/dcn321_fpu.c
index f4d826e0d13a..e96d05f9e8c1 100644
--- a/drivers/gpu/drm/amd/display/dc/dml/dcn321/dcn321_fpu.c
+++ b/drivers/gpu/drm/amd/display/dc/dml/dcn321/dcn321_fpu.c
@@ -30,6 +30,7 @@
 #include "dcn32/dcn32_resource.h"
 #include "dcn321/dcn321_resource.h"
 #include "dml/dcn32/display_mode_vba_util_32.h"
+#include "dc_priv.h"
 
 #define DCN3_2_DEFAULT_DET_SIZE 256
 
diff --git a/drivers/gpu/drm/amd/display/dc/dml/dcn35/dcn35_fpu.c b/drivers/gpu/drm/amd/display/dc/dml/dcn35/dcn35_fpu.c
index c15fbc18bfdf..d03f82ad2108 100644
--- a/drivers/gpu/drm/amd/display/dc/dml/dcn35/dcn35_fpu.c
+++ b/drivers/gpu/drm/amd/display/dc/dml/dcn35/dcn35_fpu.c
@@ -32,6 +32,7 @@
 #include "dml/dml_inline_defs.h"
 
 #include "link_service.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER_INIT(logger)
 
diff --git a/drivers/gpu/drm/amd/display/dc/dml/dcn351/dcn351_fpu.c b/drivers/gpu/drm/amd/display/dc/dml/dcn351/dcn351_fpu.c
index 0c5a2667d526..762d37c500e9 100644
--- a/drivers/gpu/drm/amd/display/dc/dml/dcn351/dcn351_fpu.c
+++ b/drivers/gpu/drm/amd/display/dc/dml/dcn351/dcn351_fpu.c
@@ -11,6 +11,7 @@
 #include "dml/dml_inline_defs.h"
 
 #include "link_service.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER_INIT(logger)
 
diff --git a/drivers/gpu/drm/amd/display/dc/dml2_wrapper/dml21_wrapper/dml21_translation_helper.c b/drivers/gpu/drm/amd/display/dc/dml2_wrapper/dml21_wrapper/dml21_translation_helper.c
index 6a9f822b2b33..d96373c33b31 100644
--- a/drivers/gpu/drm/amd/display/dc/dml2_wrapper/dml21_wrapper/dml21_translation_helper.c
+++ b/drivers/gpu/drm/amd/display/dc/dml2_wrapper/dml21_wrapper/dml21_translation_helper.c
@@ -9,6 +9,7 @@
 #include "dml21_utils.h"
 #include "dml21_translation_helper.h"
 #include "soc_and_ip_translator.h"
+#include "dc_priv.h"
 
 static void dml21_populate_pmo_options(struct dml2_pmo_options *pmo_options,
 		const struct dc *in_dc,
diff --git a/drivers/gpu/drm/amd/display/dc/dml2_wrapper/dml21_wrapper/dml21_utils.c b/drivers/gpu/drm/amd/display/dc/dml2_wrapper/dml21_wrapper/dml21_utils.c
index 0aecfa8b909f..62283f36d275 100644
--- a/drivers/gpu/drm/amd/display/dc/dml2_wrapper/dml21_wrapper/dml21_utils.c
+++ b/drivers/gpu/drm/amd/display/dc/dml2_wrapper/dml21_wrapper/dml21_utils.c
@@ -10,6 +10,7 @@
 #include "dml2_dc_resource_mgmt.h"
 
 #include "dml2_core_dcn4_calcs.h"
+#include "dc_priv.h"
 
 int dml21_helper_find_dml_pipe_idx_by_stream_id(struct dml2_context *ctx, unsigned int stream_id)
 {
diff --git a/drivers/gpu/drm/amd/display/dc/dml2_wrapper/dml21_wrapper/dml21_wrapper_fpu.c b/drivers/gpu/drm/amd/display/dc/dml2_wrapper/dml21_wrapper/dml21_wrapper_fpu.c
index a1525f7e0e61..6e34bfd9b239 100644
--- a/drivers/gpu/drm/amd/display/dc/dml2_wrapper/dml21_wrapper/dml21_wrapper_fpu.c
+++ b/drivers/gpu/drm/amd/display/dc/dml2_wrapper/dml21_wrapper/dml21_wrapper_fpu.c
@@ -13,6 +13,7 @@
 #include "dml2_wrapper_fpu.h"
 #include "dml21_wrapper.h"
 #include "dml21_wrapper_fpu.h"
+#include "dc_priv.h"
 
 #define INVALID -1
 
diff --git a/drivers/gpu/drm/amd/display/dc/dml2_wrapper/dml2_dc_resource_mgmt.c b/drivers/gpu/drm/amd/display/dc/dml2_wrapper/dml2_dc_resource_mgmt.c
index 4050b0a47caf..ac23b494e9a3 100644
--- a/drivers/gpu/drm/amd/display/dc/dml2_wrapper/dml2_dc_resource_mgmt.c
+++ b/drivers/gpu/drm/amd/display/dc/dml2_wrapper/dml2_dc_resource_mgmt.c
@@ -30,6 +30,7 @@
 #include "dml2_internal_types.h"
 #include "dml2_utils.h"
 #include "dml2_dc_resource_mgmt.h"
+#include "dc_priv.h"
 
 #define MAX_ODM_FACTOR 4
 #define MAX_MPCC_FACTOR 4
diff --git a/drivers/gpu/drm/amd/display/dc/dml2_wrapper/dml2_mall_phantom.c b/drivers/gpu/drm/amd/display/dc/dml2_wrapper/dml2_mall_phantom.c
index edc4dcdde952..ec443cef57fe 100644
--- a/drivers/gpu/drm/amd/display/dc/dml2_wrapper/dml2_mall_phantom.c
+++ b/drivers/gpu/drm/amd/display/dc/dml2_wrapper/dml2_mall_phantom.c
@@ -29,6 +29,7 @@
 #include "dml2_internal_types.h"
 #include "dml2_utils.h"
 #include "dml2_mall_phantom.h"
+#include "dc_priv.h"
 
 unsigned int dml2_helper_calculate_num_ways_for_subvp(struct dml2_context *ctx, struct dc_state *context)
 {
diff --git a/drivers/gpu/drm/amd/display/dc/dml2_wrapper/dml2_translation_helper.c b/drivers/gpu/drm/amd/display/dc/dml2_wrapper/dml2_translation_helper.c
index a0130bbfc12a..e6960f1df77b 100644
--- a/drivers/gpu/drm/amd/display/dc/dml2_wrapper/dml2_translation_helper.c
+++ b/drivers/gpu/drm/amd/display/dc/dml2_wrapper/dml2_translation_helper.c
@@ -27,6 +27,7 @@
 #include "display_mode_core.h"
 #include "dml2_internal_types.h"
 #include "dml2_translation_helper.h"
+#include "dc_priv.h"
 
 #define NUM_DCFCLK_STAS 5
 #define NUM_DCFCLK_STAS_NEW 8
diff --git a/drivers/gpu/drm/amd/display/dc/dml2_wrapper/dml2_utils.c b/drivers/gpu/drm/amd/display/dc/dml2_wrapper/dml2_utils.c
index 8688792aa956..a74d6777bbe2 100644
--- a/drivers/gpu/drm/amd/display/dc/dml2_wrapper/dml2_utils.c
+++ b/drivers/gpu/drm/amd/display/dc/dml2_wrapper/dml2_utils.c
@@ -30,6 +30,7 @@
 #include "dml2_internal_types.h"
 #include "dml2_translation_helper.h"
 #include "dml2_utils.h"
+#include "dc_priv.h"
 
 void dml2_util_copy_dml_timing(struct dml_timing_cfg_st *dml_timing_array, unsigned int dst_index, unsigned int src_index)
 {
diff --git a/drivers/gpu/drm/amd/display/dc/dml2_wrapper/dml2_wrapper.c b/drivers/gpu/drm/amd/display/dc/dml2_wrapper/dml2_wrapper.c
index 2fe3c4643f58..133bc9e3bfb0 100644
--- a/drivers/gpu/drm/amd/display/dc/dml2_wrapper/dml2_wrapper.c
+++ b/drivers/gpu/drm/amd/display/dc/dml2_wrapper/dml2_wrapper.c
@@ -12,6 +12,7 @@
 #include "dml21_wrapper/dml21_wrapper_fpu.h"
 
 #include "dc_fpu.h"
+#include "dc_priv.h"
 
 #if !defined(DC_RUN_WITH_PREEMPTION_ENABLED)
 #define DC_RUN_WITH_PREEMPTION_ENABLED(code) code
diff --git a/drivers/gpu/drm/amd/display/dc/dml2_wrapper/dml2_wrapper_fpu.c b/drivers/gpu/drm/amd/display/dc/dml2_wrapper/dml2_wrapper_fpu.c
index 8a31986bc299..1055764381c5 100644
--- a/drivers/gpu/drm/amd/display/dc/dml2_wrapper/dml2_wrapper_fpu.c
+++ b/drivers/gpu/drm/amd/display/dc/dml2_wrapper/dml2_wrapper_fpu.c
@@ -35,6 +35,7 @@
 #include "dml2_wrapper_fpu.h"
 #include "dml21_wrapper/dml21_wrapper.h"
 #include "dml21_wrapper/dml21_wrapper_fpu.h"
+#include "dc_priv.h"
 
 void initialize_dml2_ip_params(struct dml2_context *dml2, const struct dc *in_dc, struct ip_params_st *out)
 {
diff --git a/drivers/gpu/drm/amd/display/dc/dpp/dcn10/dcn10_dpp.c b/drivers/gpu/drm/amd/display/dc/dpp/dcn10/dcn10_dpp.c
index de420cdf1514..cc893bbafc27 100644
--- a/drivers/gpu/drm/amd/display/dc/dpp/dcn10/dcn10_dpp.c
+++ b/drivers/gpu/drm/amd/display/dc/dpp/dcn10/dcn10_dpp.c
@@ -30,6 +30,7 @@
 #include "reg_helper.h"
 #include "dcn10/dcn10_dpp.h"
 #include "basics/conversion.h"
+#include "dc_priv.h"
 
 #define NUM_PHASES    64
 #define HORZ_MAX_TAPS 8
diff --git a/drivers/gpu/drm/amd/display/dc/dpp/dcn10/dcn10_dpp_dscl.c b/drivers/gpu/drm/amd/display/dc/dpp/dcn10/dcn10_dpp_dscl.c
index b9adf8433b36..75c8842a4946 100644
--- a/drivers/gpu/drm/amd/display/dc/dpp/dcn10/dcn10_dpp_dscl.c
+++ b/drivers/gpu/drm/amd/display/dc/dpp/dcn10/dcn10_dpp_dscl.c
@@ -30,6 +30,7 @@
 #include "reg_helper.h"
 #include "dcn10/dcn10_dpp.h"
 #include "basics/conversion.h"
+#include "dc_priv.h"
 
 
 #define NUM_PHASES    64
diff --git a/drivers/gpu/drm/amd/display/dc/dpp/dcn20/dcn20_dpp_cm.c b/drivers/gpu/drm/amd/display/dc/dpp/dcn20/dcn20_dpp_cm.c
index 74cc176d9437..e3e31e561b18 100644
--- a/drivers/gpu/drm/amd/display/dc/dpp/dcn20/dcn20_dpp_cm.c
+++ b/drivers/gpu/drm/amd/display/dc/dpp/dcn20/dcn20_dpp_cm.c
@@ -32,6 +32,7 @@
 #include "basics/conversion.h"
 
 #include "dcn10/dcn10_cm_common.h"
+#include "dc_priv.h"
 
 #define REG(reg)\
 	dpp->tf_regs->reg
diff --git a/drivers/gpu/drm/amd/display/dc/dpp/dcn201/dcn201_dpp.c b/drivers/gpu/drm/amd/display/dc/dpp/dcn201/dcn201_dpp.c
index a2079db62f63..1d2fab6f2081 100644
--- a/drivers/gpu/drm/amd/display/dc/dpp/dcn201/dcn201_dpp.c
+++ b/drivers/gpu/drm/amd/display/dc/dpp/dcn201/dcn201_dpp.c
@@ -30,6 +30,7 @@
 #include "reg_helper.h"
 #include "dcn201/dcn201_dpp.h"
 #include "basics/conversion.h"
+#include "dc_priv.h"
 
 #define REG(reg)\
 	dpp->tf_regs->reg
diff --git a/drivers/gpu/drm/amd/display/dc/dpp/dcn30/dcn30_dpp.c b/drivers/gpu/drm/amd/display/dc/dpp/dcn30/dcn30_dpp.c
index 3db10019fa84..1ca5518255de 100644
--- a/drivers/gpu/drm/amd/display/dc/dpp/dcn30/dcn30_dpp.c
+++ b/drivers/gpu/drm/amd/display/dc/dpp/dcn30/dcn30_dpp.c
@@ -29,6 +29,7 @@
 #include "dcn30/dcn30_dpp.h"
 #include "basics/conversion.h"
 #include "dcn30/dcn30_cm_common.h"
+#include "dc_priv.h"
 
 #define REG(reg)\
 	dpp->tf_regs->reg
diff --git a/drivers/gpu/drm/amd/display/dc/dpp/dcn30/dcn30_dpp_cm.c b/drivers/gpu/drm/amd/display/dc/dpp/dcn30/dcn30_dpp_cm.c
index 86f47d33ec64..1756f0b504f0 100644
--- a/drivers/gpu/drm/amd/display/dc/dpp/dcn30/dcn30_dpp_cm.c
+++ b/drivers/gpu/drm/amd/display/dc/dpp/dcn30/dcn30_dpp_cm.c
@@ -31,6 +31,7 @@
 #include "dcn30/dcn30_dpp.h"
 #include "basics/conversion.h"
 #include "dcn30/dcn30_cm_common.h"
+#include "dc_priv.h"
 
 #define REG(reg)\
 	dpp->tf_regs->reg
diff --git a/drivers/gpu/drm/amd/display/dc/dpp/dcn401/dcn401_dpp_dscl.c b/drivers/gpu/drm/amd/display/dc/dpp/dcn401/dcn401_dpp_dscl.c
index adb3f155d051..9c2f50331056 100644
--- a/drivers/gpu/drm/amd/display/dc/dpp/dcn401/dcn401_dpp_dscl.c
+++ b/drivers/gpu/drm/amd/display/dc/dpp/dcn401/dcn401_dpp_dscl.c
@@ -30,6 +30,7 @@
 #include "reg_helper.h"
 #include "dcn401/dcn401_dpp.h"
 #include "basics/conversion.h"
+#include "dc_priv.h"
 
 
 #define NUM_PHASES    64
diff --git a/drivers/gpu/drm/amd/display/dc/dpp/dcn60/dcn60_dpp_cm.c b/drivers/gpu/drm/amd/display/dc/dpp/dcn60/dcn60_dpp_cm.c
index de0d89ac3f8b..62126d5cc86b 100644
--- a/drivers/gpu/drm/amd/display/dc/dpp/dcn60/dcn60_dpp_cm.c
+++ b/drivers/gpu/drm/amd/display/dc/dpp/dcn60/dcn60_dpp_cm.c
@@ -4,6 +4,7 @@
 #include "dcn60/dcn60_dpp.h"
 #include "dcn30/dcn30_cm_common.h"
 #include "basics/conversion.h"
+#include "dc_priv.h"
 
 #define REG(reg) \
 	dpp->tf_regs->reg
diff --git a/drivers/gpu/drm/amd/display/dc/dpp/dcn60/dcn60_dpp_dscl.c b/drivers/gpu/drm/amd/display/dc/dpp/dcn60/dcn60_dpp_dscl.c
index d1a81e5616b3..b37a538df6ba 100644
--- a/drivers/gpu/drm/amd/display/dc/dpp/dcn60/dcn60_dpp_dscl.c
+++ b/drivers/gpu/drm/amd/display/dc/dpp/dcn60/dcn60_dpp_dscl.c
@@ -9,6 +9,7 @@
 #include "reg_helper.h"
 #include "dcn60/dcn60_dpp.h"
 #include "basics/conversion.h"
+#include "dc_priv.h"
 
 #define REG(reg)\
 	dpp->tf_regs->reg
diff --git a/drivers/gpu/drm/amd/display/dc/dsc/dc_dsc.c b/drivers/gpu/drm/amd/display/dc/dsc/dc_dsc.c
index 56db43d1b072..63f069cb0300 100644
--- a/drivers/gpu/drm/amd/display/dc/dsc/dc_dsc.c
+++ b/drivers/gpu/drm/amd/display/dc/dsc/dc_dsc.c
@@ -27,6 +27,7 @@
 #include "dc_hw_types.h"
 #include "dsc.h"
 #include "dc.h"
+#include "dc_priv.h"
 #include "rc_calc.h"
 #include "fixed31_32.h"
 
diff --git a/drivers/gpu/drm/amd/display/dc/hdcp/hdcp_msg.c b/drivers/gpu/drm/amd/display/dc/hdcp/hdcp_msg.c
index f3413d743107..b2cc2ab39838 100644
--- a/drivers/gpu/drm/amd/display/dc/hdcp/hdcp_msg.c
+++ b/drivers/gpu/drm/amd/display/dc/hdcp/hdcp_msg.c
@@ -31,6 +31,7 @@
 #include "link_service.h"
 #include "link_hwss.h"
 #include "link/protocols/link_dpcd.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER \
 	link->ctx->logger
diff --git a/drivers/gpu/drm/amd/display/dc/hpo/dcn30/dcn30_hpo_frl_link_encoder.c b/drivers/gpu/drm/amd/display/dc/hpo/dcn30/dcn30_hpo_frl_link_encoder.c
index 56e753d2f43d..7ac238c97d69 100644
--- a/drivers/gpu/drm/amd/display/dc/hpo/dcn30/dcn30_hpo_frl_link_encoder.c
+++ b/drivers/gpu/drm/amd/display/dc/hpo/dcn30/dcn30_hpo_frl_link_encoder.c
@@ -29,6 +29,7 @@
 #include "dcn30_hpo_frl_link_encoder.h"
 #include "reg_helper.h"
 #include "dcn10/dcn10_link_encoder.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER enc3->base.ctx->logger
 
diff --git a/drivers/gpu/drm/amd/display/dc/hubbub/dcn10/dcn10_hubbub.c b/drivers/gpu/drm/amd/display/dc/hubbub/dcn10/dcn10_hubbub.c
index 4e33648f74bb..f7acc0d75167 100644
--- a/drivers/gpu/drm/amd/display/dc/hubbub/dcn10/dcn10_hubbub.c
+++ b/drivers/gpu/drm/amd/display/dc/hubbub/dcn10/dcn10_hubbub.c
@@ -27,6 +27,7 @@
 #include "dcn10/dcn10_hubp.h"
 #include "dcn10_hubbub.h"
 #include "reg_helper.h"
+#include "dc_priv.h"
 
 #define CTX \
 	hubbub1->base.ctx
diff --git a/drivers/gpu/drm/amd/display/dc/hubbub/dcn20/dcn20_hubbub.c b/drivers/gpu/drm/amd/display/dc/hubbub/dcn20/dcn20_hubbub.c
index e5b55fe502ca..3cbde1b9e7f0 100644
--- a/drivers/gpu/drm/amd/display/dc/hubbub/dcn20/dcn20_hubbub.c
+++ b/drivers/gpu/drm/amd/display/dc/hubbub/dcn20/dcn20_hubbub.c
@@ -27,6 +27,7 @@
 #include "dcn20_hubbub.h"
 #include "reg_helper.h"
 #include "clk_mgr.h"
+#include "dc_priv.h"
 
 #define REG(reg)\
 	hubbub1->regs->reg
diff --git a/drivers/gpu/drm/amd/display/dc/hubbub/dcn201/dcn201_hubbub.c b/drivers/gpu/drm/amd/display/dc/hubbub/dcn201/dcn201_hubbub.c
index e6b527cd2047..a76a1dc9b797 100644
--- a/drivers/gpu/drm/amd/display/dc/hubbub/dcn201/dcn201_hubbub.c
+++ b/drivers/gpu/drm/amd/display/dc/hubbub/dcn201/dcn201_hubbub.c
@@ -26,6 +26,7 @@
 #include "dcn20/dcn20_hubbub.h"
 #include "dcn201_hubbub.h"
 #include "reg_helper.h"
+#include "dc_priv.h"
 
 #define REG(reg)\
 	hubbub1->regs->reg
diff --git a/drivers/gpu/drm/amd/display/dc/hubbub/dcn21/dcn21_hubbub.c b/drivers/gpu/drm/amd/display/dc/hubbub/dcn21/dcn21_hubbub.c
index 881e91e9385d..afbee30245be 100644
--- a/drivers/gpu/drm/amd/display/dc/hubbub/dcn21/dcn21_hubbub.c
+++ b/drivers/gpu/drm/amd/display/dc/hubbub/dcn21/dcn21_hubbub.c
@@ -27,6 +27,7 @@
 #include "dcn20/dcn20_hubbub.h"
 #include "dcn21_hubbub.h"
 #include "reg_helper.h"
+#include "dc_priv.h"
 
 #define REG(reg)\
 	hubbub1->regs->reg
diff --git a/drivers/gpu/drm/amd/display/dc/hubbub/dcn30/dcn30_hubbub.c b/drivers/gpu/drm/amd/display/dc/hubbub/dcn30/dcn30_hubbub.c
index 582d647da812..67325f1efeb3 100644
--- a/drivers/gpu/drm/amd/display/dc/hubbub/dcn30/dcn30_hubbub.c
+++ b/drivers/gpu/drm/amd/display/dc/hubbub/dcn30/dcn30_hubbub.c
@@ -27,6 +27,7 @@
 #include "dm_services.h"
 #include "reg_helper.h"
 #include "dcn30_hubbub.h"
+#include "dc_priv.h"
 
 
 #define CTX \
diff --git a/drivers/gpu/drm/amd/display/dc/hubbub/dcn31/dcn31_hubbub.c b/drivers/gpu/drm/amd/display/dc/hubbub/dcn31/dcn31_hubbub.c
index 786843362061..7965d3dc5df6 100644
--- a/drivers/gpu/drm/amd/display/dc/hubbub/dcn31/dcn31_hubbub.c
+++ b/drivers/gpu/drm/amd/display/dc/hubbub/dcn31/dcn31_hubbub.c
@@ -28,6 +28,7 @@
 #include "dcn31_hubbub.h"
 #include "dm_services.h"
 #include "reg_helper.h"
+#include "dc_priv.h"
 
 
 #define CTX \
diff --git a/drivers/gpu/drm/amd/display/dc/hubbub/dcn32/dcn32_hubbub.c b/drivers/gpu/drm/amd/display/dc/hubbub/dcn32/dcn32_hubbub.c
index dd9bc1f08b56..1353650cc650 100644
--- a/drivers/gpu/drm/amd/display/dc/hubbub/dcn32/dcn32_hubbub.c
+++ b/drivers/gpu/drm/amd/display/dc/hubbub/dcn32/dcn32_hubbub.c
@@ -29,6 +29,7 @@
 #include "dm_services.h"
 #include "reg_helper.h"
 #include "dal_asic_id.h"
+#include "dc_priv.h"
 
 
 #define CTX \
diff --git a/drivers/gpu/drm/amd/display/dc/hubbub/dcn35/dcn35_hubbub.c b/drivers/gpu/drm/amd/display/dc/hubbub/dcn35/dcn35_hubbub.c
index ad333cd3241b..b36640a6c1a5 100644
--- a/drivers/gpu/drm/amd/display/dc/hubbub/dcn35/dcn35_hubbub.c
+++ b/drivers/gpu/drm/amd/display/dc/hubbub/dcn35/dcn35_hubbub.c
@@ -32,6 +32,7 @@
 #include "dm_services.h"
 #include "reg_helper.h"
 #include "dc_dmub_srv.h"
+#include "dc_priv.h"
 
 
 #define CTX \
diff --git a/drivers/gpu/drm/amd/display/dc/hubbub/dcn401/dcn401_hubbub.c b/drivers/gpu/drm/amd/display/dc/hubbub/dcn401/dcn401_hubbub.c
index 957e8f5a6475..3adf0b16633d 100644
--- a/drivers/gpu/drm/amd/display/dc/hubbub/dcn401/dcn401_hubbub.c
+++ b/drivers/gpu/drm/amd/display/dc/hubbub/dcn401/dcn401_hubbub.c
@@ -28,6 +28,7 @@
 #include "dcn401_hubbub.h"
 #include "dm_services.h"
 #include "reg_helper.h"
+#include "dc_priv.h"
 
 
 #define CTX \
diff --git a/drivers/gpu/drm/amd/display/dc/hubbub/dcn42/dcn42_hubbub.c b/drivers/gpu/drm/amd/display/dc/hubbub/dcn42/dcn42_hubbub.c
index 244f3f2824ed..fc417e33f467 100644
--- a/drivers/gpu/drm/amd/display/dc/hubbub/dcn42/dcn42_hubbub.c
+++ b/drivers/gpu/drm/amd/display/dc/hubbub/dcn42/dcn42_hubbub.c
@@ -10,6 +10,7 @@
 #include "dcn42/dcn42_hubbub.h"
 #include "dm_services.h"
 #include "reg_helper.h"
+#include "dc_priv.h"
 
 #define DCN42_CRB_SEGMENT_SIZE_KB 64
 
diff --git a/drivers/gpu/drm/amd/display/dc/hubbub/dcn60/dcn60_hubbub.c b/drivers/gpu/drm/amd/display/dc/hubbub/dcn60/dcn60_hubbub.c
index 07282b78972a..3598b20ba1a4 100644
--- a/drivers/gpu/drm/amd/display/dc/hubbub/dcn60/dcn60_hubbub.c
+++ b/drivers/gpu/drm/amd/display/dc/hubbub/dcn60/dcn60_hubbub.c
@@ -6,6 +6,7 @@
 #include "dm_services.h"
 #include "reg_helper.h"
 #include "fixed31_32.h"
+#include "dc_priv.h"
 
 #define CTX \
 	hubbub2->base.ctx
diff --git a/drivers/gpu/drm/amd/display/dc/hubp/dcn21/dcn21_hubp.c b/drivers/gpu/drm/amd/display/dc/hubp/dcn21/dcn21_hubp.c
index c667db319baf..ef88d15c9db3 100644
--- a/drivers/gpu/drm/amd/display/dc/hubp/dcn21/dcn21_hubp.c
+++ b/drivers/gpu/drm/amd/display/dc/hubp/dcn21/dcn21_hubp.c
@@ -30,6 +30,7 @@
 #include "reg_helper.h"
 
 #include "dc_dmub_srv.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER \
 	ctx->logger
diff --git a/drivers/gpu/drm/amd/display/dc/hubp/dcn35/dcn35_hubp.c b/drivers/gpu/drm/amd/display/dc/hubp/dcn35/dcn35_hubp.c
index c879f4901c7d..45ee7421cd38 100644
--- a/drivers/gpu/drm/amd/display/dc/hubp/dcn35/dcn35_hubp.c
+++ b/drivers/gpu/drm/amd/display/dc/hubp/dcn35/dcn35_hubp.c
@@ -26,6 +26,7 @@
 
 #include "dcn35_hubp.h"
 #include "reg_helper.h"
+#include "dc_priv.h"
 
 #define REG(reg)\
 	hubp2->hubp_regs->reg
diff --git a/drivers/gpu/drm/amd/display/dc/hubp/dcn42/dcn42_hubp.c b/drivers/gpu/drm/amd/display/dc/hubp/dcn42/dcn42_hubp.c
index 0c8a23cef1e0..5dfc261bf0cb 100644
--- a/drivers/gpu/drm/amd/display/dc/hubp/dcn42/dcn42_hubp.c
+++ b/drivers/gpu/drm/amd/display/dc/hubp/dcn42/dcn42_hubp.c
@@ -5,6 +5,7 @@
 #include "dcn401/dcn401_hubp.h"
 #include "dcn42_hubp.h"
 #include "reg_helper.h"
+#include "dc_priv.h"
 
 #define REG(reg) \
 	hubp2->hubp_regs->reg
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dce/dce_hwseq.c b/drivers/gpu/drm/amd/display/dc/hwss/dce/dce_hwseq.c
index 0f44577572fb..9842778f2758 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dce/dce_hwseq.c
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dce/dce_hwseq.c
@@ -27,6 +27,7 @@
 #include "reg_helper.h"
 #include "hw_sequencer_private.h"
 #include "core_types.h"
+#include "dc_priv.h"
 
 #define CTX \
 	hws->ctx
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dce100/dce100_hwseq.c b/drivers/gpu/drm/amd/display/dc/hwss/dce100/dce100_hwseq.c
index 0d7e28260db1..afcc74da11a5 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dce100/dce100_hwseq.c
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dce100/dce100_hwseq.c
@@ -24,6 +24,7 @@
  */
 #include "dm_services.h"
 #include "dc.h"
+#include "dc_priv.h"
 #include "core_types.h"
 #include "clk_mgr.h"
 #include "dce100_hwseq.h"
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dce110/dce110_hwseq.c b/drivers/gpu/drm/amd/display/dc/hwss/dce110/dce110_hwseq.c
index a08ceaeda91c..6bbf5e89d4c5 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dce110/dce110_hwseq.c
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dce110/dce110_hwseq.c
@@ -25,6 +25,7 @@
 
 #include "dm_services.h"
 #include "dc.h"
+#include "dc_priv.h"
 #include "dc_bios_types.h"
 #include "core_types.h"
 #include "core_status.h"
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dce112/dce112_hwseq.c b/drivers/gpu/drm/amd/display/dc/hwss/dce112/dce112_hwseq.c
index ed9b0113a7a0..87f9bfb321cd 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dce112/dce112_hwseq.c
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dce112/dce112_hwseq.c
@@ -25,6 +25,7 @@
 
 #include "dm_services.h"
 #include "dc.h"
+#include "dc_priv.h"
 #include "core_types.h"
 #include "dce112_hwseq.h"
 
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dce120/dce120_hwseq.c b/drivers/gpu/drm/amd/display/dc/hwss/dce120/dce120_hwseq.c
index fbe34d1bb39a..3b728a590237 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dce120/dce120_hwseq.c
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dce120/dce120_hwseq.c
@@ -25,6 +25,7 @@
 
 #include "dm_services.h"
 #include "dc.h"
+#include "dc_priv.h"
 #include "core_types.h"
 #include "dce120_hwseq.h"
 #include "dce/dce_hwseq.h"
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dce60/dce60_hwseq.c b/drivers/gpu/drm/amd/display/dc/hwss/dce60/dce60_hwseq.c
index b73a10b0acbd..58c539a908f1 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dce60/dce60_hwseq.c
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dce60/dce60_hwseq.c
@@ -25,6 +25,7 @@
 
 #include "dm_services.h"
 #include "dc.h"
+#include "dc_priv.h"
 #include "core_types.h"
 #include "dce60_hwseq.h"
 
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dce80/dce80_hwseq.c b/drivers/gpu/drm/amd/display/dc/hwss/dce80/dce80_hwseq.c
index f44f41b13007..c56ff93be7e2 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dce80/dce80_hwseq.c
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dce80/dce80_hwseq.c
@@ -25,6 +25,7 @@
 
 #include "dm_services.h"
 #include "dc.h"
+#include "dc_priv.h"
 #include "core_types.h"
 #include "dce80_hwseq.h"
 
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dcn10/dcn10_hwseq.c b/drivers/gpu/drm/amd/display/dc/hwss/dcn10/dcn10_hwseq.c
index f1d14b97977f..939f5e4948da 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dcn10/dcn10_hwseq.c
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dcn10/dcn10_hwseq.c
@@ -59,6 +59,7 @@
 #include "dce/dmub_outbox.h"
 #include "link_service.h"
 #include "dc_state_priv.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER \
 	dc_ctx->logger
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dcn10/dcn10_init.c b/drivers/gpu/drm/amd/display/dc/hwss/dcn10/dcn10_init.c
index bc3ac96de688..442830726b38 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dcn10/dcn10_init.c
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dcn10/dcn10_init.c
@@ -28,6 +28,7 @@
 #include "dcn10/dcn10_hwseq.h"
 #include "dcn20/dcn20_hwseq.h"
 #include "dc/hwss/dce/dce_hwseq.h"
+#include "dc_priv.h"
 
 static const struct hw_sequencer_funcs dcn10_funcs = {
 	.program_gamut_remap = dcn10_program_gamut_remap,
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dcn20/dcn20_hwseq.c b/drivers/gpu/drm/amd/display/dc/hwss/dcn20/dcn20_hwseq.c
index 636cbd947918..90a05af35782 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dcn20/dcn20_hwseq.c
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dcn20/dcn20_hwseq.c
@@ -57,6 +57,7 @@
 #include "link_hwss.h"
 #include "link_service.h"
 #include "dc_state_priv.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER \
 	dc_logger
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dcn20/dcn20_init.c b/drivers/gpu/drm/amd/display/dc/hwss/dcn20/dcn20_init.c
index 789bde439192..5b07f4fea9e0 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dcn20/dcn20_init.c
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dcn20/dcn20_init.c
@@ -28,6 +28,7 @@
 #include "dcn20/dcn20_hwseq.h"
 
 #include "dcn20_init.h"
+#include "dc_priv.h"
 
 static const struct hw_sequencer_funcs dcn20_funcs = {
 	.program_gamut_remap = dcn10_program_gamut_remap,
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dcn201/dcn201_hwseq.c b/drivers/gpu/drm/amd/display/dc/hwss/dcn201/dcn201_hwseq.c
index d34f63432c6b..0aa8259297c8 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dcn201/dcn201_hwseq.c
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dcn201/dcn201_hwseq.c
@@ -41,6 +41,7 @@
 #include "reg_helper.h"
 #include "dcn10/dcn10_hubbub.h"
 #include "dio/dcn10/dcn10_dio.h"
+#include "dc_priv.h"
 
 
 #define CTX \
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dcn201/dcn201_init.c b/drivers/gpu/drm/amd/display/dc/hwss/dcn201/dcn201_init.c
index 33c22d9bbd2e..5323c2baf811 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dcn201/dcn201_init.c
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dcn201/dcn201_init.c
@@ -29,6 +29,7 @@
 #include "dcn20/dcn20_hwseq.h"
 #include "dcn201/dcn201_hwseq.h"
 #include "dcn201_init.h"
+#include "dc_priv.h"
 
 static const struct hw_sequencer_funcs dcn201_funcs = {
 	.program_gamut_remap = dcn10_program_gamut_remap,
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dcn21/dcn21_hwseq.c b/drivers/gpu/drm/amd/display/dc/hwss/dcn21/dcn21_hwseq.c
index 2be68f8dd0fc..19c6b31d7425 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dcn21/dcn21_hwseq.c
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dcn21/dcn21_hwseq.c
@@ -37,6 +37,7 @@
 #include "dc_dmub_srv.h"
 #include "abm.h"
 #include "link_service.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER_INIT(logger)
 
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dcn21/dcn21_init.c b/drivers/gpu/drm/amd/display/dc/hwss/dcn21/dcn21_init.c
index 39bf0e51ec7c..f5378a40f936 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dcn21/dcn21_init.c
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dcn21/dcn21_init.c
@@ -29,6 +29,7 @@
 #include "dcn21/dcn21_hwseq.h"
 
 #include "dcn21_init.h"
+#include "dc_priv.h"
 
 static const struct hw_sequencer_funcs dcn21_funcs = {
 	.program_gamut_remap = dcn10_program_gamut_remap,
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dcn30/dcn30_hwseq.c b/drivers/gpu/drm/amd/display/dc/hwss/dcn30/dcn30_hwseq.c
index 35d5cce0a791..2119710c37cf 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dcn30/dcn30_hwseq.c
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dcn30/dcn30_hwseq.c
@@ -54,6 +54,7 @@
 #include "link_service.h"
 #include "dc_state_priv.h"
 #include "dio/dcn10/dcn10_dio.h"
+#include "dc_priv.h"
 
 #define TO_DCN_DCCG(dccg)\
 	container_of(dccg, struct dcn_dccg, base)
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dcn30/dcn30_init.c b/drivers/gpu/drm/amd/display/dc/hwss/dcn30/dcn30_init.c
index ce42b8216f3b..4ec42a030dde 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dcn30/dcn30_init.c
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dcn30/dcn30_init.c
@@ -30,6 +30,7 @@
 #include "dcn30/dcn30_hwseq.h"
 
 #include "dcn30_init.h"
+#include "dc_priv.h"
 
 static const struct hw_sequencer_funcs dcn30_funcs = {
 	.program_gamut_remap = dcn30_program_gamut_remap,
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dcn301/dcn301_init.c b/drivers/gpu/drm/amd/display/dc/hwss/dcn301/dcn301_init.c
index 5ed4305e4663..f36136a36bbb 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dcn301/dcn301_init.c
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dcn301/dcn301_init.c
@@ -31,6 +31,7 @@
 #include "dcn301/dcn301_hwseq.h"
 
 #include "dcn301_init.h"
+#include "dc_priv.h"
 
 static const struct hw_sequencer_funcs dcn301_funcs = {
 	.program_gamut_remap = dcn30_program_gamut_remap,
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dcn302/dcn302_hwseq.c b/drivers/gpu/drm/amd/display/dc/hwss/dcn302/dcn302_hwseq.c
index 0a6d58dd8f6d..c2e0ab1e6831 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dcn302/dcn302_hwseq.c
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dcn302/dcn302_hwseq.c
@@ -29,6 +29,7 @@
 
 #include "reg_helper.h"
 #include "dc.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER_INIT(logger)
 
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dcn302/dcn302_init.c b/drivers/gpu/drm/amd/display/dc/hwss/dcn302/dcn302_init.c
index 637f9514d37b..9b6f273ced8a 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dcn302/dcn302_init.c
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dcn302/dcn302_init.c
@@ -28,6 +28,7 @@
 #include "dcn30/dcn30_init.h"
 
 #include "dc.h"
+#include "dc_priv.h"
 
 #include "dcn302_init.h"
 
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dcn303/dcn303_init.c b/drivers/gpu/drm/amd/display/dc/hwss/dcn303/dcn303_init.c
index edb4d68b8187..77e77a990d12 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dcn303/dcn303_init.c
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dcn303/dcn303_init.c
@@ -26,6 +26,7 @@
 #include "dcn303/dcn303_hwseq.h"
 #include "dcn30/dcn30_init.h"
 #include "dc.h"
+#include "dc_priv.h"
 
 #include "dcn303_init.h"
 
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dcn31/dcn31_hwseq.c b/drivers/gpu/drm/amd/display/dc/hwss/dcn31/dcn31_hwseq.c
index b6f3c0480ab6..f5b96c86ca59 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dcn31/dcn31_hwseq.c
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dcn31/dcn31_hwseq.c
@@ -55,6 +55,7 @@
 #include "dce/dmub_abm_lcd.h"
 #include "dio/dcn10/dcn10_dio.h"
 #include "dce/dmub_abm_cacp.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER_INIT(logger)
 
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dcn31/dcn31_init.c b/drivers/gpu/drm/amd/display/dc/hwss/dcn31/dcn31_init.c
index c7055312cc3d..8a0912d7caa8 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dcn31/dcn31_init.c
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dcn31/dcn31_init.c
@@ -32,6 +32,7 @@
 #include "dcn31/dcn31_hwseq.h"
 
 #include "dcn31_init.h"
+#include "dc_priv.h"
 
 static const struct hw_sequencer_funcs dcn31_funcs = {
 	.program_gamut_remap = dcn30_program_gamut_remap,
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dcn314/dcn314_hwseq.c b/drivers/gpu/drm/amd/display/dc/hwss/dcn314/dcn314_hwseq.c
index de7dde2b036b..d57f5be5c57f 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dcn314/dcn314_hwseq.c
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dcn314/dcn314_hwseq.c
@@ -54,6 +54,7 @@
 #include "dsc.h"
 #include "dcn20/dcn20_optc.h"
 #include "dcn30/dcn30_cm_common.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER_INIT(logger)
 
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dcn314/dcn314_init.c b/drivers/gpu/drm/amd/display/dc/hwss/dcn314/dcn314_init.c
index 69b020e2c4b2..0eefe089b281 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dcn314/dcn314_init.c
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dcn314/dcn314_init.c
@@ -34,6 +34,7 @@
 #include "dcn314/dcn314_hwseq.h"
 
 #include "dcn314_init.h"
+#include "dc_priv.h"
 
 static const struct hw_sequencer_funcs dcn314_funcs = {
 	.program_gamut_remap = dcn30_program_gamut_remap,
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dcn32/dcn32_hwseq.c b/drivers/gpu/drm/amd/display/dc/hwss/dcn32/dcn32_hwseq.c
index 9135b01fe388..369d77f6d8f6 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dcn32/dcn32_hwseq.c
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dcn32/dcn32_hwseq.c
@@ -53,6 +53,7 @@
 #include "../dcn20/dcn20_hwseq.h"
 #include "dc_state_priv.h"
 #include "dio/dcn10/dcn10_dio.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER_INIT(logger)
 
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dcn32/dcn32_init.c b/drivers/gpu/drm/amd/display/dc/hwss/dcn32/dcn32_init.c
index b755df909871..7c95e1f928c1 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dcn32/dcn32_init.c
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dcn32/dcn32_init.c
@@ -33,6 +33,7 @@
 #include "dcn401/dcn401_hwseq.h"
 #include "dml/dcn32/dcn32_fpu.h"
 #include "dcn32_init.h"
+#include "dc_priv.h"
 
 static const struct hw_sequencer_funcs dcn32_funcs = {
 	.program_gamut_remap = dcn30_program_gamut_remap,
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dcn35/dcn35_hwseq.c b/drivers/gpu/drm/amd/display/dc/hwss/dcn35/dcn35_hwseq.c
index aa047b5b4939..cd904a28fa12 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dcn35/dcn35_hwseq.c
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dcn35/dcn35_hwseq.c
@@ -60,6 +60,7 @@
 #include "dcn31/dcn31_hwseq.h"
 #include "dcn20/dcn20_hwseq.h"
 #include "dc_state_priv.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER \
 	dc_ctx->logger
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dcn35/dcn35_init.c b/drivers/gpu/drm/amd/display/dc/hwss/dcn35/dcn35_init.c
index 2119a8e000e9..d16e58427132 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dcn35/dcn35_init.c
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dcn35/dcn35_init.c
@@ -36,6 +36,7 @@
 #include "dcn35/dcn35_hwseq.h"
 
 #include "dcn35_init.h"
+#include "dc_priv.h"
 
 static const struct hw_sequencer_funcs dcn35_funcs = {
 	.program_gamut_remap = dcn30_program_gamut_remap,
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dcn351/dcn351_hwseq.c b/drivers/gpu/drm/amd/display/dc/hwss/dcn351/dcn351_hwseq.c
index 8720e47fb33a..5ffae3764894 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dcn351/dcn351_hwseq.c
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dcn351/dcn351_hwseq.c
@@ -28,6 +28,7 @@
 #include "resource.h"
 #include "dcn351_hwseq.h"
 #include "dcn35/dcn35_hwseq.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER_INIT(logger) \
 	struct dal_logger *dc_logger = logger
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dcn351/dcn351_init.c b/drivers/gpu/drm/amd/display/dc/hwss/dcn351/dcn351_init.c
index 0e148c6e5c50..a3c6219ff942 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dcn351/dcn351_init.c
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dcn351/dcn351_init.c
@@ -35,6 +35,7 @@
 #include "dcn351/dcn351_hwseq.h"
 
 #include "dcn351_init.h"
+#include "dc_priv.h"
 
 static const struct hw_sequencer_funcs dcn351_funcs = {
 	.program_gamut_remap = dcn30_program_gamut_remap,
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dcn401/dcn401_hwseq.c b/drivers/gpu/drm/amd/display/dc/hwss/dcn401/dcn401_hwseq.c
index 508749496826..bd31d6c2af48 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dcn401/dcn401_hwseq.c
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dcn401/dcn401_hwseq.c
@@ -41,6 +41,7 @@
 #include "../hw_sequencer.h"
 #include "dio/dcn10/dcn10_dio.h"
 #include "gpio_service_interface.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER_INIT(logger)
 
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dcn401/dcn401_init.c b/drivers/gpu/drm/amd/display/dc/hwss/dcn401/dcn401_init.c
index 1e79b4945801..8bffcfe2b7b7 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dcn401/dcn401_init.c
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dcn401/dcn401_init.c
@@ -12,6 +12,7 @@
 #include "dcn35/dcn35_hwseq.h"
 #include "dcn401/dcn401_hwseq.h"
 #include "dcn401_init.h"
+#include "dc_priv.h"
 
 static const struct hw_sequencer_funcs dcn401_funcs = {
 	.program_gamut_remap = dcn401_program_gamut_remap,
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dcn42/dcn42_hwseq.c b/drivers/gpu/drm/amd/display/dc/hwss/dcn42/dcn42_hwseq.c
index b1cc09df5e63..9e01cb85c010 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dcn42/dcn42_hwseq.c
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dcn42/dcn42_hwseq.c
@@ -36,6 +36,7 @@
 #include "dcn35/dcn35_hwseq.h"
 #include "dcn42/dcn42_hwseq.h"
 #include "dio/dcn10/dcn10_dio.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER \
 	ctx->logger
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dcn42/dcn42_init.c b/drivers/gpu/drm/amd/display/dc/hwss/dcn42/dcn42_init.c
index 00fcb2559247..80ba74138cab 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dcn42/dcn42_init.c
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dcn42/dcn42_init.c
@@ -14,6 +14,7 @@
 #include "dcn401/dcn401_hwseq.h"
 #include "dcn42/dcn42_hwseq.h"
 #include "dcn42_init.h"
+#include "dc_priv.h"
 
 static const struct hw_sequencer_funcs dcn42_funcs = {
 	.program_gamut_remap = dcn401_program_gamut_remap,
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dcn42b/dcn42b_hwseq.c b/drivers/gpu/drm/amd/display/dc/hwss/dcn42b/dcn42b_hwseq.c
index 167f2e53e1f4..027cdd63913f 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dcn42b/dcn42b_hwseq.c
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dcn42b/dcn42b_hwseq.c
@@ -16,6 +16,7 @@
 #include "opp.h"
 #include "mpc.h"
 #include "dcn42b_hwseq.h"
+#include "dc_priv.h"
 
 #define CTX \
 	hws->ctx
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dcn42b/dcn42b_init.c b/drivers/gpu/drm/amd/display/dc/hwss/dcn42b/dcn42b_init.c
index 4210dc7a8eb4..209ae0dbc445 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dcn42b/dcn42b_init.c
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dcn42b/dcn42b_init.c
@@ -8,6 +8,7 @@
 #include "dcn42/dcn42_init.h"
 #include "dcn42b_hwseq.h"
 #include "dcn42b_init.h"
+#include "dc_priv.h"
 
 void dcn42b_hw_sequencer_init_functions(struct dc *dc)
 {
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dcn50/dcn50_hwseq.c b/drivers/gpu/drm/amd/display/dc/hwss/dcn50/dcn50_hwseq.c
index 151ec838f613..7d9597ebf4f6 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dcn50/dcn50_hwseq.c
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dcn50/dcn50_hwseq.c
@@ -36,6 +36,7 @@
 #include "dc_state_priv.h"
 #include "link_enc_cfg.h"
 #include "dio/dcn10/dcn10_dio.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER_INIT(logger)
 
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dcn60/dcn60_hwseq.c b/drivers/gpu/drm/amd/display/dc/hwss/dcn60/dcn60_hwseq.c
index f8254dfe1ce7..b3b4135c8af7 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dcn60/dcn60_hwseq.c
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dcn60/dcn60_hwseq.c
@@ -39,6 +39,7 @@
 #include "dc_state_priv.h"
 #include "link_enc_cfg.h"
 #include "dio/dcn10/dcn10_dio.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER_INIT(logger)
 
diff --git a/drivers/gpu/drm/amd/display/dc/hwss/dcn60/dcn60_init.c b/drivers/gpu/drm/amd/display/dc/hwss/dcn60/dcn60_init.c
index 9fde7d1be3e5..cf205f2c574c 100644
--- a/drivers/gpu/drm/amd/display/dc/hwss/dcn60/dcn60_init.c
+++ b/drivers/gpu/drm/amd/display/dc/hwss/dcn60/dcn60_init.c
@@ -15,6 +15,7 @@
 #include "dcn50/dcn50_hwseq.h"
 #include "dcn60_init.h"
 #include "dcn60_hwseq.h"
+#include "dc_priv.h"
 
 static const struct hw_sequencer_funcs dcn60_funcs = {
 	.program_gamut_remap = dcn401_program_gamut_remap,
diff --git a/drivers/gpu/drm/amd/display/dc/irq/dce110/irq_service_dce110.c b/drivers/gpu/drm/amd/display/dc/irq/dce110/irq_service_dce110.c
index 7f3084c6dd49..129a59dc171b 100644
--- a/drivers/gpu/drm/amd/display/dc/irq/dce110/irq_service_dce110.c
+++ b/drivers/gpu/drm/amd/display/dc/irq/dce110/irq_service_dce110.c
@@ -35,6 +35,7 @@
 #include "ivsrcid/ivsrcid_vislands30.h"
 
 #include "dc.h"
+#include "dc_priv.h"
 #include "core_types.h"
 #define DC_LOGGER \
 	irq_service->ctx->logger
diff --git a/drivers/gpu/drm/amd/display/dc/link/accessories/link_dp_cts.c b/drivers/gpu/drm/amd/display/dc/link/accessories/link_dp_cts.c
index 83f676a49fd1..b2637ec27cd4 100644
--- a/drivers/gpu/drm/amd/display/dc/link/accessories/link_dp_cts.c
+++ b/drivers/gpu/drm/amd/display/dc/link/accessories/link_dp_cts.c
@@ -35,6 +35,7 @@
 #include "dc_dmub_srv.h"
 #include "dce/dmub_hw_lock_mgr.h"
 #include "clk_mgr.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER \
 	link->ctx->logger
diff --git a/drivers/gpu/drm/amd/display/dc/link/accessories/link_dp_trace.c b/drivers/gpu/drm/amd/display/dc/link/accessories/link_dp_trace.c
index c8c55f196f8d..3a517e174b08 100644
--- a/drivers/gpu/drm/amd/display/dc/link/accessories/link_dp_trace.c
+++ b/drivers/gpu/drm/amd/display/dc/link/accessories/link_dp_trace.c
@@ -24,6 +24,7 @@
  */
 #include "link_dp_trace.h"
 #include "link/protocols/link_dpcd.h"
+#include "dc_priv.h"
 
 void dp_trace_init(struct dc_link *link)
 {
diff --git a/drivers/gpu/drm/amd/display/dc/link/hwss/link_hwss_dio.c b/drivers/gpu/drm/amd/display/dc/link/hwss/link_hwss_dio.c
index befa67b2b2ae..bbbce6cb80b9 100644
--- a/drivers/gpu/drm/amd/display/dc/link/hwss/link_hwss_dio.c
+++ b/drivers/gpu/drm/amd/display/dc/link/hwss/link_hwss_dio.c
@@ -25,6 +25,7 @@
 #include "link_hwss_dio.h"
 #include "core_types.h"
 #include "link_enc_cfg.h"
+#include "dc_priv.h"
 
 /**
  * DOC: overview
diff --git a/drivers/gpu/drm/amd/display/dc/link/hwss/link_hwss_dio_fixed_vs_pe_retimer.c b/drivers/gpu/drm/amd/display/dc/link/hwss/link_hwss_dio_fixed_vs_pe_retimer.c
index e1dff4e3f446..846890a87826 100644
--- a/drivers/gpu/drm/amd/display/dc/link/hwss/link_hwss_dio_fixed_vs_pe_retimer.c
+++ b/drivers/gpu/drm/amd/display/dc/link/hwss/link_hwss_dio_fixed_vs_pe_retimer.c
@@ -25,6 +25,7 @@
 #include "link_hwss_dio.h"
 #include "link_hwss_dio_fixed_vs_pe_retimer.h"
 #include "link_enc_cfg.h"
+#include "dc_priv.h"
 
 uint8_t dp_dio_fixed_vs_pe_retimer_lane_cfg_to_hw_cfg(struct dc_link *link)
 {
diff --git a/drivers/gpu/drm/amd/display/dc/link/hwss/link_hwss_dpia.c b/drivers/gpu/drm/amd/display/dc/link/hwss/link_hwss_dpia.c
index 2a87b23582f3..8cede496ab4d 100644
--- a/drivers/gpu/drm/amd/display/dc/link/hwss/link_hwss_dpia.c
+++ b/drivers/gpu/drm/amd/display/dc/link/hwss/link_hwss_dpia.c
@@ -26,6 +26,7 @@
 #include "core_types.h"
 #include "link_hwss_dio.h"
 #include "link_enc_cfg.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER \
 	link->ctx->logger
diff --git a/drivers/gpu/drm/amd/display/dc/link/hwss/link_hwss_hpo_dp.c b/drivers/gpu/drm/amd/display/dc/link/hwss/link_hwss_hpo_dp.c
index 811048123401..cfff0029472c 100644
--- a/drivers/gpu/drm/amd/display/dc/link/hwss/link_hwss_hpo_dp.c
+++ b/drivers/gpu/drm/amd/display/dc/link/hwss/link_hwss_hpo_dp.c
@@ -27,6 +27,7 @@
 #include "core_types.h"
 #include "dccg.h"
 #include "clk_mgr.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER link->ctx->logger
 
diff --git a/drivers/gpu/drm/amd/display/dc/link/hwss/link_hwss_hpo_fixed_vs_pe_retimer_dp.c b/drivers/gpu/drm/amd/display/dc/link/hwss/link_hwss_hpo_fixed_vs_pe_retimer_dp.c
index 6d5b7450b205..4b706db98253 100644
--- a/drivers/gpu/drm/amd/display/dc/link/hwss/link_hwss_hpo_fixed_vs_pe_retimer_dp.c
+++ b/drivers/gpu/drm/amd/display/dc/link/hwss/link_hwss_hpo_fixed_vs_pe_retimer_dp.c
@@ -25,6 +25,7 @@
 #include "link_hwss_hpo_dp.h"
 #include "link_hwss_hpo_fixed_vs_pe_retimer_dp.h"
 #include "link_hwss_dio_fixed_vs_pe_retimer.h"
+#include "dc_priv.h"
 
 static void dp_hpo_fixed_vs_pe_retimer_set_tx_ffe(struct dc_link *link,
 		const struct dc_lane_settings *hw_lane_settings)
diff --git a/drivers/gpu/drm/amd/display/dc/link/hwss/link_hwss_hpo_frl.c b/drivers/gpu/drm/amd/display/dc/link/hwss/link_hwss_hpo_frl.c
index 62288133cd55..2ba3958d31b0 100644
--- a/drivers/gpu/drm/amd/display/dc/link/hwss/link_hwss_hpo_frl.c
+++ b/drivers/gpu/drm/amd/display/dc/link/hwss/link_hwss_hpo_frl.c
@@ -25,6 +25,7 @@
 #include "link_hwss_hpo_frl.h"
 #include "core_types.h"
 #include "link/hwss/link_hwss_virtual.h"
+#include "dc_priv.h"
 
 static void setup_hpo_frl_stream_attribute(struct pipe_ctx *pipe_ctx)
 {
diff --git a/drivers/gpu/drm/amd/display/dc/link/link_detection.c b/drivers/gpu/drm/amd/display/dc/link/link_detection.c
index b4546f93af0c..5f7b82b39239 100644
--- a/drivers/gpu/drm/amd/display/dc/link/link_detection.c
+++ b/drivers/gpu/drm/amd/display/dc/link/link_detection.c
@@ -48,6 +48,7 @@
 #include "link_enc_cfg.h"
 #include "dm_helpers.h"
 #include "clk_mgr.h"
+#include "dc_priv.h"
 
  // Offset DPCD 050Eh == 0x5A
 #define MST_HUB_ID_0x5A  0x5A
diff --git a/drivers/gpu/drm/amd/display/dc/link/link_dpms.c b/drivers/gpu/drm/amd/display/dc/link/link_dpms.c
index 75e232ebffe8..2aff967e73b9 100644
--- a/drivers/gpu/drm/amd/display/dc/link/link_dpms.c
+++ b/drivers/gpu/drm/amd/display/dc/link/link_dpms.c
@@ -58,6 +58,7 @@
 #include "clk_mgr.h"
 #include "atomfirmware.h"
 #include "vpg.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER \
 	dc_logger
diff --git a/drivers/gpu/drm/amd/display/dc/link/link_factory.c b/drivers/gpu/drm/amd/display/dc/link/link_factory.c
index 3b192c539f8b..93eec8a35dda 100644
--- a/drivers/gpu/drm/amd/display/dc/link/link_factory.c
+++ b/drivers/gpu/drm/amd/display/dc/link/link_factory.c
@@ -46,6 +46,7 @@
 #include "protocols/link_hpd.h"
 #include "gpio_service_interface.h"
 #include "atomfirmware.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER \
 	dc_ctx->logger
diff --git a/drivers/gpu/drm/amd/display/dc/link/link_resource.c b/drivers/gpu/drm/amd/display/dc/link/link_resource.c
index bd42bb273c0c..47659537bc68 100644
--- a/drivers/gpu/drm/amd/display/dc/link/link_resource.c
+++ b/drivers/gpu/drm/amd/display/dc/link/link_resource.c
@@ -28,6 +28,7 @@
 
 #include "link_resource.h"
 #include "protocols/link_dp_capability.h"
+#include "dc_priv.h"
 
 void link_get_cur_link_res(const struct dc_link *link,
 		struct link_resource *link_res)
diff --git a/drivers/gpu/drm/amd/display/dc/link/link_validation.c b/drivers/gpu/drm/amd/display/dc/link/link_validation.c
index d7bd352880b3..ab8a8c6807fe 100644
--- a/drivers/gpu/drm/amd/display/dc/link/link_validation.c
+++ b/drivers/gpu/drm/amd/display/dc/link/link_validation.c
@@ -33,6 +33,7 @@
 #include "protocols/link_dp_dpia_bw.h"
 #include "protocols/link_hdmi_frl.h"
 #include "resource.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER_INIT(logger)
 
diff --git a/drivers/gpu/drm/amd/display/dc/link/protocols/link_ddc.c b/drivers/gpu/drm/amd/display/dc/link/protocols/link_ddc.c
index db798656c8a8..15ff2c7d34de 100644
--- a/drivers/gpu/drm/amd/display/dc/link/protocols/link_ddc.c
+++ b/drivers/gpu/drm/amd/display/dc/link/protocols/link_ddc.c
@@ -38,6 +38,7 @@
 #include "link_dpcd.h"
 #include "dm_helpers.h"
 #include "atomfirmware.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER \
 	ddc_service->ctx->logger
diff --git a/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_capability.c b/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_capability.c
index c487c5b87dfd..c3f840b1a0ce 100644
--- a/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_capability.c
+++ b/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_capability.c
@@ -50,6 +50,7 @@
 #include "link_enc_cfg.h"
 #include "dc_dmub_srv.h"
 #include "gpio_service_interface.h"
+#include "dc_priv.h"
 
 #define DC_TRACE_LEVEL_MESSAGE(...) /* do nothing */
 
diff --git a/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_dpia_bw.c b/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_dpia_bw.c
index f43fc4b78a8d..f5c4e815c404 100644
--- a/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_dpia_bw.c
+++ b/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_dpia_bw.c
@@ -29,6 +29,7 @@
 #include "link_dp_dpia_bw.h"
 #include "link_dpcd.h"
 #include "dc_dmub_srv.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER \
 	link->ctx->logger
diff --git a/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_irq_handler.c b/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_irq_handler.c
index da679fb7d89c..a4c533ec638b 100644
--- a/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_irq_handler.c
+++ b/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_irq_handler.c
@@ -39,6 +39,7 @@
 #include "link/link_dpms.h"
 #include "dm_helpers.h"
 #include "link_dp_dpia_bw.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER \
 	link->ctx->logger
diff --git a/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_panel_replay.c b/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_panel_replay.c
index 65a791ccf6b2..4b7b104bd3a8 100644
--- a/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_panel_replay.c
+++ b/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_panel_replay.c
@@ -30,6 +30,7 @@
 #include "dm_helpers.h"
 #include "dc/dc_dmub_srv.h"
 #include "dce/dmub_replay.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER \
 	link->ctx->logger
diff --git a/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_phy.c b/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_phy.c
index 49521ac4b0e8..a3d923aff89c 100644
--- a/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_phy.c
+++ b/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_phy.c
@@ -38,6 +38,7 @@
 #include "resource.h"
 #include "link_enc_cfg.h"
 #include "atomfirmware.h"
+#include "dc_priv.h"
 #define DC_LOGGER \
 	link->ctx->logger
 
diff --git a/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_training.c b/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_training.c
index 3be36d1063de..2a0137759ef5 100644
--- a/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_training.c
+++ b/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_training.c
@@ -47,6 +47,7 @@
 #include "link_enc_cfg.h"
 #include "resource.h"
 #include "dm_helpers.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER \
 	link->ctx->logger
diff --git a/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_training_128b_132b.c b/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_training_128b_132b.c
index 1a6bfc45927d..13b1ff756949 100644
--- a/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_training_128b_132b.c
+++ b/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_training_128b_132b.c
@@ -32,6 +32,7 @@
 #include "link_dpcd.h"
 #include "link_dp_phy.h"
 #include "link_dp_capability.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER \
 	link->ctx->logger
diff --git a/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_training_8b_10b.c b/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_training_8b_10b.c
index 4331e032416f..e4c258434775 100644
--- a/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_training_8b_10b.c
+++ b/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_training_8b_10b.c
@@ -31,6 +31,7 @@
 #include "link_dpcd.h"
 #include "link_dp_phy.h"
 #include "link_dp_capability.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER \
 	link->ctx->logger
diff --git a/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_training_dpia.c b/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_training_dpia.c
index 34fa76d97b83..f1817c7f0948 100644
--- a/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_training_dpia.c
+++ b/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_training_dpia.c
@@ -28,6 +28,7 @@
  */
 #include "link_dp_training_dpia.h"
 #include "dc.h"
+#include "dc_priv.h"
 #include "inc/core_status.h"
 #include "dpcd_defs.h"
 
diff --git a/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_training_fixed_vs_pe_retimer.c b/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_training_fixed_vs_pe_retimer.c
index 6a7c4a59ff4c..08904bc2b500 100644
--- a/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_training_fixed_vs_pe_retimer.c
+++ b/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_training_fixed_vs_pe_retimer.c
@@ -37,6 +37,7 @@
 #include "link_dp_phy.h"
 #include "link_dp_capability.h"
 #include "link_ddc.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER \
 	link->ctx->logger
diff --git a/drivers/gpu/drm/amd/display/dc/link/protocols/link_edp_panel_control.c b/drivers/gpu/drm/amd/display/dc/link/protocols/link_edp_panel_control.c
index 0e9b2b675eac..f88fccf007c0 100644
--- a/drivers/gpu/drm/amd/display/dc/link/protocols/link_edp_panel_control.c
+++ b/drivers/gpu/drm/amd/display/dc/link/protocols/link_edp_panel_control.c
@@ -41,6 +41,7 @@
 #include "abm.h"
 #include "resource.h"
 #include "link_dp_panel_replay.h"
+#include "dc_priv.h"
 #define DC_LOGGER \
 	link->ctx->logger
 #define DC_LOGGER_INIT(logger)
diff --git a/drivers/gpu/drm/amd/display/dc/link/protocols/link_hdmi_frl.c b/drivers/gpu/drm/amd/display/dc/link/protocols/link_hdmi_frl.c
index 960f18fe275b..7887d134eb28 100644
--- a/drivers/gpu/drm/amd/display/dc/link/protocols/link_hdmi_frl.c
+++ b/drivers/gpu/drm/amd/display/dc/link/protocols/link_hdmi_frl.c
@@ -42,6 +42,7 @@
 #include "dccg.h"
 
 #include "dml/dml1_frl_cap_chk.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER \
 	dc_logger
diff --git a/drivers/gpu/drm/amd/display/dc/mpc/dcn20/dcn20_mpc.c b/drivers/gpu/drm/amd/display/dc/mpc/dcn20/dcn20_mpc.c
index 905d4f23f92a..b637cdd3e6af 100644
--- a/drivers/gpu/drm/amd/display/dc/mpc/dcn20/dcn20_mpc.c
+++ b/drivers/gpu/drm/amd/display/dc/mpc/dcn20/dcn20_mpc.c
@@ -27,6 +27,7 @@
 
 #include "reg_helper.h"
 #include "dc.h"
+#include "dc_priv.h"
 #include "mem_input.h"
 #include "dcn10/dcn10_cm_common.h"
 
diff --git a/drivers/gpu/drm/amd/display/dc/mpc/dcn30/dcn30_mpc.c b/drivers/gpu/drm/amd/display/dc/mpc/dcn30/dcn30_mpc.c
index f3213ecb1745..b0af7f219bd2 100644
--- a/drivers/gpu/drm/amd/display/dc/mpc/dcn30/dcn30_mpc.c
+++ b/drivers/gpu/drm/amd/display/dc/mpc/dcn30/dcn30_mpc.c
@@ -29,6 +29,7 @@
 #include "basics/conversion.h"
 #include "dcn10/dcn10_cm_common.h"
 #include "dc.h"
+#include "dc_priv.h"
 
 #define REG(reg)\
 	mpc30->mpc_regs->reg
diff --git a/drivers/gpu/drm/amd/display/dc/mpc/dcn32/dcn32_mpc.c b/drivers/gpu/drm/amd/display/dc/mpc/dcn32/dcn32_mpc.c
index 61a1e3f06575..d8b8b8cd1bfc 100644
--- a/drivers/gpu/drm/amd/display/dc/mpc/dcn32/dcn32_mpc.c
+++ b/drivers/gpu/drm/amd/display/dc/mpc/dcn32/dcn32_mpc.c
@@ -30,6 +30,7 @@
 #include "basics/conversion.h"
 #include "dcn10/dcn10_cm_common.h"
 #include "dc.h"
+#include "dc_priv.h"
 
 #define REG(reg)\
 	mpc30->mpc_regs->reg
diff --git a/drivers/gpu/drm/amd/display/dc/mpc/dcn401/dcn401_mpc.c b/drivers/gpu/drm/amd/display/dc/mpc/dcn401/dcn401_mpc.c
index a485db71c166..2e2412d05a06 100644
--- a/drivers/gpu/drm/amd/display/dc/mpc/dcn401/dcn401_mpc.c
+++ b/drivers/gpu/drm/amd/display/dc/mpc/dcn401/dcn401_mpc.c
@@ -25,6 +25,7 @@
 
 #include "reg_helper.h"
 #include "dc.h"
+#include "dc_priv.h"
 #include "dcn401_mpc.h"
 #include "dcn10/dcn10_cm_common.h"
 #include "basics/conversion.h"
diff --git a/drivers/gpu/drm/amd/display/dc/mpc/dcn60/dcn60_mpc.c b/drivers/gpu/drm/amd/display/dc/mpc/dcn60/dcn60_mpc.c
index 89c4d431a82c..de380c9caecf 100644
--- a/drivers/gpu/drm/amd/display/dc/mpc/dcn60/dcn60_mpc.c
+++ b/drivers/gpu/drm/amd/display/dc/mpc/dcn60/dcn60_mpc.c
@@ -3,6 +3,7 @@
 // Copyright 2025 Advanced Micro Devices, Inc.
 #include "reg_helper.h"
 #include "dc.h"
+#include "dc_priv.h"
 #include "dcn60_mpc.h"
 #include "dcn10/dcn10_cm_common.h"
 #include "basics/conversion.h"
diff --git a/drivers/gpu/drm/amd/display/dc/opp/dcn10/dcn10_opp.c b/drivers/gpu/drm/amd/display/dc/opp/dcn10/dcn10_opp.c
index 98335a53ca52..7f0bd2cb6272 100644
--- a/drivers/gpu/drm/amd/display/dc/opp/dcn10/dcn10_opp.c
+++ b/drivers/gpu/drm/amd/display/dc/opp/dcn10/dcn10_opp.c
@@ -27,6 +27,7 @@
 #include "dm_services.h"
 #include "dcn10_opp.h"
 #include "reg_helper.h"
+#include "dc_priv.h"
 
 #define REG(reg) \
 	(oppn10->regs->reg)
diff --git a/drivers/gpu/drm/amd/display/dc/opp/dcn20/dcn20_opp.c b/drivers/gpu/drm/amd/display/dc/opp/dcn20/dcn20_opp.c
index 544ff2bf7100..89ad9096d356 100644
--- a/drivers/gpu/drm/amd/display/dc/opp/dcn20/dcn20_opp.c
+++ b/drivers/gpu/drm/amd/display/dc/opp/dcn20/dcn20_opp.c
@@ -27,6 +27,7 @@
 #include "dm_services.h"
 #include "dcn20_opp.h"
 #include "reg_helper.h"
+#include "dc_priv.h"
 
 #define REG(reg) \
 	(oppn20->regs->reg)
diff --git a/drivers/gpu/drm/amd/display/dc/optc/dcn30/dcn30_optc.c b/drivers/gpu/drm/amd/display/dc/optc/dcn30/dcn30_optc.c
index 90ec4cb8a9dd..8f345733105a 100644
--- a/drivers/gpu/drm/amd/display/dc/optc/dcn30/dcn30_optc.c
+++ b/drivers/gpu/drm/amd/display/dc/optc/dcn30/dcn30_optc.c
@@ -26,6 +26,7 @@
 #include "reg_helper.h"
 #include "dcn30_optc.h"
 #include "dc.h"
+#include "dc_priv.h"
 #include "dcn_calc_math.h"
 #include "dc_dmub_srv.h"
 
diff --git a/drivers/gpu/drm/amd/display/dc/optc/dcn32/dcn32_optc.c b/drivers/gpu/drm/amd/display/dc/optc/dcn32/dcn32_optc.c
index f9e05efcad98..447f37918527 100644
--- a/drivers/gpu/drm/amd/display/dc/optc/dcn32/dcn32_optc.c
+++ b/drivers/gpu/drm/amd/display/dc/optc/dcn32/dcn32_optc.c
@@ -29,6 +29,7 @@
 #include "dcn31/dcn31_optc.h"
 #include "reg_helper.h"
 #include "dc.h"
+#include "dc_priv.h"
 #include "dcn_calc_math.h"
 #include "dc_dmub_srv.h"
 
diff --git a/drivers/gpu/drm/amd/display/dc/optc/dcn35/dcn35_optc.c b/drivers/gpu/drm/amd/display/dc/optc/dcn35/dcn35_optc.c
index 406446e5eae5..4e4f6f8b641f 100644
--- a/drivers/gpu/drm/amd/display/dc/optc/dcn35/dcn35_optc.c
+++ b/drivers/gpu/drm/amd/display/dc/optc/dcn35/dcn35_optc.c
@@ -31,6 +31,7 @@
 #include "dcn32/dcn32_optc.h"
 #include "reg_helper.h"
 #include "dc.h"
+#include "dc_priv.h"
 #include "dcn_calc_math.h"
 #include "dc_dmub_srv.h"
 
diff --git a/drivers/gpu/drm/amd/display/dc/optc/dcn401/dcn401_optc.c b/drivers/gpu/drm/amd/display/dc/optc/dcn401/dcn401_optc.c
index 5fcdd74eb4a0..7ffb3a82cec5 100644
--- a/drivers/gpu/drm/amd/display/dc/optc/dcn401/dcn401_optc.c
+++ b/drivers/gpu/drm/amd/display/dc/optc/dcn401/dcn401_optc.c
@@ -8,6 +8,7 @@
 #include "dcn32/dcn32_optc.h"
 #include "reg_helper.h"
 #include "dc.h"
+#include "dc_priv.h"
 #include "dcn_calc_math.h"
 #include "dc_dmub_srv.h"
 
diff --git a/drivers/gpu/drm/amd/display/dc/optc/dcn42/dcn42_optc.c b/drivers/gpu/drm/amd/display/dc/optc/dcn42/dcn42_optc.c
index 1e4f2051d732..7422c8602b0e 100644
--- a/drivers/gpu/drm/amd/display/dc/optc/dcn42/dcn42_optc.c
+++ b/drivers/gpu/drm/amd/display/dc/optc/dcn42/dcn42_optc.c
@@ -10,6 +10,7 @@
 #include "dcn401/dcn401_optc.h"
 #include "reg_helper.h"
 #include "dc.h"
+#include "dc_priv.h"
 #include "dcn_calc_math.h"
 #include "dc_dmub_srv.h"
 #include "dc_trace.h"
diff --git a/drivers/gpu/drm/amd/display/dc/pg/dcn35/dcn35_pg_cntl.c b/drivers/gpu/drm/amd/display/dc/pg/dcn35/dcn35_pg_cntl.c
index 6e5ea1bbca02..15d09b11a573 100644
--- a/drivers/gpu/drm/amd/display/dc/pg/dcn35/dcn35_pg_cntl.c
+++ b/drivers/gpu/drm/amd/display/dc/pg/dcn35/dcn35_pg_cntl.c
@@ -28,6 +28,7 @@
 #include "core_types.h"
 #include "dcn35_pg_cntl.h"
 #include "dccg.h"
+#include "dc_priv.h"
 
 #define TO_DCN_PG_CNTL(pg_cntl)\
 	container_of(pg_cntl, struct dcn_pg_cntl, base)
diff --git a/drivers/gpu/drm/amd/display/dc/pg/dcn42/dcn42_pg_cntl.c b/drivers/gpu/drm/amd/display/dc/pg/dcn42/dcn42_pg_cntl.c
index e9125d2467fc..21a12a704611 100644
--- a/drivers/gpu/drm/amd/display/dc/pg/dcn42/dcn42_pg_cntl.c
+++ b/drivers/gpu/drm/amd/display/dc/pg/dcn42/dcn42_pg_cntl.c
@@ -7,6 +7,7 @@
 #include "dcn42_pg_cntl.h"
 #include "dccg.h"
 #include "resource.h"
+#include "dc_priv.h"
 
 #define TO_DCN_PG_CNTL(pg_cntl)\
 	container_of(pg_cntl, struct dcn_pg_cntl, base)
diff --git a/drivers/gpu/drm/amd/display/dc/resource/dce100/dce100_resource.c b/drivers/gpu/drm/amd/display/dc/resource/dce100/dce100_resource.c
index 97ea22af5d2b..1cd90a68d774 100644
--- a/drivers/gpu/drm/amd/display/dc/resource/dce100/dce100_resource.c
+++ b/drivers/gpu/drm/amd/display/dc/resource/dce100/dce100_resource.c
@@ -62,6 +62,7 @@
 #ifndef mmMC_HUB_RDREQ_DMIF_LIMIT
 #include "gmc/gmc_8_2_d.h"
 #include "gmc/gmc_8_2_sh_mask.h"
+#include "dc_priv.h"
 #endif
 
 #ifndef mmDP_DPHY_INTERNAL_CTRL
diff --git a/drivers/gpu/drm/amd/display/dc/resource/dce110/dce110_resource.c b/drivers/gpu/drm/amd/display/dc/resource/dce110/dce110_resource.c
index 19252b25bce0..5f8365ffdf9c 100644
--- a/drivers/gpu/drm/amd/display/dc/resource/dce110/dce110_resource.c
+++ b/drivers/gpu/drm/amd/display/dc/resource/dce110/dce110_resource.c
@@ -66,6 +66,7 @@
 #ifndef mmMC_HUB_RDREQ_DMIF_LIMIT
 #include "gmc/gmc_8_2_d.h"
 #include "gmc/gmc_8_2_sh_mask.h"
+#include "dc_priv.h"
 #endif
 
 #ifndef mmDP_DPHY_INTERNAL_CTRL
diff --git a/drivers/gpu/drm/amd/display/dc/resource/dce112/dce112_resource.c b/drivers/gpu/drm/amd/display/dc/resource/dce112/dce112_resource.c
index 2da5d44e5203..dc73bd5528a2 100644
--- a/drivers/gpu/drm/amd/display/dc/resource/dce112/dce112_resource.c
+++ b/drivers/gpu/drm/amd/display/dc/resource/dce112/dce112_resource.c
@@ -58,6 +58,7 @@
 
 #include "dce100/dce100_resource.h"
 #include "dce112_resource.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER				\
 		dc->ctx->logger
diff --git a/drivers/gpu/drm/amd/display/dc/resource/dce120/dce120_resource.c b/drivers/gpu/drm/amd/display/dc/resource/dce120/dce120_resource.c
index 38d3b87529b0..21a7e176b92e 100644
--- a/drivers/gpu/drm/amd/display/dc/resource/dce120/dce120_resource.c
+++ b/drivers/gpu/drm/amd/display/dc/resource/dce120/dce120_resource.c
@@ -68,6 +68,7 @@
 
 #include "dce100/dce100_resource.h"
 #include "link_service.h"
+#include "dc_priv.h"
 
 #ifndef mmDP0_DP_DPHY_INTERNAL_CTRL
 	#define mmDP0_DP_DPHY_INTERNAL_CTRL		0x210f
diff --git a/drivers/gpu/drm/amd/display/dc/resource/dce60/dce60_resource.c b/drivers/gpu/drm/amd/display/dc/resource/dce60/dce60_resource.c
index 65c7dae3ff66..b8b1eda7ef46 100644
--- a/drivers/gpu/drm/amd/display/dc/resource/dce60/dce60_resource.c
+++ b/drivers/gpu/drm/amd/display/dc/resource/dce60/dce60_resource.c
@@ -66,6 +66,7 @@
 #ifndef mmMC_HUB_RDREQ_DMIF_LIMIT
 #include "gmc/gmc_6_0_d.h"
 #include "gmc/gmc_6_0_sh_mask.h"
+#include "dc_priv.h"
 #endif
 
 #ifndef mmDP_DPHY_INTERNAL_CTRL
diff --git a/drivers/gpu/drm/amd/display/dc/resource/dce80/dce80_resource.c b/drivers/gpu/drm/amd/display/dc/resource/dce80/dce80_resource.c
index 2f4de697ec4b..3d7162f82986 100644
--- a/drivers/gpu/drm/amd/display/dc/resource/dce80/dce80_resource.c
+++ b/drivers/gpu/drm/amd/display/dc/resource/dce80/dce80_resource.c
@@ -64,6 +64,7 @@
 #endif
 
 #include "dce80/dce80_resource.h"
+#include "dc_priv.h"
 
 #ifndef mmDP_DPHY_INTERNAL_CTRL
 #define mmDP_DPHY_INTERNAL_CTRL                         0x1CDE
diff --git a/drivers/gpu/drm/amd/display/dc/resource/dcn10/dcn10_resource.c b/drivers/gpu/drm/amd/display/dc/resource/dcn10/dcn10_resource.c
index 37974c45b44a..47f6eeebb6f9 100644
--- a/drivers/gpu/drm/amd/display/dc/resource/dcn10/dcn10_resource.c
+++ b/drivers/gpu/drm/amd/display/dc/resource/dcn10/dcn10_resource.c
@@ -26,6 +26,7 @@
 #include "core_status.h"
 #include "dm_services.h"
 #include "dc.h"
+#include "dc_priv.h"
 
 #include "dcn10/dcn10_init.h"
 
diff --git a/drivers/gpu/drm/amd/display/dc/resource/dcn20/dcn20_resource.c b/drivers/gpu/drm/amd/display/dc/resource/dcn20/dcn20_resource.c
index 996fce26941f..979523c92074 100644
--- a/drivers/gpu/drm/amd/display/dc/resource/dcn20/dcn20_resource.c
+++ b/drivers/gpu/drm/amd/display/dc/resource/dcn20/dcn20_resource.c
@@ -26,6 +26,7 @@
 
 #include "dm_services.h"
 #include "dc.h"
+#include "dc_priv.h"
 
 #include "dcn20/dcn20_init.h"
 
diff --git a/drivers/gpu/drm/amd/display/dc/resource/dcn201/dcn201_resource.c b/drivers/gpu/drm/amd/display/dc/resource/dcn201/dcn201_resource.c
index 765c63513a31..f53467f1fe96 100644
--- a/drivers/gpu/drm/amd/display/dc/resource/dcn201/dcn201_resource.c
+++ b/drivers/gpu/drm/amd/display/dc/resource/dcn201/dcn201_resource.c
@@ -25,6 +25,7 @@
 
 #include "dm_services.h"
 #include "dc.h"
+#include "dc_priv.h"
 
 #include "dcn201/dcn201_init.h"
 #include "dml/dcn20/dcn20_fpu.h"
diff --git a/drivers/gpu/drm/amd/display/dc/resource/dcn21/dcn21_resource.c b/drivers/gpu/drm/amd/display/dc/resource/dcn21/dcn21_resource.c
index 4095a850ebc6..5f82d6823857 100644
--- a/drivers/gpu/drm/amd/display/dc/resource/dcn21/dcn21_resource.c
+++ b/drivers/gpu/drm/amd/display/dc/resource/dcn21/dcn21_resource.c
@@ -28,6 +28,7 @@
 
 #include "dm_services.h"
 #include "dc.h"
+#include "dc_priv.h"
 
 #include "dcn21/dcn21_init.h"
 
diff --git a/drivers/gpu/drm/amd/display/dc/resource/dcn30/dcn30_resource.c b/drivers/gpu/drm/amd/display/dc/resource/dcn30/dcn30_resource.c
index aecbcd28c2d9..88dc17b1e4d1 100644
--- a/drivers/gpu/drm/amd/display/dc/resource/dcn30/dcn30_resource.c
+++ b/drivers/gpu/drm/amd/display/dc/resource/dcn30/dcn30_resource.c
@@ -26,6 +26,7 @@
 
 #include "dm_services.h"
 #include "dc.h"
+#include "dc_priv.h"
 
 #include "dcn30/dcn30_init.h"
 
diff --git a/drivers/gpu/drm/amd/display/dc/resource/dcn301/dcn301_resource.c b/drivers/gpu/drm/amd/display/dc/resource/dcn301/dcn301_resource.c
index 29113f518c53..0008c8a2867b 100644
--- a/drivers/gpu/drm/amd/display/dc/resource/dcn301/dcn301_resource.c
+++ b/drivers/gpu/drm/amd/display/dc/resource/dcn301/dcn301_resource.c
@@ -26,6 +26,7 @@
 
 #include "dm_services.h"
 #include "dc.h"
+#include "dc_priv.h"
 
 #include "dcn301/dcn301_init.h"
 
diff --git a/drivers/gpu/drm/amd/display/dc/resource/dcn302/dcn302_resource.c b/drivers/gpu/drm/amd/display/dc/resource/dcn302/dcn302_resource.c
index f67b3e00bd86..ca47e743f5bb 100644
--- a/drivers/gpu/drm/amd/display/dc/resource/dcn302/dcn302_resource.c
+++ b/drivers/gpu/drm/amd/display/dc/resource/dcn302/dcn302_resource.c
@@ -78,6 +78,7 @@
 #include "dpcs/dpcs_3_0_0_sh_mask.h"
 #include "nbio/nbio_7_4_offset.h"
 #include "amdgpu_socbb.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER \
 	dc->ctx->logger
diff --git a/drivers/gpu/drm/amd/display/dc/resource/dcn303/dcn303_resource.c b/drivers/gpu/drm/amd/display/dc/resource/dcn303/dcn303_resource.c
index 9e1bf34cca2a..df7fbd6180f0 100644
--- a/drivers/gpu/drm/amd/display/dc/resource/dcn303/dcn303_resource.c
+++ b/drivers/gpu/drm/amd/display/dc/resource/dcn303/dcn303_resource.c
@@ -77,6 +77,7 @@
 #include "nbio/nbio_2_3_offset.h"
 
 #include "dml/dcn303/dcn303_fpu.h"
+#include "dc_priv.h"
 
 #define DC_LOGGER \
 	dc->ctx->logger
diff --git a/drivers/gpu/drm/amd/display/dc/resource/dcn31/dcn31_resource.c b/drivers/gpu/drm/amd/display/dc/resource/dcn31/dcn31_resource.c
index 6359fbb574df..8fa3935df077 100644
--- a/drivers/gpu/drm/amd/display/dc/resource/dcn31/dcn31_resource.c
+++ b/drivers/gpu/drm/amd/display/dc/resource/dcn31/dcn31_resource.c
@@ -26,6 +26,7 @@
 
 #include "dm_services.h"
 #include "dc.h"
+#include "dc_priv.h"
 
 #include "dcn31/dcn31_init.h"
 
diff --git a/drivers/gpu/drm/amd/display/dc/resource/dcn314/dcn314_resource.c b/drivers/gpu/drm/amd/display/dc/resource/dcn314/dcn314_resource.c
index 0ddfceca69dd..f6ef9e50110e 100644
--- a/drivers/gpu/drm/amd/display/dc/resource/dcn314/dcn314_resource.c
+++ b/drivers/gpu/drm/amd/display/dc/resource/dcn314/dcn314_resource.c
@@ -27,6 +27,7 @@
 
 #include "dm_services.h"
 #include "dc.h"
+#include "dc_priv.h"
 
 #include "dcn31/dcn31_init.h"
 #include "dcn314/dcn314_init.h"
diff --git a/drivers/gpu/drm/amd/display/dc/resource/dcn315/dcn315_resource.c b/drivers/gpu/drm/amd/display/dc/resource/dcn315/dcn315_resource.c
index a1894be8cbb2..c34017e92242 100644
--- a/drivers/gpu/drm/amd/display/dc/resource/dcn315/dcn315_resource.c
+++ b/drivers/gpu/drm/amd/display/dc/resource/dcn315/dcn315_resource.c
@@ -26,6 +26,7 @@
 
 #include "dm_services.h"
 #include "dc.h"
+#include "dc_priv.h"
 
 #include "dcn31/dcn31_init.h"
 
diff --git a/drivers/gpu/drm/amd/display/dc/resource/dcn316/dcn316_resource.c b/drivers/gpu/drm/amd/display/dc/resource/dcn316/dcn316_resource.c
index 4a2d56a196b4..66b02193551d 100644
--- a/drivers/gpu/drm/amd/display/dc/resource/dcn316/dcn316_resource.c
+++ b/drivers/gpu/drm/amd/display/dc/resource/dcn316/dcn316_resource.c
@@ -26,6 +26,7 @@
 
 #include "dm_services.h"
 #include "dc.h"
+#include "dc_priv.h"
 
 #include "dcn31/dcn31_init.h"
 
diff --git a/drivers/gpu/drm/amd/display/dc/resource/dcn32/dcn32_resource.c b/drivers/gpu/drm/amd/display/dc/resource/dcn32/dcn32_resource.c
index 619b9b3362fc..49c77d2c0fa1 100644
--- a/drivers/gpu/drm/amd/display/dc/resource/dcn32/dcn32_resource.c
+++ b/drivers/gpu/drm/amd/display/dc/resource/dcn32/dcn32_resource.c
@@ -27,6 +27,7 @@
 #include "dc_types.h"
 #include "dm_services.h"
 #include "dc.h"
+#include "dc_priv.h"
 
 #include "dcn32/dcn32_init.h"
 
diff --git a/drivers/gpu/drm/amd/display/dc/resource/dcn32/dcn32_resource_helpers.c b/drivers/gpu/drm/amd/display/dc/resource/dcn32/dcn32_resource_helpers.c
index 602a0e4e5dc0..9401709009e4 100644
--- a/drivers/gpu/drm/amd/display/dc/resource/dcn32/dcn32_resource_helpers.c
+++ b/drivers/gpu/drm/amd/display/dc/resource/dcn32/dcn32_resource_helpers.c
@@ -30,6 +30,7 @@
 #include "dml/dcn32/dcn32_fpu.h"
 #include "dc_state_priv.h"
 #include "dc_stream_priv.h"
+#include "dc_priv.h"
 
 static bool is_dual_plane(enum surface_pixel_format format)
 {
diff --git a/drivers/gpu/drm/amd/display/dc/resource/dcn321/dcn321_resource.c b/drivers/gpu/drm/amd/display/dc/resource/dcn321/dcn321_resource.c
index 4097093d9012..5f5203324e5f 100644
--- a/drivers/gpu/drm/amd/display/dc/resource/dcn321/dcn321_resource.c
+++ b/drivers/gpu/drm/amd/display/dc/resource/dcn321/dcn321_resource.c
@@ -26,6 +26,7 @@
 
 #include "dm_services.h"
 #include "dc.h"
+#include "dc_priv.h"
 
 #include "dcn32/dcn32_init.h"
 
diff --git a/drivers/gpu/drm/amd/display/dc/resource/dcn35/dcn35_resource.c b/drivers/gpu/drm/amd/display/dc/resource/dcn35/dcn35_resource.c
index 940dd00e97fa..a0bcba089b49 100644
--- a/drivers/gpu/drm/amd/display/dc/resource/dcn35/dcn35_resource.c
+++ b/drivers/gpu/drm/amd/display/dc/resource/dcn35/dcn35_resource.c
@@ -26,6 +26,7 @@
 
 #include "dm_services.h"
 #include "dc.h"
+#include "dc_priv.h"
 
 #include "dcn31/dcn31_init.h"
 #include "dcn35/dcn35_init.h"
diff --git a/drivers/gpu/drm/amd/display/dc/resource/dcn351/dcn351_resource.c b/drivers/gpu/drm/amd/display/dc/resource/dcn351/dcn351_resource.c
index df2aaa46e70c..e8332badd11e 100644
--- a/drivers/gpu/drm/amd/display/dc/resource/dcn351/dcn351_resource.c
+++ b/drivers/gpu/drm/amd/display/dc/resource/dcn351/dcn351_resource.c
@@ -4,6 +4,7 @@
 
 #include "dm_services.h"
 #include "dc.h"
+#include "dc_priv.h"
 
 #include "dcn31/dcn31_init.h"
 #include "dcn351/dcn351_init.h"
diff --git a/drivers/gpu/drm/amd/display/dc/resource/dcn36/dcn36_resource.c b/drivers/gpu/drm/amd/display/dc/resource/dcn36/dcn36_resource.c
index e8580f844af9..d517dbbd9558 100644
--- a/drivers/gpu/drm/amd/display/dc/resource/dcn36/dcn36_resource.c
+++ b/drivers/gpu/drm/amd/display/dc/resource/dcn36/dcn36_resource.c
@@ -3,6 +3,7 @@
 
 #include "dm_services.h"
 #include "dc.h"
+#include "dc_priv.h"
 
 #include "dcn31/dcn31_init.h"
 #include "dcn35/dcn35_init.h"
diff --git a/drivers/gpu/drm/amd/display/dc/resource/dcn401/dcn401_resource.c b/drivers/gpu/drm/amd/display/dc/resource/dcn401/dcn401_resource.c
index b78b0541d113..ea7010f18ca0 100644
--- a/drivers/gpu/drm/amd/display/dc/resource/dcn401/dcn401_resource.c
+++ b/drivers/gpu/drm/amd/display/dc/resource/dcn401/dcn401_resource.c
@@ -4,6 +4,7 @@
 
 #include "dm_services.h"
 #include "dc.h"
+#include "dc_priv.h"
 
 #include "dcn32/dcn32_init.h"
 #include "dcn401/dcn401_init.h"
diff --git a/drivers/gpu/drm/amd/display/dc/resource/dcn42/dcn42_resource.c b/drivers/gpu/drm/amd/display/dc/resource/dcn42/dcn42_resource.c
index 2ad191ec5c38..0214b6cc09a4 100644
--- a/drivers/gpu/drm/amd/display/dc/resource/dcn42/dcn42_resource.c
+++ b/drivers/gpu/drm/amd/display/dc/resource/dcn42/dcn42_resource.c
@@ -4,6 +4,7 @@
 
 #include "dm_services.h"
 #include "dc.h"
+#include "dc_priv.h"
 
 #include "dcn32/dcn32_init.h"
 #include "dcn42/dcn42_init.h"
diff --git a/drivers/gpu/drm/amd/display/dc/resource/dcn42/dcn42_resource_fpu.c b/drivers/gpu/drm/amd/display/dc/resource/dcn42/dcn42_resource_fpu.c
index 33b9775420d3..49fdd35454b8 100644
--- a/drivers/gpu/drm/amd/display/dc/resource/dcn42/dcn42_resource_fpu.c
+++ b/drivers/gpu/drm/amd/display/dc/resource/dcn42/dcn42_resource_fpu.c
@@ -5,6 +5,7 @@
 
 
 #include "dc.h"
+#include "dc_priv.h"
 #include "dcn42_resource_fpu.h"
 
 #define DC_LOGGER_INIT(logger)
diff --git a/drivers/gpu/drm/amd/display/dc/resource/dcn42b/dcn42b_resource.c b/drivers/gpu/drm/amd/display/dc/resource/dcn42b/dcn42b_resource.c
index e111e7532383..177d575f7fc1 100644
--- a/drivers/gpu/drm/amd/display/dc/resource/dcn42b/dcn42b_resource.c
+++ b/drivers/gpu/drm/amd/display/dc/resource/dcn42b/dcn42b_resource.c
@@ -6,6 +6,7 @@
 
 #include "dm_services.h"
 #include "dc.h"
+#include "dc_priv.h"
 
 #include "dcn32/dcn32_init.h"
 #include "dcn42/dcn42_init.h"
diff --git a/drivers/gpu/drm/amd/display/dc/resource/dcn60/dcn60_resource.c b/drivers/gpu/drm/amd/display/dc/resource/dcn60/dcn60_resource.c
index fbaf4e2d31d1..2f09dfb6418c 100644
--- a/drivers/gpu/drm/amd/display/dc/resource/dcn60/dcn60_resource.c
+++ b/drivers/gpu/drm/amd/display/dc/resource/dcn60/dcn60_resource.c
@@ -5,6 +5,7 @@
 #include "dm_services.h"
 #include "dm_helpers.h"
 #include "dc.h"
+#include "dc_priv.h"
 
 #include "dcn32/dcn32_init.h"
 #include "dcn401/dcn401_init.h"
diff --git a/drivers/gpu/drm/amd/display/dc/rmcm/dcn42/dcn42_rmcm.c b/drivers/gpu/drm/amd/display/dc/rmcm/dcn42/dcn42_rmcm.c
index 952f0ade24a5..74fd0008ba62 100644
--- a/drivers/gpu/drm/amd/display/dc/rmcm/dcn42/dcn42_rmcm.c
+++ b/drivers/gpu/drm/amd/display/dc/rmcm/dcn42/dcn42_rmcm.c
@@ -25,6 +25,7 @@
 
 #include "reg_helper.h"
 #include "dc.h"
+#include "dc_priv.h"
 #include "dcn42_rmcm.h"
 #include "dcn10/dcn10_cm_common.h"
 #include "basics/conversion.h"
diff --git a/drivers/gpu/drm/amd/display/dc/rmcm/dcn60/dcn60_rmcm.c b/drivers/gpu/drm/amd/display/dc/rmcm/dcn60/dcn60_rmcm.c
index df4d6476d70a..5d7eb93a92d9 100644
--- a/drivers/gpu/drm/amd/display/dc/rmcm/dcn60/dcn60_rmcm.c
+++ b/drivers/gpu/drm/amd/display/dc/rmcm/dcn60/dcn60_rmcm.c
@@ -25,6 +25,7 @@
 
 #include "dm_services.h"
 #include "dc.h"
+#include "dc_priv.h"
 #include "reg_helper.h"
 
 #include "dcn/dcn_6_0_0_offset.h"
diff --git a/drivers/gpu/drm/amd/display/dc/soc_and_ip_translator/dcn401/dcn401_soc_and_ip_translator.c b/drivers/gpu/drm/amd/display/dc/soc_and_ip_translator/dcn401/dcn401_soc_and_ip_translator.c
index c3dfcf2a73e3..17516048a616 100644
--- a/drivers/gpu/drm/amd/display/dc/soc_and_ip_translator/dcn401/dcn401_soc_and_ip_translator.c
+++ b/drivers/gpu/drm/amd/display/dc/soc_and_ip_translator/dcn401/dcn401_soc_and_ip_translator.c
@@ -4,6 +4,7 @@
 
 #include "dcn401_soc_and_ip_translator.h"
 #include "bounding_boxes/dcn4_soc_bb.h"
+#include "dc_priv.h"
 
 /* soc_and_ip_translator component used to get up-to-date values for bounding box.
  * Bounding box values are stored in several locations and locations can vary with DCN revision.
diff --git a/drivers/gpu/drm/amd/display/dc/soc_and_ip_translator/dcn42/dcn42_soc_and_ip_translator.c b/drivers/gpu/drm/amd/display/dc/soc_and_ip_translator/dcn42/dcn42_soc_and_ip_translator.c
index c6c1b19b7370..ba9a686ffda7 100644
--- a/drivers/gpu/drm/amd/display/dc/soc_and_ip_translator/dcn42/dcn42_soc_and_ip_translator.c
+++ b/drivers/gpu/drm/amd/display/dc/soc_and_ip_translator/dcn42/dcn42_soc_and_ip_translator.c
@@ -5,6 +5,7 @@
 #include "dcn42_soc_and_ip_translator.h"
 #include "../dcn401/dcn401_soc_and_ip_translator.h"
 #include "bounding_boxes/dcn42_soc_bb.h"
+#include "dc_priv.h"
 
 /* soc_and_ip_translator component used to get up-to-date values for bounding box.
  * Bounding box values are stored in several locations and locations can vary with DCN revision.
diff --git a/drivers/gpu/drm/amd/display/dc/soc_and_ip_translator/dcn60/dcn60_soc_and_ip_translator.c b/drivers/gpu/drm/amd/display/dc/soc_and_ip_translator/dcn60/dcn60_soc_and_ip_translator.c
index aef527c7584b..6af8a70188fe 100644
--- a/drivers/gpu/drm/amd/display/dc/soc_and_ip_translator/dcn60/dcn60_soc_and_ip_translator.c
+++ b/drivers/gpu/drm/amd/display/dc/soc_and_ip_translator/dcn60/dcn60_soc_and_ip_translator.c
@@ -6,6 +6,7 @@
 #include "soc_and_ip_translator/dcn401/dcn401_soc_and_ip_translator.h"
 #include "bounding_boxes/dcn6_soc_bb.h"
 #include "dal_asic_id.h"
+#include "dc_priv.h"
 
 /* soc_and_ip_translator component used to get up-to-date values for bounding box.
  * Bounding box values are stored in several locations and locations can vary with DCN revision.

-- 
2.56.0

