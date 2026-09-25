From: David Heidelberg <david@ixit.cz>
Date: Fri, 25 Sep 2026 17:28:06 +0200
Subject: [PATCH v5 5/7] ASoC: cs35l36: Implement set_tdm_slot to program RX
 and TX slots
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260925-pixel3-audio-v5-5-7ffb32c980bf@ixit.cz>
References: <20260925-pixel3-audio-v5-0-7ffb32c980bf@ixit.cz>
In-Reply-To: <20260925-pixel3-audio-v5-0-7ffb32c980bf@ixit.cz>
To: Srinivas Kandagatla <srini@kernel.org>, 
 Srinivas Kandagatla <srinivas.kandagatla@oss.qualcomm.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 David Rhodes <david.rhodes@cirrus.com>, 
 Richard Fitzgerald <rf@opensource.cirrus.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 David Rhodes <drhodes@opensource.cirrus.com>, 
 Conor Dooley <conor+dt@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: Viken Dadhaniya <viken.dadhaniya@oss.qualcomm.com>, 
 linux-sound@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, patches@opensource.cirrus.com, 
 devicetree@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>, 
 Charles Keepax <ckeepax@opensource.cirrus.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3455; i=david@ixit.cz;
 h=from:subject:message-id; bh=QCDauQWrYVk2oMrA2lmeV2L5dI8FaDlTbmA3MpK6x3I=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqtpMFui09s2ua1oS+Xbo9QMefjsbzP0xS7PGiX
 XTkMIrBS52JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaraTBQAKCRBgAj/E00kg
 cvXpD/9s+sM3vbiqdsWkPODhuwMFKApCHeFupH6S8KJMCamBQkyFeChv6W0np4WMGtCrn5T7MCx
 Egn/nMjIJN4O4IOWIJ4vg4z+rC+W7jOONZdVRmBaSpkYG0R2GyWP4F94/BCAkEjMtjURqyKjI5t
 5VcQH/RkFGsew+KzS4rw1XEjSyuM13ZuG0PHjZSQfnZtnk0PY4UbYzubwnNQ8rwmTOtzZpvQK1e
 GbNR2rNvRATgyoklPCKpWUWzb6Wa8+hDsQ0BPXxcJWWmNOPrb6cGzbsZzxTw9oE9c/EUsifOvzs
 2QsR1aenPOsZ7rJAZL8aqg4lSb1hUy9DrjOG024xfLAef40lEA6qkAEJ1yhDKF/bg/drnL0UIw6
 FBJPT7LEXATx6NcUFN56AF1ng6YMAGD4BIIROb2tupDXTYvK0yYmhUGsG1Dkd0uccktlJG1UQar
 8dnpFvhVsXl7spMXt7x+GzswMaKqjQjI0ZbdWmFQflcYfHNJjzKA/ZWbtMeIk7G8HFQ6OGBxxtr
 DXqDUB4b7VvKubzm2BqE6FzPhEH6un0wIfCUONA62+g6AzL7mtqSNnSZpSmenqOn9bD1oWjXXqr
 NwP1YR9XsmdLyJQwrqekv10x8b6de1yMBlX82P3dOri8JWZ9O6x3RNgsZNkUnsdG+yeFgr6eaS7
 APldtYyto2dlxeg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Program the ASP RX and TX slot registers from the TDM masks passed by
the machine driver. Each set bit in a mask names a slot; codec channels
are assigned to those slots in order, ASPRX1 taking the first RX slot
and ASPTX1..TX8 the first eight TX slots, with a warning if the mask
names more slots than the device has channels.

Passing slots == 0 or an empty mask restores the hardware defaults,
ASPRX1 in slot 0 and ASPTX1..TX8 in slots 0..7.

This lets a machine driver with several amplifiers on one bus, such as
sdm845 with two CS35L36, put each amplifier on its own RX slot and keep
their TX slots from colliding.

Assisted-by: LLM
Reviewed-by: Charles Keepax <ckeepax@opensource.cirrus.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 sound/soc/codecs/cs35l36.c | 44 ++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 44 insertions(+)

