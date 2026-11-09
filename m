From: Ricardo Rivera-Matos <rriveram@opensource.cirrus.com>
Date: Mon, 09 Nov 2026 11:57:06 -0600
Subject: [PATCH 4/4] ASoC: cs35l45: Adds Boost BPE configuration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-cs35l45-bpe-v1-4-9d7bc95a90a4@opensource.cirrus.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794247023; l=23416;
 i=rriveram@opensource.cirrus.com; s=20261106; h=from:subject:message-id;
 bh=gps5vC3SzMqWQrPGoUjiUxvXcFZri3u0qytB+85Xp2w=;
 b=AeEKiWCZjcxupOquNg/8FQeqVosuWcE2mdQGbUxDM1HrZUzgqbeB2nARGX+lFKL0XAld3xu/l
 G60e62GjXDZAeAgO2jH8Ln3fLOz4Pj7czWQjHdQCPQufad/c27bMs7Y
X-Developer-Key: i=rriveram@opensource.cirrus.com; a=ed25519;
 pk=k/iAEAtSPXvaWRDFupudzm6His7B7iJP1uiZ578a7Y8=
X-Endpoint-Received: by B4 Relay for rriveram@opensource.cirrus.com/20261106 with auth_id=1437
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adds support for boot time configuration of the boost
brownout prevention engine (BBPE). The engine monitors the
battery voltage and the current through the boost inductor
and applies a limit to the output current of the boost
converter via its controller logic.

Signed-off-by: Ricardo Rivera-Matos <rriveram@opensource.cirrus.com>
---
 sound/soc/codecs/cs35l45-tables.c |  47 +++++
 sound/soc/codecs/cs35l45.c        | 378 ++++++++++++++++++++++++++++++++++++++
 sound/soc/codecs/cs35l45.h        | 144 +++++++++++++++
 3 files changed, 569 insertions(+)

diff --git a/sound/soc/codecs/cs35l45-tables.c b/sound/soc/codecs/cs35l45-tables.c
index 95c39788b71b..599415812bf5 100644
--- a/sound/soc/codecs/cs35l45-tables.c
+++ b/sound/soc/codecs/cs35l45-tables.c
@@ -54,6 +54,18 @@ static const struct reg_default cs35l45_defaults[] = {
 	{ CS35L45_SYNC_TX_RX_ENABLES,		0x00000200 },
 	{ CS35L45_SYNC_SW_TX_ID,		0x00000000 },
 	{ CS35L45_BOOST_LPMODE_CFG,		0x00000002 },
+	{ CS35L45_BST_BPE_INST_THLD,		0x5A46321E },
+	{ CS35L45_BST_BPE_INST_ILIM,		0x3C140C04 },
+	{ CS35L45_BST_BPE_INST_ATK_RATE,	0x06060600 },
+	{ CS35L45_BST_BPE_INST_HOLD_TIME,	0x02020202 },
+	{ CS35L45_BST_BPE_INST_RLS_RATE,	0x06060606 },
+	{ CS35L45_BST_BPE_MISC_CONFIG,		0x00008000 },
+	{ CS35L45_BST_BPE_IL_LIM_THLD,		0x0006022C },
+	{ CS35L45_BST_BPE_IL_LIM_DLY,		0x0000040C },
+	{ CS35L45_BST_BPE_IL_LIM_ATK_RATE,	0x00000000 },
+	{ CS35L45_BST_BPE_IL_LIM_RLS_RATE,	0x00000000 },
+	{ CS35L45_BST_BPE_OUT_ATK_RATE,		0x00000002 },
+	{ CS35L45_BST_BPE_OUT_RLS_RATE,		0x00000002 },
 	{ CS35L45_ASP_ENABLES1,			0x00000000 },
 	{ CS35L45_ASP_CONTROL1,			0x00000028 },
 	{ CS35L45_ASP_CONTROL2,			0x18180200 },
@@ -143,6 +155,18 @@ static bool cs35l45_readable_reg(struct device *dev, unsigned int reg)
 	case CS35L45_WKI2C_CTL:
 	case CS35L45_PWRMGT_STS:
 	case CS35L45_REFCLK_INPUT:
+	case CS35L45_BST_BPE_INST_THLD:
+	case CS35L45_BST_BPE_INST_ILIM:
+	case CS35L45_BST_BPE_INST_ATK_RATE:
+	case CS35L45_BST_BPE_INST_HOLD_TIME:
+	case CS35L45_BST_BPE_INST_RLS_RATE:
+	case CS35L45_BST_BPE_MISC_CONFIG:
+	case CS35L45_BST_BPE_IL_LIM_THLD:
+	case CS35L45_BST_BPE_IL_LIM_DLY:
+	case CS35L45_BST_BPE_IL_LIM_ATK_RATE:
+	case CS35L45_BST_BPE_IL_LIM_RLS_RATE:
+	case CS35L45_BST_BPE_OUT_ATK_RATE:
+	case CS35L45_BST_BPE_OUT_RLS_RATE:
 	case CS35L45_GLOBAL_SAMPLE_RATE:
 	case CS35L45_SYNC_TX_RX_ENABLES:
 	case CS35L45_SYNC_SW_TX_ID:
@@ -440,3 +464,26 @@ const char *cs35l45_bpe_get_attn_prop(const enum bpe_modes mode)
 	return cs35l45_bpe_attenuation_props[mode];
 }
 EXPORT_SYMBOL_NS_GPL(cs35l45_bpe_get_attn_prop, "SND_SOC_CS35L45");
