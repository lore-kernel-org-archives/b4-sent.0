From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Sat, 08 Feb 2025 12:13:49 +0100
Subject: [PATCH v2] media: dw9719: Add of_match table
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250208-dw9761dts-v2-1-c038f8a2fb94@apitzsch.eu>
X-B4-Tracking: v=1; b=H4sIAGw8p2cC/43Oy27DIBCF4VexWJdoZrDBeJX3iLLAMI5ZOG6BX
 CTL7x6atvsuf+no09lE5hQ5i6HZROJ7zHG91qCPRvjZXS8sY6gtCKgDAi3DwxqNoWTpg/fgDbY
 jOlH3n4mn+Hxbp3PtKa2LLHNi9ye0iNARKN31B7JGGYlyDnxZOfAxcZhdOfh1+cUSf93qn/Iji
 oVzdu8/9d6/reGO39zoMsuaSyxD009ak/UA9blVgZRG0i16pcGw6bseLVvjRnHe9xd6asUMIQE
 AAA==
X-Change-ID: 20250206-dw9761dts-cdcc0c714b1a
To: Daniel Scally <djrscally@gmail.com>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1739013233; l=1668;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=b835oDqUUZS0v891A6AlggPykmhV5x5NmgzamCCTc1s=;
 b=4hhSpZKPITXRRN4vBFA46KSzOWefN37FlAADEfvQdm6PUU79Ry8HS4ryRkVrOS0GJDIQsHGJS
 3fWNMEHzD/qDwRtLdm0/SV1FW/mloJ8wuQd3KUY68+ottY4rHuay0XA
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add of_match table for "dongwoon,dw9719" and "dongwoon,dw9761"
compatible string. This fixes automatic driver loading when using a
device-tree, and if built as a module like major linux distributions do.

Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
This patch depends on https://lore.kernel.org/linux-media/20241105203658.29737-1-hdegoede@redhat.com/
---
 drivers/media/i2c/dw9719.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/drivers/media/i2c/dw9719.c b/drivers/media/i2c/dw9719.c
index 032fbcb981f20f4e93202415e62f67379897a048..6c76212d4c698462a9128d26ef95f0eccb243c7c 100644
--- a/drivers/media/i2c/dw9719.c
+++ b/drivers/media/i2c/dw9719.c
@@ -360,6 +360,13 @@ static const struct i2c_device_id dw9719_id_table[] = {
 };
 MODULE_DEVICE_TABLE(i2c, dw9719_id_table);
 
+static const struct of_device_id dw9719_of_table[] = {
+	{ .compatible = "dongwoon,dw9719" },
+	{ .compatible = "dongwoon,dw9761" },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, dw9719_of_table);
+
 static DEFINE_RUNTIME_DEV_PM_OPS(dw9719_pm_ops, dw9719_suspend, dw9719_resume,
 				 NULL);
 
@@ -367,6 +374,7 @@ static struct i2c_driver dw9719_i2c_driver = {
 	.driver = {
 		.name = "dw9719",
 		.pm = pm_sleep_ptr(&dw9719_pm_ops),
+		.of_match_table = of_match_ptr(dw9719_of_table),
 	},
 	.probe = dw9719_probe,
 	.remove = dw9719_remove,

---
base-commit: 8f6629c004b193d23612641c3607e785819e97ab
change-id: 20250206-dw9761dts-cdcc0c714b1a
prerequisite-message-id: 20241105203658.29737-1-hdegoede@redhat.com:v1
prerequisite-patch-id: b0a57666bd20b97291583c3052065dc314a37e79

Best regards,
-- 
André Apitzsch <git@apitzsch.eu>

