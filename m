From: Takahiro Kuwano <Takahiro.Kuwano@infineon.com>
Date: Wed, 19 Nov 2025 14:13:01 +0900
Subject: [PATCH 02/11] spi: zynqmp_gqspi: Remove reference to
 SPI_XFER_LOWER flag.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251119-amd-cleanup-v1-2-c555bd85e6e4@infineon.com>
References: <20251119-amd-cleanup-v1-0-c555bd85e6e4@infineon.com>
In-Reply-To: <20251119-amd-cleanup-v1-0-c555bd85e6e4@infineon.com>
To: u-boot@lists.denx.de, Tudor Ambarus <tudor.ambarus@linaro.org>
Cc: Jagan Teki <jagan@amarulasolutions.com>, 
 Michal Simek <michal.simek@amd.com>, Tom Rini <trini@konsulko.com>, 
 Ibai Erkiaga <ibai.erkiaga-elorza@amd.com>, Vignesh R <vigneshr@ti.com>, 
 Prasad Kummari <prasad.kummari@amd.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Havish Mutya <havish.mutya@amd.com>, 
 Ashok Reddy Soma <ashok.reddy.soma@amd.com>, 
 Venkatesh Yadav Abbarapu <venkatesh.abbarapu@amd.com>, 
 Daassi Bacem <Bacem.Daassi@infineon.com>, 
 Shinsuke Okada <Shinsuke.Okada@infineon.com>, 
 Hiroyuki Saito <Hiroyuki.Saito2@infineon.com>, 
 Takahiro Kuwano <tkuw584924@gmail.com>, 
 Takahiro Kuwano <Takahiro.Kuwano@infineon.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763529253; l=1582;
 i=Takahiro.Kuwano@infineon.com; s=20250227; h=from:subject:message-id;
 bh=VNUuewgVolvHFP3F2HRpZhcnlgOZR8fV/mUTRvu645U=;
 b=FFfXTMgppHDZdzBcotbasNSqvAK4XA9HP2omVqXVYpnO47BqHiTdHGnXvclMHyxosFOzEKxQY
 aBJaTFPvHztDHhzPQACP2yGUSBMnfe2iEANhEe21J4PEC1rpYv+F06F
X-Developer-Key: i=Takahiro.Kuwano@infineon.com; a=ed25519;
 pk=aS8V9WLuMUkl0vmgD0xJU19ZajdJmuyFBnBfVj0dfDs=
X-Endpoint-Received: by B4 Relay for Takahiro.Kuwano@infineon.com/20250227 with auth_id=566
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

SPI_XFER_LOWER is set in spi-nor-core for reading ID, SFDP and BAR.
The flag is referenced by AMD controllers only. Controller drivers can
intercept the opcode and change its settings accordingly.

Signed-off-by: Takahiro Kuwano <Takahiro.Kuwano@infineon.com>
---
 drivers/spi/zynqmp_gqspi.c | 21 ++++++++++++++++++---
 1 file changed, 18 insertions(+), 3 deletions(-)

diff --git a/drivers/spi/zynqmp_gqspi.c b/drivers/spi/zynqmp_gqspi.c
index 4a25ee0c459..143b957516b 100644
--- a/drivers/spi/zynqmp_gqspi.c
+++ b/drivers/spi/zynqmp_gqspi.c
@@ -823,6 +823,23 @@ static int zynqmp_qspi_release_bus(struct udevice *dev)
 	return 0;
 }
 
+static bool zynqmp_qspi_is_lower_only(const struct spi_mem_op *op)
+{
+	/*
+	 * This is a list of opcodes for which we must read only from lower chip
+	 * in dual parallel mode.
+	 */
+	switch (op->cmd.opcode) {
+	case SPINOR_OP_RDID:
+	case SPINOR_OP_RDSFDP:
+	case SPINOR_OP_BRRD:
+	case SPINOR_OP_RDEAR:
+		return true;
+	}
+
+	return false;
+}
+
 static bool zynqmp_qspi_update_stripe(const struct spi_mem_op *op)
 {
 	/*
@@ -870,7 +887,7 @@ static int zynqmp_qspi_exec_op(struct spi_slave *slave,
 	priv->bus = 0;
 
 	if (priv->is_parallel) {
-		if (slave->flags & SPI_XFER_LOWER)
+		if (zynqmp_qspi_is_lower_only(op))
 			priv->bus = 1;
 		if (zynqmp_qspi_update_stripe(op))
 			priv->stripe = 1;
@@ -889,8 +906,6 @@ static int zynqmp_qspi_exec_op(struct spi_slave *slave,
 
 	zynqmp_qspi_chipselect(priv, 0);
 
-	slave->flags &= ~SPI_XFER_LOWER;
-
 	return ret;
 }
 

-- 
2.34.1

