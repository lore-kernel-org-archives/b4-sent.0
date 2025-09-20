From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Sat, 20 Sep 2025 14:03:41 +0200
Subject: [PATCH v2 2/8] media: i2c: dw9719: Deprecate dongwoon,vcm-freq
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250920-dw9719-v2-2-028cdaa156e5@apitzsch.eu>
References: <20250920-dw9719-v2-0-028cdaa156e5@apitzsch.eu>
In-Reply-To: <20250920-dw9719-v2-0-028cdaa156e5@apitzsch.eu>
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, devicetree@vger.kernel.org, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Daniel Scally <djrscally@gmail.com>
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Val Packett <val@packett.cool>, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758369833; l=1393;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=IAzlkl9/y7ZEPjP9FcEzM1T6TtpgJTz8PkPbMDCgBe8=;
 b=gjEM7rLw/wEH6ScrAvo6wFfzvqisjK8oB1sN23asixFFyLUrJS4O72PxhPtWGP8TFoPyf2WEu
 vmdVKYSGDWEDQNwztzi3axDLOfYAshNjVibLIkTEGdg84QMv7ycfBwB
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The name of property "dongwoon,vcm-freq" doesn't match its purpose.
Change the name of the property to "dongwoon,vcm-prescale" to better
describe its purpose and deprecate the old one.

Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
 drivers/media/i2c/dw9719.c | 9 ++++++++-
 1 file changed, 8 insertions(+), 1 deletion(-)

diff --git a/drivers/media/i2c/dw9719.c b/drivers/media/i2c/dw9719.c
index 032fbcb981f20f4e93202415e62f67379897a048..5ed0042fce18acd9e6ce9f6cf6c6982e36fed275 100644
--- a/drivers/media/i2c/dw9719.c
+++ b/drivers/media/i2c/dw9719.c
@@ -82,6 +82,7 @@ static int dw9719_power_up(struct dw9719_device *dw9719, bool detect)
 {
 	u64 val;
 	int ret;
+	int err;
 
 	ret = regulator_enable(dw9719->regulator);
 	if (ret)
@@ -123,7 +124,13 @@ static int dw9719_power_up(struct dw9719_device *dw9719, bool detect)
 					 &dw9719->sac_mode);
 
 		/* Optional indication of VCM frequency */
-		device_property_read_u32(dw9719->dev, "dongwoon,vcm-freq",
+		err = device_property_read_u32(dw9719->dev, "dongwoon,vcm-freq",
+					       &dw9719->vcm_freq);
+		if (err == 0)
+			dev_warn(dw9719->dev, "dongwoon,vcm-freq property is deprecated, please use dongwoon,vcm-prescale\n");
+
+		/* Optional indication of VCM prescale */
+		device_property_read_u32(dw9719->dev, "dongwoon,vcm-prescale",
 					 &dw9719->vcm_freq);
 	}
 

-- 
2.51.0

