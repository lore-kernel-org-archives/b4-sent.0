From: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Date: Mon, 16 Nov 2026 01:50:26 +0530
Subject: [PATCH 2/2] ASoC: codecs: Add NXP TFA9865 amplifier driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-vantage-tfa9865-v1-2-e88f0dccc427@yahoo.com>
References: <20261116-vantage-tfa9865-v1-0-e88f0dccc427@yahoo.com>
In-Reply-To: <20261116-vantage-tfa9865-v1-0-e88f0dccc427@yahoo.com>
To: Venkat Yadlapati <venkat.yadlapati@yahoo.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jaroslav Kysela <perex@perex.cz>, 
 Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794774024; l=14890;
 i=venkat.yadlapati@yahoo.com; s=20261023; h=from:subject:message-id;
 bh=J4P6OkrHekSL0ACMzkiE1QgV1MoyBafRY5lzswvWTYw=;
 b=5gPc2+KUyDRkfgHFu0OvwUYSn5AqI6zGQeTB0zzUDt8w4RllLUS+Sk4lhSR8f4mSYy8D3HmwZ
 VfE2+qp+YC6CLacd6dEGQ87HpMZZ8zewdpsly4I+T+cHrbCV4WlEQnv
X-Developer-Key: i=venkat.yadlapati@yahoo.com; a=ed25519;
 pk=e8KStCtEMvUP1Se/riB/KVnDAQFEVR2Dw2PcuA8/eME=
X-Endpoint-Received: by B4 Relay for venkat.yadlapati@yahoo.com/20261023 with auth_id=1303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a driver for the NXP (now Goodix) TFA9865 speaker amplifier. The
chip has no DSP, so the driver only has to apply the initialization
sequence for the device revision, select the I2S slot that feeds the
amplifier and power the amplifier and its boost converter up and down.

The register settings are taken from the NXP tfa98xx driver. Only the
B0 revision and the 32-bit I2S slots configured at reset are supported
for now.

Assisted-by: LLM
Signed-off-by: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
---
 sound/soc/codecs/Kconfig   |  14 ++
 sound/soc/codecs/Makefile  |   2 +
 sound/soc/codecs/tfa9865.c | 359 +++++++++++++++++++++++++++++++++++++++++++++
 3 files changed, 375 insertions(+)

diff --git a/sound/soc/codecs/Kconfig b/sound/soc/codecs/Kconfig
index ba59dabeeccd..a30057b2d1ef 100644
--- a/sound/soc/codecs/Kconfig
+++ b/sound/soc/codecs/Kconfig
@@ -284,6 +284,7 @@ config SND_SOC_ALL_CODECS
 	imply SND_SOC_TAS6424
 	imply SND_SOC_TAS675X
 	imply SND_SOC_TDA7419
+	imply SND_SOC_TFA9865
 	imply SND_SOC_TFA9879
 	imply SND_SOC_TFA989X
 	imply SND_SOC_TLV320ADC3XXX
@@ -2321,6 +2322,19 @@ config SND_SOC_TDA7419
 	depends on I2C
 	select REGMAP_I2C
 
+config SND_SOC_TFA9865
+	tristate "NXP/Goodix TFA9865 amplifier"
+	depends on I2C
+	select REGMAP_I2C
+	help
+	  Enable support for the NXP (now Goodix) TFA9865 mono class-D
+	  speaker amplifier with boost converter. The amplifier has no DSP,
+	  speaker protection is left to the host. The driver supports the
+	  B0 revision of the chip with 32-bit I2S slots.
+
+	  To compile this driver as a module, choose M here: the module
+	  will be called snd-soc-tfa9865.
+
 config SND_SOC_TFA9879
 	tristate "NXP Semiconductors TFA9879 amplifier"
 	depends on I2C
