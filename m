From: Aaron Kling <webgeek1234@gmail.com>
Date: Tue, 10 Mar 2026 23:43:05 -0500
Subject: [PATCH 2/2] ASoC: codecs: aw88166: Support device specific
 firmware
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260310-aw88166-fw-v1-2-2777563bb673@gmail.com>
References: <20260310-aw88166-fw-v1-0-2777563bb673@gmail.com>
In-Reply-To: <20260310-aw88166-fw-v1-0-2777563bb673@gmail.com>
To: Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Weidong Wang <wangweidong.a@awinic.com>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>, 
 Teguh Sobirin <teguh@sobir.in>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773204187; l=2476;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=IUiKI3G7Quxrzr7+sMW/p+gunEW5XcQpZpT+LkFebXw=;
 b=Z3cLzOXp21cqtHEcGNTpuYnI7j7kXoHBjGXO1JnYqHrt3Rms60lwb6XDeHbVMK0a7+IwB4nKx
 X4Ba5qqv7bQCkbeMkv8rRz9+7yFCQdRV2oZ1ukvfAf1P9YZyE5mHbcH
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Teguh Sobirin <teguh@sobir.in>

This driver currently loads firmware from a hardcoded path. Support
loading device specific firmware when provided by the boot firmware.

Signed-off-by: Teguh Sobirin <teguh@sobir.in>
Co-authored-by: Aaron Kling <webgeek1234@gmail.com>
---
 sound/soc/codecs/aw88166.c | 19 +++++++++++++++----
 1 file changed, 15 insertions(+), 4 deletions(-)

diff --git a/sound/soc/codecs/aw88166.c b/sound/soc/codecs/aw88166.c
index daee4de9e3b01fb335975a65456cc79575533d7e..52d33a2f7cb12877138ea5083ad42e2777f8d323 100644
--- a/sound/soc/codecs/aw88166.c
+++ b/sound/soc/codecs/aw88166.c
@@ -1574,18 +1574,22 @@ static int aw88166_dev_init(struct aw88166 *aw88166, struct aw_container *aw_cfg
 static int aw88166_request_firmware_file(struct aw88166 *aw88166)
 {
 	const struct firmware *cont = NULL;
+	const char *fw_name;
 	int ret;
 
 	aw88166->aw_pa->fw_status = AW88166_DEV_FW_FAILED;
 
-	ret = request_firmware(&cont, AW88166_ACF_FILE, aw88166->aw_pa->dev);
+	if (device_property_read_string(aw88166->aw_pa->dev, "firmware-name", &fw_name) < 0)
+		fw_name = AW88166_ACF_FILE;
+
+	ret = request_firmware(&cont, fw_name, aw88166->aw_pa->dev);
 	if (ret) {
-		dev_err(aw88166->aw_pa->dev, "request [%s] failed!\n", AW88166_ACF_FILE);
+		dev_err(aw88166->aw_pa->dev, "request [%s] failed!\n", fw_name);
 		return ret;
 	}
 
 	dev_dbg(aw88166->aw_pa->dev, "loaded %s - size: %zu\n",
-			AW88166_ACF_FILE, cont ? cont->size : 0);
+			fw_name, cont ? cont->size : 0);
 
 	aw88166->aw_cfg = devm_kzalloc(aw88166->aw_pa->dev,
 			struct_size(aw88166->aw_cfg, data, cont->size), GFP_KERNEL);
@@ -1599,7 +1603,7 @@ static int aw88166_request_firmware_file(struct aw88166 *aw88166)
 
 	ret = aw88395_dev_load_acf_check(aw88166->aw_pa, aw88166->aw_cfg);
 	if (ret) {
-		dev_err(aw88166->aw_pa->dev, "load [%s] failed!\n", AW88166_ACF_FILE);
+		dev_err(aw88166->aw_pa->dev, "load [%s] failed!\n", fw_name);
 		return ret;
 	}
 
@@ -1802,9 +1806,16 @@ static const struct i2c_device_id aw88166_i2c_id[] = {
 };
 MODULE_DEVICE_TABLE(i2c, aw88166_i2c_id);
 
+static const struct of_device_id aw88166_of_match[] = {
+	{ .compatible = "awinic,aw88166" },
+	{ /* sentinel */ }
+};
+MODULE_DEVICE_TABLE(of, aw88166_of_match);
+
 static struct i2c_driver aw88166_i2c_driver = {
 	.driver = {
 		.name = AW88166_I2C_NAME,
+		.of_match_table = aw88166_of_match,
 	},
 	.probe = aw88166_i2c_probe,
 	.id_table = aw88166_i2c_id,

-- 
2.53.0

