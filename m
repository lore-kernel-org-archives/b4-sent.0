From: Sven Peter <sven@svenpeter.dev>
Date: Tue, 15 Apr 2025 15:36:58 +0000
Subject: [PATCH v2 4/6] i2c: pasemi: Improve error recovery
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250415-pasemi-fixes-v2-4-c543bf53151a@svenpeter.dev>
References: <20250415-pasemi-fixes-v2-0-c543bf53151a@svenpeter.dev>
In-Reply-To: <20250415-pasemi-fixes-v2-0-c543bf53151a@svenpeter.dev>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=4795; i=sven@svenpeter.dev;
 h=from:subject:message-id; bh=UdXQ8SUtLivYr558egJosJKmHk91VYvtGnZh/V57dEs=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ/q/Wo13a1P715ycGSTHyJd7p1dg2YusT38uru8S/HfoW
 4udw9lfHaUsDGIcDLJiiizb99ubPnn4RnDppkvvYeawMoEMYeDiFICJ+NYz/HdNckyT5XKt4GsS
 MeSS/31mp7N65u8gs9C8i406n1JjOBn+cDUKp69mDp+WPaHu2f6rqzh4Tj052h0e43FXwmtpzT9
 dbgA=
X-Developer-Key: i=sven@svenpeter.dev; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@svenpeter.dev/default with auth_id=167
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Hector Martin <marcan@marcan.st>

The hardware (supposedly) has a 25ms timeout for clock stretching
and the driver uses 100ms which should be plenty. The error
reocvery itself is however lacking.

Add handling for all the missing error condition, and better recovery in
pasemi_smb_clear(). Also move the timeout to a #define since it's used
in multiple places now.

Signed-off-by: Hector Martin <marcan@marcan.st>
[sven: adjusted commit message after splitting the commit into two]
Signed-off-by: Sven Peter <sven@svenpeter.dev>
---
 drivers/i2c/busses/i2c-pasemi-core.c | 75 +++++++++++++++++++++++++++++++-----
 1 file changed, 65 insertions(+), 10 deletions(-)

diff --git a/drivers/i2c/busses/i2c-pasemi-core.c b/drivers/i2c/busses/i2c-pasemi-core.c
index 9b611dbdfef23e78a4ea75ac0311938d52b6ba96..2f31f039bedfd7f78d6572fe925125b1a6d0724b 100644
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
+#define TRANSFER_TIMEOUT_MS	100
+
 static inline void reg_write(struct pasemi_smbus *smbus, int reg, int val)
 {
 	dev_dbg(smbus->dev, "smbus write reg %x val %08x\n", reg, val);
@@ -80,24 +87,44 @@ static void pasemi_reset(struct pasemi_smbus *smbus)
 	reinit_completion(&smbus->irq_completion);
 }
 
-static void pasemi_smb_clear(struct pasemi_smbus *smbus)
+static int pasemi_smb_clear(struct pasemi_smbus *smbus)
 {
 	unsigned int status;
+	int ret;
 
-	status = reg_read(smbus, REG_SMSTA);
+	/* First wait for the bus to go idle */
+	ret = readx_poll_timeout(ioread32, smbus->ioaddr + REG_SMSTA,
+				 status, !(status & (SMSTA_XIP | SMSTA_JAM)),
+				 USEC_PER_MSEC, USEC_PER_MSEC * TRANSFER_TIMEOUT_MS);
+
+	if (ret < 0) {
+		dev_err(smbus->dev, "Bus is still stuck (status 0x%08x)\n", status);
+		return -EIO;
+	}
+
+	/* If any badness happened or there is data in the FIFOs, reset the FIFOs */
+	if ((status & (SMSTA_MRNE | SMSTA_JMD | SMSTA_MTO | SMSTA_TOM | SMSTA_MTN | SMSTA_MTA)) ||
+	    !(status & SMSTA_MTE))
+		pasemi_reset(smbus);
+
+	/* Clear the flags */
 	reg_write(smbus, REG_SMSTA, status);
+
+	return 0;
 }
 
 static int pasemi_smb_waitready(struct pasemi_smbus *smbus)
 {
-	int timeout = 100;
+	int timeout = TRANSFER_TIMEOUT_MS;
 	int ret;
 	unsigned int status;
 
 	if (smbus->use_irq) {
 		reinit_completion(&smbus->irq_completion);
-		reg_write(smbus, REG_IMASK, SMSTA_XEN | SMSTA_MTN);
-		ret = wait_for_completion_timeout(&smbus->irq_completion, msecs_to_jiffies(100));
+		/* XEN should be set when a transaction terminates, whether due to error or not */
+		reg_write(smbus, REG_IMASK, SMSTA_XEN);
+		ret = wait_for_completion_timeout(&smbus->irq_completion,
+						  msecs_to_jiffies(timeout));
 		reg_write(smbus, REG_IMASK, 0);
 		status = reg_read(smbus, REG_SMSTA);
 
@@ -123,9 +150,35 @@ static int pasemi_smb_waitready(struct pasemi_smbus *smbus)
 		}
 	}
 
+	/* Controller timeout? */
+	if (status & SMSTA_TOM) {
+		dev_warn(smbus->dev, "Controller timeout, status 0x%08x\n", status);
+		return -EIO;
+	}
+
+	/* Peripheral timeout? */
+	if (status & SMSTA_MTO) {
+		dev_warn(smbus->dev, "Peripheral timeout, status 0x%08x\n", status);
+		return -ETIME;
+	}
+
+	/* Still stuck in a transaction? */
+	if (status & SMSTA_XIP) {
+		dev_warn(smbus->dev, "Bus stuck, status 0x%08x\n", status);
+		return -EIO;
+	}
+
+	/* Arbitration loss? */
+	if (status & SMSTA_MTA) {
+		dev_warn(smbus->dev, "Arbitration loss, status 0x%08x\n", status);
+		return -EBUSY;
+	}
+
 	/* Got NACK? */
-	if (status & SMSTA_MTN)
+	if (status & SMSTA_MTN) {
+		dev_warn(smbus->dev, "NACK, status 0x%08x\n", status);
 		return -ENXIO;
+	}
 
 	/* Clear XEN */
 	reg_write(smbus, REG_SMSTA, SMSTA_XEN);
@@ -187,9 +240,9 @@ static int pasemi_i2c_xfer(struct i2c_adapter *adapter,
 	struct pasemi_smbus *smbus = adapter->algo_data;
 	int ret, i;
 
-	pasemi_smb_clear(smbus);
-
-	ret = 0;
+	ret = pasemi_smb_clear(smbus);
+	if (ret)
+		return ret;
 
 	for (i = 0; i < num && !ret; i++)
 		ret = pasemi_i2c_xfer_msg(adapter, &msgs[i], (i == (num - 1)));
@@ -210,7 +263,9 @@ static int pasemi_smb_xfer(struct i2c_adapter *adapter,
 	addr <<= 1;
 	read_flag = read_write == I2C_SMBUS_READ;
 
-	pasemi_smb_clear(smbus);
+	err = pasemi_smb_clear(smbus);
+	if (err)
+		return err;
 
 	switch (size) {
 	case I2C_SMBUS_QUICK:

-- 
2.34.1

