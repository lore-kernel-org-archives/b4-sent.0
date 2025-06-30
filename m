From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Mon, 30 Jun 2025 21:05:21 +0200
Subject: [PATCH v2 1/5] media: i2c: imx214: Remove unneeded parentheses
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250630-imx214_fixes-v2-1-cd1a76c412c0@apitzsch.eu>
References: <20250630-imx214_fixes-v2-0-cd1a76c412c0@apitzsch.eu>
In-Reply-To: <20250630-imx214_fixes-v2-0-cd1a76c412c0@apitzsch.eu>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Ricardo Ribalda <ribalda@kernel.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Markus Elfring <Markus.Elfring@web.de>
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751310420; l=950;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=e5+tRksV+Fgl0BxWMBz64V6Vf1Cb5OmGU/GImJC7m7A=;
 b=8tixpZey59d010cuk2qUfM6JIln2FMlXURuGTGQANKhAnO3Kx+0wtuCINSlZn1eCDTxJsMsa1
 FY2l+SxzSTxDcQlwMrxqCtdWjOyIemQ9rIFmFJom0R4PhbJa45ptRZ4
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The parentheses are not needed to calculate bit_rate_mbps.

Reviewed-by: Laurent Pinchart <laurent.pinchart@ideasonboard.com>
Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
 drivers/media/i2c/imx214.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/media/i2c/imx214.c b/drivers/media/i2c/imx214.c
index a0cef9e61b41be8ea76a6d6e4b8c9fc4060cfa0f..8e9b5c9c93b0888f3d6be857168711edaf050db3 100644
--- a/drivers/media/i2c/imx214.c
+++ b/drivers/media/i2c/imx214.c
@@ -1029,8 +1029,8 @@ static int imx214_start_streaming(struct imx214 *imx214)
 		return ret;
 	}
 
-	bit_rate_mbps = (imx214->pll.pixel_rate_csi / 1000000)
-			* imx214->pll.bits_per_pixel;
+	bit_rate_mbps = imx214->pll.pixel_rate_csi / 1000000
+		      * imx214->pll.bits_per_pixel;
 	ret = cci_write(imx214->regmap, IMX214_REG_REQ_LINK_BIT_RATE,
 			IMX214_LINK_BIT_RATE_MBPS(bit_rate_mbps), NULL);
 	if (ret) {

-- 
2.50.0

