From: Yang Xiwen <forbidden405@outlook.com>
Date: Thu, 01 Jan 2026 03:52:51 +0800
Subject: [PATCH v2 5/5] test: clk: add test for CLK_LAZY_REPARENT
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260101-clk-reparent-v2-5-3eb42b78c7f1@outlook.com>
References: <20260101-clk-reparent-v2-0-3eb42b78c7f1@outlook.com>
In-Reply-To: <20260101-clk-reparent-v2-0-3eb42b78c7f1@outlook.com>
To: Simon Glass <sjg@chromium.org>, Tom Rini <trini@konsulko.com>, 
 Lukasz Majewski <lukma@denx.de>, Sean Anderson <seanga2@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767210769; l=3118;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=0Pl/4UHRtRVi92DdI/7xYV0tGtA+gqluhy3uohM5ie0=;
 b=V6l/EmNk9rF8Fyy/dPheLmqVFpDUA6zzIcSbzP57DDZpwXrdKw4xM4lSwIdufLty/ZNRgWuMm
 Ai423hmU1vMCBgFquiR8eWT3+WnlXburo2+DbD0LRrSkp5Wn3S7nkwc
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a test for the newly introduced CLK_LAZY_PARENT feature.

Modify clk_sandbox_ccf driver to register two clocks(i2s and i2s_root)
in reversed order.

The test function then try to acquire the clocks and asserts that their
internal states are maintained correctly.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/clk/clk_sandbox_ccf.c | 10 ++++++++++
 include/sandbox-clk.h         |  2 ++
 test/dm/clk_ccf.c             | 29 +++++++++++++++++++++++++++++
 3 files changed, 41 insertions(+)

diff --git a/drivers/clk/clk_sandbox_ccf.c b/drivers/clk/clk_sandbox_ccf.c
index f96a15c30b3a..3a11b361cd2b 100644
--- a/drivers/clk/clk_sandbox_ccf.c
+++ b/drivers/clk/clk_sandbox_ccf.c
@@ -229,6 +229,7 @@ static const struct udevice_id sandbox_clk_ccf_test_ids[] = {
 
 static const char *const usdhc_sels[] = { "pll3_60m", "pll3_80m", };
 static const char *const i2c_sels[] = { "pll3_60m", "pll3_80m", };
+static const char *const i2s_sels[] = { "pll3_60m", "pll3_80m", };
 
 static int sandbox_clk_ccf_probe(struct udevice *dev)
 {
@@ -277,6 +278,15 @@ static int sandbox_clk_ccf_probe(struct udevice *dev)
 	clk_dm(SANDBOX_CLK_I2C_ROOT,
 	       sandbox_clk_gate2("i2c_root", "i2c", base + 0x7c, 0));
 
+	/* Register i2s_root(child) and i2s(parent) in reverse order to test CLK_LAZY_REPARENT */
+	clk_dm(SANDBOX_CLK_I2S_ROOT,
+	       sandbox_clk_gate2("i2s_root", "i2s", base + 0x80, 0));
+
+	reg = BIT(29) | BIT(25) | BIT(17);
+	clk_dm(SANDBOX_CLK_I2S,
+	       sandbox_clk_composite("i2s", i2s_sels, ARRAY_SIZE(i2s_sels),
+				     &reg, CLK_SET_RATE_UNGATE));
+
 	return 0;
 }
 
diff --git a/include/sandbox-clk.h b/include/sandbox-clk.h
index c2616c27a44a..0cd735e3ad5f 100644
--- a/include/sandbox-clk.h
+++ b/include/sandbox-clk.h
@@ -21,6 +21,8 @@ enum {
 	SANDBOX_CLK_USDHC2_SEL,
 	SANDBOX_CLK_I2C,
 	SANDBOX_CLK_I2C_ROOT,
+	SANDBOX_CLK_I2S,
+	SANDBOX_CLK_I2S_ROOT,
 };
 
 enum sandbox_pllv3_type {
diff --git a/test/dm/clk_ccf.c b/test/dm/clk_ccf.c
index ac56f17b775d..c4c1b6ba758a 100644
--- a/test/dm/clk_ccf.c
+++ b/test/dm/clk_ccf.c
@@ -209,3 +209,32 @@ static int dm_test_clk_ccf(struct unit_test_state *uts)
 	return 1;
 }
 DM_TEST(dm_test_clk_ccf, UTF_SCAN_FDT);
+
+#if CONFIG_IS_ENABLED(CLK_LAZY_REPARENT)
+/* Test CLK_LAZY_REPARENT feature */
+static int dm_test_clk_lazy_reparent(struct unit_test_state *uts)
+{
+	struct udevice *dev;
+	struct clk *clk_i2s, *clk_i2s_root;
+	int ret;
+
+	/* Get the device using the clk device */
+	ut_assertok(uclass_get_device_by_name(UCLASS_CLK, "clk-ccf", &dev));
+
+	ret = clk_get_by_id(SANDBOX_CLK_I2S_ROOT, &clk_i2s_root);
+	ret |= clk_get_by_id(SANDBOX_CLK_I2S, &clk_i2s);
+	ut_assertok(ret);
+
+	ut_asserteq_str(clk_i2s_root->parent_name, "i2s");
+	ut_assertnull(clk_i2s_root->dev->parent);
+
+	ret = clk_enable(clk_i2s_root);
+	ut_assertok(ret);
+
+	ut_assertnull(clk_i2s_root->parent_name);
+	ut_asserteq_ptr(clk_i2s_root->dev->parent, clk_i2s->dev);
+
+	return 0;
+}
+DM_TEST(dm_test_clk_lazy_reparent, UTF_SCAN_FDT);
+#endif

-- 
2.43.0

