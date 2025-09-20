From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Sat, 20 Sep 2025 14:03:42 +0200
Subject: [PATCH v2 3/8] media: i2c: dw9719: Remove unused i2c device id
 table
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250920-dw9719-v2-3-028cdaa156e5@apitzsch.eu>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758369833; l=1027;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=mUZrDSJoYo2aj0olxKZRSTyHXKgynAJkOjdM9pfxGf4=;
 b=Yz8roYjQv9VoTv5p5CUVXxBWr5bvH5xPSAv3GxDTUwWmlZWQFujcMtDTNcchUuaoVdmIEBxS8
 XutCP8Dh55dC0ZGY3fc4+ttaKn56oPuJ4Tvk1jhU9drzCQDLyeUPgww
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Nothing depends on the I²C device ID table, so remove it.

Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
 drivers/media/i2c/dw9719.c | 8 --------
 1 file changed, 8 deletions(-)

diff --git a/drivers/media/i2c/dw9719.c b/drivers/media/i2c/dw9719.c
index 5ed0042fce18acd9e6ce9f6cf6c6982e36fed275..8d83e6fb478124d83d65f80d33a50c0aff438a6d 100644
--- a/drivers/media/i2c/dw9719.c
+++ b/drivers/media/i2c/dw9719.c
@@ -360,13 +360,6 @@ static void dw9719_remove(struct i2c_client *client)
 	pm_runtime_set_suspended(&client->dev);
 }
 
-static const struct i2c_device_id dw9719_id_table[] = {
-	{ "dw9719" },
-	{ "dw9761" },
-	{ }
-};
-MODULE_DEVICE_TABLE(i2c, dw9719_id_table);
-
 static DEFINE_RUNTIME_DEV_PM_OPS(dw9719_pm_ops, dw9719_suspend, dw9719_resume,
 				 NULL);
 
@@ -377,7 +370,6 @@ static struct i2c_driver dw9719_i2c_driver = {
 	},
 	.probe = dw9719_probe,
 	.remove = dw9719_remove,
-	.id_table = dw9719_id_table,
 };
 module_i2c_driver(dw9719_i2c_driver);
 

-- 
2.51.0