+
+static const u32 cs35l45_bst_bpe_hold_times_us[] = {
+	0, 5, 10, 25, 50, 100, 250, 500, 1000, 2500, 5000, 10000,
+};
+
+int cs35l45_bst_bpe_pack_hold_times(const u32 *hold_times, u32 *packed_code)
+{
+	int i, j;
+
+	for (i = 0; i < CS35L45_BST_BPE_NUM_LEVELS; i++) {
+		for (j = 0; j < ARRAY_SIZE(cs35l45_bst_bpe_hold_times_us); j++)
+			if (hold_times[i] == cs35l45_bst_bpe_hold_times_us[j])
+				break;
+
+		if (j == ARRAY_SIZE(cs35l45_bst_bpe_hold_times_us))
+			return -EINVAL;
+
+		*packed_code |= CS35L45_BST_BPE_PACK_CODE(j, i);
+	}
+
+	return 0;
+}
+EXPORT_SYMBOL_NS_GPL(cs35l45_bst_bpe_pack_hold_times, "SND_SOC_CS35L45");
diff --git a/sound/soc/codecs/cs35l45.c b/sound/soc/codecs/cs35l45.c
index 72f4ab1b89be..c087f9db6ea7 100644
--- a/sound/soc/codecs/cs35l45.c
+++ b/sound/soc/codecs/cs35l45.c
@@ -1367,6 +1367,380 @@ static int cs35l45_apply_abpe_config(struct cs35l45_private *cs35l45)
 	return regmap_set_bits(cs35l45->regmap, CS35L45_BLOCK_ENABLES2, CS35L45_ABPE_EN_MASK);
 }
 
