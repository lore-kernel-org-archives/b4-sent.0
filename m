From: Shuming Fan <shumingf@realtek.com>
Date: Thu, 24 Sep 2026 13:53:03 +0800
Subject: [PATCH v2 2/3] ASoC: sdw_utils: Add rt766/rt767 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260924-rt766-v2-2-e0b63606a5e8@realtek.com>
References: <20260924-rt766-v2-0-e0b63606a5e8@realtek.com>
In-Reply-To: <20260924-rt766-v2-0-e0b63606a5e8@realtek.com>
To: broonie@kernel.org, lgirdwood@gmail.com
Cc: Shuming Fan <shumingf@realtek.com>, derek.fang@realtek.com, 
 lars@metafoo.de, oder_chiou@realtek.com, linux-sound@vger.kernel.org, 
 flove@realtek.com, jack.yu@realtek.com
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790229204; l=8678;
 i=shumingf@realtek.com; s=20260924; h=from:subject:message-id;
 bh=c5X1x1FT3e+gilmbYgue3fli6mT9isbmLdg83n6//7Y=;
 b=6FlY3y8ym75ApjCCT4q6wx6Pw8huw/JTvor608CAxpbCendFfoM2cbjvDJk5nvpYFKeG0twzh
 5HVQucfxAwBAQTuigyZWwcLTNByzrGxEJd32Y8fNj2Bb/rUh2gHeyf3
X-Developer-Key: i=shumingf@realtek.com; a=ed25519;
 pk=ZM8Pg7tEJ0SDXQeBw6SfvcYyqXU9nF88DuTyxzf9utE=
X-Endpoint-Received: by B4 Relay for shumingf@realtek.com/20260924 with auth_id=1053
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch adds the codec_info and route-related settings.

Signed-off-by: Shuming Fan <shumingf@realtek.com>
---
 sound/soc/sdw_utils/soc_sdw_rt_mf_sdca.c          |   6 +
 sound/soc/sdw_utils/soc_sdw_rt_sdca_jack_common.c |   8 +
 sound/soc/sdw_utils/soc_sdw_utils.c               | 172 ++++++++++++++++++++++
 3 files changed, 186 insertions(+)

diff --git a/sound/soc/sdw_utils/soc_sdw_rt_mf_sdca.c b/sound/soc/sdw_utils/soc_sdw_rt_mf_sdca.c
index 5bf3627a97a0..6e5fa93b5fc2 100644
--- a/sound/soc/sdw_utils/soc_sdw_rt_mf_sdca.c
+++ b/sound/soc/sdw_utils/soc_sdw_rt_mf_sdca.c
@@ -33,6 +33,11 @@ static const struct snd_soc_dapm_route rt722_spk_map[] = {
 	{ "Speaker", NULL, "rt722 SPK" },
 };
 
