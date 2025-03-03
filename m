From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Mon, 03 Mar 2025 17:06:05 +0800
Subject: [PATCH] pmdomain: amlogic: fix T7 ISP secpower
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250303-fix-t7-pwrc-v1-1-b563612bcd86@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAPxwxWcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDYwNj3bTMCt0Sc92C8qJk3TRjYzNTgyRDS4PUNCWgjoKiVKA02LTo2Np
 aAPHs9UBdAAAA
To: Ulf Hansson <ulf.hansson@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-pm@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740992766; l=1171;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=rJx19Mccy9v03r4IPzrydNTt9cu21guWRk4PdtQnj/s=;
 b=uqesClxVofnbW/ynh5d/bm2c3Kt2QwEI3r8qy7137qIkThIhcwEJ5t8Lm7peBNEKl3AhmZ73V
 TB14yRL8lI1C2wcDWE5UOeddEEODPuhesytoihG1QQQjHR9llVP55r3
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ISP and MIPI_ISP, these two have a parent-child relationship,
ISP depends on MIPI_ISP.

Fixes: ca75e4b214c6 ("pmdomain: amlogic: Add support for T7 power domains controller")
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 drivers/pmdomain/amlogic/meson-secure-pwrc.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/pmdomain/amlogic/meson-secure-pwrc.c b/drivers/pmdomain/amlogic/meson-secure-pwrc.c
index 42ce41a2fe3a..ff76ea36835e 100644
--- a/drivers/pmdomain/amlogic/meson-secure-pwrc.c
+++ b/drivers/pmdomain/amlogic/meson-secure-pwrc.c
@@ -221,7 +221,7 @@ static const struct meson_secure_pwrc_domain_desc t7_pwrc_domains[] = {
 	SEC_PD(T7_VI_CLK2,	0),
 	/* ETH is for ethernet online wakeup, and should be always on */
 	SEC_PD(T7_ETH,		GENPD_FLAG_ALWAYS_ON),
-	SEC_PD(T7_ISP,		0),
+	TOP_PD(T7_ISP,		0, PWRC_T7_MIPI_ISP_ID),
 	SEC_PD(T7_MIPI_ISP,	0),
 	TOP_PD(T7_GDC,		0, PWRC_T7_NIC3_ID),
 	TOP_PD(T7_DEWARP,	0, PWRC_T7_NIC3_ID),

---
base-commit: 73e4ffb27bb8a093d557bb2dac1a271474cca99c
change-id: 20250303-fix-t7-pwrc-f33650b190ef

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