diff --git a/sound/soc/codecs/Makefile b/sound/soc/codecs/Makefile
index 3826f9e4fce8..0e421a3c620b 100644
--- a/sound/soc/codecs/Makefile
+++ b/sound/soc/codecs/Makefile
@@ -334,6 +334,7 @@ snd-soc-tas2781-comlib-i2c-y := tas2781-comlib-i2c.o
 snd-soc-tas2781-fmwlib-y := tas2781-fmwlib.o
 snd-soc-tas2781-i2c-y := tas2781-i2c.o
 snd-soc-tas2783-sdw-y := tas2783-sdw.o
+snd-soc-tfa9865-y := tfa9865.o
 snd-soc-tfa9879-y := tfa9879.o
 snd-soc-tfa989x-y := tfa989x.o
 snd-soc-tlv320adc3xxx-y := tlv320adc3xxx.o
@@ -782,6 +783,7 @@ obj-$(CONFIG_SND_SOC_TAS6424)	+= snd-soc-tas6424.o
 obj-$(CONFIG_SND_SOC_TAS675X)	+= snd-soc-tas675x.o
 obj-$(CONFIG_SND_SOC_TDA7419)	+= snd-soc-tda7419.o
 obj-$(CONFIG_SND_SOC_TAS2770) += snd-soc-tas2770.o
+obj-$(CONFIG_SND_SOC_TFA9865)	+= snd-soc-tfa9865.o
 obj-$(CONFIG_SND_SOC_TFA9879)	+= snd-soc-tfa9879.o
 obj-$(CONFIG_SND_SOC_TFA989X)	+= snd-soc-tfa989x.o
 obj-$(CONFIG_SND_SOC_TLV320ADC3XXX)	+= snd-soc-tlv320adc3xxx.o
