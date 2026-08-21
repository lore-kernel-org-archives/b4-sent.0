From: Aiden Isik <aidenisik@member.fsf.org>
Date: Fri, 21 Aug 2026 16:14:50 +0100
Subject: [PATCH v4 2/2] watchdog: s3c2410_wdt: Add exynos5515-wdt
 compatible data
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260821-for-next-lucky7-watchdog-v4-2-d070cee5009f@member.fsf.org>
References: <20260821-for-next-lucky7-watchdog-v4-0-d070cee5009f@member.fsf.org>
In-Reply-To: <20260821-for-next-lucky7-watchdog-v4-0-d070cee5009f@member.fsf.org>
To: Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, linux-watchdog@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, 
 Aiden Isik <aidenisik@member.fsf.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1808;
 i=aidenisik@member.fsf.org; h=from:subject:message-id;
 bh=QWYVk8sPa3JpVI2qehkdPPdXsdkAd9IZBVEvEfGjKrA=;
 b=owEBbQKS/ZANAwAIAUknAbLEetfrAcsmYgBqiGt3sDmRORR/fLqcaMqThVjJHZWLnAKsHoQ0V
 b8XQDOS8DWJAjMEAAEIAB0WIQSDy8UkXGpc3JNbEaVJJwGyxHrX6wUCaohrdwAKCRBJJwGyxHrX
 62M5EADqq638uNLyQAj0YtUWxeEU5/5rcG4wuWMzIdCJ/lJWPbpH127DRiigccTmvXSvB9a5CEZ
 jlR99X6ccqSHdv3qKIfV+3C1WXagZKmslOCwJrQ1KbQvmPAFtEmUhV3bhz2k/ZjTuxxzINCwlQo
 pD7Y8d/99GcLBtOXF2KQCUXYsKxwI20NHk5T6G014KxcwRiHadHlzCYulNdIRNh1P30Us7ulwhV
 7roCC6yZrL+Ug0fOhSd6l0h5tFfIKBva0IQfC6Pq8OecUvdcHSFn7WeQswrqDnKG9RdQIzorDhK
 chILIUE6Mc2AxgCyDF1ZQPvYQDO8gZjlCdwlXYB51amcYLorSW2adupeUzTzYMZslVg9FrUYDgG
 d26Dj+wSq+M2IfcokS0U8VFRaV+5+Cu+801EJQHw4eRicXz+0A/MboeJcVE2YK4TkF0jjDrznqW
 ahWGpqBrNtdV2XwldI8khaD6hsi0y+DI07+BP7dEQv1ltuFigkv7h1sPVVYHaIHeD7c0TnTISWD
 +/Dvbq0Lm+Ml4m7i7XX7SsdVh9q3goJ6LEcTWogJIDjweDbzKkE5FQht3+TRHDlAd4G4oj3Nk23
 Ucef8lM1TjBvLPNpobBDVjzlnFXaaPsl7wxqPJ5KLD9LOHHy58gowvXsoq+1S5nJt/JoCcas3tw
 D7iadSYtVPR/UCw==
X-Developer-Key: i=aidenisik@member.fsf.org; a=openpgp;
 fpr=83CBC5245C6A5CDC935B11A5492701B2C47AD7EB
X-Endpoint-Received: by B4 Relay for aidenisik@member.fsf.org/default with auth_id=956
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add driver data for the Exynos5515 SoC's watchdog timer.

Unlike similar SoCs such as GS101 or Exynos990, Exynos5515's PMU does
not require explicit counter enablement for the watchdog to tick.

Signed-off-by: Aiden Isik <aidenisik@member.fsf.org>
---
 drivers/watchdog/s3c2410_wdt.c | 16 ++++++++++++++++
 1 file changed, 16 insertions(+)

diff --git a/drivers/watchdog/s3c2410_wdt.c b/drivers/watchdog/s3c2410_wdt.c
index e31f93db0509..e61439a3f4b2 100644
--- a/drivers/watchdog/s3c2410_wdt.c
+++ b/drivers/watchdog/s3c2410_wdt.c
@@ -232,6 +232,20 @@ static const struct s3c2410_wdt_variant drv_data_exynos5420 = {
 		  QUIRK_HAS_PMU_RST_STAT | QUIRK_HAS_PMU_AUTO_DISABLE,
 };
 
+/*
+ * Unlike similar SoCs like GS101, Exynos5515's PMU does not require
+ * explicit counter enablement. Hence, QUIRK_HAS_PMU_CNT_EN is not set.
+ */
+static const struct s3c2410_wdt_variant drv_data_exynos5515 = {
+	.mask_reset_reg = EXYNOSAUTOV920_CLUSTER0_NONCPU_INT_EN,
+	.mask_bit = 2,
+	.mask_reset_inv = true,
+	.rst_stat_reg = EXYNOS5_RST_STAT_REG_OFFSET,
+	.rst_stat_bit = 24,
+	.quirks = QUIRK_HAS_WTCLRINT_REG | QUIRK_HAS_PMU_MASK_RESET | \
+		  QUIRK_HAS_PMU_RST_STAT | QUIRK_HAS_DBGACK_BIT,
+};
+
 static const struct s3c2410_wdt_variant drv_data_exynos7 = {
 	.disable_reg = EXYNOS5_WDT_DISABLE_REG_OFFSET,
 	.mask_reset_reg = EXYNOS5_WDT_MASK_RESET_REG_OFFSET,
@@ -379,6 +393,8 @@ static const struct of_device_id s3c2410_wdt_match[] = {
 	  .data = &drv_data_exynos5250 },
 	{ .compatible = "samsung,exynos5420-wdt",
 	  .data = &drv_data_exynos5420 },
+	{ .compatible = "samsung,exynos5515-wdt",
+	  .data = &drv_data_exynos5515 },
 	{ .compatible = "samsung,exynos7-wdt",
 	  .data = &drv_data_exynos7 },
 	{ .compatible = "samsung,exynos850-wdt",

-- 
2.54.0

