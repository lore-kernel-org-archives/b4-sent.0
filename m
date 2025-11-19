From: Takahiro Kuwano <Takahiro.Kuwano@infineon.com>
Date: Wed, 19 Nov 2025 14:13:05 +0900
Subject: [PATCH 06/11] spi: zynq_qspi: Read two bytes of SR and FSR in
 parallel mode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251119-amd-cleanup-v1-6-c555bd85e6e4@infineon.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763529253; l=2092;
 i=Takahiro.Kuwano@infineon.com; s=20250227; h=from:subject:message-id;
 bh=WjL7JrYA8pMbQNnx2ziFd7r5iasN8w1r6c7vFE5QK50=;
 b=fWtCGx+JijA2nBj/f5CBHr3JMfO2fyWre60j85z1J7AUA/hhml+gDQTcAUaHcIbUP0rYZayGz
 plRw65feVcfBpzgkMbUf5h1F0N30o99vtkY0y+Q+p8zqR9h/9syi44q
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
 drivers/spi/zynq_qspi.c | 26 ++++++++++++++++++++++++--
 1 file changed, 24 insertions(+), 2 deletions(-)

diff --git a/drivers/spi/zynq_qspi.c b/drivers/spi/zynq_qspi.c
index 67005a3b8df..3d9fc11314f 100644
--- a/drivers/spi/zynq_qspi.c
+++ b/drivers/spi/zynq_qspi.c
@@ -753,6 +753,17 @@ static bool update_stripe(const struct spi_mem_op *op)
 	return true;
 }
 
+static bool zynq_qspi_is_read_status(const struct spi_mem_op *op)
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
 static int zynq_qspi_exec_op(struct spi_slave *slave,
 			     const struct spi_mem_op *op)
 {
@@ -762,6 +773,7 @@ static int zynq_qspi_exec_op(struct spi_slave *slave,
 	unsigned int flag = 0;
 	const u8 *tx_buf = NULL;
 	u8 *rx_buf = NULL;
+	u8 sr_buf[2];
 
 	if (op->data.nbytes) {
 		if (op->data.dir == SPI_MEM_DATA_IN)
@@ -805,10 +817,20 @@ static int zynq_qspi_exec_op(struct spi_slave *slave,
 
 	/* 2nd transfer: rx or tx data path */
 	if (tx_buf || rx_buf) {
-		ret = zynq_qspi_xfer(slave->dev, op->data.nbytes * 8, tx_buf,
-				     rx_buf, flag | SPI_XFER_END);
+		op_len = op->data.nbytes;
+
+		if (priv->is_parallel && zynq_qspi_is_read_status(op)) {
+			rx_buf = sr_buf;
+			op_len = 2;
+		}
+
+		ret = zynq_qspi_xfer(slave->dev, op_len * 8, tx_buf, rx_buf,
+				     flag | SPI_XFER_END);
 		if (ret)
 			return ret;
+
+		if (priv->is_parallel && zynq_qspi_is_read_status(op))
+			*(u8 *)op->data.buf.in = sr_buf[0] & sr_buf[1];
 	}
 
 	spi_release_bus(slave);

-- 
2.34.1

