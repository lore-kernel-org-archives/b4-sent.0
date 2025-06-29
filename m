From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Subject: [PATCH 0/5] media: i2c: imx214: Add some style improvements
Date: Sun, 29 Jun 2025 16:49:19 +0200
Message-Id: <20250629-imx214_fixes-v1-0-873eb94ad635@apitzsch.eu>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAG9SYWgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDMyNj3czcCiNDk/i0zIrUYl1DI+M0IwvTNNMkMyMloJaColSwBFBHdGx
 tLQBbj4ZMXgAAAA==
X-Change-ID: 20250623-imx214_fixes-123f285f5b62
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Ricardo Ribalda <ribalda@kernel.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751208572; l=963;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=Qrm0HjuGR3bHxMm7TLB4FwO8uMQKo+bfdVF5GxtW79o=;
 b=mdoLtV5SWyla4ObJye/fTmXTvFkEF1uQdtwjacG5Eii5Cr5bMPpjaraofCZA60PwaCvFLH6YI
 f1BC7ZEWRhKCU1qdoC89TWcw02vqt4mM6G7mKjwhWUzJIT+XSkiyyXt
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The following changes have be suggested by Laurent in [1]. But the
related series had already be applied. That's why they are addressed in
this series.

[1] https://lore.kernel.org/linux-media/20250621181751.GA9125@pendragon.ideasonboard.com/

Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
André Apitzsch (5):
      media: i2c: imx214: Remove unneeded parentheses
      media: i2c: imx214: Drop dev argument from imx214_parse_fwnode()
      media: i2c: imx214: Use __free(fwnode_handle)
      media: i2c: imx214: Move imx214_pll_update to imx214_ctrls_init
      media: i2c: imx214: Separat legacy link frequency check from PLL calculation

 drivers/media/i2c/imx214.c | 245 ++++++++++++++++++++++-----------------------
 1 file changed, 121 insertions(+), 124 deletions(-)
---
base-commit: 5e2562c1e46d3623fbdef77693f374eade075840
change-id: 20250623-imx214_fixes-123f285f5b62

Best regards,
-- 
André Apitzsch <git@apitzsch.eu>