+static int cs35l45_bst_bpe_pack_array(struct cs35l45_private *cs35l45, const char *property,
+				      size_t count, unsigned int first_lane, u32 min, u32 max,
+				      u32 step, u32 *packed)
+{
+	u32 code, values[CS35L45_BST_BPE_NUM_LEVELS];
+	unsigned int i;
+	int ret;
+
+	if (!step || (first_lane + count) > ARRAY_SIZE(values))
+		return -EINVAL;
+
+	ret = cs35l45_bpe_read_array(cs35l45, property, values, count);
+	if (ret < 0)
+		return ret;
+
+	for (i = 0; i < count; i++) {
+		if (values[i] < min || values[i] > max)
+			return dev_err_probe(cs35l45->dev, -EINVAL,
+					     "Invalid %s value %u at index %u\n",
+					     property, values[i], i);
+
+		code = (values[i] - min) / step;
+
+		*packed |= CS35L45_BST_BPE_PACK_CODE(code, first_lane + i);
+	}
+
+	return 0;
+}
+
+static int cs35l45_bst_bpe_pack_scalar(struct cs35l45_private *cs35l45, const char *property,
+				       u32 field_mask, unsigned int shift, u32 min, u32 max,
+				       u32 step, u32 *packed)
+{
+	u32 value, code;
+	int ret;
+
+	if (!device_property_present(cs35l45->dev, property))
+		return -EINVAL;
+
+	ret = device_property_read_u32(cs35l45->dev, property, &value);
+	if (ret)
+		return dev_err_probe(cs35l45->dev, ret, "Failed to read %s\n", property);
+
+	if (!step || value < min || value > max)
+		return dev_err_probe(cs35l45->dev, -EINVAL, "Invalid %s value %u\n",
+				     property, value);
+
+	code = (value - min) / step;
+	if (code > field_mask >> shift)
+		return dev_err_probe(cs35l45->dev, -EINVAL,
+				     "%s value %u does not fit its field\n", property, value);
+
+	*packed |= code << shift;
+
+	return 0;
+}
+
+static int cs35l45_bst_bpe_set_inst_thld(struct cs35l45_private *cs35l45)
+{
+	u32 packed = 0;
+	int ret;
+
+	ret = cs35l45_bst_bpe_pack_array(cs35l45, "cirrus,boost-bpe-battery-thresholds-microvolt",
+					 CS35L45_BST_BPE_NUM_VOLTAGE_LEVELS, 0,
+					 CS35L45_BST_BPE_INST_THLD_MIN_UV,
+					 CS35L45_BST_BPE_INST_THLD_MAX_UV,
+					 CS35L45_BST_BPE_INST_THLD_STEP_UV, &packed);
+	if (ret)
+		return ret;
+
+	return regmap_write(cs35l45->regmap, CS35L45_BST_BPE_INST_THLD, packed);
+}
+
+static int cs35l45_bst_bpe_set_inst_ilim(struct cs35l45_private *cs35l45)
+{
+	u32 packed = 0;
+	int ret;
+
+	ret = cs35l45_bst_bpe_pack_array(cs35l45, "cirrus,boost-bpe-battery-limits-microamp",
+					 CS35L45_BST_BPE_NUM_VOLTAGE_LEVELS, 0,
+					 CS35L45_BST_BPE_INST_ILIM_MIN_UA,
+					 CS35L45_BST_BPE_INST_ILIM_MAX_UA,
+					 CS35L45_BST_BPE_INST_ILIM_STEP_UA, &packed);
+	if (ret)
+		return ret;
+
+	return regmap_write(cs35l45->regmap, CS35L45_BST_BPE_INST_ILIM, packed);
+}
+
+static int cs35l45_bst_bpe_set_inst_atk_rate(struct cs35l45_private *cs35l45)
+{
+	u32 packed = 0;
+	int ret;
+
+	ret = cs35l45_bst_bpe_pack_array(cs35l45, "cirrus,boost-bpe-battery-attack-rates",
+					 CS35L45_BST_BPE_NUM_VOLTAGE_ATTACK_LEVELS, 1, 0,
+					 CS35L45_BST_BPE_ATTACK_RATE_3P90625MA_PER_US, 1, &packed);
+	if (ret)
+		return ret;
+
+	return regmap_write(cs35l45->regmap, CS35L45_BST_BPE_INST_ATK_RATE, packed);
+}
+
+static int cs35l45_bst_bpe_set_inst_hold_time(struct cs35l45_private *cs35l45)
+{
+	u32 values[CS35L45_BST_BPE_NUM_VOLTAGE_LEVELS];
+	u32 packed = 0;
+	int ret;
+
+	ret = cs35l45_bpe_read_array(cs35l45, "cirrus,boost-bpe-battery-hold-times-us", values,
+				     ARRAY_SIZE(values));
+	if (ret < 0)
+		return ret;
+
+	ret = cs35l45_bst_bpe_pack_hold_times(values, &packed);
+	if (ret)
+		return dev_err_probe(cs35l45->dev, ret, "Invalid Boost BPE hold time\n");
+
+	return regmap_write(cs35l45->regmap, CS35L45_BST_BPE_INST_HOLD_TIME, packed);
+}
+
+static int cs35l45_bst_bpe_set_inst_rls_rate(struct cs35l45_private *cs35l45)
+{
+	u32 packed = 0;
+	int ret;
+
+	ret = cs35l45_bst_bpe_pack_array(cs35l45, "cirrus,boost-bpe-battery-release-rates",
+					 CS35L45_BST_BPE_NUM_VOLTAGE_LEVELS, 0, 0,
+					 CS35L45_BST_BPE_RELEASE_RATE_0P001907MA_PER_US, 1,
+					 &packed);
+	if (ret)
+		return ret;
+
+	return regmap_write(cs35l45->regmap, CS35L45_BST_BPE_INST_RLS_RATE, packed);
+}
+
+static int cs35l45_bst_bpe_set_out_atk_rate(struct cs35l45_private *cs35l45)
+{
+	u32 value;
+	int ret;
+
+	ret = device_property_read_u32(cs35l45->dev, "cirrus,boost-bpe-output-attack-rate",
+				       &value);
+	if (ret)
+		return ret;
+
+	if (value > CS35L45_BST_BPE_ATTACK_RATE_3P90625MA_PER_US)
+		return -EINVAL;
+
+	return regmap_write(cs35l45->regmap, CS35L45_BST_BPE_OUT_ATK_RATE, value);
+}
+
+static int cs35l45_bst_bpe_set_out_rls_rate(struct cs35l45_private *cs35l45)
+{
+	u32 value;
+	int ret;
+
+	ret = device_property_read_u32(cs35l45->dev, "cirrus,boost-bpe-output-release-rate",
+				       &value);
+	if (ret)
+		return ret;
+
+	if (value > CS35L45_BST_BPE_RELEASE_RATE_0P001907MA_PER_US)
+		return -EINVAL;
+
+	return regmap_write(cs35l45->regmap, CS35L45_BST_BPE_OUT_RLS_RATE, value);
+}
+
+static int cs35l45_bst_bpe_set_il_lim_thld(struct cs35l45_private *cs35l45)
+{
+	u32 packed = 0;
+	int ret;
+
+	ret = cs35l45_bst_bpe_pack_scalar(cs35l45, "cirrus,boost-bpe-inductor-threshold-microamp",
+					  CS35L45_BST_BPE_IL_LIM1_THLD_MASK,
+					  CS35L45_BST_BPE_IL_LIM1_THLD_SHIFT,
+					  CS35L45_BST_BPE_IL_LIM_THLD_MIN_UA,
+					  CS35L45_BST_BPE_IL_LIM_THLD_MAX_UA,
+					  CS35L45_BST_BPE_IL_LIM_THLD_STEP_UA, &packed);
+	if (ret)
+		return ret;
+
+	ret = cs35l45_bst_bpe_pack_array(cs35l45,
+					 "cirrus,boost-bpe-inductor-threshold-deltas-microamp",
+					 CS35L45_BST_BPE_NUM_CURRENT_LEVELS, 1,
+					 CS35L45_BST_BPE_IL_LIM_THLD_DEL_MIN_UA,
+					 CS35L45_BST_BPE_IL_LIM_THLD_DEL_MAX_UA,
+					 CS35L45_BST_BPE_IL_LIM_THLD_DEL_STEP_UA, &packed);
+	if (ret)
+		return ret;
+
+	ret = cs35l45_bst_bpe_pack_scalar(cs35l45,
+					  "cirrus,boost-bpe-inductor-threshold-hysteresis-microamp",
+					  CS35L45_BST_BPE_IL_LIM_THLD_HYST_MASK,
+					  CS35L45_BST_BPE_IL_LIM_THLD_HYST_SHIFT,
+					  CS35L45_BST_BPE_IL_LIM_THLD_HYST_MIN_UA,
+					  CS35L45_BST_BPE_IL_LIM_THLD_HYST_MAX_UA,
+					  CS35L45_BST_BPE_IL_LIM_THLD_HYST_STEP_UA, &packed);
+	if (ret)
+		return ret;
+
+	return regmap_write(cs35l45->regmap, CS35L45_BST_BPE_IL_LIM_THLD, packed);
+}
+
+static int cs35l45_bst_bpe_set_il_lim_dly(struct cs35l45_private *cs35l45)
+{
+	u32 packed = 0;
+	int ret;
+
+	ret = cs35l45_bst_bpe_pack_scalar(cs35l45, "cirrus,boost-bpe-inductor-delay-hysteresis-us",
+					  CS35L45_BST_BPE_IL_LIM_DLY_HYST_MASK,
+					  CS35L45_BST_BPE_IL_LIM_DLY_HYST_SHIFT,
+					  CS35L45_BST_BPE_IL_LIM_DLY_HYST_MIN_US,
+					  CS35L45_BST_BPE_IL_LIM_DLY_HYST_MAX_US,
+					  CS35L45_BST_BPE_IL_LIM_DLY_HYST_STEP_US, &packed);
+	if (ret)
+		return ret;
+
+	ret = cs35l45_bst_bpe_pack_array(cs35l45, "cirrus,boost-bpe-inductor-delays-ms",
+					 CS35L45_BST_BPE_NUM_CURRENT_LEVELS, 0,
+					 CS35L45_BST_BPE_IL_LIM_DLY_MIN_MS,
+					 CS35L45_BST_BPE_IL_LIM_DLY_MAX_MS,
+					 CS35L45_BST_BPE_IL_LIM_DLY_STEP_MS, &packed);
+	if (ret)
+		return ret;
+
+	return regmap_write(cs35l45->regmap, CS35L45_BST_BPE_IL_LIM_DLY, packed);
+}
+
+static int cs35l45_bst_bpe_set_il_lim_atk_rate(struct cs35l45_private *cs35l45)
+{
+	u32 packed = 0;
+	int ret;
+
+	ret = cs35l45_bst_bpe_pack_array(cs35l45, "cirrus,boost-bpe-inductor-attack-rates",
+					 CS35L45_BST_BPE_NUM_CURRENT_LEVELS, 0, 0,
+					 CS35L45_BST_BPE_ATTACK_RATE_3P90625MA_PER_US, 1, &packed);
+	if (ret)
+		return ret;
+
+	return regmap_write(cs35l45->regmap, CS35L45_BST_BPE_IL_LIM_ATK_RATE, packed);
+}
+
+static int cs35l45_bst_bpe_set_il_lim_rls_rate(struct cs35l45_private *cs35l45)
+{
+	u32 packed = 0;
+	int ret;
+
+	ret = cs35l45_bst_bpe_pack_array(cs35l45, "cirrus,boost-bpe-inductor-release-rates",
+					 CS35L45_BST_BPE_NUM_CURRENT_LEVELS, 0, 0,
+					 CS35L45_BST_BPE_RELEASE_RATE_0P001907MA_PER_US, 1,
+					 &packed);
+	if (ret)
+		return ret;
+
+	return regmap_write(cs35l45->regmap, CS35L45_BST_BPE_IL_LIM_RLS_RATE, packed);
+}
+
+static int cs35l45_bst_bpe_set_mode(struct cs35l45_private *cs35l45, u32 *output_mode)
+{
+	u32 release_mode, mask, packed;
+	int ret;
+
+	ret = device_property_read_u32(cs35l45->dev, "cirrus,boost-bpe-output-operating-mode",
+				       output_mode);
+	if (ret)
+		return dev_err_probe(cs35l45->dev, ret, "Failed to read boost BPE op mode\n");
+
+	if ((*output_mode != CS35L45_BST_BPE_OUTPUT_MODE_BOTH) &&
+	    (*output_mode != CS35L45_BST_BPE_OUTPUT_MODE_VOLTAGE_ONLY))
+		return dev_err_probe(cs35l45->dev, -EINVAL, "Invalid boost BPE op mode found\n");
+
+	mask = CS35L45_BST_BPE_OUT_OPMODE_SEL_MASK;
+	packed = FIELD_PREP(CS35L45_BST_BPE_OUT_OPMODE_SEL_MASK, *output_mode);
+
+	if (*output_mode == CS35L45_BST_BPE_OUTPUT_MODE_BOTH) {
+		ret = device_property_read_u32(cs35l45->dev,
+					       "cirrus,boost-bpe-inductor-release-mode",
+					       &release_mode);
+		if (ret)
+			return dev_err_probe(cs35l45->dev, ret,
+					     "Failed to read inductor response release mode\n");
+
+		if ((release_mode != CS35L45_BST_BPE_IL_RELEASE_MODE_INSTANT) &&
+		    (release_mode != CS35L45_BST_BPE_IL_RELEASE_MODE_COUNTER))
+			return dev_err_probe(cs35l45->dev, -EINVAL,
+					     "Invalid boost BPE indductor current release mode\n");
+
+		mask |= CS35L45_BST_BPE_IL_LIM_MODE_MASK;
+		packed |= FIELD_PREP(CS35L45_BST_BPE_IL_LIM_MODE_MASK, release_mode);
+	}
+
+	return regmap_update_bits(cs35l45->regmap, CS35L45_BST_BPE_MISC_CONFIG, mask, packed);
+}
+
+static int cs35l45_bst_bpe_set_il_lim_limiter(struct cs35l45_private *cs35l45)
+{
+	int ret;
+
+	ret = cs35l45_bst_bpe_set_il_lim_thld(cs35l45);
+	if (ret)
+		return ret;
+
+	ret = cs35l45_bst_bpe_set_il_lim_dly(cs35l45);
+	if (ret)
+		return ret;
+
+	ret = cs35l45_bst_bpe_set_il_lim_atk_rate(cs35l45);
+	if (ret)
+		return ret;
+
+	return cs35l45_bst_bpe_set_il_lim_rls_rate(cs35l45);
+}
+
+static int cs35l45_bst_bpe_set_inst_limiter(struct cs35l45_private *cs35l45)
+{
+	int ret;
+
+	ret = cs35l45_bst_bpe_set_inst_thld(cs35l45);
+	if (ret)
+		return ret;
+
+	ret = cs35l45_bst_bpe_set_inst_ilim(cs35l45);
+	if (ret)
+		return ret;
+
+	ret = cs35l45_bst_bpe_set_inst_atk_rate(cs35l45);
+	if (ret)
+		return ret;
+
+	ret = cs35l45_bst_bpe_set_inst_hold_time(cs35l45);
+	if (ret)
+		return ret;
+
+	return cs35l45_bst_bpe_set_inst_rls_rate(cs35l45);
+}
+
+static int cs35l45_apply_boost_bpe_config(struct cs35l45_private *cs35l45)
+{
+	u32 output_mode;
+	int ret;
+
+	if (!device_property_read_bool(cs35l45->dev, "cirrus,boost-bpe-enable"))
+		return 0;
+
+	ret = cs35l45_bst_bpe_set_mode(cs35l45, &output_mode);
+	if (ret)
+		return ret;
+
+	ret = cs35l45_bst_bpe_set_inst_limiter(cs35l45);
+	if (ret)
+		return ret;
+
+	ret = cs35l45_bst_bpe_set_out_atk_rate(cs35l45);
+	if (ret)
+		return ret;
+
+	ret = cs35l45_bst_bpe_set_out_rls_rate(cs35l45);
+	if (ret)
+		return ret;
+
+	if (output_mode == CS35L45_BST_BPE_OUTPUT_MODE_BOTH) {
+		ret = cs35l45_bst_bpe_set_il_lim_limiter(cs35l45);
+		if (ret)
+			return ret;
+	}
+
+	ret = regmap_set_bits(cs35l45->regmap, CS35L45_BLOCK_ENABLES2, CS35L45_BBPE_EN_MASK);
+	if (ret)
+		return dev_err_probe(cs35l45->dev, ret, "Failed to enable Boost BPE\n");
+
+	return 0;
+}
+
 static int cs35l45_apply_ldpm_config(struct cs35l45_private *cs35l45)
 {
 	char prop_name[CS35L45_LDPM_PROP_NAME_MAX];
@@ -1518,6 +1892,10 @@ static int cs35l45_apply_property_config(struct cs35l45_private *cs35l45)
 				   val << CS35L45_ASP_DOUT_HIZ_CTRL_SHIFT);
 	}
 
