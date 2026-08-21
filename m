From: Jason Yang <jason98166@gmail.com>
Date: Fri, 21 Aug 2026 19:44:19 +0800
Subject: [PATCH] phy: rockchip-samsung-dcphy: Enable runtime PM at PHY core
 level
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260821-dcphy-rpm-v1-v1-1-a7db728b2539@gmail.com>
X-B4-Tracking: v=1; b=H4sIABI6iGoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDCyND3ZTkgoxK3aKCXN0yQ11Dk2QLg5TE1OSkNHMloJaCotS0zAqwcdG
 xtbUA9ZQPJF4AAAA=
To: Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Heiko Stuebner <heiko@sntech.de>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>
Cc: Heiko Stuebner <heiko.stuebner@cherry.de>, 
 linux-phy@lists.infradead.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Jason Yang <jason98166@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787312659; l=2166;
 i=jason98166@gmail.com; s=20260721; h=from:subject:message-id;
 bh=rV+NofLh7S6yCChqGRpahjAqRQEXtDM0htO9np1Bxqo=;
 b=57lr4YbeWUQV/oNo07yMtqo7IjzVndgDcWGOgaLPrTo3CyHIsAirw6wRlUFdK8mWyj0DJbew5
 /a7QHFJ7gIHBi6hFxN2KWVW9a6aXFhoO7j4aDFXxQy2pX4JkjZHmv/N
X-Developer-Key: i=jason98166@gmail.com; a=ed25519;
 pk=xQmD001Q/ooHl39PxyQtusbUQmgbOsSfpFryRVWZ/k4=
X-Endpoint-Received: by B4 Relay for jason98166@gmail.com/20260721 with auth_id=887
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

phy_create() only enables runtime PM on the new PHY device if the parent
already has it enabled, and this driver enables it afterwards. The PHY
device therefore never gets runtime PM, and phy_pm_runtime_get_sync()
returns -ENOTSUPP for every phy_init() and phy_power_on(). The block is
still resumed today, but only through the supplier link fw_devlink builds
from the phys phandle, which fw_devlink=off and =permissive do not.

Move devm_pm_runtime_enable() before devm_phy_create(), as done for the
sibling HDPTX PHY in commit 10ba8479f460 ("phy:
phy-rockchip-samsung-hdptx: Enable runtime PM at PHY core level").

Fixes: b2a1a2ae7818 ("phy: rockchip: Add Samsung MIPI D-/C-PHY driver")
Signed-off-by: Jason Yang <jason98166@gmail.com>
---
 drivers/phy/rockchip/phy-rockchip-samsung-dcphy.c | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/drivers/phy/rockchip/phy-rockchip-samsung-dcphy.c b/drivers/phy/rockchip/phy-rockchip-samsung-dcphy.c
index cbd780556da8..11e872cc6611 100644
--- a/drivers/phy/rockchip/phy-rockchip-samsung-dcphy.c
+++ b/drivers/phy/rockchip/phy-rockchip-samsung-dcphy.c
@@ -1610,16 +1610,16 @@ static int samsung_mipi_dcphy_probe(struct platform_device *pdev)
 		return dev_err_probe(dev, PTR_ERR(samsung->grf_apb_rst),
 				     "Failed to get system grf_apb_rst control\n");
 
+	ret = devm_pm_runtime_enable(dev);
+	if (ret)
+		return dev_err_probe(dev, ret, "Failed to enable runtime PM\n");
+
 	samsung->phy = devm_phy_create(dev, NULL, &samsung_mipi_dcphy_ops);
 	if (IS_ERR(samsung->phy))
 		return dev_err_probe(dev, PTR_ERR(samsung->phy), "Failed to create MIPI DC-PHY\n");
 
 	phy_set_drvdata(samsung->phy, samsung);
 
-	ret = devm_pm_runtime_enable(dev);
-	if (ret)
-		return dev_err_probe(dev, ret, "Failed to enable runtime PM\n");
-
 	phy_provider = devm_of_phy_provider_register(dev, samsung_mipi_dcphy_xlate);
 	if (IS_ERR(phy_provider))
 		return dev_err_probe(dev, PTR_ERR(phy_provider),

---
base-commit: 1590cf0329716306e948a8fc29f1d3ee87d3989f
change-id: 20260821-dcphy-rpm-v1-14c80daecbf7

Best regards,
-- 
Jason Yang <jason98166@gmail.com>

