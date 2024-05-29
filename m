From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Wed, 29 May 2024 11:10:34 +0800
Subject: [PATCH v2 2/3] pmdomain: amlogic: Add support for A4 power domains
 controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240529-a4_secpowerdomain-v2-2-47502fc0eaf3@amlogic.com>
References: <20240529-a4_secpowerdomain-v2-0-47502fc0eaf3@amlogic.com>
In-Reply-To: <20240529-a4_secpowerdomain-v2-0-47502fc0eaf3@amlogic.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jianxin Pan <jianxin.pan@amlogic.com>, Ulf Hansson <ulf.hansson@linaro.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-pm@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1716952234; l=2626;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=xHQwoF0xxtI+C2XFx/t3frUsHcsxAgorsw6ZKo8der0=;
 b=mLQ4AfvdscxxLVeNIfgZB2VnyugTUuQbZSysS6LAb0zTrB6XFaWMZjTWc1AJaCsGV4ZfjMElU
 2BkqNjElNNQAPlxrDtG6tIaVTi8PEHVq+JF/CTJ9r4FZFrkaQSt00YX
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for A4 power controller. A4 power control
registers are in secure domain, and should be accessed by SMC.

Reviewed-by: Neil Armstrong <neil.armstrong@linaro.org>
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 drivers/pmdomain/amlogic/meson-secure-pwrc.c | 28 ++++++++++++++++++++++++++++
 1 file changed, 28 insertions(+)

diff --git a/drivers/pmdomain/amlogic/meson-secure-pwrc.c b/drivers/pmdomain/amlogic/meson-secure-pwrc.c
index 4d5bda0d60fc..3a84d8a74a5e 100644
--- a/drivers/pmdomain/amlogic/meson-secure-pwrc.c
+++ b/drivers/pmdomain/amlogic/meson-secure-pwrc.c
@@ -14,6 +14,7 @@
 #include <dt-bindings/power/amlogic,c3-pwrc.h>
 #include <dt-bindings/power/meson-s4-power.h>
 #include <dt-bindings/power/amlogic,t7-pwrc.h>
+#include <dt-bindings/power/amlogic,a4-pwrc.h>
 #include <linux/arm-smccc.h>
 #include <linux/firmware/meson/meson_sm.h>
 #include <linux/module.h>
@@ -136,6 +137,24 @@ static struct meson_secure_pwrc_domain_desc a1_pwrc_domains[] = {
 	SEC_PD(RSA,	0),
 };
 
+static struct meson_secure_pwrc_domain_desc a4_pwrc_domains[] = {
+	SEC_PD(A4_AUDIO,	0),
+	SEC_PD(A4_SDIOA,	0),
+	SEC_PD(A4_EMMC,	0),
+	SEC_PD(A4_USB_COMB,	0),
+	SEC_PD(A4_ETH,		0),
+	SEC_PD(A4_VOUT,		0),
+	SEC_PD(A4_AUDIO_PDM,	0),
+	/* DMC is for DDR PHY ana/dig and DMC, and should be always on */
+	SEC_PD(A4_DMC,	GENPD_FLAG_ALWAYS_ON),
+	/* WRAP is secure_top, a lot of modules are included, and should be always on */
+	SEC_PD(A4_SYS_WRAP,	GENPD_FLAG_ALWAYS_ON),
+	SEC_PD(A4_AO_I2C_S,	0),
+	SEC_PD(A4_AO_UART,	0),
+	/* IR is wake up trigger source, and should be always on */
+	SEC_PD(A4_AO_IR,	GENPD_FLAG_ALWAYS_ON),
+};
+
 static struct meson_secure_pwrc_domain_desc c3_pwrc_domains[] = {
 	SEC_PD(C3_NNA,		0),
 	SEC_PD(C3_AUDIO,	0),
@@ -311,6 +330,11 @@ static struct meson_secure_pwrc_domain_data meson_secure_a1_pwrc_data = {
 	.count = ARRAY_SIZE(a1_pwrc_domains),
 };
 
+static struct meson_secure_pwrc_domain_data amlogic_secure_a4_pwrc_data = {
+	.domains = a4_pwrc_domains,
+	.count = ARRAY_SIZE(a4_pwrc_domains),
+};
+
 static struct meson_secure_pwrc_domain_data amlogic_secure_c3_pwrc_data = {
 	.domains = c3_pwrc_domains,
 	.count = ARRAY_SIZE(c3_pwrc_domains),
@@ -331,6 +355,10 @@ static const struct of_device_id meson_secure_pwrc_match_table[] = {
 		.compatible = "amlogic,meson-a1-pwrc",
 		.data = &meson_secure_a1_pwrc_data,
 	},
+	{
+		.compatible = "amlogic,a4-pwrc",
+		.data = &amlogic_secure_a4_pwrc_data,
+	},
 	{
 		.compatible = "amlogic,c3-pwrc",
 		.data = &amlogic_secure_c3_pwrc_data,

-- 
2.37.1

