From: Yang Xiwen <forbidden405@outlook.com>
Date: Sun, 19 Nov 2023 06:10:08 +0800
Subject: [PATCH v2 4/4] test: dm: clk_ccf: get "i2c_root" clock from
 &clk_ccf
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231111-enable_count-v2-4-20e3728600b5@outlook.com>
References: <20231111-enable_count-v2-0-20e3728600b5@outlook.com>
In-Reply-To: <20231111-enable_count-v2-0-20e3728600b5@outlook.com>
To: Simon Glass <sjg@chromium.org>, Lukasz Majewski <lukma@denx.de>, 
 Sean Anderson <seanga2@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1700345405; l=1735;
 i=forbidden405@outlook.com; s=20230415; h=from:subject:message-id;
 bh=kEgPFJ4X6SdN9/xo6Bpw8Z8sY9qknlOpf5kLOse5840=;
 b=wUskUNU0LOLnt604lHn7i3NBTNmkVqKUiUTXqFKnwBGDueXFXz5fqXxv18SuviLZK1Yxhqu+M
 EQl6YurMF/BDmHQ0Po/7zxtnVJBijKKwh+eIo0PR5fiaYOWLBg8t7oG
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=hfdpPU3AXR+t7fdv58tXCD4UzRNq+fop2TMJezFlAhM=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230415 with auth_id=44
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

get i2c_root clock from device tree. In this way we get an CCF clock and
also test ccf_clk_ops.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 test/dm/clk_ccf.c | 14 +++++++++++---
 1 file changed, 11 insertions(+), 3 deletions(-)

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

