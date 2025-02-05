From: Chuan Liu <chuan.liu@amlogic.com>
Date: Wed, 05 Feb 2025 15:58:43 +0800
Subject: [PATCH v2] soc: amlogic: clk-measure: Optimize the memory size of
 clk-measure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250205-optimize_memory_size_of_clk_measure-v2-1-4f546053495d@amlogic.com>
X-B4-Tracking: v=1; b=H4sIADIao2cC/5WNWw6CMBREt0LutzVteYlf7sMQ0tRbuJFS0iJRS
 fduYQf+zZlk5mwQ0BMGuGYbeFwpkJsSyFMGelBTj4weiUFyWXIhc+bmhSx9sbNonf90Yc/OdHp
 8pkqFl0dmGl1wvIiybgpIT7NHQ+/Dcm8TDxSWtD2kq9jb//5XwQTjlVKV4sKYvL4pO7qe9Fk7C
 22M8QfWd3ks2AAAAA==
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1738742326; l=7454;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=CmPH3b1j74K558ccUEKEAgqGmyZRPF8SYGNr1A0i6CM=;
 b=JJUxo3NfEYFOoJCIwiriJ83d+KNiGzq1jcQ7AAQRhodrDHrguh/T49K5lXqMIA6/MlHve3lFP
 s4xSfhbuf4ZBFeBNFKMh3Jf1wUXoMOCsh0Qa2hN9H1/mhH7nO53BjKH
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Drop "CLK_MSR_MAX" and replace it with adding a member "msr_count" in
the structure to specify the count of msr_id.

Mark the table of msr_id as const.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
The number of msr_ids for each chip is inconsistent. Defining a
fixed-size array for each chip to store msr_ids would waste memory.
---
Changes in v2:
- Discard the global variable and restore the "priv" member in the
"struct meson_msr_id".
- Mark msr_id_table as const.
- Link to v1: https://lore.kernel.org/r/20250123-optimize_memory_size_of_clk_measure-v1-1-06aa6a01ff37@amlogic.com
---
 drivers/soc/amlogic/meson-clk-measure.c | 86 ++++++++++++++++++++++++---------
 1 file changed, 62 insertions(+), 24 deletions(-)

diff --git a/drivers/soc/amlogic/meson-clk-measure.c b/drivers/soc/amlogic/meson-clk-measure.c
index a6453ffeb753..39638d6a593c 100644
--- a/drivers/soc/amlogic/meson-clk-measure.c
+++ b/drivers/soc/amlogic/meson-clk-measure.c
@@ -33,23 +33,26 @@ static DEFINE_MUTEX(measure_lock);
 #define DIV_STEP		32
 #define DIV_MAX			640
 
-#define CLK_MSR_MAX		128
-
 struct meson_msr_id {
 	struct meson_msr *priv;
 	unsigned int id;
 	const char *name;
 };
 
+struct meson_msr_data {
+	struct meson_msr_id *msr_table;
+	unsigned int msr_count;
+};
+
 struct meson_msr {
 	struct regmap *regmap;
-	struct meson_msr_id msr_table[CLK_MSR_MAX];
+	struct meson_msr_data data;
 };
 
 #define CLK_MSR_ID(__id, __name) \
 	[__id] = {.id = __id, .name = __name,}
 
