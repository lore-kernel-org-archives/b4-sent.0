From: Sasha Finkelstein <fnkl.kernel@gmail.com>
Date: Fri, 07 Mar 2025 21:07:45 +0100
Subject: [PATCH v3 1/2] iommu: apple-dart: Increase MAX_DARTS_PER_DEVICE to
 3
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250307-isp-dart-v3-1-684fe4489591@gmail.com>
References: <20250307-isp-dart-v3-0-684fe4489591@gmail.com>
In-Reply-To: <20250307-isp-dart-v3-0-684fe4489591@gmail.com>
To: Sven Peter <sven@svenpeter.dev>, Janne Grunau <j@jannau.net>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, Joerg Roedel <joro@8bytes.org>, 
 Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 iommu@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Sasha Finkelstein <fnkl.kernel@gmail.com>, Hector Martin <marcan@marcan.st>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741378068; l=698;
 i=fnkl.kernel@gmail.com; s=20241124; h=from:subject:message-id;
 bh=lnQqB1BR4mWIGODXOGI5G9lt91LbhceR/0LaO+MRnP8=;
 b=hb786voX2A/Zpfx3df/i6HBELMfG+WChRQ+gVPjf13bM7zHlP5dR/JwTCojn8llcpbX90nexF
 PK1W1aIzQaYB/s5G7gj1BOAxx9vqxvreXXoTQpErQTiKqYEeOtsrraY
X-Developer-Key: i=fnkl.kernel@gmail.com; a=ed25519;
 pk=aSkp1PdZ+eF4jpMO6oLvz/YfT5XkBUneWwyhQrOgmsU=
X-Endpoint-Received: by B4 Relay for fnkl.kernel@gmail.com/20241124 with auth_id=283
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Hector Martin <marcan@marcan.st>

ISP needs this.

Signed-off-by: Hector Martin <marcan@marcan.st>
Reviewed-by: Alyssa Rosenzweig <alyssa@rosenzweig.io>
Signed-off-by: Sasha Finkelstein <fnkl.kernel@gmail.com>
---
 drivers/iommu/apple-dart.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/iommu/apple-dart.c b/drivers/iommu/apple-dart.c
index 95ba3caeb40177901086076416874b9905a1f40a..edb2fb22333506d7c64ad1b6321df00ebfd07747 100644
--- a/drivers/iommu/apple-dart.c
+++ b/drivers/iommu/apple-dart.c
@@ -36,7 +36,7 @@
 
 #define DART_MAX_STREAMS 256
 #define DART_MAX_TTBR 4
-#define MAX_DARTS_PER_DEVICE 2
+#define MAX_DARTS_PER_DEVICE 3
 
 /* Common registers */
 

-- 
2.48.1

