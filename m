From: Ilia Snezhkov <iasnezhkov@gmail.com>
To: broonie@kernel.org, lgirdwood@gmail.com
Cc: perex@perex.cz, tiwai@suse.com, matthias.bgg@gmail.com, 
 angelogioacchino.delregno@collabora.com, linux-sound@vger.kernel.org, 
 linux-mediatek@lists.infradead.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org
Subject: [PATCH] ASoC: mediatek: common: bound the memif lookup in
 mtk_afe_pcm_pointer()
Date: Thu, 26 Nov 2026 00:07:08 +0000
Message-Id: <20261126000708.15974-1-iasnezhkov@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795651628; l=2919;
 i=iasnezhkov@gmail.com; s=mindone2026; h=from:subject:message-id;
 bh=/MSilR+p9QlLbiiOAiffhnckpIPuLQJEn5v5/pYSrPg=;
 b=ZpWJEpubgE9tN5k9iITzX5MCuJ0E8v4Hefkrg+/4X+/g7f7N+BQsyxRJOAWDl8QQ8QvDAsL0R
 6lf0kbRmTs7DSyCS/14KARp2KBgP5HfWACViFMm0kVvWvKw7lPJQVgf
X-Developer-Key: i=iasnezhkov@gmail.com; a=ed25519;
 pk=hQgXfiWi4ukk2jh4BHu1vRVhg9BUivo//AFp50AKMag=
X-Endpoint-Received: by B4 Relay for iasnezhkov@gmail.com/mindone2026 with auth_id=1643
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

mtk_afe_pcm_pointer() indexes afe->memif[] with the id of the front-end
CPU DAI. The hostless front ends registered by mt6797, mt8183 and mt8186
(e.g. MT8186_DAI_HOSTLESS_LPBK, MT8183_DAI_HOSTLESS_SPEECH) have ids at
or above the memif count, so their PCMs read past the end of the
afe->memif array and then dereference whatever memif->data that yields.

The pointer callback is reached whenever the PCM core updates the
hardware pointer of such a running stream, for instance through
SNDRV_PCM_IOCTL_HWSYNC, a status query or a read. On an MT6789 phone
with the same common code, capturing from the Hostless_Speech PCM
after starting it oopsed in mtk_afe_pcm_pointer() on a NULL memif->data.

A hostless front end has no memory interface and no position to report:
return 0 for a CPU DAI id outside the memif table.

Found on hardware and drafted with an AI coding assistant.

Fixes: 283b612429a2 ("ASoC: mediatek: implement mediatek common structure")
Signed-off-by: Ilia Snezhkov <iasnezhkov@gmail.com>
---

Notes:
    Observed with the downstream (MediaTek BSP-derived) copy of this file on an
    MT6789 phone running android17-6.18 (6.18.32): tinycap on the hostless
    speech PCM after start -> mtk_afe_pcm_pointer+0x60, NULL + 0x10. Our
    downstream fix also returns 0 for a memif without data; upstream every
    memif in range has data, so only the range check is needed here.
    Not reproduced on mt8183/mt8186 hardware; not compile-tested in this form.

 sound/soc/mediatek/common/mtk-afe-platform-driver.c | 9 +++++++--
 1 file changed, 7 insertions(+), 2 deletions(-)

diff --git a/sound/soc/mediatek/common/mtk-afe-platform-driver.c b/sound/soc/mediatek/common/mtk-afe-platform-driver.c
index 7dd93d4..7877d80 100644
--- a/sound/soc/mediatek/common/mtk-afe-platform-driver.c
+++ b/sound/soc/mediatek/common/mtk-afe-platform-driver.c
@@ -82,8 +82,8 @@ snd_pcm_uframes_t mtk_afe_pcm_pointer(struct snd_soc_component *component,
 {
 	struct snd_soc_pcm_runtime *rtd = snd_soc_substream_to_rtd(substream);
 	struct mtk_base_afe *afe = snd_soc_component_get_drvdata(component);
-	struct mtk_base_afe_memif *memif = &afe->memif[snd_soc_rtd_to_cpu(rtd, 0)->id];
-	const struct mtk_base_memif_data *memif_data = memif->data;
+	int id = snd_soc_rtd_to_cpu(rtd, 0)->id;
+	const struct mtk_base_memif_data *memif_data;
 	struct regmap *regmap = afe->regmap;
 	struct device *dev = afe->dev;
 	unsigned int hw_ptr_lower32 = 0, hw_ptr_upper32 = 0;
@@ -92,6 +92,11 @@ snd_pcm_uframes_t mtk_afe_pcm_pointer(struct snd_soc_component *component,
 	int ret;
 	unsigned long long pcm_ptr_bytes = 0;
 
+	if (id < 0 || id >= afe->memif_size)
+		return 0;
+
+	memif_data = afe->memif[id].data;
+
 	ret = regmap_read(regmap, memif_data->reg_ofs_cur, &hw_ptr_lower32);
 	if (ret) {
 		dev_err(dev, "%s hw_ptr_lower32 err\n", __func__);
-- 
2.54.0 (Apple Git-157)


