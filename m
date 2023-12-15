From: Yang Xiwen <forbidden405@outlook.com>
Date: Sat, 16 Dec 2023 04:21:11 +0800
Subject: [PATCH] test: dm: clk_ccf: fix building error
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231216-b4-fix_build-v1-1-b8e79c94744f@outlook.com>
X-B4-Tracking: v=1; b=H4sIADa1fGUC/x3N0QqDMAyF4VeRXC9g46ZjrzJEmjZqoHSjRRHEd
 1/Y5X/g45xQpahUeDUnFNm16idbuFsDYfV5EdRoDdRS58j1yHec9Zh40xQxto+ZmPrw9AMYYV8
 FufgcVkN5S8nGbxET/4/3eF0/jmOJd3MAAAA=
To: Lukasz Majewski <lukma@denx.de>, Sean Anderson <seanga2@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1702671687; l=965;
 i=forbidden405@outlook.com; s=20230415; h=from:subject:message-id;
 bh=+YXHGjJV5RfD1cYTUUsRy7jDcslvBWZ6f1oAnKJy2ik=;
 b=n93+32jLKxGIt2ZK5H1I6ciRL0d34TBI5fIQo9rECktwXXleLGzehEsIHl2j+cHS9rrn0v469
 ETiKx4IKPtFBSK/Voo4BcX3xo1mEBQKsxP2il5JZx6Bpb44/aQ5Rga+
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=hfdpPU3AXR+t7fdv58tXCD4UzRNq+fop2TMJezFlAhM=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230415 with auth_id=44
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix unused variable error produced by building tests

Fixes: d3061824 (test: dm: clk_ccf: test ccf_clk_ops)
Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
it's detected by u-boot gitlab CI.
---
 test/dm/clk_ccf.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/test/dm/clk_ccf.c b/test/dm/clk_ccf.c
index b8be6d6572..5a3c58c6b5 100644
--- a/test/dm/clk_ccf.c
+++ b/test/dm/clk_ccf.c
@@ -18,11 +18,12 @@
 /* Tests for Common Clock Framework driver */
 static int dm_test_clk_ccf(struct unit_test_state *uts)
 {
-	struct clk *clk, *pclk, clk_ccf;
+	struct clk *clk, *pclk;
 	struct udevice *dev, *test_dev;
 	long long rate;
 	int ret;
 #if CONFIG_IS_ENABLED(CLK_CCF)
+	struct clk clk_ccf;
 	const char *clkname;
 	int clkid, i;
 #endif

---
base-commit: c9945276f77921feb8df7be75cced3338d08e8d4
change-id: 20231216-b4-fix_build-d05f2b26c8a7

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

