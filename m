From: Hermes Wu <Hermes.wu@ite.com.tw>
Subject: [PATCH v5 0/2] Add ITE IT6162 MIPI DSI to HDMI bridge driver
Date: Thu, 29 Oct 2026 18:12:29 +0800
Message-Id: <20261029-upstream-6162-v5-0-8369f9e5afe6@ite.com.tw>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAA0c42oC/3XNyw7CIBAF0F9pWIvhJaAr/8O4KMNgWWgbwKox/
 XfRjY/G5Z3MufdOMqaImWyaO0k4xhz7Uw2rRUOga08HpNHXTAQTmgkh6XnIJWF7pJprQaVZcTT
 WB2g9qWZIGOL11bfb19zFXPp0e9WP/Hn91zRyyig6AK0BHA+4jQWX0B+X5UKeVaN4c8nWv1xU7
 tF5p8Ha+jDj8oPz2bqs3Kq1Cc6AUkzPuPrks3VVuRHaKisxMOm/+DRNDyZnrXxoAQAA
X-Change-ID: 20260223-upstream-6162-3751e78dfcad
To: Andrzej Hajda <andrzej.hajda@intel.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Robert Foss <rfoss@kernel.org>, 
 Laurent Pinchart <Laurent.pinchart@ideasonboard.com>, 
 Jonas Karlman <jonas@kwiboo.se>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Luca Ceresoli <luca.ceresoli@bootlin.com>
Cc: Pet.Weng@ite.com.tw, Kenneth.Hung@ite.com.tw, 
 Hermes Wu <Hermes.Wu@ite.com.tw>, dri-devel@lists.freedesktop.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793268764; l=9031;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=yJH7FtZvNZDml9iZjLPMB66iKpCXjr37vKQnfvmPxm0=;
 b=cEFrgiTBsiD4urhm7tMVF2pJWZY/84/LmAsL+GrmMUQiea9wZoU3LXFqMPj+HLiffxkMuG1kD
 4EqewlACKUMDaixfZj2Qx9FgveHaKw6eMnqXhObybtff8RSnjSrP/GA
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series adds support for the ITE IT6162 MIPI DSI to HDMI
bridge chip. The IT6162 is an I2C-controlled bridge that receives MIPI
DSI input and outputs HDMI signals.

The device supports the following configurations:
  - Single MIPI DSI input: up to 4K @ 30Hz
  - Dual MIPI DSI input (combined): up to 4K @ 60Hz

This series introduces:
  - dt-bindings: Add YAML binding document for ITE IT6162
  - drm/bridge: Add ITE IT6162 MIPI DSI to HDMI bridge driver

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
Changes in v5:
- Move per-patch changelogs into the cover letter

- Documentation/devicetree/bindings/display/bridge/ite,it6162.yaml:
  * Use 1-based data-lanes numbering as lane 0 is the D-PHY clock lane,
    revert example to <1 2 3 4>
  * Constrain data-lanes to in-order lanes or full reversal <4 3 2 1>
  * Document port@1 as the preferred port for a single MIPI DSI input
  * Keep port@0 and port@3 optional: a single MIPI DSI input uses port@1,
    and the HDMI connector is created for the bridge without a port@3
    link
  * Keep a single endpoint node per MIPI DSI port, as other bridge
    bindings based on port-base do
  * Drop Reviewed-by tag due to above changes

