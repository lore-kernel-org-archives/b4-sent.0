From: Sven Peter <sven@svenpeter.dev>
Date: Sun, 27 Apr 2025 11:30:46 +0000
Subject: [PATCH v3 4/4] i2c: pasemi: Log bus reset causes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250427-pasemi-fixes-v3-4-af28568296c0@svenpeter.dev>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1721; i=sven@svenpeter.dev;
 h=from:subject:message-id; bh=nRlmnXOqgPKLCOyL2YLd20qO5WoVbBnMs4FETTpxuT0=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQwafaNkZs3Xm+Uc2HqnaujX3wlmuf03pS3wKklQ7jgs8V
 BEKbgzuKGVhEONgkBVTZNm+3970ycM3gks3XXoPM4eVCWQIAxenAEwkSoCRoe3lrfgzK9alnTzR
 d2rmUuMbDCpCXdXT70tf3vTUUX9q0yxGhlNHouR9UuSX7eNuUgib6ON3wELfcflEo8f23nPvry0
 9wAAA
X-Developer-Key: i=sven@svenpeter.dev; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@svenpeter.dev/default with auth_id=167
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Hector Martin <marcan@marcan.st>

This ensures we get all information we need to debug issues when users
forward us their logs.

Signed-off-by: Hector Martin <marcan@marcan.st>
Reviewed-by: Neal Gompa <neal@gompa.dev>
Reviewed-by: Alyssa Rosenzweig <alyssa@rosenzweig.io>
Signed-off-by: Sven Peter <sven@svenpeter.dev>
---
 drivers/i2c/busses/i2c-pasemi-core.c | 9 +++++++--
 1 file changed, 7 insertions(+), 2 deletions(-)

diff --git a/drivers/i2c/busses/i2c-pasemi-core.c b/drivers/i2c/busses/i2c-pasemi-core.c
index dad20ee0c6689eda309cb0374aa75b42669cbcdc..f4eca44ed18395331a366537bd06f2eb3ba08e21 100644
--- a/drivers/i2c/busses/i2c-pasemi-core.c
+++ b/drivers/i2c/busses/i2c-pasemi-core.c
@@ -22,6 +22,7 @@
 /* Register offsets */
 #define REG_MTXFIFO	0x00
 #define REG_MRXFIFO	0x04
+#define REG_XFSTA	0x0c
 #define REG_SMSTA	0x14
 #define REG_IMASK	0x18
 #define REG_CTL		0x1c
@@ -99,14 +100,18 @@ static int pasemi_smb_clear(struct pasemi_smbus *smbus)
 				 USEC_PER_MSEC * PASEMI_TRANSFER_TIMEOUT_MS);
 
 	if (ret < 0) {
-		dev_err(smbus->dev, "Bus is still stuck (status 0x%08x)\n", status);
+		dev_err(smbus->dev, "Bus is still stuck (status 0x%08x xfstatus 0x%08x)\n",
+			 status, reg_read(smbus, REG_XFSTA));
 		return -EIO;
 	}
 
 	/* If any badness happened or there is data in the FIFOs, reset the FIFOs */
 	if ((status & (SMSTA_MRNE | SMSTA_JMD | SMSTA_MTO | SMSTA_TOM | SMSTA_MTN | SMSTA_MTA)) ||
-	    !(status & SMSTA_MTE))
+	    !(status & SMSTA_MTE)) {
+		dev_warn(smbus->dev, "Issuing reset due to status 0x%08x (xfstatus 0x%08x)\n",
+			 status, reg_read(smbus, REG_XFSTA));
 		pasemi_reset(smbus);
+	}
 
 	/* Clear the flags */
 	reg_write(smbus, REG_SMSTA, status);

-- 
2.34.1

