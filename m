From: Dave Airlie <airlied@redhat.com>
Subject: [PATCH 00/19] drm/amd/display: refactor DC interfaces to abstract
 it better.
Date: Thu, 12 Nov 2026 11:43:35 +1000
Message-Id: <20261112-amdgpu-dc-cleanup-v1-0-0fae41718ad2@redhat.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MSwqAMAwA0atI1gZMQUGvIi76iRrQWloqQvHuF
 pdvMVMgcRROMDUFIt+S5PIV1DZgd+03RnHVoDo1EJFCfbotZHQW7cHa54DG9oZHGjtHBLULkVd
 5/ue8vO8HMb4rZGMAAAA=
X-Change-ID: 20261112-amdgpu-dc-cleanup-bc5be9190d11
To: Harry Wentland <harry.wentland@amd.com>, Leo Li <sunpeng.li@amd.com>, 
 Rodrigo Siqueira <siqueira@igalia.com>, 
 Alex Deucher <alexander.deucher@amd.com>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 David Airlie <airlied@gmail.com>, Austin Zheng <austin.zheng@amd.com>, 
 Jun Lei <jun.lei@amd.com>, Kenneth Feng <kenneth.feng@amd.com>
Cc: amd-gfx@lists.freedesktop.org, dri-devel@lists.freedesktop.org, 
 Dave Airlie <airlied@redhat.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=25013; i=airlied@redhat.com;
 h=from:subject:message-id; bh=EhUeBsCO+cU1/rVHwXnz9Mnn1sI2JdDlW/XL/ajVbpA=;
 b=owEBbQKS/ZANAwAKAQx081l5xIa+AcsmYgBq9RnKy9GZVpPclBMO7zvQOZW3HOC0ele9cEP4w
 BnJ1ok+NdWJAjMEAAEKAB0WIQQQptkdobBb0p9t66wMdPNZecSGvgUCavUZygAKCRAMdPNZecSG
 vjUHEACpwsE09mlhmhcmTDXN8jlOkZqVnQSq1rYxXWJYdK9enQoD+l4v1WDX9UZW2m2pY2rFWfg
 cqYFUZepAHxvujitITp5svD0hTuTgUXccJxMM8UuI4Jn7G6qopdSmWHC+sfxGh0ObycyXq8HGka
 EIy/4rct4qsGdrivG/iM+nhh+2ZJ291UbcGr03QeY/sq1eEbQxHZS6cZpbcy6UlkQqKrIjzH+4+
 2gK6uxzuwg70W0tWiTBWMTfmv38HZfxjx3zTBH9n9+x2UJTuP2Lwlw/SuIvT0f74txd6hmE7k1g
 UwwptCOba/OfzWHv1TwN4624w6U+0rljoAN+zEq4KlGyJHMByCxseITNSZG7lwn1AsFTPyomeKF
 xxV2xIDUmgAiMkBTS2xZ3nIVCQNkD7Z8iWtow2QpCXvivn7JZ6T6byJF4zkbdkQYEDarW57424B
 Qe78Mh7TafHBDtMCmosVxcloeRXMjavfTye+3lCxY7R/HVbo82GH+oaJdA0Cawwe8TO2fZph9XE
 6mW3WTfox2IkfSm18mMzh/BvT8TVWuVdZsp3Gk/R+ddhUcRlSQ2Qf1EyJFOp3IoOhY3XIownWol
 AzeP5ehHJN63/fvKzRTh6j+iz/HAsYVlA6/k6c2fMkDh7jQb0Gf0vpn035jiKk16uoFAmxPH118
 ZSe73BAkr+54SVw==
X-Developer-Key: i=airlied@redhat.com; a=openpgp;
 fpr=10A6D91DA1B05BD29F6DEBAC0C74F35979C486BE
X-Endpoint-Received: by B4 Relay for airlied@redhat.com/default with auth_id=1321
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

I recently was looking into refactoring some things and noticed
that "struct dc" leaks outside of dc a lot, and this is a large
messy struct and if say someone wanted to use bindgen anywhere
near this code it would be a nightmare.

Then I thought, struct dc isn't meant to be like this, so I spent
some time with an LLM refactoring it so that it's hidden again.

This series does that, it starts by dropping some dead code,
adding some DC accessors, using them in various places.

It then moves dc.h and then a hacky patch to stop dc includes from leaking
out again.

Then it does it all again for some other dc structs that are private.

Some things are a bit messy, especially the ABM calculations, and things
in modules not being quite separated enough, but I've tried to keep the
solutions sane.

Dave.

