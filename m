From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Thu, 27 Jun 2024 19:47:52 +0800
Subject: [PATCH 2/3] pmdomain: amlogic: Add support for A5 power domains
 controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240627-a5_secpower-v1-2-1f47dde1270c@amlogic.com>
References: <20240627-a5_secpower-v1-0-1f47dde1270c@amlogic.com>
In-Reply-To: <20240627-a5_secpower-v1-0-1f47dde1270c@amlogic.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jianxin Pan <jianxin.pan@amlogic.com>, Ulf Hansson <ulf.hansson@linaro.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-pm@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 Hongyu Chen <hongyu.chen1@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1719488872; l=2530;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=zWxLtelNKu19heqKs9wOyiplUpI+DyeIV7xOkfT+HwI=;
 b=Q2fjW+FoiPk3SlMyEGT1KOBPCDtlv+iKtLDF1wDDMNTEdR1UsHTAvXROY6xZNm5ch7gAtubOt
 ARKBdI22iOlC0SFpCvBkVGmqTg5pB0id21KF/i0mvBc3B9PmbWAxM+p
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for the A5 power controller, whose registers are
in the secure domain and should be accessed via SMC.

Signed-off-by: Hongyu Chen <hongyu.chen1@amlogic.com>
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 drivers/pmdomain/amlogic/meson-secure-pwrc.c | 26 ++++++++++++++++++++++++++
 1 file changed, 26 insertions(+)

diff --git a/drivers/pmdomain/amlogic/meson-secure-pwrc.c b/drivers/pmdomain/amlogic/meson-secure-pwrc.c
index df5567418226..f6729eea6b8c 100644
--- a/drivers/pmdomain/amlogic/meson-secure-pwrc.c
+++ b/drivers/pmdomain/amlogic/meson-secure-pwrc.c
@@ -15,6 +15,7 @@
 #include <dt-bindings/power/meson-s4-power.h>
 #include <dt-bindings/power/amlogic,t7-pwrc.h>
 #include <dt-bindings/power/amlogic,a4-pwrc.h>
+#include <dt-bindings/power/amlogic,a5-pwrc.h>
 #include <linux/arm-smccc.h>
 #include <linux/firmware/meson/meson_sm.h>
 #include <linux/module.h>
@@ -155,6 +156,22 @@ static struct meson_secure_pwrc_domain_desc a4_pwrc_domains[] = {
 	SEC_PD(A4_AO_IR,	GENPD_FLAG_ALWAYS_ON),
 };
 
+static struct meson_secure_pwrc_domain_desc a5_pwrc_domains[] = {
+	SEC_PD(A5_NNA,		0),
+	SEC_PD(A5_AUDIO,	0),
+	SEC_PD(A5_SDIOA,	0),
+	SEC_PD(A5_EMMC,		0),
+	SEC_PD(A5_USB_COMB,	0),
+	SEC_PD(A5_ETH,		0),
+	SEC_PD(A5_RSA,		0),
+	SEC_PD(A5_AUDIO_PDM,	0),
+	/* DMC is for DDR PHY ana/dig and DMC, and should be always on */
+	SEC_PD(A5_DMC,		GENPD_FLAG_ALWAYS_ON),
+	/* WRAP is secure_top, a lot of modules are included, and should be always on */
+	SEC_PD(A5_SYS_WRAP,	GENPD_FLAG_ALWAYS_ON),
+	SEC_PD(A5_DSPA,		0),
+};
+
 static struct meson_secure_pwrc_domain_desc c3_pwrc_domains[] = {
 	SEC_PD(C3_NNA,		0),
 	SEC_PD(C3_AUDIO,	0),
@@ -335,6 +352,11 @@ static struct meson_secure_pwrc_domain_data amlogic_secure_a4_pwrc_data = {
 	.count = ARRAY_SIZE(a4_pwrc_domains),
 };
 
+static struct meson_secure_pwrc_domain_data amlogic_secure_a5_pwrc_data = {
+	.domains = a5_pwrc_domains,
+	.count = ARRAY_SIZE(a5_pwrc_domains),
+};
+
 static struct meson_secure_pwrc_domain_data amlogic_secure_c3_pwrc_data = {
 	.domains = c3_pwrc_domains,
 	.count = ARRAY_SIZE(c3_pwrc_domains),
@@ -359,6 +381,10 @@ static const struct of_device_id meson_secure_pwrc_match_table[] = {
 		.compatible = "amlogic,a4-pwrc",
 		.data = &amlogic_secure_a4_pwrc_data,
 	},
+	{
+		.compatible = "amlogic,a5-pwrc",
+		.data = &amlogic_secure_a5_pwrc_data,
+	},
 	{
 		.compatible = "amlogic,c3-pwrc",
 		.data = &amlogic_secure_c3_pwrc_data,

-- 
2.37.1

