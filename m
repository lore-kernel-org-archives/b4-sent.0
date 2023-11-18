From: Yang Xiwen <forbidden405@outlook.com>
Date: Sun, 19 Nov 2023 06:10:05 +0800
Subject: [PATCH v2 1/4] clk: clk_sandbox_ccf: assign ccf_clk_ops to .ops of
 the driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231111-enable_count-v2-1-20e3728600b5@outlook.com>
References: <20231111-enable_count-v2-0-20e3728600b5@outlook.com>
In-Reply-To: <20231111-enable_count-v2-0-20e3728600b5@outlook.com>
To: Simon Glass <sjg@chromium.org>, Lukasz Majewski <lukma@denx.de>, 
 Sean Anderson <seanga2@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1700345405; l=1054;
 i=forbidden405@outlook.com; s=20230415; h=from:subject:message-id;
 bh=dE5cf8UrBn62M8y3lOb4IWNCRjPGOte1KTe6hOHO/4Y=;
 b=mJQL4QR9DeI/Np2cgcT1uSDWesZnLNOzf78lg2tNTD+aIwiJtaBvUUBsUqY0jENtbb9pDQQnI
 VFAAXmC19b8Ay/5txAGzzbS+fA36oC4eAX7LuA+NZx2ZIN/4GIMAU5r
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=hfdpPU3AXR+t7fdv58tXCD4UzRNq+fop2TMJezFlAhM=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230415 with auth_id=44
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

It can now act as an clk provider on which ccf_clk_ops can be tested.
Also add "#clock-cells=<1>" to test.dts.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 arch/sandbox/dts/test.dts     | 1 +
 drivers/clk/clk_sandbox_ccf.c | 1 +
 2 files changed, 2 insertions(+)

diff --git a/arch/sandbox/dts/test.dts b/arch/sandbox/dts/test.dts
index c7197795ef..b1773f1bc2 100644
--- a/arch/sandbox/dts/test.dts
+++ b/arch/sandbox/dts/test.dts
@@ -654,6 +654,7 @@
 
 	ccf: clk-ccf {
 		compatible = "sandbox,clk-ccf";
+		#clock-cells = <1>;
 	};
 
 	efi-media {
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

-- 
2.39.2