+	ret = cs35l45_apply_boost_bpe_config(cs35l45);
+	if (ret < 0)
+		return ret;
+
 	ret = cs35l45_apply_ldpm_config(cs35l45);
 	if (ret < 0)
 		return ret;
diff --git a/sound/soc/codecs/cs35l45.h b/sound/soc/codecs/cs35l45.h
index 573595924365..8c94a7f42c65 100644
--- a/sound/soc/codecs/cs35l45.h
+++ b/sound/soc/codecs/cs35l45.h
@@ -41,6 +41,18 @@
 #define CS35L45_BOOST_LPMODE_CFG		0x00003810
 #define CS35L45_BOOST_DCM_CFG			0x0000380C
 #define CS35L45_BOOST_OV_CFG			0x0000382C
+#define CS35L45_BST_BPE_INST_THLD		0x00003C00
+#define CS35L45_BST_BPE_INST_ILIM		0x00003C04
+#define CS35L45_BST_BPE_INST_ATK_RATE		0x00003C0C
+#define CS35L45_BST_BPE_INST_HOLD_TIME		0x00003C10
+#define CS35L45_BST_BPE_INST_RLS_RATE		0x00003C14
+#define CS35L45_BST_BPE_MISC_CONFIG		0x00003C20
+#define CS35L45_BST_BPE_IL_LIM_THLD		0x00003C24
+#define CS35L45_BST_BPE_IL_LIM_DLY		0x00003C28
+#define CS35L45_BST_BPE_IL_LIM_ATK_RATE	0x00003C2C
+#define CS35L45_BST_BPE_IL_LIM_RLS_RATE	0x00003C30
+#define CS35L45_BST_BPE_OUT_ATK_RATE		0x00003C34
+#define CS35L45_BST_BPE_OUT_RLS_RATE		0x00003C38
 #define CS35L45_ASP_ENABLES1			0x00004800
 #define CS35L45_ASP_CONTROL1			0x00004804
 #define CS35L45_ASP_CONTROL2			0x00004808
