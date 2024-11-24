From: Sasha Finkelstein <fnkl.kernel@gmail.com>
Date: Sun, 24 Nov 2024 16:48:28 +0100
Subject: [PATCH] dmaengine: apple-admac: Avoid accessing registers in probe
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241124-admac-power-v1-1-58f2165a4d55@gmail.com>
X-B4-Tracking: v=1; b=H4sIAMtKQ2cC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxNDQyMT3cSU3MRk3YL88tQiXfM0Y6Nko0RDC1ODRCWgjoKi1LTMCrBp0bG
 1tQAYOnwwXQAAAA==
X-Change-ID: 20241124-admac-power-7f32c2a1850a
To: Hector Martin <marcan@marcan.st>, Sven Peter <sven@svenpeter.dev>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, Vinod Koul <vkoul@kernel.org>, 
 =?utf-8?q?Martin_Povi=C5=A1er?= <povik+lin@cutebit.org>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 dmaengine@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sasha Finkelstein <fnkl.kernel@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732463315; l=1574;
 i=fnkl.kernel@gmail.com; s=20241124; h=from:subject:message-id;
 bh=fzYr2mOnaTThuwM8nzcfIvcWzFVACOsEp4j04pez3Us=;
 b=RMWELGTjitjliRQGKVjh9SJeijRLX/Kvt/3E/LLmmy3YJdBhs3xVJh9TFlJpN0Hg+IxvsqdiH
 zT/+9C3lwZEAHnQOhKvdsR7FrdibkKVGBpZb3XTTIDy4zEzccMhr/E3
X-Developer-Key: i=fnkl.kernel@gmail.com; a=ed25519;
 pk=aSkp1PdZ+eF4jpMO6oLvz/YfT5XkBUneWwyhQrOgmsU=
X-Endpoint-Received: by B4 Relay for fnkl.kernel@gmail.com/20241124 with auth_id=283
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ADMAC attached to the AOP has complex power sequencing, and is
power gated when the probe callback runs. Move the register reads
to other functions, where we can guarantee that the hardware is
switched on.

Fixes: 568aa6dd641f ("dmaengine: apple-admac: Allocate cache SRAM to channels")
Signed-off-by: Sasha Finkelstein <fnkl.kernel@gmail.com>
---
 drivers/dma/apple-admac.c | 7 ++-----
 1 file changed, 2 insertions(+), 5 deletions(-)

diff --git a/drivers/dma/apple-admac.c b/drivers/dma/apple-admac.c
index 9588773dd2eb670a2f6115fdaef39a0e88248015..037ec38730cf980eee11ebb8ec17be7623879cf8 100644
--- a/drivers/dma/apple-admac.c
+++ b/drivers/dma/apple-admac.c
@@ -153,6 +153,8 @@ static int admac_alloc_sram_carveout(struct admac_data *ad,
 {
 	struct admac_sram *sram;
 	int i, ret = 0, nblocks;
+	ad->txcache.size = readl_relaxed(ad->base + REG_TX_SRAM_SIZE);
+	ad->rxcache.size = readl_relaxed(ad->base + REG_RX_SRAM_SIZE);
 
 	if (dir == DMA_MEM_TO_DEV)
 		sram = &ad->txcache;
@@ -912,12 +914,7 @@ static int admac_probe(struct platform_device *pdev)
 		goto free_irq;
 	}
 
-	ad->txcache.size = readl_relaxed(ad->base + REG_TX_SRAM_SIZE);
-	ad->rxcache.size = readl_relaxed(ad->base + REG_RX_SRAM_SIZE);
-
 	dev_info(&pdev->dev, "Audio DMA Controller\n");
-	dev_info(&pdev->dev, "imprint %x TX cache %u RX cache %u\n",
-		 readl_relaxed(ad->base + REG_IMPRINT), ad->txcache.size, ad->rxcache.size);
 
 	return 0;
 

---
base-commit: 9f16d5e6f220661f73b36a4be1b21575651d8833
change-id: 20241124-admac-power-7f32c2a1850a

