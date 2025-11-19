From: Takahiro Kuwano <Takahiro.Kuwano@infineon.com>
Date: Wed, 19 Nov 2025 14:13:03 +0900
Subject: [PATCH 04/11] spi: zynq-qspi: Set priv->is_parallel/stacked in
 child_pre_probe()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251119-amd-cleanup-v1-4-c555bd85e6e4@infineon.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763529253; l=2137;
 i=Takahiro.Kuwano@infineon.com; s=20250227; h=from:subject:message-id;
 bh=AcN4YC1gFntwwrYIL2/OY5TYR2qJN2dBFjKE+vFyyx0=;
 b=nSdcPv6/MpckFvlZTkjPkJBwlkyU7yYrRYW1ZnCZhRlSqXRJadKKQZjPKonn3TYI9Ee6Bovf+
 o9AbmzDl+XEAmz1vmT+AnyJOLJnRchHj0Qz5upv6n4wFwqgoI8jLSi5
X-Developer-Key: i=Takahiro.Kuwano@infineon.com; a=ed25519;
 pk=aS8V9WLuMUkl0vmgD0xJU19ZajdJmuyFBnBfVj0dfDs=
X-Endpoint-Received: by B4 Relay for Takahiro.Kuwano@infineon.com/20250227 with auth_id=566
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

priv->is_paralle/stacked should be set at probe instead of at every
exec_op(). It can be set in child_pre_probe() by checking the existence
of parallel/stacked-memories property.

Also remove QSPI_SELECT_LOWER/UPPER_CS flags. They are problematic as
they overwrite SPI_XFER_BEGIN/END defined in spi.h.

Signed-off-by: Takahiro Kuwano <Takahiro.Kuwano@infineon.com>
---
 drivers/spi/zynq_qspi.c | 20 +++++++++-----------
 1 file changed, 9 insertions(+), 11 deletions(-)

diff --git a/drivers/spi/zynq_qspi.c b/drivers/spi/zynq_qspi.c
index e43dbb40c4a..a2d6d80d04e 100644
--- a/drivers/spi/zynq_qspi.c
+++ b/drivers/spi/zynq_qspi.c
@@ -46,9 +46,6 @@ DECLARE_GLOBAL_DATA_PTR;
 #define ZYNQ_QSPI_TXD_00_11_OFFSET	0x88	/* Transmit 3-byte inst */
 #define ZYNQ_QSPI_FR_QOUT_CODE		0x6B    /* read instruction code */
 
-#define QSPI_SELECT_LOWER_CS            BIT(0)
-#define QSPI_SELECT_UPPER_CS            BIT(1)
-
 /*
  * QSPI Linear Configuration Register
  *
@@ -205,6 +202,15 @@ static int zynq_qspi_child_pre_probe(struct udevice *bus)
 	priv->max_hz = slave->max_hz;
 	slave->multi_cs_cap = true;
 
+	/*
+	 * The properties have values that represent flash sizes but we just
+	 * need to know the existence of the property here.
+	 */
+	priv->is_parallel = ofnode_read_bool(dev_ofnode(bus),
+					     "parallel-memories");
+	priv->is_stacked = ofnode_read_bool(dev_ofnode(bus),
+					    "stacked-memories");
+
 	return 0;
 }
 
@@ -757,12 +763,6 @@ static int zynq_qspi_exec_op(struct spi_slave *slave,
 	const u8 *tx_buf = NULL;
 	u8 *rx_buf = NULL;
 
-	if ((slave->flags & QSPI_SELECT_LOWER_CS) &&
-	    (slave->flags & QSPI_SELECT_UPPER_CS))
-		priv->is_parallel = true;
-	if (slave->flags & SPI_XFER_STACKED)
-		priv->is_stacked = true;
-
 	if (op->data.nbytes) {
 		if (op->data.dir == SPI_MEM_DATA_IN)
 			rx_buf = op->data.buf.in;
@@ -811,8 +811,6 @@ static int zynq_qspi_exec_op(struct spi_slave *slave,
 			return ret;
 	}
 
-	priv->is_parallel = false;
-	priv->is_stacked = false;
 	slave->flags &= ~SPI_XFER_LOWER;
 	spi_release_bus(slave);
 

-- 
2.34.1

