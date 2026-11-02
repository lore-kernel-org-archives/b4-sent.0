From: Igor Velkov <iav@iav.lv>
Date: Mon, 02 Nov 2026 17:48:57 +0000
Subject: [PATCH] media: rockchip: rga: Keep the clocks enabled without
 CONFIG_PM
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261102-rga-runtime-pm-clocks-v1-1-1bad7807f037@iav.lv>
X-B4-Tracking: v=1; b=H4sIAAjN6GoC/x3MMQqAMAxA0atIZgNtEUGvIg6hjRrUKqmKIN7d4
 viG/x9IrMIJ2uIB5UuSbDHDlgX4ieLIKCEbnHG1tcahjoR6xkNWxn1Fv2x+TthQxfVA7AMZyO2
 uPMj9f7v+fT9WzOPOZwAAAA==
To: Jacob Chen <jacob-chen@iotwrt.com>, 
 Ezequiel Garcia <ezequiel@vanguardiasur.com.ar>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Hans Verkuil <hverkuil@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1515; i=iav@iav.lv;
 h=from:subject:message-id; bh=2aAiFLoBlld6RgGQ0EoX3zPXerU1gatyiz1du1lqQ/o=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFkvznJuXqItWfLsVZbVh6suzL/lV89km7ZRp2PH05sit
 1eWKkY/6ihlYRDjYpAVU2SZcEjjVsaSq3/9PcwfwMxhZQIZwsDFKQAT4W9jZJjTcy61VDnn5Bze
 xbPXt1cpLQl8znXX89rSD3lnBVTbA9wYfjEt5ojpX778SvpCg1zuTaftVnWsusl/dsJcuQtnvsb
 K2jICAA==
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Only rga_runtime_resume() enables the clocks. Without CONFIG_PM the
runtime PM callbacks are not registered, so rga_probe() reads the
version register with the clocks disabled.

Enable the clocks from probe in that case, as etnaviv and v3d do.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
Split out of the rkvdec CONFIG_PM discussion, as Nicolas asked [1].
Build-tested only (arm64, COMPILE_TEST, W=1, CONFIG_PM=n and =y):
ARCH_ROCKCHIP selects PM, so no board runs this path.

[1] https://lore.kernel.org/r/8aafdbbf04a0d939c6b4d7d5577d97bb58d1c439.camel@collabora.com
---
 drivers/media/platform/rockchip/rga/rga.c | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/drivers/media/platform/rockchip/rga/rga.c b/drivers/media/platform/rockchip/rga/rga.c
index 543a0da75572..c50141bb5654 100644
--- a/drivers/media/platform/rockchip/rga/rga.c
+++ b/drivers/media/platform/rockchip/rga/rga.c
@@ -701,7 +701,10 @@ static int rga_parse_dt(struct rockchip_rga *rga)
 	udelay(1);
 	reset_control_deassert(ahb_rst);
 
-	ret = devm_clk_bulk_get_all(rga->dev, &rga->clks);
+	if (IS_ENABLED(CONFIG_PM))
+		ret = devm_clk_bulk_get_all(rga->dev, &rga->clks);
+	else
+		ret = devm_clk_bulk_get_all_enabled(rga->dev, &rga->clks);
 	if (ret < 0) {
 		dev_err(rga->dev, "failed to get clocks\n");
 		return ret;

---
base-commit: 27285b099fbc5cb2ae3aef20f3bbd7b3c88b3005
change-id: 20261102-rga-runtime-pm-clocks-9a4e6faecda0

Best regards,
-- 
Igor Velkov <iav@iav.lv>

