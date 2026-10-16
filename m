From: HuskerMinion <mocker-mug-unwoven@duck.com>
Date: Fri, 16 Oct 2026 02:14:01 -0600
Subject: [PATCH 1/2] ASoC: mediatek: mt8183: Leave cache-only mode before
 enabling clocks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261016-mt8183-afe-fixes-v1-1-f0db51e0c073@duck.com>
References: <20261016-mt8183-afe-fixes-v1-0-f0db51e0c073@duck.com>
In-Reply-To: <20261016-mt8183-afe-fixes-v1-0-f0db51e0c073@duck.com>
To: Mark Brown <broonie@kernel.org>, Liam Girdwood <lgirdwood@gmail.com>
Cc: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 linux-sound@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, HuskerMinion <mocker-mug-unwoven@duck.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792138468; l=2642;
 i=mocker-mug-unwoven@duck.com; s=20261016; h=from:subject:message-id;
 bh=zfpo94JkGvQ2yQUBuXqzym/mB6mYvui+lp17sFP9VUg=;
 b=SHKWVz3Ac5OanWSlHksMbUBv4Otf/d62j9t1248uqxkqmUt08CThxbFzD1ksClZrJ7WQGwJuZ
 eZxRoSbAYFSAj41XHL/f8/m7MMh+vZ77DBTQK/zRLF7Qm7pbrb3Dtjt
X-Developer-Key: i=mocker-mug-unwoven@duck.com; a=ed25519;
 pk=Q7l9BnP4XnFimCK28K+NVowcECqTaJNXicdBAInot0k=
X-Endpoint-Received: by B4 Relay for mocker-mug-unwoven@duck.com/20261016 with auth_id=1206
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The audiosys clock gates are bits in AUDIO_TOP_CON0 and AUDIO_TOP_CON1.
The clock driver writes them through the audiosys syscon regmap, which
is the same regmap the AFE driver uses. The AFE marks both registers
volatile, so while the regmap is cache-only, regmap_update_bits() on
them returns -EBUSY and nothing reaches the hardware. The MediaTek gate
clock ops ignore that error.

mt8183_afe_runtime_resume() calls mt8183_afe_enable_clock() first and
only then takes the regmap out of cache-only mode. After probe the
regmap is always cache-only at that point, so the gate enables are
dropped. The clock framework then counts the AFE and I2S gates as
enabled while they are still closed in hardware.

On the Amazon Echo Show 8 (2nd gen) the bootloader leaves these gates
closed. Playback and capture never start: the memif current pointer
stays at 0, no AFE interrupt fires and aplay fails with an I/O error.
clk_summary lists aud_afe and aud_i2s1 as enabled, but with hardware
enable N, and their power-down bits in AUDIO_TOP_CON0 are still set.

Leave cache-only mode before enabling the clocks, and go back to
cache-only mode if enabling them fails. The bypass case used during
probe is unchanged.

Fixes: a94aec035a12 ("ASoC: mediatek: mt8183: add platform driver")
Cc: stable@vger.kernel.org
Signed-off-by: HuskerMinion <mocker-mug-unwoven@duck.com>
---
 sound/soc/mediatek/mt8183/mt8183-afe-pcm.c | 16 +++++++++++++---
 1 file changed, 13 insertions(+), 3 deletions(-)

diff --git a/sound/soc/mediatek/mt8183/mt8183-afe-pcm.c b/sound/soc/mediatek/mt8183/mt8183-afe-pcm.c
index d8938542b..d6175da3b 100644
--- a/sound/soc/mediatek/mt8183/mt8183-afe-pcm.c
+++ b/sound/soc/mediatek/mt8183/mt8183-afe-pcm.c
@@ -706,16 +706,26 @@ static int mt8183_afe_runtime_resume(struct device *dev)
 {
 	struct mtk_base_afe *afe = dev_get_drvdata(dev);
 	struct mt8183_afe_private *afe_priv = afe->platform_priv;
+	bool reg_ctl = afe->regmap && !afe_priv->pm_runtime_bypass_reg_ctl;
 	int ret;
 
+	/*
+	 * The audiosys clock gates are written through this same regmap and
+	 * are volatile, so their writes are dropped while it is cache-only.
+	 */
+	if (reg_ctl)
+		regcache_cache_only(afe->regmap, false);
+
 	ret = mt8183_afe_enable_clock(afe);
-	if (ret)
+	if (ret) {
+		if (reg_ctl)
+			regcache_cache_only(afe->regmap, true);
 		return ret;
+	}
 
-	if (!afe->regmap || afe_priv->pm_runtime_bypass_reg_ctl)
+	if (!reg_ctl)
 		goto skip_regmap;
 
-	regcache_cache_only(afe->regmap, false);
 	regcache_sync(afe->regmap);
 
 	/* enable audio sys DCM for power saving */

-- 
2.43.0