+static const struct snd_soc_dapm_route rt766_spk_map[] = {
+	{ "Speaker", NULL, "rt766 SPOL" },
+	{ "Speaker", NULL, "rt766 SPOR" },
+};
+
 /* Structure to map codec names to respective route arrays and sizes */
 struct codec_route_map {
 	const char *codec_name;
@@ -45,6 +50,7 @@ static const struct codec_route_map codec_routes[] = {
 	{ "rt712", rt712_spk_map, ARRAY_SIZE(rt712_spk_map) },
 	{ "rt721", rt721_spk_map, ARRAY_SIZE(rt721_spk_map) },
 	{ "rt722", rt722_spk_map, ARRAY_SIZE(rt722_spk_map) },
+	{ "rt766", rt766_spk_map, ARRAY_SIZE(rt766_spk_map) },
 };
 
 static const struct codec_route_map *get_codec_route_map(const char *codec_name)
diff --git a/sound/soc/sdw_utils/soc_sdw_rt_sdca_jack_common.c b/sound/soc/sdw_utils/soc_sdw_rt_sdca_jack_common.c
index 2547b5b3fdd7..b4e427d55130 100644
--- a/sound/soc/sdw_utils/soc_sdw_rt_sdca_jack_common.c
+++ b/sound/soc/sdw_utils/soc_sdw_rt_sdca_jack_common.c
@@ -70,6 +70,11 @@ static const struct snd_soc_dapm_route rt722_sdca_map[] = {
 	{ "rt722 MIC2", NULL, "Headset Mic" },
 };
 
+static const struct snd_soc_dapm_route rt766_sdca_map[] = {
+	{ "Headphone", NULL, "rt766 HP" },
+	{ "rt766 MIC2", NULL, "Headset Mic" },
+};
+
 static struct snd_soc_jack_pin rt_sdca_jack_pins[] = {
 	{
 		.pin    = "Headphone",
@@ -133,6 +138,9 @@ int asoc_sdw_rt_sdca_jack_rtd_init(struct snd_soc_pcm_runtime *rtd, struct snd_s
 	} else if (strstr(component->name_prefix, "rt722")) {
 		ret = snd_soc_dapm_add_routes(dapm, rt722_sdca_map,
 					      ARRAY_SIZE(rt722_sdca_map));
+	} else if (strstr(component->name_prefix, "rt766")) {
+		ret = snd_soc_dapm_add_routes(dapm, rt766_sdca_map,
+					      ARRAY_SIZE(rt766_sdca_map));
 	} else {
 		dev_err(card->dev, "%s is not supported\n", component->name_prefix);
 		return -EINVAL;
diff --git a/sound/soc/sdw_utils/soc_sdw_utils.c b/sound/soc/sdw_utils/soc_sdw_utils.c
index f0f0822d8ed6..14aee10b40ba 100644
--- a/sound/soc/sdw_utils/soc_sdw_utils.c
+++ b/sound/soc/sdw_utils/soc_sdw_utils.c
@@ -779,6 +779,178 @@ struct asoc_sdw_codec_info codec_info_list[] = {
 		},
 		.dai_num = 3,
 	},
+	{
+		.vendor_id = 0x025d,
+		.part_id = 0x767,
+		.name_prefix = "rt766",
+		.version_id = 3,
+		.dais =	{
+			{
+				.direction = {true, true},
+				.dai_name = "rt766-sdca-aif1",
+				.dai_type = SOC_SDW_DAI_TYPE_JACK,
+				.dailink = {SOC_SDW_JACK_OUT_DAI_ID, SOC_SDW_JACK_IN_DAI_ID},
+				.init = asoc_sdw_rt_sdca_jack_init,
+				.exit = asoc_sdw_rt_sdca_jack_exit,
+				.rtd_init = asoc_sdw_rt_sdca_jack_rtd_init,
+				.controls = generic_jack_controls,
+				.num_controls = ARRAY_SIZE(generic_jack_controls),
+				.widgets = generic_jack_widgets,
+				.num_widgets = ARRAY_SIZE(generic_jack_widgets),
+			},
+			{
+				.direction = {true, false},
+				.dai_name = "rt766-sdca-aif2",
+				.component_name = "rt766",
+				.dai_type = SOC_SDW_DAI_TYPE_AMP,
+				.dailink = {SOC_SDW_AMP_OUT_DAI_ID, SOC_SDW_UNUSED_DAI_ID},
+				.init = asoc_sdw_rt_amp_init,
+				.exit = asoc_sdw_rt_amp_exit,
+				.rtd_init = asoc_sdw_rt_mf_sdca_spk_rtd_init,
+				.controls = generic_spk_controls,
+				.num_controls = ARRAY_SIZE(generic_spk_controls),
+				.widgets = generic_spk_widgets,
+				.num_widgets = ARRAY_SIZE(generic_spk_widgets),
+			},
+			{
+				.direction = {false, true},
+				.dai_name = "rt766-sdca-aif3",
+				.dai_type = SOC_SDW_DAI_TYPE_MIC,
+				.dailink = {SOC_SDW_UNUSED_DAI_ID, SOC_SDW_DMIC_DAI_ID},
+				.rtd_init = asoc_sdw_rt_dmic_rtd_init,
+			},
+		},
+		.dai_num = 3,
+	},
+	{
+		.vendor_id = 0x025d,
+		.part_id = 0x767,
+		.name_prefix = "rt766",
+		.version_id = 4,
+		.dais =	{
+			{
+				.direction = {true, true},
+				.dai_name = "rt766-sdca-aif1",
+				.dai_type = SOC_SDW_DAI_TYPE_JACK,
+				.dailink = {SOC_SDW_JACK_OUT_DAI_ID, SOC_SDW_JACK_IN_DAI_ID},
+				.init = asoc_sdw_rt_sdca_jack_init,
+				.exit = asoc_sdw_rt_sdca_jack_exit,
+				.rtd_init = asoc_sdw_rt_sdca_jack_rtd_init,
+				.controls = generic_jack_controls,
+				.num_controls = ARRAY_SIZE(generic_jack_controls),
+				.widgets = generic_jack_widgets,
+				.num_widgets = ARRAY_SIZE(generic_jack_widgets),
+			},
+			{
+				.direction = {true, false},
+				.dai_name = "rt766-sdca-aif2",
+				.component_name = "rt766",
+				.dai_type = SOC_SDW_DAI_TYPE_AMP,
+				.dailink = {SOC_SDW_AMP_OUT_DAI_ID, SOC_SDW_UNUSED_DAI_ID},
+				.init = asoc_sdw_rt_amp_init,
+				.exit = asoc_sdw_rt_amp_exit,
+				.rtd_init = asoc_sdw_rt_mf_sdca_spk_rtd_init,
+				.controls = generic_spk_controls,
+				.num_controls = ARRAY_SIZE(generic_spk_controls),
+				.widgets = generic_spk_widgets,
+				.num_widgets = ARRAY_SIZE(generic_spk_widgets),
+			},
+			{
+				.direction = {false, true},
+				.dai_name = "rt766-sdca-aif3",
+				.dai_type = SOC_SDW_DAI_TYPE_MIC,
+				.dailink = {SOC_SDW_UNUSED_DAI_ID, SOC_SDW_DMIC_DAI_ID},
+				.rtd_init = asoc_sdw_rt_dmic_rtd_init,
+			},
+		},
+		.dai_num = 3,
+	},
+	{
+		.vendor_id = 0x025d,
+		.part_id = 0x766,
+		.name_prefix = "rt766",
+		.version_id = 3,
+		.dais =	{
+			{
+				.direction = {true, true},
+				.dai_name = "rt766-sdca-aif1",
+				.dai_type = SOC_SDW_DAI_TYPE_JACK,
+				.dailink = {SOC_SDW_JACK_OUT_DAI_ID, SOC_SDW_JACK_IN_DAI_ID},
+				.init = asoc_sdw_rt_sdca_jack_init,
+				.exit = asoc_sdw_rt_sdca_jack_exit,
+				.rtd_init = asoc_sdw_rt_sdca_jack_rtd_init,
+				.controls = generic_jack_controls,
+				.num_controls = ARRAY_SIZE(generic_jack_controls),
+				.widgets = generic_jack_widgets,
+				.num_widgets = ARRAY_SIZE(generic_jack_widgets),
+			},
+			{
+				.direction = {true, false},
+				.dai_name = "rt766-sdca-aif2",
+				.component_name = "rt766",
+				.dai_type = SOC_SDW_DAI_TYPE_AMP,
+				.dailink = {SOC_SDW_AMP_OUT_DAI_ID, SOC_SDW_UNUSED_DAI_ID},
+				.init = asoc_sdw_rt_amp_init,
+				.exit = asoc_sdw_rt_amp_exit,
+				.rtd_init = asoc_sdw_rt_mf_sdca_spk_rtd_init,
+				.controls = generic_spk_controls,
+				.num_controls = ARRAY_SIZE(generic_spk_controls),
+				.widgets = generic_spk_widgets,
+				.num_widgets = ARRAY_SIZE(generic_spk_widgets),
+			},
+			{
+				.direction = {false, true},
+				.dai_name = "rt766-sdca-aif3",
+				.dai_type = SOC_SDW_DAI_TYPE_MIC,
+				.dailink = {SOC_SDW_UNUSED_DAI_ID, SOC_SDW_DMIC_DAI_ID},
+				.rtd_init = asoc_sdw_rt_dmic_rtd_init,
+			},
+		},
+		.dai_num = 3,
+	},
+	{
+		.vendor_id = 0x025d,
+		.part_id = 0x766,
+		.name_prefix = "rt766",
+		.version_id = 4,
+		.dais =	{
+			{
+				.direction = {true, true},
+				.dai_name = "rt766-sdca-aif1",
+				.dai_type = SOC_SDW_DAI_TYPE_JACK,
+				.dailink = {SOC_SDW_JACK_OUT_DAI_ID, SOC_SDW_JACK_IN_DAI_ID},
+				.init = asoc_sdw_rt_sdca_jack_init,
+				.exit = asoc_sdw_rt_sdca_jack_exit,
+				.rtd_init = asoc_sdw_rt_sdca_jack_rtd_init,
+				.controls = generic_jack_controls,
+				.num_controls = ARRAY_SIZE(generic_jack_controls),
+				.widgets = generic_jack_widgets,
+				.num_widgets = ARRAY_SIZE(generic_jack_widgets),
+			},
+			{
+				.direction = {true, false},
+				.dai_name = "rt766-sdca-aif2",
+				.component_name = "rt766",
+				.dai_type = SOC_SDW_DAI_TYPE_AMP,
+				.dailink = {SOC_SDW_AMP_OUT_DAI_ID, SOC_SDW_UNUSED_DAI_ID},
+				.init = asoc_sdw_rt_amp_init,
+				.exit = asoc_sdw_rt_amp_exit,
+				.rtd_init = asoc_sdw_rt_mf_sdca_spk_rtd_init,
+				.controls = generic_spk_controls,
+				.num_controls = ARRAY_SIZE(generic_spk_controls),
+				.widgets = generic_spk_widgets,
+				.num_widgets = ARRAY_SIZE(generic_spk_widgets),
+			},
+			{
+				.direction = {false, true},
+				.dai_name = "rt766-sdca-aif3",
+				.dai_type = SOC_SDW_DAI_TYPE_MIC,
+				.dailink = {SOC_SDW_UNUSED_DAI_ID, SOC_SDW_DMIC_DAI_ID},
+				.rtd_init = asoc_sdw_rt_dmic_rtd_init,
+			},
+		},
+		.dai_num = 3,
+	},
 	{
 		.vendor_id = 0x019f,
 		.part_id = 0x8373,

-- 
2.55.0

