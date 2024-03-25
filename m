From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Mon, 25 Mar 2024 19:05:09 +0100
Subject: [PATCH] regulator: tps65132: Add of_match table
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240325-of_tps65132-v1-1-86a5f7ef4ede@apitzsch.eu>
X-B4-Tracking: v=1; b=H4sIANS8AWYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDYyMT3fy0+JKCYjNTQ2MjXTMLY0vzRNNEy2RzIyWgjoKi1LTMCrBp0bG
 1tQA1zrrTXQAAAA==
To: Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>
Cc: linux-kernel@vger.kernel.org, ~postmarketos/upstreaming@lists.sr.ht, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711389916; l=1264;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=Y23B5v2pnT5ytkfuGZwM57ZFxcbAa4hFV6lYc2Evsoo=;
 b=FGBKARqa/RCXMwGNRqo61P/XH/+1MAcptJw6JzImB7Xdoaz8tiLaQzKI+eVlCfbcvuFjjVfMw
 KT5ItZH7RTzA2KhytGWXHlJlJymGVDFGdGsy2ONsHVXVr6ZOXcnhIrW
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add of_match table for "ti,tps65132" compatible string.
This fixes automatic driver loading when using device-tree,
and if built as a module like major linux distributions do.

Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
 drivers/regulator/tps65132-regulator.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/drivers/regulator/tps65132-regulator.c b/drivers/regulator/tps65132-regulator.c
index a06f5f2d7932..9c2f0dd42613 100644
--- a/drivers/regulator/tps65132-regulator.c
+++ b/drivers/regulator/tps65132-regulator.c
@@ -267,10 +267,17 @@ static const struct i2c_device_id tps65132_id[] = {
 };
 MODULE_DEVICE_TABLE(i2c, tps65132_id);
 
+static const struct of_device_id __maybe_unused tps65132_of_match[] = {
+	{ .compatible = "ti,tps65132" },
+	{},
+};
+MODULE_DEVICE_TABLE(of, tps65132_of_match);
+
 static struct i2c_driver tps65132_i2c_driver = {
 	.driver = {
 		.name = "tps65132",
 		.probe_type = PROBE_PREFER_ASYNCHRONOUS,
+		.of_match_table = of_match_ptr(tps65132_of_match),
 	},
 	.probe = tps65132_probe,
 	.id_table = tps65132_id,

---
base-commit: 1fdad13606e104ff103ca19d2d660830cb36d43e
change-id: 20240324-of_tps65132-68397a5a9c72

Best regards,
-- 
André Apitzsch <git@apitzsch.eu>

