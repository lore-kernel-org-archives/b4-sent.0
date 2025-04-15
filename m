From: Sven Peter <sven@svenpeter.dev>
Date: Tue, 15 Apr 2025 15:36:57 +0000
Subject: [PATCH v2 3/6] i2c: pasemi: Improve timeout handling
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250415-pasemi-fixes-v2-3-c543bf53151a@svenpeter.dev>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2138; i=sven@svenpeter.dev;
 h=from:subject:message-id; bh=pieYM48LE5ENsb4OlGmWM38fJJzel5K/67CDk0KItDE=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ/q/WvWKcJ/Ij8b3P05fYM58StKf7c2kj6UO6rKVr2u/R
 bN/jY3vKGVhEONgkBVTZNm+3970ycM3gks3XXoPM4eVCWQIAxenAExk7yWG/w5Skwunb99z8fBu
 o7eC/youx5b+YzCc+W/XoprbuSEdnPcZGU4/lzac0t5wuYzjwwGL5tcNvtVFW7/VPLu1Y0rwgYr
 9DAwA
X-Developer-Key: i=sven@svenpeter.dev; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@svenpeter.dev/default with auth_id=167
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add proper timeout handling for the interrupt path.
Previously, this was only correctly done for the polling path.
Note that we drop reg_write(smbus, REG_SMSTA, status) here which
will be done anyway whenever the next transaction starts via
pasemi_smb_clear.

Signed-off-by: Sven Peter <sven@svenpeter.dev>
---
 drivers/i2c/busses/i2c-pasemi-core.c | 24 +++++++++++++++++-------
 1 file changed, 17 insertions(+), 7 deletions(-)

diff --git a/drivers/i2c/busses/i2c-pasemi-core.c b/drivers/i2c/busses/i2c-pasemi-core.c
index df1b0087dcacb0a3b94196368137d5e20b0e6d7e..9b611dbdfef23e78a4ea75ac0311938d52b6ba96 100644
--- a/drivers/i2c/busses/i2c-pasemi-core.c
+++ b/drivers/i2c/busses/i2c-pasemi-core.c
@@ -91,32 +91,42 @@ static void pasemi_smb_clear(struct pasemi_smbus *smbus)
 static int pasemi_smb_waitready(struct pasemi_smbus *smbus)
 {
 	int timeout = 100;
+	int ret;
 	unsigned int status;
 
 	if (smbus->use_irq) {
 		reinit_completion(&smbus->irq_completion);
 		reg_write(smbus, REG_IMASK, SMSTA_XEN | SMSTA_MTN);
-		wait_for_completion_timeout(&smbus->irq_completion, msecs_to_jiffies(100));
+		ret = wait_for_completion_timeout(&smbus->irq_completion, msecs_to_jiffies(100));
 		reg_write(smbus, REG_IMASK, 0);
 		status = reg_read(smbus, REG_SMSTA);
+
+		if (ret < 0) {
+			dev_err(smbus->dev,
+				"Completion wait failed with %d, status 0x%08x\n",
+				ret, status);
+			return ret;
+		} else if (ret == 0) {
+			dev_warn(smbus->dev, "Timeout, status 0x%08x\n", status);
+			return -ETIME;
+		}
 	} else {
 		status = reg_read(smbus, REG_SMSTA);
 		while (!(status & SMSTA_XEN) && timeout--) {
 			msleep(1);
 			status = reg_read(smbus, REG_SMSTA);
 		}
+
+		if (timeout < 0) {
+			dev_warn(smbus->dev, "Timeout, status 0x%08x\n", status);
+			return -ETIME;
+		}
 	}
 
 	/* Got NACK? */
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

