From: Abdurrahman Hussain <abdurrahman@nexthop.ai>
Date: Tue, 03 Feb 2026 01:55:12 +0000
Subject: [PATCH v4] spi: xilinx: use device property accessors.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260203-spi-xilinx-v4-1-42f7c326061b@nexthop.ai>
X-B4-Tracking: v=1; b=H4sIAH9VgWkC/03OQQ6DIBCF4asY1sXAqJR21Xs0LkDHMklFA9bYG
 O9eNF24/Bfvy1tZxEAY2T1bWcCZIg0+RXnJWOOMfyGnNjUDAUpIqXkciS/0Jr9wabUu28qqSt5
 YGowBO1oO7Fmn7sLQ88kFNGfiKiTIQuWgKgDBJTe2/YRgXG/8w+MyuWHMDe2gozgN4Xucm4ud/
 SMA5x9zkRTdoAGBGjphz0y9bdsPsT+ax+YAAAA=
X-Change-ID: 20260118-spi-xilinx-1b884d5b6519
To: Mark Brown <broonie@kernel.org>, Michal Simek <michal.simek@amd.com>
Cc: linux-spi@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Abdurrahman Hussain <abdurrahman@nexthop.ai>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770083719; l=1424;
 i=abdurrahman@nexthop.ai; s=20260119; h=from:subject:message-id;
 bh=JnhvafHbNCA383rSJUeixD1NuH8QF2CYjO1pAgK3Pbs=;
 b=4kZg1Y5eIQ5AUsqkxYCepuzdNSwUt5ZgPJLeCt7hsoG5JfExAcj+26GBMPshRjiD0GsWqGkjc
 OOf6cP+lKA7DoDZkCl5vICaChIHBevWJvMGBxn2578x8A+B0y0Ucs/B
X-Developer-Key: i=abdurrahman@nexthop.ai; a=ed25519;
 pk=S+ysnf+NwMcBdHBlyKIUEAtaFGSIhQwcJcgcXhq0osg=
X-Endpoint-Received: by B4 Relay for abdurrahman@nexthop.ai/20260119 with auth_id=608
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Switch to device property accessors.

Signed-off-by: Abdurrahman Hussain <abdurrahman@nexthop.ai>
---
Switch to generic device property accessors.

2.52.0

base-commit: 944aacb68baf7624ab8d277d0ebf07f025ca137c
---
Changes in v4:
- Removed patches making the irq optional.
- Link to v3: https://lore.kernel.org/r/20260122-spi-xilinx-v3-1-8cea20e82f0b@nexthop.ai
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

