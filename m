From: Sven Peter <sven@svenpeter.dev>
Date: Sun, 27 Apr 2025 11:30:44 +0000
Subject: [PATCH v3 2/4] i2c: pasemi: Improve timeout handling
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250427-pasemi-fixes-v3-2-af28568296c0@svenpeter.dev>
References: <20250427-pasemi-fixes-v3-0-af28568296c0@svenpeter.dev>
In-Reply-To: <20250427-pasemi-fixes-v3-0-af28568296c0@svenpeter.dev>
To: Janne Grunau <j@jannau.net>, Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>, 
 Naveen N Rao <naveen@kernel.org>, Andi Shyti <andi.shyti@kernel.org>, 
 Neal Gompa <neal@gompa.dev>, Hector Martin <marcan@marcan.st>
Cc: linuxppc-dev@lists.ozlabs.org, asahi@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, linux-i2c@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Sven Peter <sven@svenpeter.dev>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3201; i=sven@svenpeter.dev;
 h=from:subject:message-id; bh=Ymd7PRyxpRzDKy8qH3xCi40gQpZYxfTSb89hsdr26SY=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQwafaPG+qs01Hw2ePLjJX2BzQCNpflYco5LOcgN2DZczZ
 zJtrKQ7SlkYxDgYZMUUWbbvtzd98vCN4NJNl97DzGFlAhnCwMUpABN5K8XIsG/1rvhWyy0vUh/M
 jb89KW4Fh03/nk3WU1kWRIaYHnxy1ovhr+CLAw/XWKlEqOteFl6cpj+n7eCHmIete9hyXmx8oLD
 xGhcA
X-Developer-Key: i=sven@svenpeter.dev; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@svenpeter.dev/default with auth_id=167
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The hardware (supposedly) has a 25ms timeout for clock stretching
and the driver uses 100ms which should be plenty.
The interrupt path however misses handling for errors while waiting for
the completion and the polling path uses an open-coded readx_poll_timeout.
Note that we drop reg_write(smbus, REG_SMSTA, status) while fixing those
issues here which will be done anyway whenever the next transaction starts
via pasemi_smb_clear.

Signed-off-by: Sven Peter <sven@svenpeter.dev>
---
 drivers/i2c/busses/i2c-pasemi-core.c | 41 +++++++++++++++++++++++++-----------
 1 file changed, 29 insertions(+), 12 deletions(-)

diff --git a/drivers/i2c/busses/i2c-pasemi-core.c b/drivers/i2c/busses/i2c-pasemi-core.c
index 3f5571a90c1d268ea2a9d95285f1a5e47f0481ff..ee38e8a1e1f5d062384e85a2fd49d7da9257aacc 100644
--- a/drivers/i2c/busses/i2c-pasemi-core.c
+++ b/drivers/i2c/busses/i2c-pasemi-core.c
@@ -9,6 +9,7 @@
 #include <linux/delay.h>
 #include <linux/i2c.h>
 #include <linux/io.h>
+#include <linux/iopoll.h>
 #include <linux/kernel.h>
 #include <linux/module.h>
 #include <linux/pci.h>
@@ -52,6 +53,12 @@
 #define CTL_UJM		BIT(8)
 #define CTL_CLK_M	GENMASK(7, 0)
 
+/*
+ * The hardware (supposedly) has a 25ms timeout for clock stretching, thus
+ * use 100ms here which should be plenty.
+ */
+#define PASEMI_TRANSFER_TIMEOUT_MS	100
+
 static inline void reg_write(struct pasemi_smbus *smbus, int reg, int val)
 {
 	dev_dbg(smbus->dev, "smbus write reg %x val %08x\n", reg, val);
@@ -90,20 +97,36 @@ static void pasemi_smb_clear(struct pasemi_smbus *smbus)
 
 static int pasemi_smb_waitready(struct pasemi_smbus *smbus)
 {
-	int timeout = 100;
 	unsigned int status;
 
 	if (smbus->use_irq) {
 		reinit_completion(&smbus->irq_completion);
 		reg_write(smbus, REG_IMASK, SMSTA_XEN | SMSTA_MTN);
-		wait_for_completion_timeout(&smbus->irq_completion, msecs_to_jiffies(100));
+		int ret = wait_for_completion_timeout(
+				&smbus->irq_completion,
+				msecs_to_jiffies(PASEMI_TRANSFER_TIMEOUT_MS));
 		reg_write(smbus, REG_IMASK, 0);
 		status = reg_read(smbus, REG_SMSTA);
+
+		if (ret < 0) {
+			dev_err(smbus->dev,
+				"Completion wait failed with %d, status 0x%08x\n",
+				ret, status);
+			return ret;
+		} else if (ret == 0) {
+			dev_err(smbus->dev, "Timeout, status 0x%08x\n", status);
+			return -ETIME;
+		}
 	} else {
-		status = reg_read(smbus, REG_SMSTA);
-		while (!(status & SMSTA_XEN) && timeout--) {
-			msleep(1);
-			status = reg_read(smbus, REG_SMSTA);
+		int ret = readx_poll_timeout(
+				ioread32, smbus->ioaddr + REG_SMSTA,
+				status, status & SMSTA_XEN,
+				USEC_PER_MSEC,
+				USEC_PER_MSEC * PASEMI_TRANSFER_TIMEOUT_MS);
+
+		if (ret < 0) {
+			dev_err(smbus->dev, "Timeout, status 0x%08x\n", status);
+			return -ETIME;
 		}
 	}
 
@@ -111,12 +134,6 @@ static int pasemi_smb_waitready(struct pasemi_smbus *smbus)
 	if (status & SMSTA_MTN)
 		return -ENXIO;
 
-	if (timeout < 0) {
-		dev_warn(smbus->dev, "Timeout, status 0x%08x\n", status);
-		reg_write(smbus, REG_SMSTA, status);
-		return -ETIME;
-	}
-
 	/* Clear XEN */
 	reg_write(smbus, REG_SMSTA, SMSTA_XEN);
 

-- 
2.34.1