-static struct meson_msr_id clk_msr_m8[CLK_MSR_MAX] = {
+static const struct meson_msr_id clk_msr_m8[] = {
 	CLK_MSR_ID(0, "ring_osc_out_ee0"),
 	CLK_MSR_ID(1, "ring_osc_out_ee1"),
 	CLK_MSR_ID(2, "ring_osc_out_ee2"),
@@ -98,7 +101,7 @@ static struct meson_msr_id clk_msr_m8[CLK_MSR_MAX] = {
 	CLK_MSR_ID(63, "mipi_csi_cfg"),
 };
 
-static struct meson_msr_id clk_msr_gx[CLK_MSR_MAX] = {
+static const struct meson_msr_id clk_msr_gx[] = {
 	CLK_MSR_ID(0, "ring_osc_out_ee_0"),
 	CLK_MSR_ID(1, "ring_osc_out_ee_1"),
 	CLK_MSR_ID(2, "ring_osc_out_ee_2"),
@@ -168,7 +171,7 @@ static struct meson_msr_id clk_msr_gx[CLK_MSR_MAX] = {
 	CLK_MSR_ID(82, "ge2d"),
 };
 
-static struct meson_msr_id clk_msr_axg[CLK_MSR_MAX] = {
+static const struct meson_msr_id clk_msr_axg[] = {
 	CLK_MSR_ID(0, "ring_osc_out_ee_0"),
 	CLK_MSR_ID(1, "ring_osc_out_ee_1"),
 	CLK_MSR_ID(2, "ring_osc_out_ee_2"),
@@ -242,7 +245,7 @@ static struct meson_msr_id clk_msr_axg[CLK_MSR_MAX] = {
 	CLK_MSR_ID(109, "audio_locker_in"),
 };
 
-static struct meson_msr_id clk_msr_g12a[CLK_MSR_MAX] = {
+static const struct meson_msr_id clk_msr_g12a[] = {
 	CLK_MSR_ID(0, "ring_osc_out_ee_0"),
 	CLK_MSR_ID(1, "ring_osc_out_ee_1"),
 	CLK_MSR_ID(2, "ring_osc_out_ee_2"),
@@ -358,7 +361,7 @@ static struct meson_msr_id clk_msr_g12a[CLK_MSR_MAX] = {
 	CLK_MSR_ID(122, "audio_pdm_dclk"),
 };
 
-static struct meson_msr_id clk_msr_sm1[CLK_MSR_MAX] = {
+static const struct meson_msr_id clk_msr_sm1[] = {
 	CLK_MSR_ID(0, "ring_osc_out_ee_0"),
 	CLK_MSR_ID(1, "ring_osc_out_ee_1"),
 	CLK_MSR_ID(2, "ring_osc_out_ee_2"),
@@ -489,7 +492,7 @@ static struct meson_msr_id clk_msr_sm1[CLK_MSR_MAX] = {
 };
 
 static int meson_measure_id(struct meson_msr_id *clk_msr_id,
-			       unsigned int duration)
+			    unsigned int duration)
 {
 	struct meson_msr *priv = clk_msr_id->priv;
 	unsigned int val;
@@ -573,13 +576,14 @@ DEFINE_SHOW_ATTRIBUTE(clk_msr);
 static int clk_msr_summary_show(struct seq_file *s, void *data)
 {
 	struct meson_msr_id *msr_table = s->private;
+	unsigned int msr_count = msr_table->priv->data.msr_count;
 	unsigned int precision = 0;
 	int val, i;
 
 	seq_puts(s, "  clock                     rate    precision\n");
 	seq_puts(s, "---------------------------------------------\n");
 
-	for (i = 0 ; i < CLK_MSR_MAX ; ++i) {
+	for (i = 0 ; i < msr_count ; ++i) {
 		if (!msr_table[i].name)
 			continue;
 
@@ -604,7 +608,7 @@ static const struct regmap_config meson_clk_msr_regmap_config = {
 
 static int meson_msr_probe(struct platform_device *pdev)
 {
-	const struct meson_msr_id *match_data;
+	const struct meson_msr_data *match_data;
 	struct meson_msr *priv;
 	struct dentry *root, *clks;
 	void __iomem *base;
@@ -621,7 +625,16 @@ static int meson_msr_probe(struct platform_device *pdev)
 		return -ENODEV;
 	}
 
-	memcpy(priv->msr_table, match_data, sizeof(priv->msr_table));
+	priv->data.msr_table = devm_kcalloc(&pdev->dev,
+					    match_data->msr_count,
+					    sizeof(struct meson_msr_id),
+					    GFP_KERNEL);
+	if (!priv->data.msr_table)
+		return -ENOMEM;
+
+	memcpy(priv->data.msr_table, match_data->msr_table,
+	       match_data->msr_count * sizeof(struct meson_msr_id));
+	priv->data.msr_count = match_data->msr_count;
 
 	base = devm_platform_ioremap_resource(pdev, 0);
 	if (IS_ERR(base))
@@ -636,45 +649,70 @@ static int meson_msr_probe(struct platform_device *pdev)
 	clks = debugfs_create_dir("clks", root);
 
 	debugfs_create_file("measure_summary", 0444, root,
-			    priv->msr_table, &clk_msr_summary_fops);
+			    priv->data.msr_table, &clk_msr_summary_fops);
 
-	for (i = 0 ; i < CLK_MSR_MAX ; ++i) {
-		if (!priv->msr_table[i].name)
+	for (i = 0 ; i < priv->data.msr_count ; ++i) {
+		if (!priv->data.msr_table[i].name)
 			continue;
 
-		priv->msr_table[i].priv = priv;
+		priv->data.msr_table[i].priv = priv;
 
-		debugfs_create_file(priv->msr_table[i].name, 0444, clks,
-				    &priv->msr_table[i], &clk_msr_fops);
+		debugfs_create_file(priv->data.msr_table[i].name, 0444, clks,
+				    &priv->data.msr_table[i], &clk_msr_fops);
 	}
 
 	return 0;
 }
 
+static const struct meson_msr_data clk_msr_gx_data = {
+	.msr_table = (void *)clk_msr_gx,
+	.msr_count = ARRAY_SIZE(clk_msr_gx),
+};
+
+static const struct meson_msr_data clk_msr_m8_data = {
+	.msr_table = (void *)clk_msr_m8,
+	.msr_count = ARRAY_SIZE(clk_msr_m8),
+};
+
+static const struct meson_msr_data clk_msr_axg_data = {
+	.msr_table = (void *)clk_msr_axg,
+	.msr_count = ARRAY_SIZE(clk_msr_axg),
+};
+
+static const struct meson_msr_data clk_msr_g12a_data = {
+	.msr_table = (void *)clk_msr_g12a,
+	.msr_count = ARRAY_SIZE(clk_msr_g12a),
+};
+
+static const struct meson_msr_data clk_msr_sm1_data = {
+	.msr_table = (void *)clk_msr_sm1,
+	.msr_count = ARRAY_SIZE(clk_msr_sm1),
+};
+
 static const struct of_device_id meson_msr_match_table[] = {
 	{
 		.compatible = "amlogic,meson-gx-clk-measure",
-		.data = (void *)clk_msr_gx,
+		.data = &clk_msr_gx_data,
 	},
 	{
 		.compatible = "amlogic,meson8-clk-measure",
-		.data = (void *)clk_msr_m8,
+		.data = &clk_msr_m8_data,
 	},
 	{
 		.compatible = "amlogic,meson8b-clk-measure",
-		.data = (void *)clk_msr_m8,
+		.data = &clk_msr_m8_data,
 	},
 	{
 		.compatible = "amlogic,meson-axg-clk-measure",
-		.data = (void *)clk_msr_axg,
+		.data = &clk_msr_axg_data,
 	},
 	{
 		.compatible = "amlogic,meson-g12a-clk-measure",
-		.data = (void *)clk_msr_g12a,
+		.data = &clk_msr_g12a_data,
 	},
 	{
 		.compatible = "amlogic,meson-sm1-clk-measure",
-		.data = (void *)clk_msr_sm1,
+		.data = &clk_msr_sm1_data,
 	},
 	{ /* sentinel */ }
 };

---
base-commit: 1e1fd26ed4ca05cc1f0e5857918da4dd54967f7d
change-id: 20250123-optimize_memory_size_of_clk_measure-f9c40e815794

Best regards,
-- 
Chuan Liu <chuan.liu@amlogic.com>

