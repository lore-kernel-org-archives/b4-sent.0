From: Aiden Isik <aidenisik@member.fsf.org>
Date: Tue, 18 Aug 2026 19:03:18 +0100
Subject: [PATCH v3 2/2] watchdog: s3c2410_wdt: Add exynos5515-wdt
 compatible data
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260818-for-next-lucky7-watchdog-v3-2-2912bd122c57@member.fsf.org>
References: <20260818-for-next-lucky7-watchdog-v3-0-2912bd122c57@member.fsf.org>
In-Reply-To: <20260818-for-next-lucky7-watchdog-v3-0-2912bd122c57@member.fsf.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1508;
 i=aidenisik@member.fsf.org; h=from:subject:message-id;
 bh=hF1hTKAa3Af2BP1y4rV71oo3r+CdBS8fUgCThTjSOzY=;
 b=owEBbQKS/ZANAwAIAUknAbLEetfrAcsmYgBqhJ5qTJMrIxLzrhlg5Hr5EOOKKjXSpIqZOslww
 WIKL/RnbuGJAjMEAAEIAB0WIQSDy8UkXGpc3JNbEaVJJwGyxHrX6wUCaoSeagAKCRBJJwGyxHrX
 6zz2D/4sFnKJvYdx9lx9yScTwO5Wsd1quMKX5dzjpm1fXALYRYvzLuTMr++ry8vUrxs4wqiopXX
 sQQRiew5Kaxg5qVKZkhzhcdicJqTwJPp+ev9yC0JMXA0BLMkHyA0XDMYTCSxXKsumAOr1ss7CjW
 fQhJHIxl8iOrpOwov4W7KqXiNEeZLlAI0Xt89A8Zkvdh5kXcCHGtOPMJQMrcP6JiLPMQbRlndIl
 XEcoLvFJ5Tqbv2hq/J9vqkUvIO8jVCeuZHcERaYB/a+frnRBJdtTNjww/QPbvwZ2xWnJh92Ggce
 yF37z5G35pFVmAdMDVtR7BLz4xXT41EN4cKi5BtNUD07Ym90FzFkFo1zc8e1v5ktCSdL0+5bIji
 YxZvHdk+IU/UL8viIpAIuzHEZycIK8Yojlcet7RLHIczBKhKn4u+z3CzSc0TCm68pB2JXbiCO/2
 BIFV9d2WuI0ADcHGs7fpVwNPR+PkUEMBAM+8jOVp6B+IG730GqQSxOuRdDoywfv/lzaDEOIfSiy
 KFtlU9n3i71RuucMBQkDtplTajTYNLq0edD56uG2AzAASwm6zW2k9FRevH+Xbt+fbIwwqXfhGDc
 qIhdD9rWEtXbciDklEaPcF1wE8wG/vkAMjpXg0qvXURZRMtEL1kkLoMh9lnC5mqK4c6qPC6YTHp
 QZmrLvurgP+WaWw==
X-Developer-Key: i=aidenisik@member.fsf.org; a=openpgp;
 fpr=83CBC5245C6A5CDC935B11A5492701B2C47AD7EB
X-Endpoint-Received: by B4 Relay for aidenisik@member.fsf.org/default with auth_id=956
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add driver data for the Exynos5515 SoC's watchdog timer.

Signed-off-by: Aiden Isik <aidenisik@member.fsf.org>
---
 drivers/watchdog/s3c2410_wdt.c | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/drivers/watchdog/s3c2410_wdt.c b/drivers/watchdog/s3c2410_wdt.c
index e31f93db0509..5592f25fe6c8 100644
--- a/drivers/watchdog/s3c2410_wdt.c
+++ b/drivers/watchdog/s3c2410_wdt.c
@@ -232,6 +232,16 @@ static const struct s3c2410_wdt_variant drv_data_exynos5420 = {
 		  QUIRK_HAS_PMU_RST_STAT | QUIRK_HAS_PMU_AUTO_DISABLE,
 };
 
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
@@ -379,6 +389,8 @@ static const struct of_device_id s3c2410_wdt_match[] = {
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

