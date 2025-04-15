From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Subject: [PATCH 0/4] media: i2c: imx214: Add support for more clock
 frequencies
Date: Tue, 15 Apr 2025 23:22:14 +0200
Message-Id: <20250415-imx214_ccs_pll-v1-0-d3d7748e5fbd@apitzsch.eu>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAbO/mcC/x3MSwqAIBRG4a3EHSeoWVBbiQjRv7pgDxRCiPaeN
 PwG5zyUEBmJhuqhiJsTn0eBqitymz1WCPbFpKVupZGd4D1rZWbn0nyFIGAsvESPttFUoiti4fw
 Px+l9Pw8JVeRgAAAA
X-Change-ID: 20250406-imx214_ccs_pll-e4aed0e9e532
To: Ricardo Ribalda <ribalda@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744752164; l=1042;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=7zVUtljGidorOLsS4uAD2nmE4ANyfK0eCdDp8g5uebQ=;
 b=jSZ1gTTw4HzCRtRKEtmcDRQuWRaTCEle2bfWQZPN7igj2mH2SxaRIwrdEIS+LddecuwT57f59
 rIruLG1rcd0Br+V8X8DIPOIdO+HgJItymEf8qZd5PFaH7PX0vIv6mA3
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
André Apitzsch (4):
      media: i2c: imx214: Reorder imx214_parse_fwnode call
      media: i2c: imx214: Prepare for variable clock frequency
      media: i2c: imx214: Make use of CCS PLL calculator
      media: i2c: imx214: Read clock frequency from device tree

 drivers/media/i2c/Kconfig  |   1 +
 drivers/media/i2c/imx214.c | 262 +++++++++++++++++++++++++++++++++++----------
 2 files changed, 205 insertions(+), 58 deletions(-)
---
base-commit: 5b37f7bfff3b1582c34be8fb23968b226db71ebd
change-id: 20250406-imx214_ccs_pll-e4aed0e9e532

Best regards,
-- 
André Apitzsch <git@apitzsch.eu>

