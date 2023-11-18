From: Yang Xiwen <forbidden405@outlook.com>
Date: Sun, 19 Nov 2023 06:07:06 +0800
Subject: [PATCH 3/4] clk: clk_sandbox: get devm clock i2c_root
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231111-enable_count-v1-3-509f400a99cb@outlook.com>
References: <20231111-enable_count-v1-0-509f400a99cb@outlook.com>
In-Reply-To: <20231111-enable_count-v1-0-509f400a99cb@outlook.com>
To: Simon Glass <sjg@chromium.org>, Lukasz Majewski <lukma@denx.de>, 
 Sean Anderson <seanga2@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1700345230; l=1883;
 i=forbidden405@outlook.com; s=20230415; h=from:subject:message-id;
 bh=NV6lQRVixnIUlPN940DJuyvXA1K8ViHVEEbIhr+SFt8=;
 b=t+BSBQdTipWYhTDxktYwj/lmcUyb8vE4x3hgDEuMXHozFBy5t6DNTE8los+daKxjXZrbUmWvS
 aQF8VmOWtNyChiABnKKVS6YQvy2tGji1k02kjna3M/tobngX2NfrAsS
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=hfdpPU3AXR+t7fdv58tXCD4UzRNq+fop2TMJezFlAhM=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230415 with auth_id=44
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This clock is added to dts. Get it in the devm group in the driver or
the testcases will fail.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 arch/sandbox/dts/test.dts      | 5 +++--
 arch/sandbox/include/asm/clk.h | 1 +
 drivers/clk/clk_sandbox_test.c | 5 +++++
 3 files changed, 9 insertions(+), 2 deletions(-)

diff --git a/arch/sandbox/dts/test.dts b/arch/sandbox/dts/test.dts
index b1773f1bc2..f99397c528 100644
--- a/arch/sandbox/dts/test.dts
+++ b/arch/sandbox/dts/test.dts
@@ -632,8 +632,9 @@
 			 <&clk_sandbox 1>,
 			 <&clk_sandbox 0>,
 			 <&clk_sandbox 3>,
-			 <&clk_sandbox 2>;
-		clock-names = "fixed", "i2c", "spi", "uart2", "uart1";
+			 <&clk_sandbox 2>,
+			 <&ccf 11>;
+		clock-names = "fixed", "i2c", "spi", "uart2", "uart1", "i2c_root";
 	};
 
 	clk-test2 {
diff --git a/arch/sandbox/include/asm/clk.h b/arch/sandbox/include/asm/clk.h
index df7156fe31..597bc528dc 100644
--- a/arch/sandbox/include/asm/clk.h
+++ b/arch/sandbox/include/asm/clk.h
@@ -41,6 +41,7 @@ enum sandbox_clk_test_id {
 	SANDBOX_CLK_TEST_ID_I2C,
 	SANDBOX_CLK_TEST_ID_DEVM1,
 	SANDBOX_CLK_TEST_ID_DEVM2,
+	SANDBOX_CLK_TEST_ID_I2C_ROOT,
 	SANDBOX_CLK_TEST_ID_DEVM_NULL,
 
 	SANDBOX_CLK_TEST_ID_COUNT,
diff --git a/drivers/clk/clk_sandbox_test.c b/drivers/clk/clk_sandbox_test.c
index 5807a454f3..c0623dee10 100644
--- a/drivers/clk/clk_sandbox_test.c
+++ b/drivers/clk/clk_sandbox_test.c
@@ -53,6 +53,11 @@ int sandbox_clk_test_devm_get(struct udevice *dev)
 		return PTR_ERR(clk);
 	sbct->clkps[SANDBOX_CLK_TEST_ID_DEVM2] = clk;
 
+	clk = devm_clk_get_optional(dev, "i2c_root");
+	if (IS_ERR(clk))
+		return PTR_ERR(clk);
+	sbct->clkps[SANDBOX_CLK_TEST_ID_I2C_ROOT] = clk;
+
 	sbct->clkps[SANDBOX_CLK_TEST_ID_DEVM_NULL] = NULL;
 	clk = devm_clk_get_optional(dev, "not_an_existing_clock");
 	if (IS_ERR(clk))

-- 
2.39.2