- drivers/gpu/drm/bridge/ite-it6162.c:
  * Detect lane reversal from 1-based data-lanes (data_lanes[0] == 4)
  * Rebase on drm-misc-next: use struct drm_atomic_commit in
    atomic_enable/atomic_disable, replace .atomic_reset with
    .atomic_create_state, pass DRM_OUTPUT_COLOR_FORMAT_RGB444 to
    drm_hdmi_compute_mode_clock()
  * Take the colorspace sent to firmware from the AVI infoframe instead of
    conn_state->hdmi.output_format, which is no longer enum hdmi_colorspace
  * Enable the supplies once, while detecting the chip, and disable them
    through devres on removal and on every probe failure; unwind a
    partially failed enable in the power-down order; propagate
    it6162_poweron() errors and drop the unused it6162_poweroff()
  * Power up ivdd, wait at least 1 ms, then ovdd1833 and ovdd, and power
    down in the reverse order with the same wait before ivdd
  * Rename it6162_poweron() to it6162_hw_start() and the power_on flag to
    hw_ready, as the function no longer enables the supplies: it resets
    and configures the chip, then enables the interrupt and connector
    status reporting
  * Order teardown with devres: initialise the (devm managed) mutex, wait
    queue and HDCP work first, and register the bridge before the HDCP
    work cancel action and the IRQ, so the IRQ is freed and the work
    cancelled before the bridge is removed; drop .remove()
  * Hold it6162->lock while writing or clearing an infoframe through the
    data buffer
  * Update the HDCP content protection property from a dedicated work
    holding connection_mutex, and drop updates for an HDCP session that
    has already ended
  * Zero-initialise the video settings and set the HSync/VSync polarity
    and scan mode bits as the programming guide defines them, which also
    fixes the inverted VSync polarity
  * Check regmap read results before using the data read
  * Name the chip ID and version register offsets as in the programming
    guide (register 0x00 is the most significant ID byte); the ID check
    is unchanged
  * Document that the firmware is given the HDMI output timing from the
    requested mode, not the MIPI input timing in adjusted_mode
  * Drop the endpoint node reference on the data-lanes error path
  * Get the chip info with i2c_get_match_data(), add it to the I2C ID
    table and fail probe if it is missing
  * Honour the requested length when reading an EDID block
  * Leave the cached HPD state to the IRQ thread instead of updating it
    from detect
  * Drop Reviewed-by tag due to above changes

- Link to v4: https://lore.kernel.org/r/20260319-upstream-6162-v4-0-7268483ef03d@ite.com.tw

Changes in v4:
- Documentation/devicetree/bindings/display/bridge/ite,it6162.yaml:
  * Drop ite,support-hdcp
  * Drop endpoint properties already in video-interfaces.yaml
  * Fix data-lanes in example with <0 1 2 3>
  * Add blanking line in example before endpoint subnode starts
  * Add reset-gpio and power controls to required

- drivers/gpu/drm/bridge/ite-it6162.c:
  * Drop struc it6162_audio
  * Add HDCP_AUTO in enum hdcp_ver{}, FW enable HDCP by sink capability.
  * Call drm_atomic_helper_connector_hdmi_clear_audio_infoframe()
    in it6162_bridge_hdmi_audio_shutdown()
  * Drop it6162_bridge_hdmi_audio_startup()
  * Add hdmi_clear_hdmi_infoframe and hdmi_write_hdmi_infoframe
  * Drop it6162_parse_dt() due to "ite,support-hdcp" is removed from DT.
  * add DRM_BRIDGE_OP_HDMI to it6162->bridge.ops

- Link to v3: https://lore.kernel.org/r/20260313-upstream-6162-v3-0-8497fb7c4406@ite.com.tw

Changes in v3:
- Documentation/devicetree/bindings/display/bridge/ite,it6162.yaml:
  * Fix lane-polarities: remove $ref redefinition, allow via video-interfaces.yaml
  * Improve ite,support-hdcp description to clarify FW-based HDCP behavior
  * Remove descriptions repeating schema constraints
  * Remove stray comment in ports required section
  * Fix data-lanes spacing in example: <1 2 3 4>
  * Add missing newline at end of file
  * Add missing change log  that Reviewed-by tag was removed when V1->V2

