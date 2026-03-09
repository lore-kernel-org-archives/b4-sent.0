From: Hermes Wu <Hermes.wu@ite.com.tw>
Subject: [PATCH v2 0/2] Add ITE IT6162 MIPI DSI to HDMI bridge driver
Date: Mon, 09 Mar 2026 17:42:00 +0800
Message-Id: <20260309-upstream-6162-v2-0-debdb6c88030@ite.com.tw>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOiVrmkC/3XMyw7CIBCF4VdpZi0N0EiNK9/DdEGHwc6ilwCip
 uHdxe5d/ic53w6RAlOEa7NDoMyR16WGPjWAk10eJNjVBi21kVp34rnFFMjOwiijRdefFfUX59E
 6qJ8tkOf34d2H2hPHtIbPwWf1W/9JWQkpaEQ0BnFUnm6cqMV1btMLhlLKFy9WPYarAAAA
X-Change-ID: 20260223-upstream-6162-3751e78dfcad
To: Andrzej Hajda <andrzej.hajda@intel.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Robert Foss <rfoss@kernel.org>, 
 Laurent Pinchart <Laurent.pinchart@ideasonboard.com>, 
 Jonas Karlman <jonas@kwiboo.se>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Pet.Weng@ite.com.tw, Kenneth.Hung@ite.com.tw, 
 Hermes Wu <Hermes.Wu@ite.com.tw>, dri-devel@lists.freedesktop.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773049323; l=1930;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=NAw3pmerl2daFVsMxe2ILxwHNaOUCVrEQyupey4IYUg=;
 b=kI8MUPIXZ4Q397NAM5GYlaF3UrnVBNdIBcj4UetpIuMZ6S/t+HtzrKm6FKEXJFxUhfYYFpBW8
 +lZ6z1FGfGDC51yvx6OkxBRnRge+QKfBlbPtY0JLN3lAFaF8SwW8kUD
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
Changes in v2:
- dt-bindings:
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

 .../bindings/display/bridge/ite,it6162.yaml        |  216 +++
 MAINTAINERS                                        |    7 +
 drivers/gpu/drm/bridge/Kconfig                     |   17 +
 drivers/gpu/drm/bridge/Makefile                    |    1 +
 drivers/gpu/drm/bridge/ite-it6162.c                | 1847 ++++++++++++++++++++
 5 files changed, 2088 insertions(+)
---
base-commit: 2622649ad6cdbb3e77bfafc8c0fe686090b77f70
change-id: 20260223-upstream-6162-3751e78dfcad

Best regards,
-- 
Hermes Wu <Hermes.wu@ite.com.tw>

