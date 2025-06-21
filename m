From: Yang Xiwen <forbidden405@outlook.com>
Date: Sat, 21 Jun 2025 18:54:20 +0800
Subject: [PATCH RFC 3/3] clk: sandbox: reverse the order to register clk
 i2c_root and i2c
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250621-clk-reparent-v1-3-48a7f2f31c59@outlook.com>
References: <20250621-clk-reparent-v1-0-48a7f2f31c59@outlook.com>
In-Reply-To: <20250621-clk-reparent-v1-0-48a7f2f31c59@outlook.com>
To: Simon Glass <sjg@chromium.org>, Tom Rini <trini@konsulko.com>, 
 Lukasz Majewski <lukma@denx.de>, Sean Anderson <seanga2@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1750503259; l=1071;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=aQSA7Q7r1hkmSAHzG9f5x6P95Gk/sYDULKCIbOSFSDQ=;
 b=5QdURyUI0hcXo3SAFd6XUQWtJVWJ1gMobrMRm7eaWRaRe5zmkPDBYlnmZxzS0T1ixGMfQLRon
 jegfYlKcRTrBop8QcH63rNOAO0b1e//eYSAdwFJyZTSUsXDK7Y88f7/
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Reverse the clk_register() order of i2c_root and i2c to test the feature
that allows register clocks in a less strict order.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/clk/clk_sandbox_ccf.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/drivers/clk/clk_sandbox_ccf.c b/drivers/clk/clk_sandbox_ccf.c
index f96a15c30b3a..ed4f69807644 100644
--- a/drivers/clk/clk_sandbox_ccf.c
+++ b/drivers/clk/clk_sandbox_ccf.c
@@ -269,14 +269,14 @@ static int sandbox_clk_ccf_probe(struct udevice *dev)
 	       sandbox_clk_mux("usdhc2_sel", &reg, 17, 1, usdhc_sels,
 			       ARRAY_SIZE(usdhc_sels)));
 
+	clk_dm(SANDBOX_CLK_I2C_ROOT,
+	       sandbox_clk_gate2("i2c_root", "i2c", base + 0x7c, 0));
+
 	reg = BIT(28) | BIT(24) | BIT(16);
 	clk_dm(SANDBOX_CLK_I2C,
 	       sandbox_clk_composite("i2c", i2c_sels, ARRAY_SIZE(i2c_sels),
 				     &reg, CLK_SET_RATE_UNGATE));
 
-	clk_dm(SANDBOX_CLK_I2C_ROOT,
-	       sandbox_clk_gate2("i2c_root", "i2c", base + 0x7c, 0));
-
 	return 0;
 }
 

-- 
2.43.0

