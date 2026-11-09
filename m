From: Ricardo Rivera-Matos <rriveram@opensource.cirrus.com>
Date: Mon, 09 Nov 2026 11:57:04 -0600
Subject: [PATCH 2/4] ASoC: cs35l45: Adds support for ABPE feature
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-cs35l45-bpe-v1-2-9d7bc95a90a4@opensource.cirrus.com>
References: <20261109-cs35l45-bpe-v1-0-9d7bc95a90a4@opensource.cirrus.com>
In-Reply-To: <20261109-cs35l45-bpe-v1-0-9d7bc95a90a4@opensource.cirrus.com>
To: David Rhodes <david.rhodes@cirrus.com>, 
 Richard Fitzgerald <rf@opensource.cirrus.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jaroslav Kysela <perex@perex.cz>, 
 Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, patches@opensource.cirrus.com, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ricardo Rivera-Matos <rriveram@opensource.cirrus.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794247023; l=13624;
 i=rriveram@opensource.cirrus.com; s=20261106; h=from:subject:message-id;
 bh=jEfMrLs/ya5G5IdFkACQD+N8iJlEBZDW0HuyzxRPpPc=;
 b=U/ZbJpxvFlK0U86h1WMTWWAyBeQ97I7CO/Yr7w4VbGNGgRlL0hVpeo4kcCme/nVw8isLIYuZ6
 +OhWQAvkm+MDQOqqTVdJi53L/nvgK1DA6z++FO+9Hie6JcErUEVNQg8
X-Developer-Key: i=rriveram@opensource.cirrus.com; a=ed25519;
 pk=k/iAEAtSPXvaWRDFupudzm6His7B7iJP1uiZ578a7Y8=
X-Endpoint-Received: by B4 Relay for rriveram@opensource.cirrus.com/20261106 with auth_id=1437
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adds support for boot time configuration of the amplifier brownout
prevention engine (ABPE). This circuit monitors the battery voltage
and responds with a tunable limiter on the audio output signal.

This limiter has four response levels, three limiter response
profiles (logarithmic, linear voltage, and linear power), and
configurable attack, hold, and release characteristics.

Signed-off-by: Ricardo Rivera-Matos <rriveram@opensource.cirrus.com>
---
 sound/soc/codecs/cs35l45-tables.c |  48 ++++++++
 sound/soc/codecs/cs35l45.c        | 223 ++++++++++++++++++++++++++++++++++++++
 sound/soc/codecs/cs35l45.h        |  49 +++++++++
 3 files changed, 320 insertions(+)

diff --git a/sound/soc/codecs/cs35l45-tables.c b/sound/soc/codecs/cs35l45-tables.c
index 554c8121a74f..95c39788b71b 100644
--- a/sound/soc/codecs/cs35l45-tables.c
+++ b/sound/soc/codecs/cs35l45-tables.c
@@ -77,6 +77,12 @@ static const struct reg_default cs35l45_defaults[] = {
 	{ CS35L45_DSP1RX6_INPUT,		0x00000028 },
 	{ CS35L45_DSP1RX7_INPUT,		0x0000003A },
 	{ CS35L45_DSP1RX8_INPUT,		0x00000028 },
+	{ CS35L45_BPE_INST_THLD,		0x5A46321E },
+	{ CS35L45_BPE_INST_ATTN,		0x060C1218 },
+	{ CS35L45_BPE_INST_ATK_RATE,		0x06060606 },
+	{ CS35L45_BPE_INST_HOLD_TIME,		0x02020202 },
+	{ CS35L45_BPE_INST_RLS_RATE,		0x05050505 },
+	{ CS35L45_BPE_MISC_CONFIG,		0x0000005A },
 	{ CS35L45_LDPM_CONFIG,			0x00003636 },
 	{ CS35L45_AMP_PCM_CONTROL,		0x00100000 },
 	{ CS35L45_AMP_GAIN,			0x00002300 },
@@ -164,6 +170,12 @@ static bool cs35l45_readable_reg(struct device *dev, unsigned int reg)
 	case CS35L45_DSP1RX6_INPUT:
 	case CS35L45_DSP1RX7_INPUT:
 	case CS35L45_DSP1RX8_INPUT:
+	case CS35L45_BPE_INST_THLD:
+	case CS35L45_BPE_INST_ATTN:
+	case CS35L45_BPE_INST_ATK_RATE:
+	case CS35L45_BPE_INST_HOLD_TIME:
+	case CS35L45_BPE_INST_RLS_RATE:
+	case CS35L45_BPE_MISC_CONFIG:
 	case CS35L45_HVLV_CONFIG:
 	case CS35L45_LDPM_CONFIG:
 	case CS35L45_AMP_PCM_CONTROL:
@@ -392,3 +404,39 @@ int cs35l45_get_ldpm_delay(u32 delay_ms)
 	return -EINVAL;
 }
 EXPORT_SYMBOL_NS_GPL(cs35l45_get_ldpm_delay, "SND_SOC_CS35L45");
