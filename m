From: Aiden Isik <aidenisik@member.fsf.org>
Date: Tue, 18 Aug 2026 16:44:48 +0100
Subject: [PATCH v2 2/2] watchdog: s3c2410_wdt: Add exynos5515-wdt
 compatible data
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260818-for-next-lucky7-watchdog-v2-2-6743f479a47f@member.fsf.org>
References: <20260818-for-next-lucky7-watchdog-v2-0-6743f479a47f@member.fsf.org>
In-Reply-To: <20260818-for-next-lucky7-watchdog-v2-0-6743f479a47f@member.fsf.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1518;
 i=aidenisik@member.fsf.org; h=from:subject:message-id;
 bh=C5r2bV9nYfxOIJNnwxYrMhWREb+Zhh0VM+xx1N3wI6g=;
 b=owEBbQKS/ZANAwAIAUknAbLEetfrAcsmYgBqhH315BAAGOJEjlp4J5rR3Yo9RyUegV+hrjWJ8
 HG6X6/iKn2JAjMEAAEIAB0WIQSDy8UkXGpc3JNbEaVJJwGyxHrX6wUCaoR99QAKCRBJJwGyxHrX
 6ws6EACwRp3RhFcTaoItfWoc9PNEejm0Hh+aNlLnAZWaYaPV87RYE/yjBb6TPPhP2IMq3Mo8+K+
 5JU4MnoO4FMDdfxQ4NWug+RgSyoTYNo4qr9uh3Rl1qWv+v6BJN7MdoFYxX9g202Ag08B3NlxfyB
 OJmjTq2mfbZ/HHyc6xv0mGC7grqB+OuFHdC3Qt9uAfNXtXpGrSvBI+HPzjrWAm6Gsp96rhg2LQL
 28CyaCDNu0WcmEmflQNf53tfSDegt/M5RJ18VdVBh7TzxQnORsQsuoWYA2v94/c3DuUfVpH5lhL
 ASm65HXaKN2mPx/ErOTgv1SehFGxBiBR8oopAR5TK/1Nu952gUW0Jcwqo/jP1IGq3injEAShv6h
 2cX6iwGGt8SU55hTbo7FASV9wkoV0Tn3rs0yn05Wdq6FVfuheaNoNtDYdvMjdEFOQb5AAgliLvK
 GBxhALdW5frgLwTJYJR7UaAGpoI0jf27oPE6NYpTF0UslijiwF56KPSELTIzw0wuESjDuUlMYgr
 QrAdg4Vz63gm9P4RoEz0rU/LvYfT9WaiWOmp/QpahX0jm3Reyc6kT79k6zFjsnp+9aJ92InPPkl
 lon462/vrn+e8ejxaCBUGbixwaFz1EXDh91I/JBKERGyrvyRNwkAJKaBnd4jBAdi+HeYDW2FxB0
 3W7qQcego3c2eYQ==
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
index e31f93db0509..7299dfdb0c09 100644
--- a/drivers/watchdog/s3c2410_wdt.c
+++ b/drivers/watchdog/s3c2410_wdt.c
@@ -232,6 +232,16 @@ static const struct s3c2410_wdt_variant drv_data_exynos5420 = {
 		  QUIRK_HAS_PMU_RST_STAT | QUIRK_HAS_PMU_AUTO_DISABLE,
 };
 
+static const struct s3c2410_wdt_variant drv_data_exynos5515 = {
+	.mask_reset_reg = EXYNOSAUTOV920_CLUSTER0_NONCPU_INT_EN,
+	.mask_bit = 2,
+	.rst_stat_reg = EXYNOS5_RST_STAT_REG_OFFSET,
+	.rst_stat_bit = 24,
+	.quirks = QUIRK_HAS_WTCLRINT_REG | QUIRK_HAS_PMU_MASK_RESET | \
+		  QUIRK_HAS_PMU_RST_STAT | QUIRK_HAS_PMU_AUTO_DISABLE | \
+		  QUIRK_HAS_DBGACK_BIT,
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

