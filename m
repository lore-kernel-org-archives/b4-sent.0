From: Federico Fuga <fuga@studiofuga.com>
Date: Wed, 03 Sep 2025 18:31:36 +0200
Subject: [PATCH] SUNXI / TWSI: Implement I2C bus unlocking for stuck
 devices during initialization.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250903-fix-i2c_stuck_bus-v1-1-b2583ca6703b@studiofuga.com>
X-B4-Tracking: v=1; b=H4sIAGdtuGgC/x2M0QpAQBAAf0X77GrdOeJXJHG32BS6RUr+3eVxa
 mYeEApMAnXyQKCLhbc1QpYm4OZ+nUixjwwatcUKjRr5VqxdJ8fplm44ReVojTdlX6C3ELs9UJT
 +Z9O+7wf0NDwKYwAAAA==
X-Change-ID: 20250903-fix-i2c_stuck_bus-4053d37a60d5
To: Stefan Roese <stefan.roese@mailbox.org>, 
 Heiko Schocher <hs@nabladev.com>, Tom Rini <trini@konsulko.com>
Cc: u-boot@lists.denx.de, Federico Fuga <fuga@studiofuga.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=5156; i=fuga@studiofuga.com;
 h=from:subject:message-id; bh=R2rYc4d7A5y6B8AyV0Sx/umAav/jlGPTR1mI0EJ4P1s=;
 b=owGbwMvMwCWWHKr8a5mpjg3jabUkhowduRmmWhzsr/dc7+3tvyQv/H/p67fPr4bx3Xum4X7r3
 tSKNY84OkpZGMS4GGTFFFnmvHx2Jutb9tmPuuu1YOawMoEMYeDiFICJHFvEyHB+w13Lm0XfBXUa
 moQXhV1qiRLM6917MijR/uGy+1Nu5RozMsx90lTBa984QV924vyW5sdX3G6e5zm/1Kcp616i8FK
 hGRwA
X-Developer-Key: i=fuga@studiofuga.com; a=openpgp;
 fpr=9CE9E6CC6AF66BCDF12DAF2A635523FAA6352C3C
X-Endpoint-Received: by B4 Relay for fuga@studiofuga.com/default with auth_id=333
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch introduces an I2C bus recovery mechanism for the Marvell mvtwsi controller, limited to sunxi versions.

Under certain conditions, such as a system reset during an active I2C transaction, a slave device can be left holding the SDA line low. This occurs because the slave is still waiting for the master to complete the transfer with clock pulses, but the master (CPU) has been reset.

While the mvtwsi peripheral is reset during boot, this does not affect the state of the slave device on the bus. The bus remains stuck, which can be detected during driver initialization by observing that the I2C Status Register is not in its expected IDLE state (0xF8).

This patchset adds logic to check for this condition during init. If a non-IDLE state is detected, it triggers a bus recovery procedure to unlock the bus and return it to a functional state.

This code is applicable for SUNXI devices only, that allow direct control of SDA/SCL signals.

Testing
This implementation was successfully tested on an older version of U-Boot, where it reliably fixed a reproducible bus-hang issue. It has not been tested on the current master branch, but a review of the driver shows that the relevant code sections are very similar. Community testing on current hardware would be greatly appreciated.

---
Federico Fuga

Signed-off-by: Federico Fuga <fuga@studiofuga.com>
---
 drivers/i2c/mvtwsi.c | 81 ++++++++++++++++++++++++++++++++++++++++++++++++++--
 1 file changed, 79 insertions(+), 2 deletions(-)

diff --git a/drivers/i2c/mvtwsi.c b/drivers/i2c/mvtwsi.c
index 44e8e191b0392b9a91e19f2e32c3df2039789064..b574bbe3173888a6202c057495c2d786b952bc33 100644
--- a/drivers/i2c/mvtwsi.c
+++ b/drivers/i2c/mvtwsi.c
@@ -63,6 +63,9 @@ struct  mvtwsi_registers {
 	u32 status;
 	u32 baudrate;
 	u32 soft_reset;
+	u32 enhanced_features;
+	u32 twi_line;
+	u32 twi_dvfs;
 	u32 debug; /* Dummy field for build compatibility with mvebu */
 };
 