diff --git a/sound/soc/codecs/cs35l36.c b/sound/soc/codecs/cs35l36.c
index 170588be4dbe3..5fc8ec292e3c4 100644
--- a/sound/soc/codecs/cs35l36.c
+++ b/sound/soc/codecs/cs35l36.c
@@ -942,32 +942,76 @@ static const struct cs35l36_pll_config *cs35l36_get_clk_config(
 	for (i = 0; i < ARRAY_SIZE(cs35l36_pll_sysclk); i++) {
 		if (cs35l36_pll_sysclk[i].freq == freq)
 			return &cs35l36_pll_sysclk[i];
 	}
 
 	return NULL;
 }
 
+static void cs35l36_mask_to_slots(struct cs35l36_private *cs35l36,
+				  unsigned long mask, unsigned int base_reg,
+				  unsigned int nchan)
+{
+	unsigned int chan = 0, shift;
+	int slot;
+
+	/* Two 6-bit slot fields per register, at bits 0 and 16 */
+	for_each_set_bit(slot, &mask, BITS_PER_TYPE(mask)) {
+		if (chan == nchan) {
+			dev_warn(cs35l36->dev,
+				 "Too many slots in TDM mask: %lx\n", mask);
+			return;
+		}
+
+		shift = (chan % 2) * CS35L36_ASP_TX2_SLOT_SHIFT;
+		regmap_update_bits(cs35l36->regmap, base_reg + (chan / 2) * 4,
+				   CS35L36_ASP_RX1_SLOT_MASK << shift,
+				   slot << shift);
+		chan++;
+	}
+}
+
+static int cs35l36_set_tdm_slot(struct snd_soc_dai *dai,
+				unsigned int tx_mask, unsigned int rx_mask,
+				int slots, int slot_width)
+{
+	struct cs35l36_private *cs35l36 =
+			snd_soc_component_get_drvdata(dai->component);
+
+	/* Note: rx/tx is from point of view of the CPU end */
+	if (!slots || !rx_mask)
+		rx_mask = BIT(0);		/* ASPRX1 in slot 0 */
+
+	if (!slots || !tx_mask)
+		tx_mask = GENMASK(7, 0);	/* ASPTX1..8 in slots 0..7 */
+
+	cs35l36_mask_to_slots(cs35l36, rx_mask, CS35L36_ASP_RX1_SLOT, 1);
+	cs35l36_mask_to_slots(cs35l36, tx_mask, CS35L36_ASP_TX1_TX2_SLOT, 8);
+
+	return 0;
+}
+
 static const u64 cs35l36_selectable_formats =
 	SND_SOC_POSSIBLE_DAIFMT_I2S	|
 	SND_SOC_POSSIBLE_DAIFMT_DSP_A	|
 	SND_SOC_POSSIBLE_DAIFMT_GATED	|
 	SND_SOC_POSSIBLE_DAIFMT_CONT	|
 	SND_SOC_POSSIBLE_DAIFMT_NB_NF	|
 	SND_SOC_POSSIBLE_DAIFMT_NB_IF	|
 	SND_SOC_POSSIBLE_DAIFMT_IB_NF	|
 	SND_SOC_POSSIBLE_DAIFMT_IB_IF;
 
 static const struct snd_soc_dai_ops cs35l36_ops = {
 	.set_fmt = cs35l36_set_dai_fmt,
 	.hw_params = cs35l36_pcm_hw_params,
 	.set_sysclk = cs35l36_dai_set_sysclk,
 	.auto_selectable_formats = &cs35l36_selectable_formats,
 	.num_auto_selectable_formats = 1,
+	.set_tdm_slot = cs35l36_set_tdm_slot,
 };
 
 #define CS35L36_RATES (		    \
 	SNDRV_PCM_RATE_8000_48000 | \
 	SNDRV_PCM_RATE_12000 |	    \
 	SNDRV_PCM_RATE_24000 |	    \
 	SNDRV_PCM_RATE_88200 |	    \
 	SNDRV_PCM_RATE_96000 |	    \

-- 
2.55.0

