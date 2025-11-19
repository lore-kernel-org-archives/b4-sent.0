From: Takahiro Kuwano <Takahiro.Kuwano@infineon.com>
Date: Wed, 19 Nov 2025 14:13:02 +0900
Subject: [PATCH 03/11] spi: zynqmp_gqspi: Read two bytes of SR and FSR in
 parallel mode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251119-amd-cleanup-v1-3-c555bd85e6e4@infineon.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763529253; l=1977;
 i=Takahiro.Kuwano@infineon.com; s=20250227; h=from:subject:message-id;
 bh=dYJks90c0thR9+NvaZ3228TFTgjm4+W+446C0lC1WQE=;
 b=K/am5HAxodhVQKF+wDdFBFTsmz6j3rzmtkQUq4wF9UHn0o1g3xNDbzUvuwK2BtVznM3Ced1hY
 wD18qCIFYrnAAdBbQGJyTpUBqFj3IAfQGvnDS216yx7k63c/LucG90A
X-Developer-Key: i=Takahiro.Kuwano@infineon.com; a=ed25519;
 pk=aS8V9WLuMUkl0vmgD0xJU19ZajdJmuyFBnBfVj0dfDs=
X-Endpoint-Received: by B4 Relay for Takahiro.Kuwano@infineon.com/20250227 with auth_id=566
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In parallel mode, status register value of two chips need to be read
and evaluated. Currenlty spi-nor-core takes care for that by reading
two bytes and performing logical AND of two bytes for read_sr() and
read_fsr(), assuming the controller performs byte interleaving in
parallel mode, but it depends on controller specification.

Controller driver should take care for parallel mode to read status
registers.

Signed-off-by: Takahiro Kuwano <Takahiro.Kuwano@infineon.com>
---
 drivers/spi/zynqmp_gqspi.c | 19 +++++++++++++++++++
 1 file changed, 19 insertions(+)

diff --git a/drivers/spi/zynqmp_gqspi.c b/drivers/spi/zynqmp_gqspi.c
index 143b957516b..c6cd706574e 100644
--- a/drivers/spi/zynqmp_gqspi.c
+++ b/drivers/spi/zynqmp_gqspi.c
@@ -867,11 +867,23 @@ static bool zynqmp_qspi_update_stripe(const struct spi_mem_op *op)
 	}
 }
 
+static bool zynqmp_qspi_is_read_status(const struct spi_mem_op *op)
+{
+	switch (op->cmd.opcode) {
+	case SPINOR_OP_RDSR:
+	case SPINOR_OP_RDFSR:
+		return true;
+	}
+
+	return false;
+}
+
 static int zynqmp_qspi_exec_op(struct spi_slave *slave,
 			       const struct spi_mem_op *op)
 {
 	struct zynqmp_qspi_priv *priv = dev_get_priv(slave->dev->parent);
 	int ret = 0;
+	u8 sr_buf[2];
 
 	priv->op = op;
 	priv->tx_buf = op->data.buf.out;
@@ -891,6 +903,10 @@ static int zynqmp_qspi_exec_op(struct spi_slave *slave,
 			priv->bus = 1;
 		if (zynqmp_qspi_update_stripe(op))
 			priv->stripe = 1;
+		if (zynqmp_qspi_is_read_status(op)) {
+			priv->rx_buf = sr_buf;
+			priv->len = 2;
+		}
 	}
 
 	zynqmp_qspi_chipselect(priv, 1);
@@ -904,6 +920,9 @@ static int zynqmp_qspi_exec_op(struct spi_slave *slave,
 	else if (op->data.dir == SPI_MEM_DATA_OUT)
 		ret = zynqmp_qspi_genfifo_fill_tx(priv);
 
+	if (priv->is_parallel && zynqmp_qspi_is_read_status(op))
+		*(u8 *)op->data.buf.in = sr_buf[0] & sr_buf[1];
+
 	zynqmp_qspi_chipselect(priv, 0);
 
 	return ret;

-- 
2.34.1

