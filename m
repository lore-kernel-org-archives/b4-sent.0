From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Subject: [PATCH v3 0/5] media: i2c: imx214: Add support for more clock
 frequencies
Date: Wed, 21 May 2025 21:34:23 +0200
Message-Id: <20250521-imx214_ccs_pll-v3-0-bfb4a2b53d14@apitzsch.eu>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAL8qLmgC/2XM0QqCMBTG8VeRXbfY5qbVVe8RIbad5QHTsdmwx
 HdvShAV5+p/4PtNJIBHCOSQTcRDxIB9lyLfZEQ3dXcFiiY1EUwoJllB8TYKLiutQ+XaloKswTD
 Yg8oFSSPnweK4gqdz6gbD0PvH6ke+fN8UV79U5JRRk5uylDtQ9mKOtcPhGXSzhTtZsCg+QLo/Q
 CTAJlsJVnBr+Tcwz/MLkEYpUO8AAAA=
X-Change-ID: 20250406-imx214_ccs_pll-e4aed0e9e532
To: Ricardo Ribalda <ribalda@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Shawn Guo <shawnguo@kernel.org>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 devicetree@vger.kernel.org, imx@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>, 
 Ricardo Ribalda <ribalda@chromium.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747856148; l=1895;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=YCdymVDth/prPqkIK7W4QDnBSw+ChQ0vJvm38czsFpg=;
 b=syVQLuePuGfp3dACqYgN2W+Ayfo4zcFv5KgkcjstEAWtm0hlQX+CxxZbPIZe6GwMN6KyO86Ns
 /0lOZW8RTyTAklCrce5sVjlA8tuwqb/AzmNUrP5MyZOt5LtV/+4+vuG
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The imx214 driver currently supports only a 24 MHz external clock. But
there are devices, like Qualcomm-MSM8916-based phones, which cannot
provide this frequency. To make the sensor usable by those devices, add
support for additional clock frequencies.

This series supersedes
https://lore.kernel.org/linux-media/20250308-imx214_clk_freq-v1-0-467a4c083c35@apitzsch.eu/

Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
Changes in v3:
- Limit range of pll_ip_clk_freq_hz (Sakari)
- Drop unneeded 'ret'
- Use pll.pixel_rate_csi for bit rate calculation
- Add patch that deprecates the clock-frequency property
- Link to v2: https://lore.kernel.org/r/20250505-imx214_ccs_pll-v2-0-f50452061ff1@apitzsch.eu

Changes in v2:
- Add A-b tags
- Switch to v4l2_ctrl_s_ctrl_int64() to acquire the control handler mutex
- Add error handling for v4l2_ctrl_s_ctrl_int64() and
  imx214_pll_update()
- Replace "read clock frequency from dt" patch by "remove hard-coded
  external clock frequency" patch
- Link to v1:
  https://lore.kernel.org/r/20250415-imx214_ccs_pll-v1-0-d3d7748e5fbd@apitzsch.eu

---
André Apitzsch (5):
      media: i2c: imx214: Reorder imx214_parse_fwnode call
      media: i2c: imx214: Prepare for variable clock frequency
      media: i2c: imx214: Make use of CCS PLL calculator
      media: dt-bindings: sony,imx214: Deprecate property clock-frequency
      media: i2c: imx214: Remove hard-coded external clock frequency

 .../devicetree/bindings/media/i2c/sony,imx214.yaml |  29 ++-
 drivers/media/i2c/Kconfig                          |   1 +
 drivers/media/i2c/imx214.c                         | 263 ++++++++++++++++-----
 3 files changed, 217 insertions(+), 76 deletions(-)
---
base-commit: ae0384b772a260975af192746d900c328392e525
change-id: 20250406-imx214_ccs_pll-e4aed0e9e532

Best regards,
-- 
André Apitzsch <git@apitzsch.eu>

