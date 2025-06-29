From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Sun, 29 Jun 2025 16:49:24 +0200
Subject: [PATCH 5/5] media: i2c: imx214: Separat legacy link frequency
 check from PLL calculation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250629-imx214_fixes-v1-5-873eb94ad635@apitzsch.eu>
References: <20250629-imx214_fixes-v1-0-873eb94ad635@apitzsch.eu>
In-Reply-To: <20250629-imx214_fixes-v1-0-873eb94ad635@apitzsch.eu>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Ricardo Ribalda <ribalda@kernel.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751208572; l=1164;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=fAmGDmfadAfG2+q/PfRs357Eh8ZGt/KKlqJTNCdh9uA=;
 b=uTy7Vr/Wz2r8Keavv7B3f00oF7RQ7FpLgLFTJhRmo6PbYIKYRQRaqolNWwFhwB02ms5fT36hg
 Ge/EdJ4CWRTDi5tqC0TuF3R/r9PdImnqhA41F9GWjPXNmrncMFfKk8y
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This makes it easier to drop this legacy support from the driver later.

Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
 drivers/media/i2c/imx214.c | 8 +++-----
 1 file changed, 3 insertions(+), 5 deletions(-)

diff --git a/drivers/media/i2c/imx214.c b/drivers/media/i2c/imx214.c
index 63cf30acdc241de2f9ab3db339590da4af3d5102..52433775e9baddd8ab988e866a83387d53c1fd5c 100644
--- a/drivers/media/i2c/imx214.c
+++ b/drivers/media/i2c/imx214.c
@@ -1362,18 +1362,16 @@ static int imx214_parse_fwnode(struct imx214 *imx214)
 		u64 freq = bus_cfg->link_frequencies[i];
 		struct ccs_pll pll;
 
-		if (!imx214_pll_calculate(imx214, &pll, freq))
-			break;
 		if (freq == IMX214_DEFAULT_LINK_FREQ_LEGACY) {
 			dev_warn(dev,
 				 "link-frequencies %d not supported, please review your DT. Continuing anyway\n",
 				 IMX214_DEFAULT_LINK_FREQ);
 			freq = IMX214_DEFAULT_LINK_FREQ;
-			if (imx214_pll_calculate(imx214, &pll, freq))
-				continue;
 			bus_cfg->link_frequencies[i] = freq;
-			break;
 		}
+
+		if (!imx214_pll_calculate(imx214, &pll, freq))
+			break;
 	}
 
 	if (i == bus_cfg->nr_of_link_frequencies)

-- 
2.50.0

