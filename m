From: Sasha Finkelstein <fnkl.kernel@gmail.com>
Date: Fri, 28 Feb 2025 17:32:08 +0100
Subject: [PATCH v2 2/2] iommu: apple-dart: Allow mismatched bypass support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250228-isp-dart-v2-2-0ead81a90e2d@gmail.com>
References: <20250228-isp-dart-v2-0-0ead81a90e2d@gmail.com>
In-Reply-To: <20250228-isp-dart-v2-0-0ead81a90e2d@gmail.com>
To: Sven Peter <sven@svenpeter.dev>, Janne Grunau <j@jannau.net>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, Joerg Roedel <joro@8bytes.org>, 
 Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 iommu@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Sasha Finkelstein <fnkl.kernel@gmail.com>, Hector Martin <marcan@marcan.st>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740760327; l=2163;
 i=fnkl.kernel@gmail.com; s=20241124; h=from:subject:message-id;
 bh=JQSupRxxeo02jeCiSjlLYXGm5UYUz824xOI4n+kLsIc=;
 b=NIJtNGenNUqCGcrYn+CSg5iwM1CMxzExqc+CYKhhPQo7i/RgO9AE9OfTxrviHYf4OG5lC8nJg
 OGL27PZVqIaAgrswsqJtotv4GAOiML7r1Pe8wVGJdZ2W5H+Kw+Q2c34
X-Developer-Key: i=fnkl.kernel@gmail.com; a=ed25519;
 pk=aSkp1PdZ+eF4jpMO6oLvz/YfT5XkBUneWwyhQrOgmsU=
X-Endpoint-Received: by B4 Relay for fnkl.kernel@gmail.com/20241124 with auth_id=283
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Hector Martin <marcan@marcan.st>

This is needed by ISP, which has DART0 with bypass and DART1/2 without.

Signed-off-by: Hector Martin <marcan@marcan.st>
Signed-off-by: Sasha Finkelstein <fnkl.kernel@gmail.com>
---
 drivers/iommu/apple-dart.c | 17 ++++++++++++-----
 1 file changed, 12 insertions(+), 5 deletions(-)

diff --git a/drivers/iommu/apple-dart.c b/drivers/iommu/apple-dart.c
index edb2fb22333506d7c64ad1b6321df00ebfd07747..13ccb801f52a4d34f6653f78e92787af7dfed1bc 100644
--- a/drivers/iommu/apple-dart.c
+++ b/drivers/iommu/apple-dart.c
@@ -277,6 +277,9 @@ struct apple_dart_domain {
  * @streams: streams for this device
  */
 struct apple_dart_master_cfg {
+	/* Intersection of DART capabilitles */
+	u32 supports_bypass : 1;
+
 	struct apple_dart_stream_map stream_maps[MAX_DARTS_PER_DEVICE];
 };
 
@@ -684,7 +687,7 @@ static int apple_dart_attach_dev_identity(struct iommu_domain *domain,
 	struct apple_dart_stream_map *stream_map;
 	int i;
 
-	if (!cfg->stream_maps[0].dart->supports_bypass)
+	if (!cfg->supports_bypass)
 		return -EINVAL;
 
 	for_each_stream_map(i, cfg, stream_map)
@@ -792,20 +795,24 @@ static int apple_dart_of_xlate(struct device *dev,
 		return -EINVAL;
 	sid = args->args[0];
 
-	if (!cfg)
+	if (!cfg) {
 		cfg = kzalloc(sizeof(*cfg), GFP_KERNEL);
+
+		/* Will be ANDed with DART capabilities */
+		cfg->supports_bypass = true;
+	}
 	if (!cfg)
 		return -ENOMEM;
 	dev_iommu_priv_set(dev, cfg);
 
 	cfg_dart = cfg->stream_maps[0].dart;
 	if (cfg_dart) {
-		if (cfg_dart->supports_bypass != dart->supports_bypass)
-			return -EINVAL;
 		if (cfg_dart->pgsize != dart->pgsize)
 			return -EINVAL;
 	}
 
+	cfg->supports_bypass &= dart->supports_bypass;
+
 	for (i = 0; i < MAX_DARTS_PER_DEVICE; ++i) {
 		if (cfg->stream_maps[i].dart == dart) {
 			set_bit(sid, cfg->stream_maps[i].sidmap);
@@ -945,7 +952,7 @@ static int apple_dart_def_domain_type(struct device *dev)
 
 	if (cfg->stream_maps[0].dart->pgsize > PAGE_SIZE)
 		return IOMMU_DOMAIN_IDENTITY;
-	if (!cfg->stream_maps[0].dart->supports_bypass)
+	if (!cfg->supports_bypass)
 		return IOMMU_DOMAIN_DMA;
 
 	return 0;

-- 
2.48.1