- drivers/gpu/drm/bridge/ite-it6162.c:
  * Fix OFFSET_VERSION_H register offset from 0x03 to 0x05
  * Add MIPI_PORT_EN_MASK macro combining MIPI_PORT1_EN_MASK and MIPI_PORT0_EN_MASK
  * Rename HDCP enums: NO_HDCP -> HDCP_DISABLE, NO_HDCP_STATE -> HDCP_STATE_IDLE,
    AUTH_DONE -> HDCP_STATE_AUTH_DONE, AUTH_FAIL -> HDCP_STATE_AUTH_FAIL
  * Rename it6162_infoblock_complete() to it6162_wait_command_complete()
  * Rename it6162_infoblock_host_set() to it6162_infoblock_trigger()
  * Remove it6162_infoblock_mipi_config() and it6162_infoblock_write_msg()
    wrappers, inline into it6162_reset_init() and
    it6162_mipi_set_video_timing() respectively
  * Remove it6162_set_default_config() wrapper, inline into
    it6162_reset_init()
  * Fix typo: hdcp_encyption -> hdcp_encryption
  * Fix typo: it6162_hdcp_read_infomation -> it6162_hdcp_read_information
  * Remove dev_err_probe() usage outside of probe path
  * Remove verbose success-path dev_info/dev_dbg logging throughout
  * Replace __func__ usage in error messages with descriptive strings
  * Fix double error printing in probe for it6162_init_pdata failure path
  * Fix uninitialized variable warning: initialize cp_status to
    DRM_MODE_CONTENT_PROTECTION_DESIRED at declaration; move
    drm_hdcp_update_content_protection() inside the state-change block
  * Fix audio sample width mapping: case 20 now maps to WORD_LENGTH_20BIT,
    case 24 to WORD_LENGTH_24BIT
  * Remove stray drm_dbg("it6162_bridge_atomic_disable") call
  * Remove drm_dbg() calls from it6162_display_mode_to_settings()
  * Drop unused struct it6162 * parameter from it6162_avi_to_video_setting()
    and it6162_display_mode_to_settings()
  * Fold it6162_set_default_config() body directly into it6162_reset_init(),
    removing the wrapper
  * it6162_infoblock_request_data(): split command complete polling and
    buffer status check into two steps; use wait_event_timeout() for
    data_buf_sts since it is updated asynchronously by the interrupt
    handler; add wait_queue_head_t data_buf_wait to struct it6162 and
    wake_up() in interrupt handler

- Link to v2: https://lore.kernel.org/r/20260309-upstream-6162-v2-0-debdb6c88030@ite.com.tw

Changes in v2:
- dt-bindings:
  * Drop Reviewed-by tag due to below changes
  * Add property "ite,spport-hdcp" to enable HDCP
  * Add property "lane-polarities" and "clock-noncontinuous" for DSI
    setting

- drm/bridge:
  * Drop unused element in struct it6162
  * Remove regmap wrappers
  * Use FIELD_PREP for bitfield operations
  * Update HDCP status with drm_hdcp_update_content_protection()
  * Add AVI, AUDIO, and SPD infoframe control
  * Remove conversion from drm_display_mode to videomode
  * Fix regulator/gpio error handling in it6162_init_pdata() to return proper error codes

- MAINTAINERS
  * squash to driver patch

- Link to v1: https://lore.kernel.org/r/20260223-upstream-6162-v1-0-ebcc66ccb1fe@ite.com.tw

---
Hermes Wu (2):
      dt-bindings: display: bridge: Add ITE IT6162 MIPI DSI to HDMI bridge
      drm/bridge: Add ITE IT6162 MIPI DSI to HDMI bridge driver

 .../bindings/display/bridge/ite,it6162.yaml        |  205 +++
 MAINTAINERS                                        |    7 +
 drivers/gpu/drm/bridge/Kconfig                     |   17 +
 drivers/gpu/drm/bridge/Makefile                    |    1 +
 drivers/gpu/drm/bridge/ite-it6162.c                | 1764 ++++++++++++++++++++
 5 files changed, 1994 insertions(+)
---
base-commit: 33ed26235db93162935d1719bc6f538c384a2fd8
change-id: 20260223-upstream-6162-3751e78dfcad

Best regards,
-- 
Hermes Wu <Hermes.wu@ite.com.tw>

