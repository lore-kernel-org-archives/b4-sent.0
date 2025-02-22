From: Sven Peter <sven@svenpeter.dev>
Date: Sat, 22 Feb 2025 13:38:33 +0000
Subject: [PATCH 1/4] i2c: pasemi: Add registers bits and switch to BIT()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250222-pasemi-fixes-v1-1-d7ea33d50c5e@svenpeter.dev>
References: <20250222-pasemi-fixes-v1-0-d7ea33d50c5e@svenpeter.dev>
In-Reply-To: <20250222-pasemi-fixes-v1-0-d7ea33d50c5e@svenpeter.dev>
To: Janne Grunau <j@jannau.net>, Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>, 
 Naveen N Rao <naveen@kernel.org>, Andi Shyti <andi.shyti@kernel.org>
Cc: linuxppc-dev@lists.ozlabs.org, asahi@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, linux-i2c@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Sven Peter <sven@svenpeter.dev>, 
 Hector Martin <marcan@marcan.st>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2037; i=sven@svenpeter.dev;
 h=from:subject:message-id; bh=iPv0XjpNaU2PSc1JHoHKcgCr0CRP3yf1b4EAPEcXwng=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ/rOy9ESFaHHtpUbMr91cTRekSrY3mPm4vwl4djZsz+Kw
 0rCA+o7SlkYxDgYZMUUWbbvtzd98vCN4NJNl97DzGFlAhnCwMUpABPpSWZk+Okau99t7x9PDrd7
 Bewzl0+r1NyzLGjKtR6F2u6Y5ZpbHzIyzBb9undnbnzudPf6usJzQa0X5xRkCsf4CkWc3b3xodM
 7JgA=
X-Developer-Key: i=sven@svenpeter.dev; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@svenpeter.dev/default with auth_id=167
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the missing register bits to the defines and also switch
those to use the BIT macro which is much more readable than
using hardcoded masks

Co-developed-by: Hector Martin <marcan@marcan.st>
Signed-off-by: Hector Martin <marcan@marcan.st>
Signed-off-by: Sven Peter <sven@svenpeter.dev>
---
 drivers/i2c/busses/i2c-pasemi-core.c | 40 ++++++++++++++++++++++--------------
 1 file changed, 25 insertions(+), 15 deletions(-)

diff --git a/drivers/i2c/busses/i2c-pasemi-core.c b/drivers/i2c/busses/i2c-pasemi-core.c
index dac694a9d781..bd128ab2e2eb 100644
--- a/drivers/i2c/busses/i2c-pasemi-core.c
+++ b/drivers/i2c/busses/i2c-pasemi-core.c
@@ -5,6 +5,7 @@
  * SMBus host driver for PA Semi PWRficient
  */
 
+#include <linux/bitfield.h>
 #include <linux/module.h>
 #include <linux/pci.h>
 #include <linux/kernel.h>
@@ -26,21 +27,30 @@
 #define REG_REV		0x28
 
 /* Register defs */
-#define MTXFIFO_READ	0x00000400
-#define MTXFIFO_STOP	0x00000200
-#define MTXFIFO_START	0x00000100
-#define MTXFIFO_DATA_M	0x000000ff
-
-#define MRXFIFO_EMPTY	0x00000100
-#define MRXFIFO_DATA_M	0x000000ff
-
-#define SMSTA_XEN	0x08000000
-#define SMSTA_MTN	0x00200000
-
-#define CTL_MRR		0x00000400
-#define CTL_MTR		0x00000200
-#define CTL_EN		0x00000800
-#define CTL_CLK_M	0x000000ff
+#define MTXFIFO_READ	BIT(10)
+#define MTXFIFO_STOP	BIT(9)
+#define MTXFIFO_START	BIT(8)
+#define MTXFIFO_DATA_M	GENMASK(7, 0)
+
+#define MRXFIFO_EMPTY	BIT(8)
+#define MRXFIFO_DATA_M	GENMASK(7, 0)
+
+#define SMSTA_XIP	BIT(28)
+#define SMSTA_XEN	BIT(27)
+#define SMSTA_JMD	BIT(25)
+#define SMSTA_JAM	BIT(24)
+#define SMSTA_MTO	BIT(23)
+#define SMSTA_MTA	BIT(22)
+#define SMSTA_MTN	BIT(21)
+#define SMSTA_MRNE	BIT(19)
+#define SMSTA_MTE	BIT(16)
+#define SMSTA_TOM	BIT(6)
+
+#define CTL_EN		BIT(11)
+#define CTL_MRR		BIT(10)
+#define CTL_MTR		BIT(9)
+#define CTL_UJM		BIT(8)
+#define CTL_CLK_M	GENMASK(7, 0)
 
 static inline void reg_write(struct pasemi_smbus *smbus, int reg, int val)
 {

-- 
2.34.1

