From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Subject: [PATCH v2 0/5] media: i2c: imx214: Add some style improvements
Date: Mon, 30 Jun 2025 21:05:20 +0200
Message-Id: <20250630-imx214_fixes-v2-0-cd1a76c412c0@apitzsch.eu>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAPDfYmgC/1WMyw6CMBBFf4XM2pp2ShFc+R+GGB5TmYVAOkhQw
 r9bSVy4PPfmnBWEApPAOVkh0MzCQx8BDwk0XdXfSXEbGVCj0xlaxY8FTXrzvJAog9Zj7ryrM4S
 ojIH2IxrXMnLHMg3htddn811/oeI/NBulVX6yVBdp1WbWXaqRp7c03ZGeUG7b9gESRQKlqgAAA
 A==
X-Change-ID: 20250623-imx214_fixes-123f285f5b62
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Ricardo Ribalda <ribalda@kernel.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Markus Elfring <Markus.Elfring@web.de>
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751310420; l=1246;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=CsLioO4S0UhSQ7xBbQqFYY0bp80O1MggCmDLd/9lJc8=;
 b=xY/S9YNCYbMxswSn24N7cArYaza0xKkgnfeEQCugtMHm+SSemOAnDrPx5aS1f6dP47z1nF3Ey
 5ZQuK//kTsYBh+u/a5dcuBvhu2e1OW646Gfd0S9bZSzY0hw47WGNoFJ
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
Changes in v2:
- Drop unnecessary sentence from commit message (patch 3/5)
- Fix typo in summary (patch 5/5)
- Use imperative mood for commit message (patch 5/5)
- Add R-b tags
- Link to v1: https://lore.kernel.org/r/20250629-imx214_fixes-v1-0-873eb94ad635@apitzsch.eu

---
André Apitzsch (5):
      media: i2c: imx214: Remove unneeded parentheses
      media: i2c: imx214: Drop dev argument from imx214_parse_fwnode()
      media: i2c: imx214: Use __free(fwnode_handle)
      media: i2c: imx214: Move imx214_pll_update to imx214_ctrls_init
      media: i2c: imx214: Separate legacy link frequency check from PLL calculation

 drivers/media/i2c/imx214.c | 245 ++++++++++++++++++++++-----------------------
 1 file changed, 121 insertions(+), 124 deletions(-)
---
base-commit: 5e2562c1e46d3623fbdef77693f374eade075840
change-id: 20250623-imx214_fixes-123f285f5b62

Best regards,
-- 
André Apitzsch <git@apitzsch.eu>

