From: Nikita Shubin <nikita.shubin@maquefel.me>
Date: Mon, 09 Sep 2024 11:10:53 +0300
Subject: [PATCH v12 28/38] ASoC: ep93xx: Drop legacy DMA support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240909-ep93xx-v12-28-e86ab2423d4b@maquefel.me>
References: <20240909-ep93xx-v12-0-e86ab2423d4b@maquefel.me>
In-Reply-To: <20240909-ep93xx-v12-0-e86ab2423d4b@maquefel.me>
To: Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Nikita Shubin <nikita.shubin@maquefel.me>, 
 Alexander Sverdlin <alexander.sverdlin@gmail.com>
Cc: linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.13-dev-e3e53
X-Developer-Signature: v=1; a=ed25519-sha256; t=1725869532; l=3001;
 i=nikita.shubin@maquefel.me; s=20230718; h=from:subject:message-id;
 bh=SYU0FfCpDAQ8R3Z8Qf0jhP48bWMjlrK6VfAOntLJB4w=;
 b=k9YI3GtfdKBqw94BWhW5xJoJvg4phs99a1pZ31SabZgGcAE0Blo/AY5b6lYYutcamYKJJqt8GLlA
 LXsk4uMNAW66pLiDJm2PgIrdnCAWY+4Q0xOl8GEVOiRUopfqbkND
X-Developer-Key: i=nikita.shubin@maquefel.me; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for nikita.shubin@maquefel.me/20230718 with auth_id=65
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Alexander Sverdlin <alexander.sverdlin@gmail.com>

And rely on OF DMA.

Signed-off-by: Alexander Sverdlin <alexander.sverdlin@gmail.com>
Signed-off-by: Nikita Shubin <nikita.shubin@maquefel.me>
---
 sound/soc/cirrus/ep93xx-i2s.c | 19 -------------------
 sound/soc/cirrus/ep93xx-pcm.c | 19 +------------------
 2 files changed, 1 insertion(+), 37 deletions(-)

diff --git a/sound/soc/cirrus/ep93xx-i2s.c b/sound/soc/cirrus/ep93xx-i2s.c
index 522de4b80293..9e83cdf8a943 100644
--- a/sound/soc/cirrus/ep93xx-i2s.c
+++ b/sound/soc/cirrus/ep93xx-i2s.c
@@ -24,7 +24,6 @@
 #include <sound/initval.h>
 #include <sound/soc.h>
 
-#include <linux/platform_data/dma-ep93xx.h>
 #include <linux/soc/cirrus/ep93xx.h>
 
 #include "ep93xx-pcm.h"
@@ -80,19 +79,6 @@ struct ep93xx_i2s_info {
 	struct snd_dmaengine_dai_dma_data dma_params_tx;
 };
 
-static struct ep93xx_dma_data ep93xx_i2s_dma_data[] = {
-	[SNDRV_PCM_STREAM_PLAYBACK] = {
-		.name		= "i2s-pcm-out",
-		.port		= EP93XX_DMA_I2S1,
-		.direction	= DMA_MEM_TO_DEV,
-	},
-	[SNDRV_PCM_STREAM_CAPTURE] = {
-		.name		= "i2s-pcm-in",
-		.port		= EP93XX_DMA_I2S1,
-		.direction	= DMA_DEV_TO_MEM,
-	},
-};
-
 static inline void ep93xx_i2s_write_reg(struct ep93xx_i2s_info *info,
 					unsigned reg, unsigned val)
 {
@@ -198,11 +184,6 @@ static int ep93xx_i2s_dai_probe(struct snd_soc_dai *dai)
 {
 	struct ep93xx_i2s_info *info = snd_soc_dai_get_drvdata(dai);
 
-	info->dma_params_tx.filter_data =
-		&ep93xx_i2s_dma_data[SNDRV_PCM_STREAM_PLAYBACK];
-	info->dma_params_rx.filter_data =
-		&ep93xx_i2s_dma_data[SNDRV_PCM_STREAM_CAPTURE];
-
 	snd_soc_dai_init_dma_data(dai,	&info->dma_params_tx,
 					&info->dma_params_rx);
 
diff --git a/sound/soc/cirrus/ep93xx-pcm.c b/sound/soc/cirrus/ep93xx-pcm.c
index fa72acd8d334..5ecb4671cbba 100644
--- a/sound/soc/cirrus/ep93xx-pcm.c
+++ b/sound/soc/cirrus/ep93xx-pcm.c
@@ -18,8 +18,6 @@
 #include <sound/soc.h>
 #include <sound/dmaengine_pcm.h>
 
-#include <linux/platform_data/dma-ep93xx.h>
-
 #include "ep93xx-pcm.h"
 
 static const struct snd_pcm_hardware ep93xx_pcm_hardware = {
@@ -35,30 +33,15 @@ static const struct snd_pcm_hardware ep93xx_pcm_hardware = {
 	.fifo_size		= 32,
 };
 
-static bool ep93xx_pcm_dma_filter(struct dma_chan *chan, void *filter_param)
-{
-	struct ep93xx_dma_data *data = filter_param;
-
-	if (data->direction == ep93xx_dma_chan_direction(chan)) {
-		chan->private = data;
-		return true;
-	}
-
-	return false;
-}
-
 static const struct snd_dmaengine_pcm_config ep93xx_dmaengine_pcm_config = {
 	.pcm_hardware = &ep93xx_pcm_hardware,
-	.compat_filter_fn = ep93xx_pcm_dma_filter,
 	.prealloc_buffer_size = 131072,
 };
 
 int devm_ep93xx_pcm_platform_register(struct device *dev)
 {
 	return devm_snd_dmaengine_pcm_register(dev,
-		&ep93xx_dmaengine_pcm_config,
-		SND_DMAENGINE_PCM_FLAG_NO_DT |
-		SND_DMAENGINE_PCM_FLAG_COMPAT);
+		&ep93xx_dmaengine_pcm_config, 0);
 }
 EXPORT_SYMBOL_GPL(devm_ep93xx_pcm_platform_register);
 

-- 
2.43.2

