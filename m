From: Sven Peter <sven@svenpeter.dev>
Date: Tue, 15 Apr 2025 15:37:00 +0000
Subject: [PATCH v2 6/6] i2c: pasemi: Log bus reset causes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250415-pasemi-fixes-v2-6-c543bf53151a@svenpeter.dev>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1542; i=sven@svenpeter.dev;
 h=from:subject:message-id; bh=VA1WhVX4Izvudq5u7eRf2fGXelyMPNY/3NDm2fN5raU=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ/q/Wq19l7xza3jP7jSI+u++w+7L/V2srnF6Fyb/Wj4xQ
 Wxp+pKOjlIWBjEOBlkxRZbt++1Nnzx8I7h006X3MHNYmUCGMHBxCsBEtjEzMtx+KuJdcOrOkUlJ
 rxm8+9rvPi4Wl21gUd+fq73jnISu6A5GhlebAySynZqu/S4pmjq5XUPuoEygj/TT0tth2o+mXug
 S5AcA
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
 drivers/i2c/busses/i2c-pasemi-core.c | 7 +++++--
 1 file changed, 5 insertions(+), 2 deletions(-)

diff --git a/drivers/i2c/busses/i2c-pasemi-core.c b/drivers/i2c/busses/i2c-pasemi-core.c
index 41db38d82fe62c73614b8fafe4cb73c7d1a24762..e5e8a748638f02e48d6ffa65e49aff5b12f70e06 100644
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
@@ -89,7 +90,7 @@ static void pasemi_reset(struct pasemi_smbus *smbus)
 
 static int pasemi_smb_clear(struct pasemi_smbus *smbus)
 {
-	unsigned int status;
+	unsigned int status, xfstatus;
 	int ret;
 
 	/* First wait for the bus to go idle */
@@ -98,7 +99,9 @@ static int pasemi_smb_clear(struct pasemi_smbus *smbus)
 				 USEC_PER_MSEC, USEC_PER_MSEC * TRANSFER_TIMEOUT_MS);
 
 	if (ret < 0) {
-		dev_err(smbus->dev, "Bus is still stuck (status 0x%08x)\n", status);
+		xfstatus = reg_read(smbus, REG_XFSTA);
+		dev_err(smbus->dev, "Bus is still stuck (status 0x%08x xfstatus 0x%08x)\n",
+			 status, xfstatus);
 		return -EIO;
 	}
 

-- 
2.34.1