+
+static const u32 cs35l45_bpe_hold_times_us[] = {
+	0, 250, 500, 1000, 5000, 10000, 25000, 50000, 100000, 250000, 500000, 1000000, 2500000,
+	5000000, 10000000,
+};
+
+int cs35l45_bpe_pack_hold_times(u32 *hold_times, u32 *packed_code)
+{
+	int i, j;
+
+	for (i = 0; i < CS35L45_BPE_NUM_LEVELS; i++) {
+		for (j = 0; j < ARRAY_SIZE(cs35l45_bpe_hold_times_us); j++)
+			if (hold_times[i] == cs35l45_bpe_hold_times_us[j])
+				break;
+
+		if (j == ARRAY_SIZE(cs35l45_bpe_hold_times_us))
+			return -EINVAL;
+
+		*packed_code |= CS35L45_BPE_PACK_CODE(j, i);
+	}
+
+	return 0;
+}
+EXPORT_SYMBOL_NS_GPL(cs35l45_bpe_pack_hold_times, "SND_SOC_CS35L45");
+
+static const char * const cs35l45_bpe_attenuation_props[] = {
+	[BPE_MODE_LOGARITHMIC] = "cirrus,amplifier-bpe-attenuation-levels-db",
+	[BPE_MODE_LINEAR_VOLTAGE] = "cirrus,amplifier-bpe-attenuation-levels-microvolt",
+	[BPE_MODE_LINEAR_POWER] = "cirrus,amplifier-bpe-attenuation-levels-microwatt",
+};
+
+const char *cs35l45_bpe_get_attn_prop(const enum bpe_modes mode)
+{
+	return cs35l45_bpe_attenuation_props[mode];
+}
+EXPORT_SYMBOL_NS_GPL(cs35l45_bpe_get_attn_prop, "SND_SOC_CS35L45");
diff --git a/sound/soc/codecs/cs35l45.c b/sound/soc/codecs/cs35l45.c
index 064ee612f05e..72f4ab1b89be 100644
--- a/sound/soc/codecs/cs35l45.c
+++ b/sound/soc/codecs/cs35l45.c
@@ -1148,6 +1148,225 @@ static void cs35l45_apply_sync_property_config(struct cs35l45_private *cs35l45)
 				   CS35L45_SYNC_SW_TXID_MASK, val);
 }
 
