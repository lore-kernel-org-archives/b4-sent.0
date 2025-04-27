From: Sven Peter <sven@svenpeter.dev>
Date: Sun, 27 Apr 2025 11:30:45 +0000
Subject: [PATCH v3 3/4] i2c: pasemi: Improve error recovery
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250427-pasemi-fixes-v3-3-af28568296c0@svenpeter.dev>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3408; i=sven@svenpeter.dev;
 h=from:subject:message-id; bh=RQjUShH7rfus6djDqHEQgJ89KeDc5Vm8l5ffHfaOO3w=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQwafaCnnKomj7TVR2fJPP2nrKIu1nnmY/XB6sRmL7W2Gl
 TN/u3zrKGVhEONgkBVTZNm+3970ycM3gks3XXoPM4eVCWQIAxenAExk4wNGhrVvj6W+rlAuuXsr
 W8ns8tK0Hf2G+9n57Wq43vz8EOrK8Jjhf+CO+N5Tsxav/3Hhxfn8aVvfMWhIvs189/nVKb4s3op
 3F3kA
X-Developer-Key: i=sven@svenpeter.dev; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@svenpeter.dev/default with auth_id=167
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Hector Martin <marcan@marcan.st>

Add handling for all the missing error condition, and better recovery in
pasemi_smb_clear().

Reviewed-by: Alyssa Rosenzweig <alyssa@rosenzweig.io>
Reviewed-by: Neal Gompa <neal@gompa.dev>
Signed-off-by: Hector Martin <marcan@marcan.st>
Co-developed-by: Sven Peter <sven@svenpeter.dev>
Signed-off-by: Sven Peter <sven@svenpeter.dev>
---
 drivers/i2c/busses/i2c-pasemi-core.c | 61 +++++++++++++++++++++++++++++++-----
 1 file changed, 54 insertions(+), 7 deletions(-)

diff --git a/drivers/i2c/busses/i2c-pasemi-core.c b/drivers/i2c/busses/i2c-pasemi-core.c
index ee38e8a1e1f5d062384e85a2fd49d7da9257aacc..dad20ee0c6689eda309cb0374aa75b42669cbcdc 100644
--- a/drivers/i2c/busses/i2c-pasemi-core.c
+++ b/drivers/i2c/busses/i2c-pasemi-core.c
@@ -87,12 +87,31 @@ static void pasemi_reset(struct pasemi_smbus *smbus)
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
+				 USEC_PER_MSEC,
+				 USEC_PER_MSEC * PASEMI_TRANSFER_TIMEOUT_MS);
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
@@ -130,9 +149,35 @@ static int pasemi_smb_waitready(struct pasemi_smbus *smbus)
 		}
 	}
 
+	/* Controller timeout? */
+	if (status & SMSTA_TOM) {
+		dev_err(smbus->dev, "Controller timeout, status 0x%08x\n", status);
+		return -EIO;
+	}
+
+	/* Peripheral timeout? */
+	if (status & SMSTA_MTO) {
+		dev_err(smbus->dev, "Peripheral timeout, status 0x%08x\n", status);
+		return -ETIME;
+	}
+
+	/* Still stuck in a transaction? */
+	if (status & SMSTA_XIP) {
+		dev_err(smbus->dev, "Bus stuck, status 0x%08x\n", status);
+		return -EIO;
+	}
+
+	/* Arbitration loss? */
+	if (status & SMSTA_MTA) {
+		dev_err(smbus->dev, "Arbitration loss, status 0x%08x\n", status);
+		return -EBUSY;
+	}
+
 	/* Got NACK? */
-	if (status & SMSTA_MTN)
+	if (status & SMSTA_MTN) {
+		dev_err(smbus->dev, "NACK, status 0x%08x\n", status);
 		return -ENXIO;
+	}
 
 	/* Clear XEN */
 	reg_write(smbus, REG_SMSTA, SMSTA_XEN);
@@ -194,9 +239,9 @@ static int pasemi_i2c_xfer(struct i2c_adapter *adapter,
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
@@ -217,7 +262,9 @@ static int pasemi_smb_xfer(struct i2c_adapter *adapter,
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

