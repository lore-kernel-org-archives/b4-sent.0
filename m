From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Sun, 17 Aug 2025 19:09:25 +0200
Subject: [PATCH 6/7] media: i2c: dw9719: Add an of_match_table
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250817-dw9719-v1-6-426f46c69a5a@apitzsch.eu>
References: <20250817-dw9719-v1-0-426f46c69a5a@apitzsch.eu>
In-Reply-To: <20250817-dw9719-v1-0-426f46c69a5a@apitzsch.eu>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755450582; l=1283;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=AM7Z9vkbnJudtfa3G+0qxABOY9vGE5baE+qTSnLT+Z8=;
 b=Ev3iti+ynUBlBW3HpTug9XQTFEc2s+o/aUidJ5fnCuGNFFCKRRHDsHVUjfTFQrtcPHm+HXdJ8
 EzAPLWOxrY5DRZdNbOKnuXSQ+59OMHDVaHGqr2me0VjTTZHceNg3TdG
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Val Packett <val@packett.cool>

Allow the dw9719 driver to be attached via FDT.

Signed-off-by: Val Packett <val@packett.cool>
Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
 drivers/media/i2c/dw9719.c | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/drivers/media/i2c/dw9719.c b/drivers/media/i2c/dw9719.c
index 2952d8064899e4ac29f3b1af02692fe8043ccfac..63c7fd4ab70a0e02518252b23b89c45df4ba273d 100644
--- a/drivers/media/i2c/dw9719.c
+++ b/drivers/media/i2c/dw9719.c
@@ -419,6 +419,14 @@ static const struct i2c_device_id dw9719_id_table[] = {
 };
 MODULE_DEVICE_TABLE(i2c, dw9719_id_table);
 
+static const struct of_device_id dw9719_of_table[] = {
+	{ .compatible = "dongwoon,dw9718s", .data = (const void *)DW9718S },
+	{ .compatible = "dongwoon,dw9719", .data = (const void *)DW9719 },
+	{ .compatible = "dongwoon,dw9761", .data = (const void *)DW9761 },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, dw9719_of_table);
+
 static DEFINE_RUNTIME_DEV_PM_OPS(dw9719_pm_ops, dw9719_suspend, dw9719_resume,
 				 NULL);
 
@@ -426,6 +434,7 @@ static struct i2c_driver dw9719_i2c_driver = {
 	.driver = {
 		.name = "dw9719",
 		.pm = pm_sleep_ptr(&dw9719_pm_ops),
+		.of_match_table = dw9719_of_table,
 	},
 	.probe = dw9719_probe,
 	.remove = dw9719_remove,

-- 
2.50.1