diff --git a/sound/soc/codecs/tfa9865.c b/sound/soc/codecs/tfa9865.c
new file mode 100644
index 000000000000..7467b8b21eda
--- /dev/null
+++ b/sound/soc/codecs/tfa9865.c
@@ -0,0 +1,359 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Driver for the NXP TFA9865 mono class-D speaker amplifier
+ *
+ * The TFA9865 has no DSP of its own, speaker protection (if any) is done by
+ * the host. Register definitions and the initialization sequence are taken
+ * from the NXP tfa98xx kernel driver:
+ * Copyright (C) 2014-2020 NXP Semiconductors, All Rights Reserved.
+ *
+ * Copyright (c) 2026 Venkat Yadlapati <venkat.yadlapati@yahoo.com>
+ */
+
+#include <linux/bitfield.h>
+#include <linux/delay.h>
+#include <linux/gpio/consumer.h>
+#include <linux/i2c.h>
+#include <linux/module.h>
+#include <linux/regmap.h>
+#include <linux/regulator/consumer.h>
+#include <sound/pcm_params.h>
+#include <sound/soc.h>
+
+#define TFA9865_SYS_CTRL0		0x00
+#define TFA9865_SYS_CTRL0_PWDN		0	/* power down */
+#define TFA9865_SYS_CTRL0_AMPE		3	/* enable amplifier */
+#define TFA9865_SYS_CTRL0_DCA		4	/* enable boost converter */
+#define TFA9865_SYS_CTRL1		0x01
+#define TFA9865_SYS_CTRL1_MANSCONF	BIT(2)	/* I2C configuration done */
+#define TFA9865_SYS_CTRL2		0x02
+#define TFA9865_SYS_CTRL2_AUDFS		GENMASK(3, 0)	/* sample rate */
+#define TFA9865_REVISIONNUMBER		0x03
+#define TFA9865_REVISIONNUMBER_REV	GENMASK(7, 0)
+#define TFA9865_REVISIONNUMBER_FAM	GENMASK(15, 8)
+#define TFA9865_CLK_GATING_CTRL		0x04
+#define TFA9865_CLK_GATING_CTRL_MANAOOSC BIT(6)	/* oscillator off in power down */
+#define TFA9865_DEVICE_INFO		0x06
+#define TFA9865_DEVICE_INFO_DEVREV	GENMASK(15, 8)
+#define TFA9865_HIDE_UNHIDE_KEY		0x0f
+#define TFA9865_STATUS_FLAGS2		0x12
+#define TFA9865_STATUS_FLAGS2_MANSTATE	GENMASK(3, 0)	/* device manager state */
+#define TFA9865_TDM_CFG1		0x21
+#define TFA9865_TDM_CFG1_TDMSPKS	8	/* slot for the amplifier input */
+#define TFA9865_TDM_GAIN		0x5f
+#define TFA9865_TDM_GAIN_TDMSPKG	5	/* input attenuation */
+#define TFA9865_TDM_GAIN_TDMSPKG_MAX	31
+#define TFA9865_KEY1			0xa0
+#define TFA9865_KEY2			0xa1
+#define TFA9865_KEY1_SEED		0xfb
+
+#define TFA9865_FAMILY			0x98
+#define TFA9865_REVISION		0x66
+
+#define TFA9865_MANSTATE_POWERDOWN	0
+#define TFA9865_MANSTATE_WAIT_SRC	1
+
+struct tfa9865 {
+	struct regmap *regmap;
+	struct gpio_desc *reset_gpiod;
+};
+
+static bool tfa9865_volatile_reg(struct device *dev, unsigned int reg)
+{
+	switch (reg) {
+	case TFA9865_SYS_CTRL0 ... TFA9865_DEVICE_INFO:
+	case 0x10 ... 0x15:	/* status and interrupt flags */
+		return true;
+	default:
+		return false;
+	}
+}
+
+static const struct regmap_config tfa9865_regmap = {
+	.reg_bits = 8,
+	.val_bits = 16,
+	.max_register = 0xff,
+
+	.volatile_reg = tfa9865_volatile_reg,
+	.cache_type = REGCACHE_NONE,
+};
+
+static const char * const tdmspks_text[] = { "Left", "Right" };
+static SOC_ENUM_SINGLE_DECL(tdmspks_enum, TFA9865_TDM_CFG1, TFA9865_TDM_CFG1_TDMSPKS,
+			    tdmspks_text);
+static const struct snd_kcontrol_new tdmspks_mux = SOC_DAPM_ENUM("Amp Input", tdmspks_enum);
+static const struct snd_kcontrol_new amp_switch = SOC_DAPM_SINGLE_VIRT("Switch", 1);
+
+static const struct snd_kcontrol_new tfa9865_controls[] = {
+	/* The input attenuation has no documented scale, larger is quieter */
+	SOC_SINGLE("Playback Volume", TFA9865_TDM_GAIN, TFA9865_TDM_GAIN_TDMSPKG,
+		   TFA9865_TDM_GAIN_TDMSPKG_MAX, 1),
+};
+
+static const struct snd_soc_dapm_widget tfa9865_dapm_widgets[] = {
+	SND_SOC_DAPM_OUTPUT("OUT"),
+	SND_SOC_DAPM_SUPPLY("POWER", TFA9865_SYS_CTRL0, TFA9865_SYS_CTRL0_PWDN, 1, NULL, 0),
+	SND_SOC_DAPM_SUPPLY("BOOST", TFA9865_SYS_CTRL0, TFA9865_SYS_CTRL0_DCA, 0, NULL, 0),
+	SND_SOC_DAPM_OUT_DRV("AMPE", SND_SOC_NOPM, 0, 0, NULL, 0),
+	SND_SOC_DAPM_SWITCH("Amp", SND_SOC_NOPM, 0, 0, &amp_switch),
+
+	SND_SOC_DAPM_MUX("Amp Input", SND_SOC_NOPM, 0, 0, &tdmspks_mux),
+	SND_SOC_DAPM_AIF_IN("AIFINL", "HiFi Playback", 0, SND_SOC_NOPM, 0, 0),
+	SND_SOC_DAPM_AIF_IN("AIFINR", "HiFi Playback", 1, SND_SOC_NOPM, 0, 0),
+};
+
+static const struct snd_soc_dapm_route tfa9865_dapm_routes[] = {
+	{"OUT", NULL, "AMPE"},
+	{"AMPE", NULL, "POWER"},
+	{"AMPE", NULL, "BOOST"},
+	{"AMPE", NULL, "Amp"},
+	{"Amp", "Switch", "Amp Input"},
+	{"Amp Input", "Left", "AIFINL"},
+	{"Amp Input", "Right", "AIFINR"},
+};
+
+static const struct snd_soc_component_driver tfa9865_component = {
+	.controls		= tfa9865_controls,
+	.num_controls		= ARRAY_SIZE(tfa9865_controls),
+	.dapm_widgets		= tfa9865_dapm_widgets,
+	.num_dapm_widgets	= ARRAY_SIZE(tfa9865_dapm_widgets),
+	.dapm_routes		= tfa9865_dapm_routes,
+	.num_dapm_routes	= ARRAY_SIZE(tfa9865_dapm_routes),
+	.use_pmdown_time	= 1,
+	.endianness		= 1,
+};
+
+static const unsigned int tfa9865_rates[] = {
+	8000, 11025, 12000, 16000, 22050, 24000, 32000, 44100, 48000
+};
+
+static int tfa9865_find_sample_rate(unsigned int rate)
+{
+	int i;
+
+	for (i = 0; i < ARRAY_SIZE(tfa9865_rates); i++)
+		if (tfa9865_rates[i] == rate)
+			return i;
+
+	return -EINVAL;
+}
+
+static int tfa9865_hw_params(struct snd_pcm_substream *substream,
+			     struct snd_pcm_hw_params *params,
+			     struct snd_soc_dai *dai)
+{
+	struct snd_soc_component *component = dai->component;
+	int sr;
+
+	/* Only the 32-bit I2S slots configured at reset are supported */
+	if (params_physical_width(params) != 32) {
+		dev_err(component->dev, "unsupported slot width: %d\n",
+			params_physical_width(params));
+		return -EINVAL;
+	}
+
+	sr = tfa9865_find_sample_rate(params_rate(params));
+	if (sr < 0) {
+		dev_err(component->dev, "unsupported sample rate: %d\n",
+			params_rate(params));
+		return sr;
+	}
+
+	return snd_soc_component_update_bits(component, TFA9865_SYS_CTRL2,
+					     TFA9865_SYS_CTRL2_AUDFS,
+					     FIELD_PREP(TFA9865_SYS_CTRL2_AUDFS, sr));
+}
+
+static int tfa9865_mute_stream(struct snd_soc_dai *dai, int mute, int stream)
+{
+	struct snd_soc_component *component = dai->component;
+	unsigned int val;
+
+	/*
+	 * Enable the amplifier only once the I2S clocks run, enabling it
+	 * earlier makes it pop when the clocks start. Leave it off if the
+	 * output is not powered.
+	 */
+	if (!mute) {
+		val = snd_soc_component_read(component, TFA9865_SYS_CTRL0);
+		if (val & BIT(TFA9865_SYS_CTRL0_PWDN))
+			return 0;
+	}
+
+	return snd_soc_component_update_bits(component, TFA9865_SYS_CTRL0,
+					     BIT(TFA9865_SYS_CTRL0_AMPE),
+					     mute ? 0 : BIT(TFA9865_SYS_CTRL0_AMPE));
+}
+
+static const struct snd_soc_dai_ops tfa9865_dai_ops = {
+	.hw_params = tfa9865_hw_params,
+	.mute_stream = tfa9865_mute_stream,
+	.no_capture_mute = 1,
+	.mute_unmute_on_trigger = 1,
+};
+
+static struct snd_soc_dai_driver tfa9865_dai = {
+	.name = "tfa9865-hifi",
+	.playback = {
+		.stream_name	= "HiFi Playback",
+		.formats	= SNDRV_PCM_FMTBIT_S32_LE,
+		.rates		= SNDRV_PCM_RATE_8000_48000,
+		.rate_min	= 8000,
+		.rate_max	= 48000,
+		.channels_min	= 1,
+		.channels_max	= 2,
+	},
+	.ops = &tfa9865_dai_ops,
+};
+
+static int tfa9865_wait_manstate(struct tfa9865 *tfa9865, unsigned int state)
+{
+	unsigned int val;
+
+	return regmap_read_poll_timeout(tfa9865->regmap, TFA9865_STATUS_FLAGS2, val,
+					FIELD_GET(TFA9865_STATUS_FLAGS2_MANSTATE, val) == state,
+					1000, 50000);
+}
+
+static const struct reg_sequence tfa9865_b0_init[] = {
+	/* "generated code" version 2 for TFA9865 B0 from the NXP driver */
+	{ 0x00, 0xf241 },
+	{ 0x02, 0x0c28 },
+	{ 0x08, 0x009a },
+	{ 0x50, 0xc000 },
+	{ 0x54, 0x10e0 },
+	{ 0x5a, 0x5f5e },
+	{ 0x5b, 0x74e2 },
+	{ 0x5c, 0xb02b },
+	{ 0x5f, 0x00a0 },
+	{ 0x62, 0x06c4 },
+	{ 0x63, 0x80d4 },
+	{ 0x65, 0x0c58 },
+	{ 0x67, 0x006e },
+	{ 0x68, 0x0820 },
+	{ 0x69, 0x0119 },
+	{ 0x74, 0x6028 },
+	{ 0x75, 0x1daa },
+	{ 0x78, 0x0001 },
+	{ 0x7c, 0x10f2 },
+	{ 0xdd, 0x01b6 },
+};
+
+static int tfa9865_init(struct tfa9865 *tfa9865)
+{
+	struct regmap *regmap = tfa9865->regmap;
+	unsigned int seed;
+	int ret;
+
+	/* Leave power down to make the protected registers accessible */
+	regmap_clear_bits(regmap, TFA9865_SYS_CTRL0, BIT(TFA9865_SYS_CTRL0_PWDN));
+	regmap_clear_bits(regmap, TFA9865_CLK_GATING_CTRL, TFA9865_CLK_GATING_CTRL_MANAOOSC);
+	ret = tfa9865_wait_manstate(tfa9865, TFA9865_MANSTATE_WAIT_SRC);
+	if (ret)
+		return ret;
+
+	/* Unlock key 1 and key 2 */
+	regmap_write(regmap, TFA9865_HIDE_UNHIDE_KEY, 0x5a6b);
+	ret = regmap_read(regmap, TFA9865_KEY1_SEED, &seed);
+	if (ret)
+		return ret;
+	regmap_write(regmap, TFA9865_KEY1, seed ^ 0x005a);
+	regmap_write(regmap, TFA9865_KEY2, 0x005a);
+
+	ret = regmap_multi_reg_write(regmap, tfa9865_b0_init, ARRAY_SIZE(tfa9865_b0_init));
+
+	/* Lock the keys again */
+	regmap_write(regmap, TFA9865_KEY2, 0);
+	regmap_write(regmap, TFA9865_KEY1, 0);
+	regmap_write(regmap, TFA9865_HIDE_UNHIDE_KEY, 0);
+	if (ret)
+		return ret;
+
+	/* Go back to power down with the oscillator off */
+	regmap_set_bits(regmap, TFA9865_SYS_CTRL0, BIT(TFA9865_SYS_CTRL0_PWDN));
+	ret = tfa9865_wait_manstate(tfa9865, TFA9865_MANSTATE_POWERDOWN);
+	if (ret)
+		return ret;
+	regmap_set_bits(regmap, TFA9865_CLK_GATING_CTRL, TFA9865_CLK_GATING_CTRL_MANAOOSC);
+
+	/* Input attenuation used by the vendor configuration */
+	regmap_update_bits(regmap, TFA9865_TDM_GAIN,
+			   TFA9865_TDM_GAIN_TDMSPKG_MAX << TFA9865_TDM_GAIN_TDMSPKG,
+			   5 << TFA9865_TDM_GAIN_TDMSPKG);
+
+	/* Configuration done, let the device manager start on power up */
+	return regmap_set_bits(regmap, TFA9865_SYS_CTRL1, TFA9865_SYS_CTRL1_MANSCONF);
+}
+
+static int tfa9865_i2c_probe(struct i2c_client *i2c)
+{
+	struct device *dev = &i2c->dev;
+	struct tfa9865 *tfa9865;
+	unsigned int val, devrev;
+	int ret;
+
+	tfa9865 = devm_kzalloc(dev, sizeof(*tfa9865), GFP_KERNEL);
+	if (!tfa9865)
+		return -ENOMEM;
+
+	i2c_set_clientdata(i2c, tfa9865);
+
+	ret = devm_regulator_get_enable_optional(dev, "vddd");
+	if (ret && ret != -ENODEV)
+		return dev_err_probe(dev, ret, "failed to enable vddd supply\n");
+
+	tfa9865->reset_gpiod = devm_gpiod_get_optional(dev, "reset", GPIOD_OUT_HIGH);
+	if (IS_ERR(tfa9865->reset_gpiod))
+		return dev_err_probe(dev, PTR_ERR(tfa9865->reset_gpiod),
+				     "failed to get reset gpio\n");
+	if (tfa9865->reset_gpiod) {
+		usleep_range(1000, 2000);
+		gpiod_set_value_cansleep(tfa9865->reset_gpiod, 0);
+		usleep_range(1000, 2000);
+	}
+
+	tfa9865->regmap = devm_regmap_init_i2c(i2c, &tfa9865_regmap);
+	if (IS_ERR(tfa9865->regmap))
+		return PTR_ERR(tfa9865->regmap);
+
+	ret = regmap_read(tfa9865->regmap, TFA9865_REVISIONNUMBER, &val);
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to read revision number\n");
+
+	if (FIELD_GET(TFA9865_REVISIONNUMBER_FAM, val) != TFA9865_FAMILY ||
+	    FIELD_GET(TFA9865_REVISIONNUMBER_REV, val) != TFA9865_REVISION)
+		return dev_err_probe(dev, -ENODEV, "unknown revision number %#x\n", val);
+
+	ret = regmap_read(tfa9865->regmap, TFA9865_DEVICE_INFO, &val);
+	if (ret)
+		return ret;
+
+	/* Only the B0 init sequence is known */
+	devrev = FIELD_GET(TFA9865_DEVICE_INFO_DEVREV, val);
+	if (((devrev >> 2) & 0x3) != 1 || (devrev & 0xf0))
+		return dev_err_probe(dev, -ENODEV, "unsupported device revision %#x\n", devrev);
+
+	ret = tfa9865_init(tfa9865);
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to initialize\n");
+
+	return devm_snd_soc_register_component(dev, &tfa9865_component, &tfa9865_dai, 1);
+}
+
+static const struct of_device_id tfa9865_of_match[] = {
+	{ .compatible = "nxp,tfa9865" },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, tfa9865_of_match);
+
+static struct i2c_driver tfa9865_i2c_driver = {
+	.driver = {
+		.name = "tfa9865",
+		.of_match_table = tfa9865_of_match,
+	},
+	.probe = tfa9865_i2c_probe,
+};
+module_i2c_driver(tfa9865_i2c_driver);
+
+MODULE_DESCRIPTION("ASoC NXP TFA9865 speaker amplifier driver");
+MODULE_LICENSE("GPL");

-- 
2.56.0

