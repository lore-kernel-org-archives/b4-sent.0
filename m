From: Aiden Isik <aidenisik@member.fsf.org>
Date: Thu, 22 Oct 2026 17:46:37 +0100
Subject: [PATCH 2/2] phy: exynos5-usbdrd: Add support for the Exynos5515
 usbdrd phy
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-for-next-lucky7-usb-phy-v1-2-2e47f8484bf4@member.fsf.org>
References: <20261022-for-next-lucky7-usb-phy-v1-0-2e47f8484bf4@member.fsf.org>
In-Reply-To: <20261022-for-next-lucky7-usb-phy-v1-0-2e47f8484bf4@member.fsf.org>
To: Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Marek Szyprowski <m.szyprowski@samsung.com>, 
 Sylwester Nawrocki <s.nawrocki@samsung.com>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, linux-phy@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, 
 Aiden Isik <aidenisik@member.fsf.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2950;
 i=aidenisik@member.fsf.org; h=from:subject:message-id;
 bh=Kiiu/e8JIBqj1FtLrHXUkttonZWwk3f0gSxzSjnt6Ys=;
 b=owEBiQJ2/ZANAwAIAUknAbLEetfrAcsmYgBq2j3tvjE8eTgCSASSGRDwhLex1H6pqWKT0Iw0O
 pESfG41hkSJAk8EAAEIADkWIQSDy8UkXGpc3JNbEaVJJwGyxHrX6wUCato97RsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwyLDIACgkQSScBssR61+sMHhAAsUopH+oG44TXLb0KyNZ1uxDtgyammvw
 MARBRATeyeRUvvyAxR+ENdfAOfQYAoBKDAuo0s2R0jHI8CEzYvzkQ/w8it1CnQjU/j84Ni9j2k5
 o55ZGjUZggmKNDKtjIRG36rtrkQKcu9zWIN6A+55PfCf1c3FMXf78tKycXPO+pngBm9EgsDD5xd
 lAHyTOqxxV9EEjd30IQiq2Riey5A0R/5q37GgGPFhEyTzeIfIILPozVq7cg465VfEhpIxzb+zo4
 ZtYy5tJPU6FicZn1jGewertAY/IfcXQSbdg08kYcgT73zeBL1KXP+Zshiiu5kM+4SZ3Sp9dgoCd
 1wS06y7CeLuyRsZHHUAnh348rqbp93z0cjKqhe9Ywz47kHjKBQGNr5Wp7Ar5DRNHtBs7WA9BEd6
 KH4nChgwGQLetqtmQowuge88XNMiiNmO8TmaQBJynxK5VurmCcWUjt3EL4JE4Kg7kezAWKHecA6
 izygaxwmaDEIzmRkjFFXY8EKbEtrtP2dzsKi6JPy8Ve0PgZ00daJgeo9Ugx5YQpxGMjOJfh30gG
 Cb/r58KUUZKVa0ujhjTyXzitf0CBPS2omURAxka7Z5Zilhcs5/a15xfc+3/dYTy1oH0vrF0sDwX
 iyiBUvLkOJ51XEsg4TRYNw1NlwjQyoDkVMe4V9ASelqVrhbv7u40=
X-Developer-Key: i=aidenisik@member.fsf.org; a=openpgp;
 fpr=83CBC5245C6A5CDC935B11A5492701B2C47AD7EB
X-Endpoint-Received: by B4 Relay for aidenisik@member.fsf.org/default with auth_id=956
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Exynos5515 USBDRD PHY is a USB PHY which supports USB Super-Speed
and High-Speed. Add support for High-Speed (UTMI+) operation.

Signed-off-by: Aiden Isik <aidenisik@member.fsf.org>
---
 drivers/phy/samsung/phy-exynos5-usbdrd.c | 43 ++++++++++++++++++++++++++++++++
 1 file changed, 43 insertions(+)

