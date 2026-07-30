From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Thu, 30 Jul 2026 15:23:14 +0100
Subject: [PATCH 7/9] ALSA: pcm_dmaengine: Use dma_slave_caps bus width
 helpers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260730-dmaengine-support-wider-dma-masks-v1-7-3732f1f9d9ca@analog.com>
References: <20260730-dmaengine-support-wider-dma-masks-v1-0-3732f1f9d9ca@analog.com>
In-Reply-To: <20260730-dmaengine-support-wider-dma-masks-v1-0-3732f1f9d9ca@analog.com>
To: dmaengine@vger.kernel.org, linux-iio@vger.kernel.org
Cc: Vinod Koul <vkoul@kernel.org>, Frank Li <Frank.Li@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785421644; l=1956;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=n/fiHizGGytrGMky+zm6a28M1rEvWtnfiQdy1LDRAco=;
 b=tO1aDn+ij/KiNvywdmFxw0Y3BU1eXHYMXTJCgJP1x9lzj1bjHmuj9bfMPuwB/3unZgmk0/p3D
 kzz13xd5gbBDB8EQFb5wN5qtpMlvs2o14Xw/MRjXpEgRfH1fd1kTz13
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use the dma_slave_caps bus width helpers instead of reading the legacy
src_addr_widths and dst_addr_widths masks directly.

Keep the existing default assumption of 1, 2 and 4 byte widths when the
DMA channel does not report slave capabilities.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 sound/core/pcm_dmaengine.c | 14 ++++++++------
 1 file changed, 8 insertions(+), 6 deletions(-)

diff --git a/sound/core/pcm_dmaengine.c b/sound/core/pcm_dmaengine.c
index 1306b04be171..37468f4643bc 100644
--- a/sound/core/pcm_dmaengine.c
+++ b/sound/core/pcm_dmaengine.c
@@ -409,15 +409,17 @@ int snd_dmaengine_pcm_refine_runtime_hwparams(
 	struct dma_chan *chan)
 {
 	struct dma_slave_caps dma_caps;
-	u32 addr_widths = BIT(DMA_SLAVE_BUSWIDTH_1_BYTE) |
-			  BIT(DMA_SLAVE_BUSWIDTH_2_BYTES) |
-			  BIT(DMA_SLAVE_BUSWIDTH_4_BYTES);
+	DECLARE_DMA_BUS_WIDTHS(bus_widths) = {};
 	snd_pcm_format_t i;
 	int ret = 0;
 
 	if (!hw || !chan || !dma_data)
 		return -EINVAL;
 
+	__set_bit(DMA_SLAVE_BUSWIDTH_1_BYTE, bus_widths);
+	__set_bit(DMA_SLAVE_BUSWIDTH_2_BYTES, bus_widths);
+	__set_bit(DMA_SLAVE_BUSWIDTH_4_BYTES, bus_widths);
+
 	ret = dma_get_slave_caps(chan, &dma_caps);
 	if (ret == 0) {
 		if (dma_caps.cmd_pause && dma_caps.cmd_resume)
@@ -426,9 +428,9 @@ int snd_dmaengine_pcm_refine_runtime_hwparams(
 			hw->info |= SNDRV_PCM_INFO_BATCH;
 
 		if (substream->stream == SNDRV_PCM_STREAM_PLAYBACK)
-			addr_widths = dma_caps.dst_addr_widths;
+			dma_slave_caps_copy_dst_widths(&dma_caps, bus_widths);
 		else
-			addr_widths = dma_caps.src_addr_widths;
+			dma_slave_caps_copy_src_widths(&dma_caps, bus_widths);
 	}
 
 	/*
@@ -460,7 +462,7 @@ int snd_dmaengine_pcm_refine_runtime_hwparams(
 			case 24:
 			case 32:
 			case 64:
-				if (addr_widths & (1 << (bits / 8)))
+				if (test_bit(bits / 8, bus_widths))
 					hw->formats |= pcm_format_to_bits(i);
 				break;
 			default:

-- 
2.55.0

