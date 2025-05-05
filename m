From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Subject: [PATCH v2 0/4] media: i2c: imx214: Add support for more clock
 frequencies
Date: Mon, 05 May 2025 23:05:52 +0200
Message-Id: <20250505-imx214_ccs_pll-v2-0-f50452061ff1@apitzsch.eu>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIADEoGWgC/13MQQ6CMBCF4auQWVvTllbUlfcwhNR2kEkQmhYbl
 HB3K3Hl8n/J+xaIGAgjnIsFAiaKNA455K4A25nhjoxcbpBcaq74gdFjlkI11sbG9z1DZdBxPKE
 uJeSTD9jSvIHXOndHcRrDa/OT+K4/Suh/KgnGmStdVakj6vbmLsbT9I622+MT6nVdP2IoWlquA
 AAA
X-Change-ID: 20250406-imx214_ccs_pll-e4aed0e9e532
To: Ricardo Ribalda <ribalda@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>, 
 Ricardo Ribalda <ribalda@chromium.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746479179; l=1442;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=am5E7+Utqe8zi5JH7YG5Vf5BHDNKW2H7Tn3z0DNQRQU=;
 b=NvbuxybdvAAlUaRuGYo/IWVQESiEcW3K0U/sph25LQlmsSTSxh0MGK5u6cA+i4fcaHMmDTGp5
 2pAPo+eHXqnC10E+3d8D0hG3TP/wgT0FJVhiZKTGEeeOKNAYuQyt/Kg
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
André Apitzsch (4):
      media: i2c: imx214: Reorder imx214_parse_fwnode call
      media: i2c: imx214: Prepare for variable clock frequency
      media: i2c: imx214: Make use of CCS PLL calculator
      media: i2c: imx214: Remove hard-coded external clock frequency

 drivers/media/i2c/Kconfig  |   1 +
 drivers/media/i2c/imx214.c | 266 ++++++++++++++++++++++++++++++++++-----------
 2 files changed, 204 insertions(+), 63 deletions(-)
---
base-commit: 4d4cc73d2632e07451c98c77fdb04aead3f78b00
change-id: 20250406-imx214_ccs_pll-e4aed0e9e532

Best regards,
-- 
André Apitzsch <git@apitzsch.eu>

