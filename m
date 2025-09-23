From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 23 Sep 2025 09:23:38 +0100
Subject: [PATCH RESEND 4/4] dma: dma-axi-dmac: simplify axi_dmac_parse_dt()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250923-b4-dev-axi-dmac-fixes-v1-4-5896dcbbd909@analog.com>
References: <20250923-b4-dev-axi-dmac-fixes-v1-0-5896dcbbd909@analog.com>
In-Reply-To: <20250923-b4-dev-axi-dmac-fixes-v1-0-5896dcbbd909@analog.com>
To: dmaengine@vger.kernel.org
Cc: Vinod Koul <vkoul@kernel.org>, Lars-Peter Clausen <lars@metafoo.de>, 
 Paul Cercueil <paul@crapouillou.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758615815; l=1551;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=hayjasLpAzSq1oaB+SvL2m79XKZRO2+rkHfQN8vJhbc=;
 b=4KiTy5skybaGEWX43S32z18MNp+wOpIqF8trWBBVvNISWPM/6Wmn9Ss5A905dkNh8NwUHkBq3
 vbfn/tfC2DODkzmEwIBLejLwtpMSN36gQ8cbhRlzMVqCaFkM29dIJ30
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Simplify axi_dmac_parse_dt() by using the cleanup device_node class for
automatically releasing the of_node reference when going out of scope.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/dma/dma-axi-dmac.c | 13 +++++--------
 1 file changed, 5 insertions(+), 8 deletions(-)

diff --git a/drivers/dma/dma-axi-dmac.c b/drivers/dma/dma-axi-dmac.c
index 15c569449a28493bd00e9b320ed83aa2a13144e2..045e9b9a90df562073c078835584a23f26d47350 100644
--- a/drivers/dma/dma-axi-dmac.c
+++ b/drivers/dma/dma-axi-dmac.c
@@ -8,6 +8,7 @@
 
 #include <linux/adi-axi-common.h>
 #include <linux/bitfield.h>
+#include <linux/cleanup.h>
 #include <linux/clk.h>
 #include <linux/device.h>
 #include <linux/dma-mapping.h>
@@ -927,22 +928,18 @@ static int axi_dmac_parse_chan_dt(struct device_node *of_chan,
 
 static int axi_dmac_parse_dt(struct device *dev, struct axi_dmac *dmac)
 {
-	struct device_node *of_channels, *of_chan;
 	int ret;
 
-	of_channels = of_get_child_by_name(dev->of_node, "adi,channels");
+	struct device_node *of_channels __free(device_node) = of_get_child_by_name(dev->of_node,
+										   "adi,channels");
 	if (of_channels == NULL)
 		return -ENODEV;
 
-	for_each_child_of_node(of_channels, of_chan) {
+	for_each_child_of_node_scoped(of_channels, of_chan) {
 		ret = axi_dmac_parse_chan_dt(of_chan, &dmac->chan);
-		if (ret) {
-			of_node_put(of_chan);
-			of_node_put(of_channels);
+		if (ret)
 			return -EINVAL;
-		}
 	}
-	of_node_put(of_channels);
 
 	return 0;
 }

-- 
2.51.0

