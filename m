From: Richard Leitner <richard.leitner@linux.dev>
Date: Tue, 21 Jul 2026 15:25:29 +0200
Subject: [PATCH 2/2] media: ov9282: enable single-read I2C transactions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260721-cci-single-v1-2-8485171e1393@linux.dev>
References: <20260721-cci-single-v1-0-8485171e1393@linux.dev>
In-Reply-To: <20260721-cci-single-v1-0-8485171e1393@linux.dev>
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Dave Stevenson <dave.stevenson@raspberrypi.com>
Cc: Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Hans de Goede <hansg@kernel.org>, linux-media@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Richard Leitner <richard.leitner@linux.dev>
X-Mailer: b4 0.16-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784640354; l=1545;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=Au+IQ66lMemkOeUGsHPOhBih0jjxOIJGUEK2eyo1odI=;
 b=M3iizulti+IZgsJg2TCFn3/otsTH0GHXiSPPlzfCOP42UEsdbM+1MjoYXcSV1Nttx5HwFEfLS
 gIkTHd8s06RC65ZNmkfGDh/aW2gmWPquUZTMFN+B8D4iiE3keNl/ZUM
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some OV9282 camera modules, such as those from Vision Components, fail
multi-byte register reads with the default CCI I2C regmap access pattern
and only work when single-register read transactions are used. This
results in the driver being unable to probe due to a chip id mismatch.

As the driver has no reliable way to identify affected modules enable
use_single_read for OV9282 unconditionally when creating the CCI regmap.

Tested on an i.M8MP system with OV9282 modules from Vision Components.

Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
 drivers/media/i2c/ov9282.c | 7 ++++++-
 1 file changed, 6 insertions(+), 1 deletion(-)

diff --git a/drivers/media/i2c/ov9282.c b/drivers/media/i2c/ov9282.c
index 5b6f897a74fcd..8267a0a9c6f2d 100644
--- a/drivers/media/i2c/ov9282.c
+++ b/drivers/media/i2c/ov9282.c
@@ -1283,6 +1283,11 @@ static int ov9282_probe(struct i2c_client *client)
 	struct ov9282 *ov9282;
 	int ret;
 
+	const struct cci_regmap_config config = {
+		.reg_addr_bits = 16,
+		.use_single_read = true,
+	};
+
 	ov9282 = devm_kzalloc(&client->dev, sizeof(*ov9282), GFP_KERNEL);
 	if (!ov9282)
 		return -ENOMEM;
@@ -1301,7 +1306,7 @@ static int ov9282_probe(struct i2c_client *client)
 		return ret;
 	}
 
-	ov9282->regmap = devm_cci_regmap_init_i2c(client, 16);
+	ov9282->regmap = devm_cci_regmap_init_i2c_cfg(client, &config);
 	if (IS_ERR(ov9282->regmap))
 		return dev_err_probe(ov9282->dev, PTR_ERR(ov9282->regmap),
 				     "Failed to init CCI\n");

-- 
2.53.0

