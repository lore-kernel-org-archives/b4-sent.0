From: David Heidelberg <david@ixit.cz>
Date: Sun, 05 Jul 2026 22:06:55 +0200
Subject: [PATCH RFC 5/6] ASoC: cs35l36: Implement set_tdm_slot to program
 RX slot register
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260705-pixel3-audio-v1-5-3b66f33859f1@ixit.cz>
References: <20260705-pixel3-audio-v1-0-3b66f33859f1@ixit.cz>
In-Reply-To: <20260705-pixel3-audio-v1-0-3b66f33859f1@ixit.cz>
To: Srinivas Kandagatla <srini@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 David Rhodes <david.rhodes@cirrus.com>, 
 Richard Fitzgerald <rf@opensource.cirrus.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 David Rhodes <drhodes@opensource.cirrus.com>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-sound@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, patches@opensource.cirrus.com, 
 devicetree@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1599; i=david@ixit.cz;
 h=from:subject:message-id; bh=Y1j5N1bsyvti4tApXHFOSmQqrynSPavAfsDRdarjbcg=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqSrmNvtTDzkkUez/EZkvPO+DARcRMgCrhrAtOH
 zTVlGJDp0KJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCakq5jQAKCRBgAj/E00kg
 cqv4D/9wBNnggajHJdc6377I+XzjGoSnLbVnz/hix5OpkOgS9eN7/TtyqNQpKhJDW6pYIw5P+/H
 Fb4C6tCRNEZtgGMBKZYDBir4Yix2JOgRQQKmzauJjjr8/NQZQyJA4YJ603E8NkhdKcc80MQfJlq
 TeuoJwv6xfpP5EZUpDPvi6J/dwC/hdbrf57nsNEaWpqHEVqcqLrupuOyM9iNVEJ3BhbpaIZy644
 jsHmyRyIYIVPjfWtl7myLl6VbleCuT4kNIYJJ2aFBQ5+kvg0rsBjlZYcikZAK08OTgImhJM+k3W
 PIwuj0Kp1zT+iL2vOh0YxtMWScBpWlMhns15VQjOW7xMXve+xFe80TkX21aidIN3U9VD5OZlsgc
 H5BjPMfFU4LMflqcCQGeB6fU5U/E5nTjDsZXVgY/vzIjRHpM5QPcTXV14eyGIGiZPHscdnQBZlv
 j5W2k89PiVgwlp8tkGQhFVooM/DP1R78mAscVEwaPKPHJBRU9wNyCWhkmcdnjxENf8SN1ASnDVm
 MJhyJ6C/FHjtvK35tMsOYODnMUAWsYRacF8M7MCw7jRQPUlr2FLphwf0e1GyJbSv0HkJkjxLB8T
 tIojJOnXz907qsU6wIED0qApTyJWmAApg1x0K6RkOpW7Sg7cX8nxb51GfJ1+DtfL9MatP4GBklL
 /sNvq7OZq3XOONg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Program ASP_RX1_SLOT with the first set bit of rx_mask so the
amplifier listens on the correct TDM slot when configured by
machine drivers.

Assisted-by: Claude:claude-4.6-opus
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 sound/soc/codecs/cs35l36.c | 16 ++++++++++++++++
 1 file changed, 16 insertions(+)

diff --git a/sound/soc/codecs/cs35l36.c b/sound/soc/codecs/cs35l36.c
index 89645327945f1..944f4cb5763e4 100644
--- a/sound/soc/codecs/cs35l36.c
+++ b/sound/soc/codecs/cs35l36.c
@@ -942,20 +942,36 @@ static const struct cs35l36_pll_config *cs35l36_get_clk_config(
 	for (i = 0; i < ARRAY_SIZE(cs35l36_pll_sysclk); i++) {
 		if (cs35l36_pll_sysclk[i].freq == freq)
 			return &cs35l36_pll_sysclk[i];
 	}
 
 	return NULL;
 }
 
+static int cs35l36_set_tdm_slot(struct snd_soc_dai *dai,
+				    unsigned int tx_mask, unsigned int rx_mask,
+				    int slots, int slot_width)
+{
+	struct cs35l36_private *cs35l36 =
+			snd_soc_component_get_drvdata(dai->component);
+
+	if (rx_mask)
+		regmap_update_bits(cs35l36->regmap, CS35L36_ASP_RX1_SLOT,
+				   CS35L36_ASP_RX1_SLOT_MASK,
+				   ffs(rx_mask) - 1);
+
+	return 0;
+}
+
 static const struct snd_soc_dai_ops cs35l36_ops = {
 	.set_fmt = cs35l36_set_dai_fmt,
 	.hw_params = cs35l36_pcm_hw_params,
 	.set_sysclk = cs35l36_dai_set_sysclk,
+	.set_tdm_slot = cs35l36_set_tdm_slot,
 };
 
 #define CS35L36_RATES (		    \
 	SNDRV_PCM_RATE_8000_48000 | \
 	SNDRV_PCM_RATE_12000 |	    \
 	SNDRV_PCM_RATE_24000 |	    \
 	SNDRV_PCM_RATE_88200 |	    \
 	SNDRV_PCM_RATE_96000 |	    \

-- 
2.53.0

