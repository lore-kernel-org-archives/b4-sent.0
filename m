From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Sun, 09 Feb 2025 22:51:58 +0100
Subject: [PATCH v3 2/2] media: i2c: dw9719: Add of_match table
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250209-dw9761dts-v3-2-14d3f00f0585@apitzsch.eu>
References: <20250209-dw9761dts-v3-0-14d3f00f0585@apitzsch.eu>
In-Reply-To: <20250209-dw9761dts-v3-0-14d3f00f0585@apitzsch.eu>
To: Daniel Scally <djrscally@gmail.com>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, devicetree@vger.kernel.org
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1739137936; l=1275;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=mGgvurDestv373N8gVyPxAuJTKfXOnE3tkcTk8bJG1E=;
 b=XzW00rKO2isZu4IP2pkHVJ3PcZy+noiay7NCF3yEykQ/JGT+96Fxt4+ep/3N5XW4x+9Ld5y4j
 MnH//KJxEvJD02Wk69bbm3tEn8zaqJJ2w4fRRLw4q9qkbewDCKSktzS
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add of_match table for "dongwoon,dw9719" and "dongwoon,dw9761"
compatible string. This fixes automatic driver loading when using a
device-tree, and if built as a module like major linux distributions do.

Signed-off-by: André Apitzsch <git@apitzsch.eu>
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

-- 
2.48.1

