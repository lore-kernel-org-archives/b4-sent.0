From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Sat, 20 Sep 2025 14:03:44 +0200
Subject: [PATCH v2 5/8] media: i2c: dw9719: Add driver_data matching
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250920-dw9719-v2-5-028cdaa156e5@apitzsch.eu>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758369833; l=1295;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=F4erGTuK3ncXkg+7Bo7QvNLiSQlxWsoxB54j160jl6g=;
 b=G6hjfMlrgllyNAUfxPWtZX+8UmxlFVQ8fAUrduk0zlkU6VEGsKLRlUf63GVX2+sTPGguctB2N
 piXQUsHv5kdAwVAf24lPrVC+L+bWh8+7EYIRM3+MkxQcBqVOsq1rYJr
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Val Packett <val@packett.cool>

In preparation for adding models with different register sets, start
assigning the model based on the i2c match data.

Signed-off-by: Val Packett <val@packett.cool>
Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
 drivers/media/i2c/dw9719.c | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/drivers/media/i2c/dw9719.c b/drivers/media/i2c/dw9719.c
index d2af2c6fcd670288084e3be2e0fb21bc9bc1ae92..5dc4126909b779aa0ce95015808b625fb21b67bb 100644
--- a/drivers/media/i2c/dw9719.c
+++ b/drivers/media/i2c/dw9719.c
@@ -282,6 +282,8 @@ static int dw9719_probe(struct i2c_client *client)
 	if (!dw9719)
 		return -ENOMEM;
 
+	dw9719->model = (enum dw9719_model)(uintptr_t)i2c_get_match_data(client);
+
 	dw9719->regmap = devm_cci_regmap_init_i2c(client, 8);
 	if (IS_ERR(dw9719->regmap))
 		return PTR_ERR(dw9719->regmap);
@@ -361,8 +363,8 @@ static void dw9719_remove(struct i2c_client *client)
 }
 
 static const struct of_device_id dw9719_of_table[] = {
-	{ .compatible = "dongwoon,dw9719" },
-	{ .compatible = "dongwoon,dw9761" },
+	{ .compatible = "dongwoon,dw9719", .data = (const void *)DW9719 },
+	{ .compatible = "dongwoon,dw9761", .data = (const void *)DW9761 },
 	{ }
 };
 MODULE_DEVICE_TABLE(of, dw9719_of_table);

-- 
2.51.0