Signed-off-by: Dave Airlie <airlied@redhat.com>
---
Dave Airlie (19):
      drm/amd/display: Drop the dead vmid module
      drm/amd/display: Add DC accessors as the first step to opaque struct dc
      drm/amd/display: Take struct dc in public DSC compute helpers
      drm/amd/display/amdgpu_dm: Use DC accessors in audio/color/backlight paths
      drm/amd/display/amdgpu_dm: Use DC accessors in psr/replay/dmub/hdcp/irq paths
      drm/amd/display/amdgpu_dm: Use DC accessors in plane/crtc/helpers paths
      drm/amd/display/amdgpu_dm: Use DC accessors in connector paths
      drm/amd/display: Use DC accessors in DAL modules
      drm/amd/display/amdgpu_dm: Use DC accessors in debugfs paths
      drm/amd/display/amdgpu_dm: Use DC accessors in the DM core paths
      drm/amd/display/amdgpu_dm: Finish DC accessor migration for non-test code
      drm/amd/display: Migrate amdgpu_dm KUnit tests off struct dc internals
      drm/amd/display: Move struct dc out of the public dc.h
      drm/amd/display: Restrict the dc directory root to DC-internal builds
      drm/amd/display: Add dc_force_max_dramclk for the DP compliance workaround
      drm/amd/display: Add DC primitives for ABM hardware programming
      drm/amd/display: Replace the dc_get_res_pool accessor with purpose APIs
      drm/amd/display: Replace dc_get_config with per-option config reads
      drm/amd/display: Replace dc_get_caps with purpose-built capability queries

 drivers/gpu/drm/amd/amdgpu/Makefile                |   1 -
 drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c  | 172 ++++----
 .../drm/amd/display/amdgpu_dm/amdgpu_dm_audio.c    |   8 +-
 .../amd/display/amdgpu_dm/amdgpu_dm_backlight.c    |  12 +-
 .../drm/amd/display/amdgpu_dm/amdgpu_dm_color.c    |  40 +-
 .../drm/amd/display/amdgpu_dm/amdgpu_dm_color.h    |   4 +-
 .../drm/amd/display/amdgpu_dm/amdgpu_dm_colorop.c  |   7 +-
 .../amd/display/amdgpu_dm/amdgpu_dm_connector.c    |  49 +--
 .../gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_crtc.c |  25 +-
 .../drm/amd/display/amdgpu_dm/amdgpu_dm_debugfs.c  | 132 +++---
 .../gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_dmub.c |  61 +--
 .../gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_hdcp.c |  39 +-
 .../drm/amd/display/amdgpu_dm/amdgpu_dm_helpers.c  |  30 +-
 .../gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_irq.c  |  30 +-
 .../amd/display/amdgpu_dm/amdgpu_dm_mst_types.c    |  44 +-
 .../drm/amd/display/amdgpu_dm/amdgpu_dm_plane.c    |  33 +-
 .../gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_psr.c  |  10 +-
 .../drm/amd/display/amdgpu_dm/amdgpu_dm_replay.c   |  12 +-
 .../drm/amd/display/amdgpu_dm/amdgpu_dm_trace.h    |   4 +-
 .../gpu/drm/amd/display/amdgpu_dm/tests/Makefile   |   1 -
 .../display/amdgpu_dm/tests/amdgpu_dm_audio_test.c |  51 +--
 .../amdgpu_dm/tests/amdgpu_dm_backlight_test.c     |  73 ++--
 .../display/amdgpu_dm/tests/amdgpu_dm_color_test.c |  25 +-
 .../amdgpu_dm/tests/amdgpu_dm_colorop_test.c       |   8 +-
 .../amdgpu_dm/tests/amdgpu_dm_connector_test.c     |  80 ++--
 .../display/amdgpu_dm/tests/amdgpu_dm_crc_test.c   |   7 +-
 .../display/amdgpu_dm/tests/amdgpu_dm_crtc_test.c  |  66 +--
 .../display/amdgpu_dm/tests/amdgpu_dm_dmub_test.c  |  86 ++--
 .../amdgpu_dm/tests/amdgpu_dm_freesync_test.c      |   7 +-
 .../display/amdgpu_dm/tests/amdgpu_dm_hdcp_test.c  |  23 +-
 .../amdgpu_dm/tests/amdgpu_dm_helpers_test.c       |  74 ++--
 .../display/amdgpu_dm/tests/amdgpu_dm_irq_test.c   | 201 +++++-----
 .../display/amdgpu_dm/tests/amdgpu_dm_ism_test.c   |  31 +-
 .../amdgpu_dm/tests/amdgpu_dm_kunit_helpers.c      |  39 +-
 .../amdgpu_dm/tests/amdgpu_dm_kunit_test_helpers.h |   3 +
 .../amdgpu_dm/tests/amdgpu_dm_mst_types_test.c     |  90 +++--
 .../display/amdgpu_dm/tests/amdgpu_dm_plane_test.c |  75 ++--
 .../display/amdgpu_dm/tests/amdgpu_dm_psr_test.c   |  21 +-
 .../amd/display/amdgpu_dm/tests/amdgpu_dm_test.c   |  55 ++-
 .../display/amdgpu_dm/tests/amdgpu_dm_wb_test.c    |   6 +-
 drivers/gpu/drm/amd/display/dc/Makefile            |  16 +
 drivers/gpu/drm/amd/display/dc/basics/dce_calcs.c  |   1 +
 drivers/gpu/drm/amd/display/dc/bios/bios_parser2.c |   1 +
 .../gpu/drm/amd/display/dc/bios/command_table2.c   |   1 +
 .../drm/amd/display/dc/bls_builder/bls_builder.c   |   1 +
 .../dc/bls_builder/bls_builder_legacy_init.h       |   2 +-
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
 drivers/gpu/drm/amd/display/dc/core/dc.c           |  23 ++
 drivers/gpu/drm/amd/display/dc/core/dc_abm.c       | 132 ++++++
 drivers/gpu/drm/amd/display/dc/core/dc_accessors.c | 313 +++++++++++++++
 drivers/gpu/drm/amd/display/dc/core/dc_debug.c     |   1 +
 .../gpu/drm/amd/display/dc/core/dc_hw_sequencer.c  |   1 +
 .../gpu/drm/amd/display/dc/core/dc_link_enc_cfg.c  |   1 +
 .../gpu/drm/amd/display/dc/core/dc_link_exports.c  |  86 ++++
 drivers/gpu/drm/amd/display/dc/core/dc_resource.c  |  11 +
 drivers/gpu/drm/amd/display/dc/core/dc_stat.c      |   3 +-
 drivers/gpu/drm/amd/display/dc/core/dc_state.c     |   1 +
 drivers/gpu/drm/amd/display/dc/core/dc_stream.c    |   1 +
 drivers/gpu/drm/amd/display/dc/core/dc_surface.c   |   1 +
 drivers/gpu/drm/amd/display/dc/core/dc_test.c      | 155 +++++++
 drivers/gpu/drm/amd/display/dc/core/dc_vm_helper.c |   1 +
 drivers/gpu/drm/amd/display/dc/core2/dc_core2.h    |   2 +-
 .../drm/amd/display/dc/dc_api_dispatch/api_shim.c  |   2 +-
 .../drm/amd/display/dc/dc_api_dispatch/api_shim.h  |   3 +-
 drivers/gpu/drm/amd/display/dc/dc_dmub_srv.c       |   1 +
 drivers/gpu/drm/amd/display/dc/dc_priv.h           | 186 +++++++++
 drivers/gpu/drm/amd/display/dc/dc_spl_translate.c  |   1 +
 .../gpu/drm/amd/display/dc/dccg/dcn31/dcn31_dccg.c |   1 +
 .../drm/amd/display/dc/dccg/dcn314/dcn314_dccg.c   |   1 +
 .../gpu/drm/amd/display/dc/dccg/dcn35/dcn35_dccg.c |   1 +
 .../drm/amd/display/dc/dccg/dcn401/dcn401_dccg.c   |   1 +
 .../gpu/drm/amd/display/dc/dccg/dcn42/dcn42_dccg.c |   1 +
 drivers/gpu/drm/amd/display/dc/dce/dce_aux.c       |   1 +
 drivers/gpu/drm/amd/display/dc/dce/dce_aux.h       |   2 +-
 .../gpu/drm/amd/display/dc/dce/dce_clock_source.c  |   1 +
 drivers/gpu/drm/amd/display/dc/dce/dce_dmcu.c      |   1 +
 drivers/gpu/drm/amd/display/dc/dce/dce_i2c.c       |   1 +
 drivers/gpu/drm/amd/display/dc/dce/dce_i2c.h       |   2 +-
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
 .../drm/amd/display/dc/dce110/dce110_mem_input_v.c |   3 +-
 .../drm/amd/display/dc/dce110/dce110_transform_v.c |   1 +
 .../display/dc/dcn10/dcn10_hw_sequencer_debug.c    |   1 +
 .../amd/display/dc/dcn201/dcn201_link_encoder.c    |   1 +
 .../drm/amd/display/dc/dcn21/dcn21_link_encoder.c  |   1 +
 drivers/gpu/drm/amd/display/dc/dcn31/dcn31_afmt.c  |   3 +-
 .../drm/amd/display/dc/dcn31/dcn31_panel_cntl.c    |   1 +
 drivers/gpu/drm/amd/display/dc/dcn31/dcn31_vpg.c   |   3 +-
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
 drivers/gpu/drm/amd/display/dc/dsc/dc_dsc.c        |  18 +-
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
 .../gpu/drm/amd/display/dc/hwss/dcn10/dcn10_init.c |   3 +-
 .../drm/amd/display/dc/hwss/dcn20/dcn20_hwseq.c    |   3 +-
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
 .../drm/amd/display/dc/hwss/dcn31/dcn31_hwseq.c    |   3 +-
 .../gpu/drm/amd/display/dc/hwss/dcn31/dcn31_init.c |   1 +
 .../drm/amd/display/dc/hwss/dcn314/dcn314_hwseq.c  |   3 +-
 .../drm/amd/display/dc/hwss/dcn314/dcn314_init.c   |   1 +
 .../drm/amd/display/dc/hwss/dcn32/dcn32_hwseq.c    |   1 +
 .../gpu/drm/amd/display/dc/hwss/dcn32/dcn32_init.c |   1 +
 .../drm/amd/display/dc/hwss/dcn35/dcn35_hwseq.c    |   3 +-
 .../drm/amd/display/dc/hwss/dcn35/dcn35_hwseq.h    |   2 +-
 .../gpu/drm/amd/display/dc/hwss/dcn35/dcn35_init.c |   1 +
 .../drm/amd/display/dc/hwss/dcn351/dcn351_hwseq.c  |   1 +
 .../drm/amd/display/dc/hwss/dcn351/dcn351_init.c   |   1 +
 .../drm/amd/display/dc/hwss/dcn401/dcn401_hwseq.c  |   1 +
 .../drm/amd/display/dc/hwss/dcn401/dcn401_hwseq.h  |   2 +-
 .../drm/amd/display/dc/hwss/dcn401/dcn401_init.c   |   1 +
 .../drm/amd/display/dc/hwss/dcn42/dcn42_hwseq.c    |   1 +
 .../gpu/drm/amd/display/dc/hwss/dcn42/dcn42_init.c |   1 +
 .../drm/amd/display/dc/hwss/dcn42b/dcn42b_hwseq.c  |   1 +
 .../drm/amd/display/dc/hwss/dcn42b/dcn42b_init.c   |   1 +
 .../drm/amd/display/dc/hwss/dcn50/dcn50_hwseq.c    |   1 +
 .../drm/amd/display/dc/hwss/dcn50/dcn50_hwseq.h    |   2 +-
 .../drm/amd/display/dc/hwss/dcn60/dcn60_hwseq.c    |   1 +
 .../drm/amd/display/dc/hwss/dcn60/dcn60_hwseq.h    |   2 +-
 .../gpu/drm/amd/display/dc/hwss/dcn60/dcn60_init.c |   1 +
 drivers/gpu/drm/amd/display/dc/hwss/hw_sequencer.h |  16 +-
 drivers/gpu/drm/amd/display/dc/inc/core_types.h    |   8 +-
 drivers/gpu/drm/amd/display/dc/{ => inc}/dc.h      | 446 ++++++++++++++-------
 .../drm/amd/display/dc/{ => inc}/dc_bios_types.h   |   0
 .../drm/amd/display/dc/{ => inc}/dc_ddc_types.h    |   0
 .../gpu/drm/amd/display/dc/{ => inc}/dc_dmub_srv.h |   0
 .../gpu/drm/amd/display/dc/{ => inc}/dc_dp_types.h |   0
 drivers/gpu/drm/amd/display/dc/{ => inc}/dc_dsc.h  |   4 +-
 .../gpu/drm/amd/display/dc/{ => inc}/dc_fused_io.h |   0
 .../drm/amd/display/dc/{ => inc}/dc_hdmi_types.h   |   0
 .../gpu/drm/amd/display/dc/{ => inc}/dc_hw_types.h |   0
 .../drm/amd/display/dc/{ => inc}/dc_memory_pool.h  |   0
 .../gpu/drm/amd/display/dc/{ => inc}/dc_plane.h    |   0
 .../gpu/drm/amd/display/dc/{ => inc}/dc_probe.h    |   0
 drivers/gpu/drm/amd/display/dc/{ => inc}/dc_stat.h |   0
 .../gpu/drm/amd/display/dc/{ => inc}/dc_state.h    |   2 +-
 .../gpu/drm/amd/display/dc/{ => inc}/dc_stream.h   |   0
 drivers/gpu/drm/amd/display/dc/inc/dc_test.h       |  85 ++++
 .../gpu/drm/amd/display/dc/{ => inc}/dc_trace.h    |   0
 .../gpu/drm/amd/display/dc/{ => inc}/dc_types.h    |   0
 drivers/gpu/drm/amd/display/dc/inc/dcn_calcs.h     |   2 +-
 .../gpu/drm/amd/display/dc/{ => inc}/dm_cp_psp.h   |   0
 .../gpu/drm/amd/display/dc/{ => inc}/dm_helpers.h  |   0
 .../gpu/drm/amd/display/dc/{ => inc}/dm_pp_smu.h   |   0
 .../gpu/drm/amd/display/dc/{ => inc}/dm_services.h |  16 +
 .../amd/display/dc/{ => inc}/dm_services_types.h   |   0
 drivers/gpu/drm/amd/display/dc/inc/hw/dchubbub.h   |   2 +-
 drivers/gpu/drm/amd/display/dc/inc/hw/hubp.h       |   4 +-
 drivers/gpu/drm/amd/display/dc/inc/hw/mcif_wb.h    |   2 +-
 drivers/gpu/drm/amd/display/dc/inc/hw/mem_input.h  |   4 +-
 drivers/gpu/drm/amd/display/dc/inc/hw/transform.h  |   2 +-
 .../gpu/drm/amd/display/dc/{ => inc}/irq_types.h   |   0
 .../gpu/drm/amd/display/dc/{ => inc}/os_types.h    |   0
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
 .../amd/display/dc/link/protocols/link_dp_dpia.c   |   2 +-
 .../display/dc/link/protocols/link_dp_dpia_bw.c    |   1 +
 .../dc/link/protocols/link_dp_irq_handler.c        |   1 +
 .../dc/link/protocols/link_dp_panel_replay.c       |   3 +-
 .../amd/display/dc/link/protocols/link_dp_phy.c    |   1 +
 .../display/dc/link/protocols/link_dp_training.c   |   1 +
 .../dc/link/protocols/link_dp_training_128b_132b.c |   1 +
 .../dc/link/protocols/link_dp_training_8b_10b.c    |   1 +
 .../dc/link/protocols/link_dp_training_dpia.c      |   3 +-
 .../link_dp_training_fixed_vs_pe_retimer.c         |   1 +
 .../dc/link/protocols/link_edp_panel_control.c     |   3 +-
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
 drivers/gpu/drm/amd/display/dmub/dmub_srv.h        |   2 +-
 drivers/gpu/drm/amd/display/dmub/src/dmub_dcn32.c  |   2 +-
 drivers/gpu/drm/amd/display/dmub/src/dmub_dcn35.c  |   2 +-
 .../gpu/drm/amd/display/include/logger_interface.h |  13 +-
 .../drm/amd/display/modules/color/color_gamma.c    |   2 +-
 .../drm/amd/display/modules/color/color_gamma.h    |   2 +-
 .../drm/amd/display/modules/freesync/freesync.c    |  14 +-
 .../gpu/drm/amd/display/modules/inc/mod_freesync.h |   2 +
 .../gpu/drm/amd/display/modules/inc/mod_stats.h    |  75 ----
 drivers/gpu/drm/amd/display/modules/inc/mod_vmid.h |  46 ---
 drivers/gpu/drm/amd/display/modules/power/power.c  |   6 +-
 .../gpu/drm/amd/display/modules/power/power_abm.c  | 168 +++-----
 .../drm/amd/display/modules/power/power_helpers.h  |  17 +-
 .../gpu/drm/amd/display/modules/power/power_psr.c  |  12 +-
 .../drm/amd/display/modules/power/power_replay.c   |  27 +-
 drivers/gpu/drm/amd/display/modules/vmid/vmid.c    | 178 --------
 drivers/gpu/drm/amd/pm/swsmu/inc/amdgpu_smu.h      |   2 +-
 366 files changed, 2633 insertions(+), 1508 deletions(-)
---
base-commit: a6836fcbb5b22968019256025321d655b78bc49c
change-id: 20261112-amdgpu-dc-cleanup-bc5be9190d11

Best regards,
-- 
Dave Airlie <airlied@redhat.com>

