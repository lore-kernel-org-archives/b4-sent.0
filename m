From: Yang Xiwen <forbidden405@outlook.com>
Date: Sat, 16 Dec 2023 02:28:52 +0800
Subject: [PATCH v3 2/2] test: dm: clk_ccf: test ccf_clk_ops
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231111-enable_count-v3-2-08a821892fa9@outlook.com>
References: <20231111-enable_count-v3-0-08a821892fa9@outlook.com>
In-Reply-To: <20231111-enable_count-v3-0-08a821892fa9@outlook.com>
To: Simon Glass <sjg@chromium.org>, Lukasz Majewski <lukma@denx.de>, 
 Sean Anderson <seanga2@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1702664931; l=4095;
 i=forbidden405@outlook.com; s=20230415; h=from:subject:message-id;
 bh=xkLwbswSd9yLC9pHs+IXaFwvSpaLH5hsTUHW/xM9Jhc=;
 b=XYHi1ozdb1XcBbG/7Zl77CI4bVTgo171eIh429wzQu23SSEqfBZl9d6MFG8gx6BEGoUDAIMen
 fVSfbPBsBRYAzJnfZ5V4u6qjcFgeYAk17moY9q+WyrbT5Az55ZcQaqU
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=hfdpPU3AXR+t7fdv58tXCD4UzRNq+fop2TMJezFlAhM=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230415 with auth_id=44
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Assign ccf_clk_ops to .ops of clk_ccf driver so that it can act as an
clk provider. Also add "#clock-cells=<1>" to its device tree node.

Add "i2c_root" to clk_test in the device tree and driver for testing.

Get "i2c_root" clock in CCF unit tests and add tests for it.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 arch/sandbox/dts/test.dts      |  4 +++-
 arch/sandbox/include/asm/clk.h |  1 +
 drivers/clk/clk_sandbox_ccf.c  |  1 +
 drivers/clk/clk_sandbox_test.c |  1 +
 test/dm/clk_ccf.c              | 14 +++++++++++---
 5 files changed, 17 insertions(+), 4 deletions(-)

diff --git a/arch/sandbox/dts/test.dts b/arch/sandbox/dts/test.dts
index c7197795ef..a3a865d65c 100644
--- a/arch/sandbox/dts/test.dts
+++ b/arch/sandbox/dts/test.dts
@@ -631,9 +631,10 @@
 		clocks = <&clk_fixed>,
 			 <&clk_sandbox 1>,
 			 <&clk_sandbox 0>,
+			 <&ccf 11>,
 			 <&clk_sandbox 3>,
 			 <&clk_sandbox 2>;
-		clock-names = "fixed", "i2c", "spi", "uart2", "uart1";
+		clock-names = "fixed", "i2c", "spi", "i2c_root", "uart2", "uart1";
 	};
 
 	clk-test2 {
@@ -654,6 +655,7 @@
 
 	ccf: clk-ccf {
 		compatible = "sandbox,clk-ccf";
+		#clock-cells = <1>;
 	};
 
 	efi-media {
diff --git a/arch/sandbox/include/asm/clk.h b/arch/sandbox/include/asm/clk.h
index df7156fe31..1daf2e7ac7 100644
--- a/arch/sandbox/include/asm/clk.h
+++ b/arch/sandbox/include/asm/clk.h
@@ -39,6 +39,7 @@ enum sandbox_clk_test_id {
 	SANDBOX_CLK_TEST_ID_FIXED,
 	SANDBOX_CLK_TEST_ID_SPI,
 	SANDBOX_CLK_TEST_ID_I2C,
+	SANDBOX_CLK_TEST_ID_I2C_ROOT,
 	SANDBOX_CLK_TEST_ID_DEVM1,
 	SANDBOX_CLK_TEST_ID_DEVM2,
 	SANDBOX_CLK_TEST_ID_DEVM_NULL,
diff --git a/drivers/clk/clk_sandbox_ccf.c b/drivers/clk/clk_sandbox_ccf.c
index fedcdd4044..38184e27aa 100644
--- a/drivers/clk/clk_sandbox_ccf.c
+++ b/drivers/clk/clk_sandbox_ccf.c
@@ -284,6 +284,7 @@ static int sandbox_clk_ccf_probe(struct udevice *dev)
 U_BOOT_DRIVER(sandbox_clk_ccf) = {
 	.name = "sandbox_clk_ccf",
 	.id = UCLASS_CLK,
+	.ops = &ccf_clk_ops,
 	.probe = sandbox_clk_ccf_probe,
 	.of_match = sandbox_clk_ccf_test_ids,
 };
diff --git a/drivers/clk/clk_sandbox_test.c b/drivers/clk/clk_sandbox_test.c
index 5807a454f3..c695b69321 100644
--- a/drivers/clk/clk_sandbox_test.c
+++ b/drivers/clk/clk_sandbox_test.c
@@ -15,6 +15,7 @@ static const char * const sandbox_clk_test_names[] = {
 	[SANDBOX_CLK_TEST_ID_FIXED] = "fixed",
 	[SANDBOX_CLK_TEST_ID_SPI] = "spi",
 	[SANDBOX_CLK_TEST_ID_I2C] = "i2c",
+	[SANDBOX_CLK_TEST_ID_I2C_ROOT] = "i2c_root",
 };
 
 int sandbox_clk_test_get(struct udevice *dev)
diff --git a/test/dm/clk_ccf.c b/test/dm/clk_ccf.c
index e4ebb93cda..b8be6d6572 100644
--- a/test/dm/clk_ccf.c
+++ b/test/dm/clk_ccf.c
@@ -18,8 +18,8 @@
 /* Tests for Common Clock Framework driver */
 static int dm_test_clk_ccf(struct unit_test_state *uts)
 {
-	struct clk *clk, *pclk;
-	struct udevice *dev;
+	struct clk *clk, *pclk, clk_ccf;
+	struct udevice *dev, *test_dev;
 	long long rate;
 	int ret;
 #if CONFIG_IS_ENABLED(CLK_CCF)
@@ -29,6 +29,7 @@ static int dm_test_clk_ccf(struct unit_test_state *uts)
 
 	/* Get the device using the clk device */
 	ut_assertok(uclass_get_device_by_name(UCLASS_CLK, "clk-ccf", &dev));
+	ut_assertok(uclass_get_device_by_name(UCLASS_MISC, "clk-test", &test_dev));
 
 	/* Test for clk_get_by_id() */
 	ret = clk_get_by_id(SANDBOX_CLK_ECSPI_ROOT, &clk);
@@ -110,11 +111,18 @@ static int dm_test_clk_ccf(struct unit_test_state *uts)
 
 #if CONFIG_IS_ENABLED(CLK_CCF)
 	/* Test clk tree enable/disable */
+
+	ret = clk_get_by_index(test_dev, SANDBOX_CLK_TEST_ID_I2C_ROOT, &clk_ccf);
+	ut_assertok(ret);
+	ut_asserteq_str("clk-ccf", clk_ccf.dev->name);
+	ut_asserteq(clk_ccf.id, SANDBOX_CLK_I2C_ROOT);
+
 	ret = clk_get_by_id(SANDBOX_CLK_I2C_ROOT, &clk);
 	ut_assertok(ret);
 	ut_asserteq_str("i2c_root", clk->dev->name);
+	ut_asserteq(clk->id, SANDBOX_CLK_I2C_ROOT);
 
-	ret = clk_enable(clk);
+	ret = clk_enable(&clk_ccf);
 	ut_assertok(ret);
 
 	ret = sandbox_clk_enable_count(clk);

-- 
2.39.2