+static int cs35l45_bpe_read_array(struct cs35l45_private *cs35l45, const char *property,
+				  u32 *values, size_t count)
+{
+	int num_values, ret;
+
+	if (!device_property_present(cs35l45->dev, property))
+		return dev_err_probe(cs35l45->dev, -EINVAL, "Missing %s\n", property);
+
+	num_values = device_property_count_u32(cs35l45->dev, property);
+	if (num_values < 0)
+		return dev_err_probe(cs35l45->dev, num_values, "Failed to count %s\n", property);
+
+	if (num_values != count)
+		return dev_err_probe(cs35l45->dev, -EINVAL, "%s must contain exactly %zu values\n",
+				     property, count);
+
+	ret = device_property_read_u32_array(cs35l45->dev, property, values, count);
+	if (ret)
+		return dev_err_probe(cs35l45->dev, ret, "Failed to read %s\n", property);
+
+	return 0;
+}
+
+static int cs35l45_bpe_set_rls_rate(struct cs35l45_private *cs35l45)
+{
+	u32 values[CS35L45_BPE_NUM_LEVELS];
+	u32 packed = 0;
+	int i, ret;
+
+	ret = cs35l45_bpe_read_array(cs35l45, "cirrus,amplifier-bpe-release-rates", values,
+				     ARRAY_SIZE(values));
+	if (ret)
+		return ret;
+
+	for (i = 0; i < CS35L45_BPE_NUM_LEVELS; i++) {
+		if (values[i] > CS35L45_BPE_INST_RLS_RATE_MAX) {
+			dev_err(cs35l45->dev, "invalid ABPE release rate at level %d\n",
+				NUM_BPE_MODE - i);
+			return -EINVAL;
+		}
+
+		packed |= CS35L45_BPE_PACK_CODE(values[i], i);
+	}
+
+	return regmap_write(cs35l45->regmap, CS35L45_BPE_INST_RLS_RATE, packed);
+}
+
+static int cs35l45_bpe_set_hold_times(struct cs35l45_private *cs35l45)
+{
+	u32 values[CS35L45_BPE_NUM_LEVELS];
+	u32 packed = 0;
+	int ret;
+
+	ret = cs35l45_bpe_read_array(cs35l45, "cirrus,amplifier-bpe-hold-times-us", values,
+				     ARRAY_SIZE(values));
+	if (ret)
+		return ret;
+
+	ret = cs35l45_bpe_pack_hold_times(values, &packed);
+	if (ret)
+		return ret;
+
+	return regmap_write(cs35l45->regmap, CS35L45_BPE_INST_HOLD_TIME, packed);
+}
+
+static int cs35l45_bpe_set_atk_rate(struct cs35l45_private *cs35l45)
+{
+	u32 values[CS35L45_BPE_NUM_LEVELS];
+	u32 packed = 0;
+	int i, ret;
+
+	ret = cs35l45_bpe_read_array(cs35l45, "cirrus,amplifier-bpe-attack-rates", values,
+				     ARRAY_SIZE(values));
+	if (ret)
+		return ret;
+
+	for (i = 0; i < CS35L45_BPE_NUM_LEVELS; i++) {
+		if (values[i] > CS35L45_BPE_INST_ATK_RATE_MAX) {
+			dev_err(cs35l45->dev, "invalid ABPE attack rate at level %d\n",
+				NUM_BPE_MODE - i);
+			return -EINVAL;
+		}
+
+		packed |= CS35L45_BPE_PACK_CODE(values[i], i);
+	}
+
+	return regmap_write(cs35l45->regmap, CS35L45_BPE_INST_ATK_RATE, packed);
+}
+
+static int cs35l45_bpe_set_attn(struct cs35l45_private *cs35l45, const enum bpe_modes mode)
+{
+	u32 values[CS35L45_BPE_NUM_LEVELS];
+	const char *prop_name;
+	u32 code, packed = 0;
+	int i, ret;
+
+	prop_name = cs35l45_bpe_get_attn_prop(mode);
+	ret = cs35l45_bpe_read_array(cs35l45, prop_name, values, ARRAY_SIZE(values));
+	if (ret)
+		return ret;
+
+	for (i = 0; i < CS35L45_BPE_NUM_LEVELS; i++) {
+		switch (mode) {
+		case BPE_MODE_LOGARITHMIC:
+			if (values[i] > CS35L45_BPE_INST_ATTN_LOG_MAX_DB)
+				return -EINVAL;
+			code = values[i] * 2;
+			break;
+		case BPE_MODE_LINEAR_VOLTAGE:
+			if (!in_range(values[i], CS35L45_BPE_INST_ATTN_VOLT_MIN_UV,
+				      CS35L45_BPE_INST_ATTN_VOLT_LEN_UV))
+				return -EINVAL;
+			code = (CS35L45_BPE_INST_ATTN_VOLT_MAX_UV - values[i]) /
+				CS35L45_BPE_INST_ATTN_STEP;
+			break;
+		case BPE_MODE_LINEAR_POWER:
+			if (!in_range(values[i], CS35L45_BPE_INST_ATTN_POWER_MIN_UW,
+				      CS35L45_BPE_INST_ATTN_POWER_LEN_UW))
+				return -EINVAL;
+			code = (CS35L45_BPE_INST_ATTN_POWER_MAX_UW - values[i]) /
+				CS35L45_BPE_INST_ATTN_STEP;
+			break;
+		default:
+			return -EINVAL;
+		}
+
+		packed |= CS35L45_BPE_PACK_CODE(code, i);
+	}
+
+	return regmap_write(cs35l45->regmap, CS35L45_BPE_INST_ATTN, packed);
+}
+
+static int cs35l45_bpe_set_thld(struct cs35l45_private *cs35l45)
+{
+	u32 values[CS35L45_BPE_NUM_LEVELS];
+	u32 code, packed = 0;
+	int i, ret;
+
+	ret = cs35l45_bpe_read_array(cs35l45, "cirrus,amplifier-bpe-thresholds-microvolt", values,
+				     ARRAY_SIZE(values));
+	if (ret)
+		return ret;
+
+	for (i = 0; i < CS35L45_BPE_NUM_LEVELS; i++) {
+		if (!in_range(values[i], CS35L45_BPE_INST_THLD_MIN_UV,
+			     CS35L45_BPE_INST_THLD_LEN_UV)) {
+			dev_err(cs35l45->dev, "invalid ABPE threshold at level %d\n",
+				NUM_BPE_MODE - i);
+			return -EINVAL;
+		}
+
+		code = (values[i] - CS35L45_BPE_INST_THLD_MIN_UV) / CS35L45_BPE_INST_THLD_STEP_UV;
+		packed |= CS35L45_BPE_PACK_CODE(code, i);
+	}
+
+	return regmap_write(cs35l45->regmap, CS35L45_BPE_INST_THLD, packed);
+}
+
+static int cs35l45_bpe_set_mode(struct cs35l45_private *cs35l45, enum bpe_modes *mode)
+{
+	const char *prop;
+	int i, ret;
+
+	ret = device_property_read_u32(cs35l45->dev, "cirrus,amplifier-bpe-response-mode",
+				       (u32 *)mode);
+	if (ret || *mode >= NUM_BPE_MODE) {
+		dev_err(cs35l45->dev, "invalid ABPE response mode\n");
+		return -EINVAL;
+	}
+
+	for (i = 0; i < NUM_BPE_MODE; i++) {
+		prop = cs35l45_bpe_get_attn_prop(i);
+
+		if (i != *mode && device_property_present(cs35l45->dev, prop)) {
+			dev_err(cs35l45->dev, "ABPE attenuation property does not match mode\n");
+			return -EINVAL;
+		}
+	}
+
+	return regmap_update_bits(cs35l45->regmap, CS35L45_BPE_MISC_CONFIG,
+				  CS35L45_BPE_MODE_SEL_MASK,
+				  FIELD_PREP(CS35L45_BPE_MODE_SEL_MASK, *mode));
+}
+
+static int cs35l45_apply_abpe_config(struct cs35l45_private *cs35l45)
+{
+	enum bpe_modes mode;
+	int ret;
+
+	if (!device_property_read_bool(cs35l45->dev, "cirrus,amplifier-bpe-enable"))
+		return 0;
+
+	ret = cs35l45_bpe_set_mode(cs35l45, &mode);
+	if (ret)
+		return ret;
+
+	ret = cs35l45_bpe_set_thld(cs35l45);
+	if (ret)
+		return ret;
+
+	ret = cs35l45_bpe_set_attn(cs35l45, mode);
+	if (ret)
+		return ret;
+
+	ret = cs35l45_bpe_set_atk_rate(cs35l45);
+	if (ret)
+		return ret;
+
+	ret = cs35l45_bpe_set_hold_times(cs35l45);
+	if (ret)
+		return ret;
+
+	ret = cs35l45_bpe_set_rls_rate(cs35l45);
+	if (ret)
+		return ret;
+
+	return regmap_set_bits(cs35l45->regmap, CS35L45_BLOCK_ENABLES2, CS35L45_ABPE_EN_MASK);
+}
+
 static int cs35l45_apply_ldpm_config(struct cs35l45_private *cs35l45)
 {
 	char prop_name[CS35L45_LDPM_PROP_NAME_MAX];
@@ -1303,6 +1522,10 @@ static int cs35l45_apply_property_config(struct cs35l45_private *cs35l45)
 	if (ret < 0)
 		return ret;
 
+	ret = cs35l45_apply_abpe_config(cs35l45);
+	if (ret < 0)
+		return ret;
+
 	return 0;
 }
 
