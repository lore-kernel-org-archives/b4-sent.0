From: Keguang Zhang <keguang.zhang@gmail.com>
Date: Mon, 15 Jun 2026 20:24:17 +0800
Subject: [PATCH] net: stmmac: loongson1: Use dev_err_probe()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260615-dwmac-loongson1-v1-1-cbcf5bc01d9b@gmail.com>
X-B4-Tracking: v=1; b=H4sIAPDuL2oC/x3MQQqAIBBA0avIrBPUSKirRIvS0QZKQ6EC8e5Jy
 7f4v0DGRJhhYgUS3pQphgbZMTD7Gjxyss2ghNJCC8Xtc66GHzEGn2OQfEC5jdaZ3mgFrboSOnr
 /47zU+gHKAVm4YQAAAA==
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>
Cc: linux-mips@vger.kernel.org, netdev@vger.kernel.org, 
 linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Keguang Zhang <keguang.zhang@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781526276; l=1168;
 i=keguang.zhang@gmail.com; s=20231129; h=from:subject:message-id;
 bh=2fl2OBxWH3wOcozENxrt6hZZsu8wzA6vdfleIZixEow=;
 b=/xcmeOq0CIVKL1BbVMNLoT/ceXxJcS0hTcnCvEZ6XK0jr4a/anBT54fyJswBJHk++djVHtRXn
 tJKVWnD0mutDflarcg2J1w0kDRCds4G4jYe4E9akQGFn9N6xspemEK7
X-Developer-Key: i=keguang.zhang@gmail.com; a=ed25519;
 pk=FMKGj/JgKll/MgClpNZ3frIIogsh5e5r8CeW2mr+WLs=
X-Endpoint-Received: by B4 Relay for keguang.zhang@gmail.com/20231129 with auth_id=102
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use dev_err_probe() for the missing match data case to simplify
error handling.

Signed-off-by: Keguang Zhang <keguang.zhang@gmail.com>
---
 drivers/net/ethernet/stmicro/stmmac/dwmac-loongson1.c | 6 ++----
 1 file changed, 2 insertions(+), 4 deletions(-)

diff --git a/drivers/net/ethernet/stmicro/stmmac/dwmac-loongson1.c b/drivers/net/ethernet/stmicro/stmmac/dwmac-loongson1.c
index de9aba756aac..ec34adb63f61 100644
--- a/drivers/net/ethernet/stmicro/stmmac/dwmac-loongson1.c
+++ b/drivers/net/ethernet/stmicro/stmmac/dwmac-loongson1.c
@@ -176,10 +176,8 @@ static int ls1x_dwmac_probe(struct platform_device *pdev)
 				     "Unable to find syscon\n");
 
 	data = of_device_get_match_data(&pdev->dev);
-	if (!data) {
-		dev_err(&pdev->dev, "No of match data provided\n");
-		return -EINVAL;
-	}
+	if (!data)
+		return dev_err_probe(&pdev->dev, -EINVAL, "No of match data provided\n");
 
 	dwmac = devm_kzalloc(&pdev->dev, sizeof(*dwmac), GFP_KERNEL);
 	if (!dwmac)

---
base-commit: ec039126b7fac4e3af35ebccaa7c6f9b6875ba81
change-id: 20260602-dwmac-loongson1-5e1b9dfc3c62

Best regards,
-- 
Keguang Zhang <keguang.zhang@gmail.com>

