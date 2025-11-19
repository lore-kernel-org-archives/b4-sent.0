From: Takahiro Kuwano <Takahiro.Kuwano@infineon.com>
Date: Wed, 19 Nov 2025 14:13:00 +0900
Subject: [PATCH 01/11] spi: zynqmp-gqspi: Set priv->is_parallel in
 child_pre_probe()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251119-amd-cleanup-v1-1-c555bd85e6e4@infineon.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763529253; l=1838;
 i=Takahiro.Kuwano@infineon.com; s=20250227; h=from:subject:message-id;
 bh=AqEOg4BZ9g/wU8lhyQ1H3eCgVdFedrYMVSatqvFmKYE=;
 b=3+dOvAz4haA1MrUtN8408QBjL1cQXC6KbuSThy5oWdIgUIcQexZIq95tGrWluM0gKQ192R8yE
 VF3xfGP83pmAi3MpE0gp4WcwXmhaVMhM8NgCFmkWfs7DJbvfED0Rs4r
X-Developer-Key: i=Takahiro.Kuwano@infineon.com; a=ed25519;
 pk=aS8V9WLuMUkl0vmgD0xJU19ZajdJmuyFBnBfVj0dfDs=
X-Endpoint-Received: by B4 Relay for Takahiro.Kuwano@infineon.com/20250227 with auth_id=566
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

priv->is_parallel should be set at probe instead of at every exec_op().
It can be set in child_pre_probe() by checking the existence of
parallel-memories property.

Also remove GQSPI_SELECT_LOWER/UPPER_CS flags. They are problematic as
they overwrite SPI_XFER_BEGIN/END defined in spi.h.

Signed-off-by: Takahiro Kuwano <Takahiro.Kuwano@infineon.com>
---
 drivers/spi/zynqmp_gqspi.c | 15 +++++++--------
 1 file changed, 7 insertions(+), 8 deletions(-)

diff --git a/drivers/spi/zynqmp_gqspi.c b/drivers/spi/zynqmp_gqspi.c
index 2a095d0c58e..4a25ee0c459 100644
--- a/drivers/spi/zynqmp_gqspi.c
+++ b/drivers/spi/zynqmp_gqspi.c
@@ -89,9 +89,6 @@
 #define SPI_XFER_ON_LOWER		1
 #define SPI_XFER_ON_UPPER		2
 
-#define GQSPI_SELECT_LOWER_CS          BIT(0)
-#define GQSPI_SELECT_UPPER_CS          BIT(1)
-
 #define GQSPI_DMA_ALIGN			0x4
 #define GQSPI_MAX_BAUD_RATE_VAL		7
 #define GQSPI_DFLT_BAUD_RATE_VAL	2
@@ -439,6 +436,13 @@ static int zynqmp_qspi_child_pre_probe(struct udevice *bus)
 	slave->bytemode = SPI_4BYTE_MODE;
 	priv->max_hz = slave->max_hz;
 
+	/*
+	 * The property has values that represent flash sizes but we just need
+	 * to know the existence of the property here.
+	 */
+	priv->is_parallel = ofnode_read_bool(dev_ofnode(bus),
+					     "parallel-memories");
+
 	return 0;
 }
 
@@ -862,10 +866,6 @@ static int zynqmp_qspi_exec_op(struct spi_slave *slave,
 	else
 		priv->u_page = 0;
 
-	if ((slave->flags & GQSPI_SELECT_LOWER_CS) &&
-	    (slave->flags & GQSPI_SELECT_UPPER_CS))
-		priv->is_parallel = true;
-
 	priv->stripe = 0;
 	priv->bus = 0;
 
@@ -889,7 +889,6 @@ static int zynqmp_qspi_exec_op(struct spi_slave *slave,
 
 	zynqmp_qspi_chipselect(priv, 0);
 
-	priv->is_parallel = false;
 	slave->flags &= ~SPI_XFER_LOWER;
 
 	return ret;

-- 
2.34.1

