From: Chuan Liu <chuan.liu@amlogic.com>
Date: Sun, 20 Sep 2026 18:25:06 +0800
Subject: [PATCH v2 04/12] soc: amlogic: clk-measure: Align compatible
 entries with DT bindings
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260920-more-socs-to-support-clk_measure-v2-4-224382a429e8@amlogic.com>
References: <20260920-more-socs-to-support-clk_measure-v2-0-224382a429e8@amlogic.com>
In-Reply-To: <20260920-more-socs-to-support-clk_measure-v2-0-224382a429e8@amlogic.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789899904; l=3018;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=N4Mx9eqZjQKXjqKlyxwgJVxp+RMgOs2WzYEHRChMU3s=;
 b=FBt+mP4nvxZ0zj8/a5vbJEOhDz5lKQllZx7AGXo7yCzqBj581hQtEUz7qg0JWGGnNbFSiX2fM
 Gm5afsxZ3uMBNGhpG6T8CfvAThO+lMlQ5ri7SycBoCxzkeEii2Ffm8z
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Reorder the meson_msr_match_table entries to match the order of the
compatible strings in the DT binding.

Move the newly added clk_msr_a1_data entry accordingly, while keeping
the existing SoC-specific data order unchanged.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 drivers/soc/amlogic/meson-clk-measure.c | 40 ++++++++++++++++-----------------
 1 file changed, 20 insertions(+), 20 deletions(-)

diff --git a/drivers/soc/amlogic/meson-clk-measure.c b/drivers/soc/amlogic/meson-clk-measure.c
index 0d4ba2555d17..d58c8d9629ea 100644
--- a/drivers/soc/amlogic/meson-clk-measure.c
+++ b/drivers/soc/amlogic/meson-clk-measure.c
@@ -1279,6 +1279,12 @@ static const struct msr_reg_offset msr_reg_offset_v2 = {
 	.duty_val = 0x18,
 };
 
+static const struct meson_msr_data clk_msr_a1_data = {
+	.msr_table = (void *)clk_msr_a1,
+	.msr_count = ARRAY_SIZE(clk_msr_a1),
+	.reg = &msr_reg_offset_v2,
+};
+
 static const struct meson_msr_data clk_msr_c3_data = {
 	.msr_table = (void *)clk_msr_c3,
 	.msr_count = ARRAY_SIZE(clk_msr_c3),
@@ -1291,12 +1297,6 @@ static const struct meson_msr_data clk_msr_s4_data = {
 	.reg = &msr_reg_offset_v2,
 };
 
-static const struct meson_msr_data clk_msr_a1_data = {
-	.msr_table = (void *)clk_msr_a1,
-	.msr_count = ARRAY_SIZE(clk_msr_a1),
-	.reg = &msr_reg_offset_v2,
-};
-
 static const struct meson_msr_data clk_msr_t7_data = {
 	.msr_table = (void *)clk_msr_t7,
 	.msr_count = ARRAY_SIZE(clk_msr_t7),
@@ -1305,16 +1305,12 @@ static const struct meson_msr_data clk_msr_t7_data = {
 
 static const struct of_device_id meson_msr_match_table[] = {
 	{
-		.compatible = "amlogic,meson-gx-clk-measure",
-		.data = &clk_msr_gx_data,
-	},
-	{
-		.compatible = "amlogic,meson8-clk-measure",
-		.data = &clk_msr_m8_data,
+		.compatible = "amlogic,a1-clk-measure",
+		.data = &clk_msr_a1_data,
 	},
 	{
-		.compatible = "amlogic,meson8b-clk-measure",
-		.data = &clk_msr_m8_data,
+		.compatible = "amlogic,c3-clk-measure",
+		.data = &clk_msr_c3_data,
 	},
 	{
 		.compatible = "amlogic,meson-axg-clk-measure",
@@ -1324,21 +1320,25 @@ static const struct of_device_id meson_msr_match_table[] = {
 		.compatible = "amlogic,meson-g12a-clk-measure",
 		.data = &clk_msr_g12a_data,
 	},
+	{
+		.compatible = "amlogic,meson-gx-clk-measure",
+		.data = &clk_msr_gx_data,
+	},
 	{
 		.compatible = "amlogic,meson-sm1-clk-measure",
 		.data = &clk_msr_sm1_data,
 	},
 	{
-		.compatible = "amlogic,c3-clk-measure",
-		.data = &clk_msr_c3_data,
+		.compatible = "amlogic,meson8-clk-measure",
+		.data = &clk_msr_m8_data,
 	},
 	{
-		.compatible = "amlogic,s4-clk-measure",
-		.data = &clk_msr_s4_data,
+		.compatible = "amlogic,meson8b-clk-measure",
+		.data = &clk_msr_m8_data,
 	},
 	{
-		.compatible = "amlogic,a1-clk-measure",
-		.data = &clk_msr_a1_data,
+		.compatible = "amlogic,s4-clk-measure",
+		.data = &clk_msr_s4_data,
 	},
 	{
 		.compatible = "amlogic,t7-clk-measure",

-- 
2.42.0

