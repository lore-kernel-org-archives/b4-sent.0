From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Sun, 17 Aug 2025 19:09:22 +0200
Subject: [PATCH 3/7] media: i2c: dw9719: Add driver_data matching
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250817-dw9719-v1-3-426f46c69a5a@apitzsch.eu>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755450582; l=1180;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=iVV78e2o0cl1oQIUHJFlr0HWutsEjrkxRyvh4oGLg+w=;
 b=Vq8uSC/Usq1sMo7iBL6uiHmbF35KllU4IuzziKWMtUwzUAJmbkJL5IUhqMXxsE8ygma6DNmjF
 6jQeRNoh3LpBPUUKQvviiwbAS7/mViR7NWE2VtMJUez0GEo16EZJw6o
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
index 5ed0042fce18acd9e6ce9f6cf6c6982e36fed275..7ce66eaede5a2a1ba9c4c30c0efc5fafcca339a0 100644
--- a/drivers/media/i2c/dw9719.c
+++ b/drivers/media/i2c/dw9719.c
@@ -282,6 +282,8 @@ static int dw9719_probe(struct i2c_client *client)
 	if (!dw9719)
 		return -ENOMEM;
 
+	dw9719->model = (enum dw9719_model)i2c_get_match_data(client);
+
 	dw9719->regmap = devm_cci_regmap_init_i2c(client, 8);
 	if (IS_ERR(dw9719->regmap))
 		return PTR_ERR(dw9719->regmap);
@@ -361,8 +363,8 @@ static void dw9719_remove(struct i2c_client *client)
 }
 
 static const struct i2c_device_id dw9719_id_table[] = {
-	{ "dw9719" },
-	{ "dw9761" },
+	{ "dw9719", .driver_data = DW9719 },
+	{ "dw9761", .driver_data = DW9761 },
 	{ }
 };
 MODULE_DEVICE_TABLE(i2c, dw9719_id_table);

-- 
2.50.1