@@ -191,6 +203,8 @@
 #define CS35L45_BST_ENABLE			0x02
 
 /* BLOCK_ENABLES2 */
+#define CS35L45_BBPE_EN_SHIFT			13
+#define CS35L45_BBPE_EN_MASK			BIT(13)
 #define CS35L45_ASP_EN_SHIFT			27
 #define CS35L45_AMP_DRE_EN_SHIFT		20
 #define CS35L45_AMP_DRE_EN_MASK		BIT(20)
@@ -282,6 +296,126 @@
 /* BOOST_LPMODE_CFG */
 #define CS35L45_BST_LPMODE_SEL			GENMASK(1, 0)
 
+/* BST_BPE_INST_THLD */
+#define CS35L45_BST_BPE_INST_L3_THLD_SHIFT	24
+#define CS35L45_BST_BPE_INST_L3_THLD_MASK	GENMASK(31, 24)
+#define CS35L45_BST_BPE_INST_L2_THLD_SHIFT	16
+#define CS35L45_BST_BPE_INST_L2_THLD_MASK	GENMASK(23, 16)
+#define CS35L45_BST_BPE_INST_L1_THLD_SHIFT	8
+#define CS35L45_BST_BPE_INST_L1_THLD_MASK	GENMASK(15, 8)
+#define CS35L45_BST_BPE_INST_L0_THLD_SHIFT	0
+#define CS35L45_BST_BPE_INST_L0_THLD_MASK	GENMASK(7, 0)
+
+#define CS35L45_BST_BPE_INST_THLD_MIN_UV	2300000
+#define CS35L45_BST_BPE_INST_THLD_MAX_UV	4500000
+#define CS35L45_BST_BPE_INST_THLD_STEP_UV	10000
+
+/* BST_BPE_INST_ILIM */
+#define CS35L45_BST_BPE_INST_L4_ILIM_SHIFT	24
+#define CS35L45_BST_BPE_INST_L4_ILIM_MASK	GENMASK(30, 24)
+#define CS35L45_BST_BPE_INST_L3_ILIM_SHIFT	16
+#define CS35L45_BST_BPE_INST_L3_ILIM_MASK	GENMASK(22, 16)
+#define CS35L45_BST_BPE_INST_L2_ILIM_SHIFT	8
+#define CS35L45_BST_BPE_INST_L2_ILIM_MASK	GENMASK(14, 8)
+#define CS35L45_BST_BPE_INST_L1_ILIM_SHIFT	0
+#define CS35L45_BST_BPE_INST_L1_ILIM_MASK	GENMASK(6, 0)
+
+#define CS35L45_BST_BPE_INST_ILIM_MIN_UA	250000
+#define CS35L45_BST_BPE_INST_ILIM_MAX_UA	4625000
+#define CS35L45_BST_BPE_INST_ILIM_STEP_UA	62500
+
+/* BST_BPE_INST_ATK_RATE */
+#define CS35L45_BST_BPE_INST_L3_ATK_RATE_SHIFT	24
+#define CS35L45_BST_BPE_INST_L3_ATK_RATE_MASK	GENMASK(26, 24)
+#define CS35L45_BST_BPE_INST_L2_ATK_RATE_SHIFT	16
+#define CS35L45_BST_BPE_INST_L2_ATK_RATE_MASK	GENMASK(18, 16)
+#define CS35L45_BST_BPE_INST_L1_ATK_RATE_SHIFT	8
+#define CS35L45_BST_BPE_INST_L1_ATK_RATE_MASK	GENMASK(10, 8)
+
+/* BST_BPE_INST_HOLD_TIME */
+#define CS35L45_BST_BPE_INST_L3_HOLD_TIME_SHIFT	24
+#define CS35L45_BST_BPE_INST_L3_HOLD_TIME_MASK		GENMASK(27, 24)
+#define CS35L45_BST_BPE_INST_L2_HOLD_TIME_SHIFT	16
+#define CS35L45_BST_BPE_INST_L2_HOLD_TIME_MASK		GENMASK(19, 16)
+#define CS35L45_BST_BPE_INST_L1_HOLD_TIME_SHIFT	8
+#define CS35L45_BST_BPE_INST_L1_HOLD_TIME_MASK		GENMASK(11, 8)
+#define CS35L45_BST_BPE_INST_L0_HOLD_TIME_SHIFT	0
+#define CS35L45_BST_BPE_INST_L0_HOLD_TIME_MASK		GENMASK(3, 0)
+
+/* BST_BPE_INST_RLS_RATE */
+#define CS35L45_BST_BPE_INST_L3_RLS_RATE_SHIFT	24
+#define CS35L45_BST_BPE_INST_L3_RLS_RATE_MASK	GENMASK(28, 24)
+#define CS35L45_BST_BPE_INST_L2_RLS_RATE_SHIFT	16
+#define CS35L45_BST_BPE_INST_L2_RLS_RATE_MASK	GENMASK(20, 16)
+#define CS35L45_BST_BPE_INST_L1_RLS_RATE_SHIFT	8
+#define CS35L45_BST_BPE_INST_L1_RLS_RATE_MASK	GENMASK(12, 8)
+#define CS35L45_BST_BPE_INST_L0_RLS_RATE_SHIFT	0
+#define CS35L45_BST_BPE_INST_L0_RLS_RATE_MASK	GENMASK(4, 0)
+
+/* BST_BPE_MISC_CONFIG */
+#define CS35L45_BST_BPE_IL_LIM_MODE_SHIFT	15
+#define CS35L45_BST_BPE_IL_LIM_MODE_MASK	BIT(15)
+#define CS35L45_BST_BPE_OUT_OPMODE_SEL_SHIFT	12
+#define CS35L45_BST_BPE_OUT_OPMODE_SEL_MASK	GENMASK(13, 12)
+
+/* BST_BPE_IL_LIM_THLD */
+#define CS35L45_BST_BPE_IL_LIM_THLD_HYST_SHIFT	24
+#define CS35L45_BST_BPE_IL_LIM_THLD_HYST_MASK	GENMASK(28, 24)
+#define CS35L45_BST_BPE_IL_LIM_THLD_DEL2_SHIFT	16
+#define CS35L45_BST_BPE_IL_LIM_THLD_DEL2_MASK	GENMASK(23, 16)
+#define CS35L45_BST_BPE_IL_LIM_THLD_DEL1_SHIFT	8
+#define CS35L45_BST_BPE_IL_LIM_THLD_DEL1_MASK	GENMASK(15, 8)
+#define CS35L45_BST_BPE_IL_LIM1_THLD_SHIFT	0
+#define CS35L45_BST_BPE_IL_LIM1_THLD_MASK	GENMASK(7, 0)
+
+#define CS35L45_BST_BPE_IL_LIM_THLD_MIN_UA	250000
+#define CS35L45_BST_BPE_IL_LIM_THLD_MAX_UA	4000000
+#define CS35L45_BST_BPE_IL_LIM_THLD_STEP_UA	62500
+
+#define CS35L45_BST_BPE_IL_LIM_THLD_DEL_MIN_UA		0
+#define CS35L45_BST_BPE_IL_LIM_THLD_DEL_MAX_UA		3750000
+#define CS35L45_BST_BPE_IL_LIM_THLD_DEL_STEP_UA	62500
+
+#define CS35L45_BST_BPE_IL_LIM_THLD_HYST_MIN_UA	0
+#define CS35L45_BST_BPE_IL_LIM_THLD_HYST_MAX_UA	968750
+#define CS35L45_BST_BPE_IL_LIM_THLD_HYST_STEP_UA	31250
+
+/* BST_BPE_IL_LIM_DLY */
+#define CS35L45_BST_BPE_IL_LIM_DLY_HYST_SHIFT	16
+#define CS35L45_BST_BPE_IL_LIM_DLY_HYST_MASK	GENMASK(20, 16)
+#define CS35L45_BST_BPE_IL_LIM2_DLY_SHIFT	8
+#define CS35L45_BST_BPE_IL_LIM2_DLY_MASK	GENMASK(15, 8)
+#define CS35L45_BST_BPE_IL_LIM1_DLY_SHIFT	0
+#define CS35L45_BST_BPE_IL_LIM1_DLY_MASK	GENMASK(7, 0)
+
+#define CS35L45_BST_BPE_IL_LIM_DLY_HYST_MIN_US		0
+#define CS35L45_BST_BPE_IL_LIM_DLY_HYST_MAX_US		992
+#define CS35L45_BST_BPE_IL_LIM_DLY_HYST_STEP_US	32
+
+#define CS35L45_BST_BPE_IL_LIM_DLY_MIN_MS	0
+#define CS35L45_BST_BPE_IL_LIM_DLY_MAX_MS	100
+#define CS35L45_BST_BPE_IL_LIM_DLY_STEP_MS	1
+
+/* BST_BPE_IL_LIM_ATK_RATE */
+#define CS35L45_BST_BPE_IL_LIM2_ATK_RATE_SHIFT	8
+#define CS35L45_BST_BPE_IL_LIM2_ATK_RATE_MASK	GENMASK(10, 8)
+#define CS35L45_BST_BPE_IL_LIM1_ATK_RATE_SHIFT	0
+#define CS35L45_BST_BPE_IL_LIM1_ATK_RATE_MASK	GENMASK(2, 0)
+
+/* BST_BPE_IL_LIM_RLS_RATE */
+#define CS35L45_BST_BPE_IL_LIM2_RLS_RATE_SHIFT	8
+#define CS35L45_BST_BPE_IL_LIM2_RLS_RATE_MASK	GENMASK(12, 8)
+#define CS35L45_BST_BPE_IL_LIM1_RLS_RATE_SHIFT	0
+#define CS35L45_BST_BPE_IL_LIM1_RLS_RATE_MASK	GENMASK(4, 0)
+
+/* BST_BPE_OUT_ATK_RATE */
+#define CS35L45_BST_BPE_OUT_ATK_RATE_SHIFT	0
+#define CS35L45_BST_BPE_OUT_ATK_RATE_MASK	GENMASK(2, 0)
+
+/* BST_BPE_OUT_RLS_RATE */
+#define CS35L45_BST_BPE_OUT_RLS_RATE_SHIFT	0
+#define CS35L45_BST_BPE_OUT_RLS_RATE_MASK	GENMASK(4, 0)
+
 /* ASP_ENABLES_1 */
 #define CS35L45_ASP_RX2_EN_SHIFT		17
 #define CS35L45_ASP_RX1_EN_SHIFT		16
