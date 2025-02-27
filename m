From: Sasha Finkelstein <fnkl.kernel@gmail.com>
Date: Thu, 27 Feb 2025 17:56:03 +0100
Subject: [PATCH 1/2] iommu: apple-dart: Increase MAX_DARTS_PER_DEVICE to 3
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250227-isp-dart-v1-1-161e91ef4f46@gmail.com>
References: <20250227-isp-dart-v1-0-161e91ef4f46@gmail.com>
In-Reply-To: <20250227-isp-dart-v1-0-161e91ef4f46@gmail.com>
To: Sven Peter <sven@svenpeter.dev>, Janne Grunau <j@jannau.net>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, Joerg Roedel <joro@8bytes.org>, 
 Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 iommu@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Sasha Finkelstein <fnkl.kernel@gmail.com>, Hector Martin <marcan@marcan.st>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740675366; l=643;
 i=fnkl.kernel@gmail.com; s=20241124; h=from:subject:message-id;
 bh=VLb6ei5YDATwjI9GwTuWhThgZUr54hxXR+bLrvtteos=;
 b=nGennlX6EccZFKEYMqV//HecoBeGHkhvWIENZ1kzeI1LmLGnOIbWsPLane7YabErGkJ94lnzi
 EDuLvx5Cd4UCBm8e92qD8T/Q5beHjuc2U6wmjryWx2nGorcigYKmfbH
X-Developer-Key: i=fnkl.kernel@gmail.com; a=ed25519;
 pk=aSkp1PdZ+eF4jpMO6oLvz/YfT5XkBUneWwyhQrOgmsU=
X-Endpoint-Received: by B4 Relay for fnkl.kernel@gmail.com/20241124 with auth_id=283
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Hector Martin <marcan@marcan.st>

ISP needs this.

Signed-off-by: Hector Martin <marcan@marcan.st>
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