diff --git a/sound/soc/codecs/cs35l45.h b/sound/soc/codecs/cs35l45.h
index 5014c765adcb..573595924365 100644
--- a/sound/soc/codecs/cs35l45.h
+++ b/sound/soc/codecs/cs35l45.h
@@ -64,6 +64,12 @@
 #define CS35L45_DSP1RX6_INPUT			0x00004C54
 #define CS35L45_DSP1RX7_INPUT			0x00004C58
 #define CS35L45_DSP1RX8_INPUT			0x00004C5C
+#define CS35L45_BPE_INST_THLD			0x00006064
+#define CS35L45_BPE_INST_ATTN			0x00006068
+#define CS35L45_BPE_INST_ATK_RATE		0x00006074
+#define CS35L45_BPE_INST_HOLD_TIME		0x00006080
+#define CS35L45_BPE_INST_RLS_RATE		0x00006084
+#define CS35L45_BPE_MISC_CONFIG		0x00006090
 #define CS35L45_HVLV_CONFIG			0x00006400
 #define CS35L45_LDPM_CONFIG			0x00006404
 #define CS35L45_AMP_PCM_CONTROL			0x00007000
@@ -188,11 +194,41 @@
 #define CS35L45_ASP_EN_SHIFT			27
 #define CS35L45_AMP_DRE_EN_SHIFT		20
 #define CS35L45_AMP_DRE_EN_MASK		BIT(20)