@@ -532,6 +666,15 @@ enum bpe_modes {
 
 #define CS35L45_BPE_PACK_CODE(_code, _idx) (_code << (24 - (8 * _idx)))
 
+#define CS35L45_BST_BPE_NUM_VOLTAGE_LEVELS		4
+#define CS35L45_BST_BPE_NUM_VOLTAGE_ATTACK_LEVELS	3
+#define CS35L45_BST_BPE_NUM_CURRENT_LEVELS		2
+#define CS35L45_BST_BPE_NUM_LEVELS			CS35L45_BST_BPE_NUM_VOLTAGE_LEVELS
+#define CS35L45_BST_BPE_NUM_HOLD_TIMES			12
+
+/* Boost BPE levels use ascending byte lanes; some arrays start at lane 1. */
+#define CS35L45_BST_BPE_PACK_CODE(_code, _idx) ((_code) << (8 * (_idx)))
+
 /*
  * IRQs
  */
@@ -609,6 +752,7 @@ int cs35l45_get_clk_freq_id(unsigned int freq);
 int cs35l45_get_ldpm_pcm_thld(int pcm_thld_db);
 int cs35l45_get_ldpm_delay(u32 delay_ms);
 int cs35l45_bpe_pack_hold_times(u32 *hold_times, u32 *packed_code);
+int cs35l45_bst_bpe_pack_hold_times(const u32 *hold_times, u32 *packed_code);
 const char *cs35l45_bpe_get_attn_prop(const enum bpe_modes mode);
 int cs35l45_probe(struct cs35l45_private *cs35l45);
 void cs35l45_remove(struct cs35l45_private *cs35l45);

-- 
2.43.0