@@ -446,12 +449,75 @@ static uint twsi_calc_freq(const int n, const int m)
  */
 static void twsi_reset(struct mvtwsi_registers *twsi)
 {
+	int i;
+
 	/* Reset controller */
 	writel(0, &twsi->soft_reset);
-	/* Wait 2 ms -- this is what the Marvell LSP does */
-	udelay(20000);
+	for (i = 10; i > 0; --i) {
+		/* poll the controller for reset. */
+		if (readl(&twsi->soft_reset) == 0)
+			break;
+		udelay(2000);
+	}
+}
+
+#if defined(CONFIG_ARCH_SUNXI)
+/*
+ * twsi_bus_unblock() - Forcibly unblock i2c devices stuck on transactions.
+ *
+ * If a i2c/twsi transaction is aborted by resetting the controller, the bus might be locked by the
+ * active slave device being stuck waiting for more clock pulse to complete the transaction. This
+ * might happen if the CPU is reset during a transaction.
+ *
+ * In this case, the reset of the bus controller is uneffective. A special procedure is required:
+ * the SCL signal must be pulsed 8 or more times while keeping the SDA signal weak (high), and
+ * then by issuing a STOP signal.
+ *
+ * This function perform this procedure for SUNXI devices that has control of the SDA/SCL signals
+ * through special registers.
+ *
+ * @twsi: The MVTWSI register structure to use.
+ */
+static void twsi_bus_unblock(struct mvtwsi_registers *twsi)
+{
+	int v;
+
+	// Take control of SDA and SCL
+	writel(readl(&twsi->twi_line) | 0x05, &twsi->twi_line);
+
+	// Pull SCL and SDA high
+	writel(readl(&twsi->twi_line) | 0x0a, &twsi->twi_line);
+	ndelay(1000);
+
+	// Pulse SCL 16 times
+	for (v = 0; v < 16; ++v) {
+		writel(readl(&twsi->twi_line) | 0x08, &twsi->twi_line);
+		ndelay(1000);
+		writel(readl(&twsi->twi_line) & 0xf7, &twsi->twi_line);
+		ndelay(1000);
+	}
+
+	// Isse a stop: pull SDA low, then SCL up, then SDA up.
+	writel(readl(&twsi->twi_line) & 0xfe, &twsi->twi_line);
+	ndelay(1000);
+	writel(readl(&twsi->twi_line) | 0x08, &twsi->twi_line);
+	ndelay(1000);
+	writel(readl(&twsi->twi_line) | 0x02, &twsi->twi_line);
+	ndelay(1000);
+
+	// release control of SDA and SCL. Then proceed with init.
+	writel(readl(&twsi->twi_line) & 0x0a, &twsi->twi_line);
+	ndelay(1000);
+}
+
+#else
+
+static void twsi_bus_unblock(struct mvtwsi_registers *twsi)
+{
 }
 
+#endif
+
 /*
  * __twsi_i2c_set_bus_speed() - Set the speed of the I2C controller.
  *
@@ -510,9 +576,20 @@ static void __twsi_i2c_init(struct mvtwsi_registers *twsi, int speed,
 			    int slaveadd, uint *actual_speed)
 {
 	uint tmp_speed;
+	uint v;
 
 	/* Reset controller */
 	twsi_reset(twsi);
+
+	/* Check for Status Register. The register should be set at MVTWSI_STATUS_IDLE (0xf8) after reset.
+	 * If this is not the case, the bus might be hard locked by a stuck device.
+	 * Issue an emergency unlock procedure
+	 */
+	v = readl(&twsi->status);
+	if (v != MVTWSI_STATUS_IDLE) {
+		twsi_bus_unblock(twsi);
+	}
+
 	/* Set speed */
 	tmp_speed = __twsi_i2c_set_bus_speed(twsi, speed);
 	if (actual_speed)

---
base-commit: 9ba067aea83404243de08390e9177dd8f59e5e02
change-id: 20250903-fix-i2c_stuck_bus-4053d37a60d5

Best regards,
-- 
Federico Fuga <fuga@studiofuga.com>

