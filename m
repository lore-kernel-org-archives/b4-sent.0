From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Mon, 11 Aug 2025 16:56:39 +0100
Subject: [PATCH RESEND 4/4] dma: dma-axi-dmac: simplify axi_dmac_parse_dt()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250811-dev-axi-dmac-fixes-v1-4-8d9895f6003f@analog.com>
References: <20250811-dev-axi-dmac-fixes-v1-0-8d9895f6003f@analog.com>
In-Reply-To: <20250811-dev-axi-dmac-fixes-v1-0-8d9895f6003f@analog.com>
To: dmaengine@vger.kernel.org
Cc: Paul Cercueil <paul@crapouillou.net>, 
 Lars-Peter Clausen <lars@metafoo.de>, Vinod Koul <vkoul@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1754927814; l=1521;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=zr8s3sNnjY22gMwbOqfgSaxAAz3Ulgnov71IpuImhaU=;
 b=/9zIhg97WgRvx1wq+Sk32F8dUuDuY3Gsx18g6z+PVDtavfmOjMTV/Pj8Rytf4EuvcNvxK43/h
 hEpn5lOsKXmClLoY4I8xmBu1t4bwFggcnzCi+/IN2/IErrjg2nzJOzI
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
index 25717a6ea9848b6c591a3ab6adb27c6f21f002b9..035fc703506977ad59fd0b6ee8a8e5858d2c120e 100644
--- a/drivers/dma/dma-axi-dmac.c
+++ b/drivers/dma/dma-axi-dmac.c
@@ -7,6 +7,7 @@
  */
 
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
2.50.1

