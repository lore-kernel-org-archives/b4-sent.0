From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 07:16:58 +0000
Subject: [PATCH 1/2] ASoC: rockchip: i2s-tdm: Register the PCM before the
 DAI
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-asoc-rockchip-i2s-tdm-v1-1-f32951b3c527@gmail.com>
References: <20261110-asoc-rockchip-i2s-tdm-v1-0-f32951b3c527@gmail.com>
In-Reply-To: <20261110-asoc-rockchip-i2s-tdm-v1-0-f32951b3c527@gmail.com>
To: Nicolas Frattaroli <frattaroli.nicolas@gmail.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Heiko Stuebner <heiko@sntech.de>
Cc: linux-rockchip@lists.infradead.org, linux-sound@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794295018; l=2286;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=18X4gDoDBalS2YNh4G/P0K7m7mnHS2iod12BwMjjV5A=;
 b=sOQmVjwZd4x1ZJ52gHSqxjkg+olv7zyeAxLb5RGz+5Kw1subi7A69KGH3veHzNI0V69UAsCPw
 bKN6z1fU26VDXVcLkifXLiwBYOdCGMIv3nhshlv+xOkEYy1reJ22w+3
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A card that was registered before its CPU DAI is put on the unbind list
by snd_soc_bind_card(), and snd_soc_component_register() retries the
bind as soon as any component is added. The DAI component of the I2S
controller satisfies the DAI link's platform, which defaults to the CPU
of_node, so the card binds right after the DAI is registered and before
the dmaengine PCM component of the same device exists. The PCM component
is then never added to the runtime, runtime->hw stays empty and every
open of the PCM fails with -EINVAL from
snd_pcm_hw_constraints_complete(), without any error being logged.

This is seen on RK3588 when the HDMI codec probes before the I2S
controller of the HDMI sound card: the card has no "dma:fddf0000.i2s"
component and "aplay -D hw:0,0" fails with "Invalid argument".

Register the dmaengine PCM first, as rockchip_spdif already does, so the
card finds both components when the DAI appears.

Fixes: 081068fd6414 ("ASoC: rockchip: add support for i2s-tdm controller")
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 sound/soc/rockchip/rockchip_i2s_tdm.c | 13 +++++++++----
 1 file changed, 9 insertions(+), 4 deletions(-)

diff --git a/sound/soc/rockchip/rockchip_i2s_tdm.c b/sound/soc/rockchip/rockchip_i2s_tdm.c
index 983319a538b1..0abd200a4268 100644
--- a/sound/soc/rockchip/rockchip_i2s_tdm.c
+++ b/sound/soc/rockchip/rockchip_i2s_tdm.c
@@ -1371,13 +1371,18 @@ static int rockchip_i2s_tdm_probe(struct platform_device *pdev)
 	if (i2s_tdm->soc_data && i2s_tdm->soc_data->init)
 		i2s_tdm->soc_data->init(&pdev->dev, res->start);
 
-	ret = devm_snd_soc_register_component(&pdev->dev,
-					      &rockchip_i2s_tdm_component,
-					      i2s_tdm->dai, 1);
+	/*
+	 * Register the PCM before the DAI: adding the DAI component can bind a
+	 * waiting card right away, and the card must find the PCM component
+	 * then or its DAI link ends up without one.
+	 */
+	ret = devm_snd_dmaengine_pcm_register(&pdev->dev, NULL, 0);
 	if (ret)
 		goto err_suspend;
 
-	ret = devm_snd_dmaengine_pcm_register(&pdev->dev, NULL, 0);
+	ret = devm_snd_soc_register_component(&pdev->dev,
+					      &rockchip_i2s_tdm_component,
+					      i2s_tdm->dai, 1);
 	if (ret)
 		goto err_suspend;
 

-- 
2.55.0