+#define CS35L45_ABPE_EN_MASK			BIT(12)
 #define CS35L45_SYNC_EN_SHIFT			8
 #define CS35L45_SYNC_EN_MASK			BIT(8)
 #define CS35L45_MEM_RDY_SHIFT			1
 #define CS35L45_MEM_RDY_MASK			BIT(1)
 
+/* BPE_INST_THLD */
+#define CS35L45_BPE_INST_THLD_MIN_UV		2300000
+#define CS35L45_BPE_INST_THLD_MAX_UV		4500000
+#define CS35L45_BPE_INST_THLD_LEN_UV		(CS35L45_BPE_INST_THLD_MAX_UV - \
+						 CS35L45_BPE_INST_THLD_MIN_UV + 1)
+#define CS35L45_BPE_INST_THLD_STEP_UV		10000
+
+/* BPE_INST_ATTN */
+#define CS35L45_BPE_INST_ATTN_LOG_MAX_DB	15
+#define CS35L45_BPE_INST_ATTN_LOG_SCALE	2
+#define CS35L45_BPE_INST_ATTN_VOLT_MIN_UV	187500
+#define CS35L45_BPE_INST_ATTN_VOLT_MAX_UV	1000000
+#define CS35L45_BPE_INST_ATTN_VOLT_LEN_UV	(CS35L45_BPE_INST_ATTN_VOLT_MAX_UV - \
+						 CS35L45_BPE_INST_ATTN_VOLT_MIN_UV + 1)
+#define CS35L45_BPE_INST_ATTN_POWER_MIN_UW	31250
+#define CS35L45_BPE_INST_ATTN_POWER_MAX_UW	1000000
+#define CS35L45_BPE_INST_ATTN_POWER_LEN_UW	(CS35L45_BPE_INST_ATTN_POWER_MAX_UW - \
+						 CS35L45_BPE_INST_ATTN_POWER_MIN_UW + 1)
+#define CS35L45_BPE_INST_ATTN_STEP		31250
+
+/* BPE_INST_ATK_RATE */
+#define CS35L45_BPE_INST_ATK_RATE_MAX		8
+
+/* BPE_INST_RLS_RATE */
+#define CS35L45_BPE_INST_RLS_RATE_MAX		14
+
+/* BPE_MISC_CONFIG */
+#define CS35L45_BPE_MODE_SEL_MASK		GENMASK(5, 4)
+
 /* ERROR_RELEASE */
 #define CS35L45_GLOBAL_ERR_RLS_MASK		BIT(11)
 
@@ -474,6 +510,13 @@ enum ldpm_groups {
 	NUM_LDPM_GROUP,
 };
 
+enum bpe_modes {
+	BPE_MODE_LOGARITHMIC,
+	BPE_MODE_LINEAR_VOLTAGE,
+	BPE_MODE_LINEAR_POWER,
+	NUM_BPE_MODE,
+};
+
 #define CS35L45_FORMATS (SNDRV_PCM_FMTBIT_S16_LE | \
 			 SNDRV_PCM_FMTBIT_S24_3LE| \
 			 SNDRV_PCM_FMTBIT_S24_LE)
@@ -485,6 +528,10 @@ enum ldpm_groups {
 
 #define CS35L45_LDPM_PROP_NAME_MAX	37
 
+#define CS35L45_BPE_NUM_LEVELS		4
+
+#define CS35L45_BPE_PACK_CODE(_code, _idx) (_code << (24 - (8 * _idx)))
+
 /*
  * IRQs
  */
@@ -561,6 +608,8 @@ int cs35l45_apply_patch(struct cs35l45_private *cs35l45);
 int cs35l45_get_clk_freq_id(unsigned int freq);
 int cs35l45_get_ldpm_pcm_thld(int pcm_thld_db);
 int cs35l45_get_ldpm_delay(u32 delay_ms);
+int cs35l45_bpe_pack_hold_times(u32 *hold_times, u32 *packed_code);
+const char *cs35l45_bpe_get_attn_prop(const enum bpe_modes mode);
 int cs35l45_probe(struct cs35l45_private *cs35l45);
 void cs35l45_remove(struct cs35l45_private *cs35l45);
 

-- 
2.43.0

