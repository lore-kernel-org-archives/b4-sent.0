From: Sven Peter <sven@svenpeter.dev>
Date: Sat, 22 Feb 2025 13:38:36 +0000
Subject: [PATCH 4/4] i2c: pasemi: Log bus reset causes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250222-pasemi-fixes-v1-4-d7ea33d50c5e@svenpeter.dev>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1852; i=sven@svenpeter.dev;
 h=from:subject:message-id; bh=Jxw9FakomFtq1Asfv39ujqR2viJkk3GlzvSkFwhw82g=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ/rOy/G9bPs878o/+CTRkbdfmm/Lhezdx5g13m4KbKiT/
 8G38L5BRykLgxgHg6yYIsv2/famTx6+EVy66dJ7mDmsTCBDGLg4BWAiGxQZ/qnyVAicXbnM/M1T
 hl+P9OxCS5f+WvFccDXf9t2Pfm+YK5DG8D+rcuO/gvTpxdKxP2UqBZRYb+95m3Jgi/zta3tq3zI
 JZbIAAA==
X-Developer-Key: i=sven@svenpeter.dev; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@svenpeter.dev/default with auth_id=167
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Hector Martin <marcan@marcan.st>

This ensures we get all information we need to debug issues when users
forward us their logs.

Signed-off-by: Hector Martin <marcan@marcan.st>
Signed-off-by: Sven Peter <sven@svenpeter.dev>
---
 drivers/i2c/busses/i2c-pasemi-core.c | 13 ++++++++++---
 1 file changed, 10 insertions(+), 3 deletions(-)

diff --git a/drivers/i2c/busses/i2c-pasemi-core.c b/drivers/i2c/busses/i2c-pasemi-core.c
index 8f0ba975172f..ae0181a76470 100644
--- a/drivers/i2c/busses/i2c-pasemi-core.c
+++ b/drivers/i2c/busses/i2c-pasemi-core.c
@@ -21,6 +21,7 @@
 /* Register offsets */
 #define REG_MTXFIFO	0x00
 #define REG_MRXFIFO	0x04
+#define REG_XFSTA	0x0c
 #define REG_SMSTA	0x14
 #define REG_IMASK	0x18
 #define REG_CTL		0x1c
@@ -84,7 +85,7 @@ static void pasemi_reset(struct pasemi_smbus *smbus)
 
 static int pasemi_smb_clear(struct pasemi_smbus *smbus)
 {
-	unsigned int status;
+	unsigned int status, xfstatus;
 	int timeout = TRANSFER_TIMEOUT_MS;
 
 	status = reg_read(smbus, REG_SMSTA);
@@ -95,15 +96,21 @@ static int pasemi_smb_clear(struct pasemi_smbus *smbus)
 		status = reg_read(smbus, REG_SMSTA);
 	}
 
+	xfstatus = reg_read(smbus, REG_XFSTA);
+
 	if (timeout < 0) {
-		dev_warn(smbus->dev, "Bus is still stuck (status 0x%08x)\n", status);
+		dev_warn(smbus->dev, "Bus is still stuck (status 0x%08x xfstatus 0x%08x)\n",
+			 status, xfstatus);
 		return -EIO;
 	}
 
 	/* If any badness happened or there is data in the FIFOs, reset the FIFOs */
 	if ((status & (SMSTA_MRNE | SMSTA_JMD | SMSTA_MTO | SMSTA_TOM | SMSTA_MTN | SMSTA_MTA)) ||
-		!(status & SMSTA_MTE))
+		!(status & SMSTA_MTE)) {
+		dev_warn(smbus->dev, "Issuing reset due to status 0x%08x (xfstatus 0x%08x)\n",
+			 status, xfstatus);
 		pasemi_reset(smbus);
+	}
 
 	/* Clear the flags */
 	reg_write(smbus, REG_SMSTA, status);

-- 
2.34.1