diff --git a/drivers/phy/samsung/phy-exynos5-usbdrd.c b/drivers/phy/samsung/phy-exynos5-usbdrd.c
index f10cf7b6e0aa..8718e8f01e46 100644
--- a/drivers/phy/samsung/phy-exynos5-usbdrd.c
+++ b/drivers/phy/samsung/phy-exynos5-usbdrd.c
@@ -2075,6 +2075,46 @@ static const struct exynos5_usbdrd_phy_drvdata exynos5433_usbdrd_phy = {
 	.n_regulators		= ARRAY_SIZE(exynos5_regulator_names),
 };
 
+static const struct exynos5_usbdrd_phy_tuning exynos5515_tunes_utmi_postinit[] = {
+	PHY_TUNING_ENTRY_PHY(EXYNOS850_DRD_HSPPARACON,
+			     (HSPPARACON_TXVREF | HSPPARACON_TXRISE |
+			      HSPPARACON_TXRES |
+			      HSPPARACON_TXPREEMPPULSE |
+			      HSPPARACON_TXPREEMPAMP |
+			      HSPPARACON_TXHSXV | HSPPARACON_TXFSLS |
+			      HSPPARACON_SQRX | HSPPARACON_OTG |
+			      HSPPARACON_COMPDIS),
+			     (FIELD_PREP_CONST(HSPPARACON_TXVREF, 15) |
+			      FIELD_PREP_CONST(HSPPARACON_TXRISE, 3) |
+			      FIELD_PREP_CONST(HSPPARACON_TXRES, 3) |
+			      FIELD_PREP_CONST(HSPPARACON_TXPREEMPPULSE, 0) |
+			      FIELD_PREP_CONST(HSPPARACON_TXPREEMPAMP, 3) |
+			      FIELD_PREP_CONST(HSPPARACON_TXHSXV, 3) |
+			      FIELD_PREP_CONST(HSPPARACON_TXFSLS, 3) |
+			      FIELD_PREP_CONST(HSPPARACON_SQRX, 7) |
+			      FIELD_PREP_CONST(HSPPARACON_OTG, 2) |
+			      FIELD_PREP_CONST(HSPPARACON_COMPDIS, 7))),
+	PHY_TUNING_ENTRY_LAST
+};
+
+static const struct exynos5_usbdrd_phy_tuning *exynos5515_tunes[PTS_MAX] = {
+	[PTS_UTMI_POSTINIT] = exynos5515_tunes_utmi_postinit,
+};
+
+static const struct exynos5_usbdrd_phy_drvdata exynos5515_usbdrd_phy = {
+	.phy_cfg		= phy_cfg_exynos850,
+	.n_phy_cfg		= ARRAY_SIZE(phy_cfg_exynos850),
+	.phy_ops		= &exynos850_usbdrd_phy_ops,
+	.phy_tunes		= exynos5515_tunes,
+	.pmu_offset_usbdrd0_phy	= EXYNOS990_PHY_CTRL_USB20,
+	.clk_names		= exynos5_clk_names,
+	.n_clks			= ARRAY_SIZE(exynos5_clk_names),
+	.core_clk_names		= exynos5_core_clk_names,
+	.n_core_clks		= ARRAY_SIZE(exynos5_core_clk_names),
+	.regulator_names	= exynos5_regulator_names,
+	.n_regulators		= ARRAY_SIZE(exynos5_regulator_names),
+};
+
 static const struct exynos5_usbdrd_phy_drvdata exynos7_usbdrd_phy = {
 	.phy_cfg		= phy_cfg_exynos5,
 	.n_phy_cfg		= ARRAY_SIZE(phy_cfg_exynos5),
@@ -2936,6 +2976,9 @@ static const struct of_device_id exynos5_usbdrd_phy_of_match[] = {
 	}, {
 		.compatible = "samsung,exynos5433-usbdrd-phy",
 		.data = &exynos5433_usbdrd_phy
+	}, {
+		.compatible = "samsung,exynos5515-usbdrd-phy",
+		.data = &exynos5515_usbdrd_phy
 	}, {
 		.compatible = "samsung,exynos7-usbdrd-phy",
 		.data = &exynos7_usbdrd_phy

-- 
2.54.0

