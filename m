From: Aaron Kling <webgeek1234@gmail.com>
Date: Wed, 11 Mar 2026 12:41:20 -0500
Subject: [PATCH v2] ASoC: codecs: aw88166: Support device specific firmware
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260311-aw88166-fw-v2-1-8ef30dae3657@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/23Myw6CMBCF4Vchs3ZML3GKrnwPw6LFFiYRMK0pG
 tJ3t7J2+Z/kfBskH9knuDQbRJ858TLXUIcG+tHOg0e+1wYlFAktBdq1bSURhhXPQrtAxgtSEur
 hGX3g947dutojp9cSP7ud5W/9y2SJApUx5kTaOTL6OkyWH8d+maArpXwB1Wh++qQAAAA=
X-Change-ID: 20260310-aw88166-fw-903bf67e0621
To: Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Weidong Wang <wangweidong.a@awinic.com>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Teguh Sobirin <teguh@sobir.in>, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773250889; l=2810;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=PSKCEBezeNkHEqW++qztKOJQazmNiZFBnmyGWtD8itQ=;
 b=ibbTDxi0MgSmlUbX182R8yJdaTgUWglLz7WRAAGGjITToHASWxtBnJxJDRrJTgFk3WhlO3JWV
 uIkEA2vrTEuAHSLZPcg4SHnTfEa48J/1kj8nrYq2EL6ZHeIaK73Wixn
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Teguh Sobirin <teguh@sobir.in>

This driver currently loads firmware from a hardcoded path. Support
loading device specific firmware when provided by the boot firmware.

Signed-off-by: Teguh Sobirin <teguh@sobir.in>
Co-developed-by: Aaron Kling <webgeek1234@gmail.com>
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
The driver currently loads a hardcoded firmware path. This adds support
for reading a device specific path from the kernel device tree.

The patch was originally part of a larger change [0] by Teguh Sobirin
and was cut down to only the device specific firmware part.

[0] https://github.com/AYNTechnologies/linux/commit/9dbdd074423d970a9dec9a60f8bb99f8cfafd6a1
---
Changes in v2:
- Rebase on current linux-next and drop the duplicated bindings patch
- Change Co-authored-by tag to Co-developed-by
- Drop unrelated of_match_table addition
- Link to v1: https://lore.kernel.org/r/20260310-aw88166-fw-v1-0-2777563bb673@gmail.com
---
 sound/soc/codecs/aw88166.c | 12 ++++++++----
 1 file changed, 8 insertions(+), 4 deletions(-)

diff --git a/sound/soc/codecs/aw88166.c b/sound/soc/codecs/aw88166.c
index daee4de9e3b01fb335975a65456cc79575533d7e..ea277a940c44dfbf033ed4a69051bf506252b1c8 100644
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
 

---
base-commit: f90aadf1c67c8b4969d1e5e6d4fd7227adb6e4d7
change-id: 20260310-aw88166-fw-903bf67e0621

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

