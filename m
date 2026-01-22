From: Abdurrahman Hussain <abdurrahman@nexthop.ai>
Date: Thu, 22 Jan 2026 09:00:29 +0000
Subject: [PATCH v3] spi: xilinx: use device property accessors.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260122-spi-xilinx-v3-1-8cea20e82f0b@nexthop.ai>
X-B4-Tracking: v=1; b=H4sIACzncWkC/03MQQ6CMBBA0auQWTukU6SiK+9hXBQZ7CRSyBRNE
 8LdbVy5fIv/N0iswgku1QbKH0kyx4LmUMEj+PhklKEYrLHOEHWYFsEsL4kZqe+649D2rqUzlGB
 RHiX/Zrd78ajzhGtQ9v+LkyFLjauta601SOj74a3qw+TjNXJew7zUXmDfv27egTSdAAAA
X-Change-ID: 20260118-spi-xilinx-1b884d5b6519
To: Mark Brown <broonie@kernel.org>, Michal Simek <michal.simek@amd.com>
Cc: linux-spi@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Abdurrahman Hussain <abdurrahman@nexthop.ai>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769072434; l=1349;
 i=abdurrahman@nexthop.ai; s=20260119; h=from:subject:message-id;
 bh=viHwx+jv2rWkq2BAgRQtX9ZKmm78TjPHuLyAvr0R44g=;
 b=MHAPlWH5Jbo0z7ZJ5RovdK2iNh+yldLOZ1VZvSlym04m9sAfV19Jv40biP9TcdKUKZEdGGZKW
 9ov8hyBh5KXCuoQ2jOiH2lz8DvLRM1hHIi+YBfDnE+J1WnZX8GYDOj9
X-Developer-Key: i=abdurrahman@nexthop.ai; a=ed25519;
 pk=S+ysnf+NwMcBdHBlyKIUEAtaFGSIhQwcJcgcXhq0osg=
X-Endpoint-Received: by B4 Relay for abdurrahman@nexthop.ai/20260119 with auth_id=608
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Switch to device property accessors.

Signed-off-by: Abdurrahman Hussain <abdurrahman@nexthop.ai>
---
Switch to generic device property accessors.

Changed from v3:

Removed the patches to make irq optional from the series

2.52.0

base-commit: 944aacb68baf7624ab8d277d0ebf07f025ca137c
---
 drivers/spi/spi-xilinx.c | 10 +++++-----
 1 file changed, 5 insertions(+), 5 deletions(-)

diff --git a/drivers/spi/spi-xilinx.c b/drivers/spi/spi-xilinx.c
index c86dc56f38b4..c4b70e95b695 100644
--- a/drivers/spi/spi-xilinx.c
+++ b/drivers/spi/spi-xilinx.c
@@ -405,11 +405,11 @@ static int xilinx_spi_probe(struct platform_device *pdev)
 		bits_per_word = pdata->bits_per_word;
 		force_irq = pdata->force_irq;
 	} else {
-		of_property_read_u32(pdev->dev.of_node, "xlnx,num-ss-bits",
-					  &num_cs);
-		ret = of_property_read_u32(pdev->dev.of_node,
-					   "xlnx,num-transfer-bits",
-					   &bits_per_word);
+		device_property_read_u32(&pdev->dev, "xlnx,num-ss-bits",
+					 &num_cs);
+		ret = device_property_read_u32(&pdev->dev,
+					       "xlnx,num-transfer-bits",
+					       &bits_per_word);
 		if (ret)
 			bits_per_word = 8;
 	}

---
base-commit: 944aacb68baf7624ab8d277d0ebf07f025ca137c
change-id: 20260118-spi-xilinx-1b884d5b6519

Best regards,
-- 
Abdurrahman Hussain <abdurrahman@nexthop.ai>

