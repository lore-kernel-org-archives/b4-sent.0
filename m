From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Fri, 22 Aug 2025 13:39:56 +0800
Subject: [PATCH 2/5] pmdomain: amlogic: Add support for S6 S7 S7D power
 domains controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250822-pm-s6-s7-s7d-v1-2-82e3f3aff327@amlogic.com>
References: <20250822-pm-s6-s7-s7d-v1-0-82e3f3aff327@amlogic.com>
In-Reply-To: <20250822-pm-s6-s7-s7d-v1-0-82e3f3aff327@amlogic.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jianxin Pan <jianxin.pan@amlogic.com>, Ulf Hansson <ulf.hansson@linaro.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-pm@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 "hongyu.chen1" <hongyu.chen1@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755841286; l=4719;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=f2m0nsIUf/owC+/pGLzsEn5pyQIYJ6wrUlxsJFTx2lE=;
 b=pwitmZC4ygGsQN/beTX1T2nbDqayrzpNTwBhuxE50uUBEkMZv8EqkL5nsYtHy9Vdkv1dgMiy9
 RdOGT7HWMBPDcBeSx54/4CPNhf8ng0FiM8VoH5ixsmzJLEe5bvfICsR
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: "hongyu.chen1" <hongyu.chen1@amlogic.com>

Add support for the S6 S7 S7D power controller, whose registers are
in the secure domain and should be accessed via SMC.

Signed-off-by: hongyu.chen1 <hongyu.chen1@amlogic.com>
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 drivers/pmdomain/amlogic/meson-secure-pwrc.c | 95 ++++++++++++++++++++++++++++
 1 file changed, 95 insertions(+)

diff --git a/drivers/pmdomain/amlogic/meson-secure-pwrc.c b/drivers/pmdomain/amlogic/meson-secure-pwrc.c
index e8bda60078c4..1d2f371d2d7f 100644
--- a/drivers/pmdomain/amlogic/meson-secure-pwrc.c
+++ b/drivers/pmdomain/amlogic/meson-secure-pwrc.c
@@ -16,6 +16,9 @@
 #include <dt-bindings/power/amlogic,t7-pwrc.h>
 #include <dt-bindings/power/amlogic,a4-pwrc.h>
 #include <dt-bindings/power/amlogic,a5-pwrc.h>
+#include <dt-bindings/power/amlogic,s6-pwrc.h>
+#include <dt-bindings/power/amlogic,s7-pwrc.h>
+#include <dt-bindings/power/amlogic,s7d-pwrc.h>
 #include <linux/arm-smccc.h>
 #include <linux/firmware/meson/meson_sm.h>
 #include <linux/module.h>
@@ -201,6 +204,71 @@ static const struct meson_secure_pwrc_domain_desc s4_pwrc_domains[] = {
 	SEC_PD(S4_AUDIO,	0),
 };
 
+static const struct meson_secure_pwrc_domain_desc s6_pwrc_domains[] = {
+	SEC_PD(S6_DSPA,		0),
+	SEC_PD(S6_DOS_HEVC,	0),
+	SEC_PD(S6_DOS_VDEC,	0),
+	SEC_PD(S6_VPU_HDMI,	0),
+	SEC_PD(S6_U2DRD,	0),
+	SEC_PD(S6_U3DRD,	0),
+	SEC_PD(S6_SD_EMMC_C,	0),
+	SEC_PD(S6_GE2D,		0),
+	SEC_PD(S6_AMFC,		0),
+	SEC_PD(S6_VC9000E,	0),
+	SEC_PD(S6_DEWARP,	0),
+	SEC_PD(S6_VICP,		0),
+	SEC_PD(S6_SD_EMMC_A,	0),
+	SEC_PD(S6_SD_EMMC_B,	0),
+	/* ETH is for ethernet online wakeup, and should be always on */
+	SEC_PD(S6_ETH,		GENPD_FLAG_ALWAYS_ON),
+	SEC_PD(S6_PCIE,		0),
+	SEC_PD(S6_NNA_4T,	0),
+	SEC_PD(S6_AUDIO,	0),
+	SEC_PD(S6_AUCPU,	0),
+	SEC_PD(S6_ADAPT,	0),
+};
+
+static const struct meson_secure_pwrc_domain_desc s7_pwrc_domains[] = {
+	SEC_PD(S7_DOS_HEVC,	0),
+	SEC_PD(S7_DOS_VDEC,	0),
+	SEC_PD(S7_VPU_HDMI,	0),
+	SEC_PD(S7_USB_COMB,	0),
+	SEC_PD(S7_SD_EMMC_C,	0),
+	SEC_PD(S7_GE2D,		0),
+	SEC_PD(S7_SD_EMMC_A,	0),
+	SEC_PD(S7_SD_EMMC_B,	0),
+	/* ETH is for ethernet online wakeup, and should be always on */
+	SEC_PD(S7_ETH,		GENPD_FLAG_ALWAYS_ON),
+	SEC_PD(S7_AUCPU,	0),
+	SEC_PD(S7_AUDIO,	0),
+};
+
+static const struct meson_secure_pwrc_domain_desc s7d_pwrc_domains[] = {
+	SEC_PD(S7D_DOS_HCODEC,	0),
+	SEC_PD(S7D_DOS_HEVC,	0),
+	SEC_PD(S7D_DOS_VDEC,	0),
+	SEC_PD(S7D_VPU_HDMI,	0),
+	SEC_PD(S7D_USB_U2DRD,	0),
+	SEC_PD(S7D_USB_U2H,	0),
+	SEC_PD(S7D_SSD_EMMC_C,	0),
+	SEC_PD(S7D_GE2D,	0),
+	SEC_PD(S7D_AMFC,	0),
+	SEC_PD(S7D_EMMC_A,	0),
+	SEC_PD(S7D_EMMC_B,	0),
+	/* ETH is for ethernet online wakeup, and should be always on */
+	SEC_PD(S7D_ETH,		GENPD_FLAG_ALWAYS_ON),
+	SEC_PD(S7D_AUCPU,	0),
+	SEC_PD(S7D_AUDIO,	0),
+	/* SRAMA is used as ATF runtime memory, and should be always on */
+	SEC_PD(S7D_SRAMA,	GENPD_FLAG_ALWAYS_ON),
+	/* DMC0 is for DDR PHY ana/dig and DMC, and should be always on */
+	SEC_PD(S7D_DMC0,	GENPD_FLAG_ALWAYS_ON),
+	/* DMC1 is for DDR PHY ana/dig and DMC, and should be always on */
+	SEC_PD(S7D_DMC1,	GENPD_FLAG_ALWAYS_ON),
+	/* DDR should be always on */
+	SEC_PD(S7D_DDR,		GENPD_FLAG_ALWAYS_ON),
+};
+
 static const struct meson_secure_pwrc_domain_desc t7_pwrc_domains[] = {
 	SEC_PD(T7_DSPA,		0),
 	SEC_PD(T7_DSPB,		0),
@@ -367,6 +435,21 @@ static const struct meson_secure_pwrc_domain_data meson_secure_s4_pwrc_data = {
 	.count = ARRAY_SIZE(s4_pwrc_domains),
 };
 
+static const struct meson_secure_pwrc_domain_data amlogic_secure_s6_pwrc_data = {
+	.domains = s6_pwrc_domains,
+	.count = ARRAY_SIZE(s6_pwrc_domains),
+};
+
+static const struct meson_secure_pwrc_domain_data amlogic_secure_s7_pwrc_data = {
+	.domains = s7_pwrc_domains,
+	.count = ARRAY_SIZE(s7_pwrc_domains),
+};
+
+static const struct meson_secure_pwrc_domain_data amlogic_secure_s7d_pwrc_data = {
+	.domains = s7d_pwrc_domains,
+	.count = ARRAY_SIZE(s7d_pwrc_domains),
+};
+
 static const struct meson_secure_pwrc_domain_data amlogic_secure_t7_pwrc_data = {
 	.domains = t7_pwrc_domains,
 	.count = ARRAY_SIZE(t7_pwrc_domains),
@@ -393,6 +476,18 @@ static const struct of_device_id meson_secure_pwrc_match_table[] = {
 		.compatible = "amlogic,meson-s4-pwrc",
 		.data = &meson_secure_s4_pwrc_data,
 	},
+	{
+		.compatible = "amlogic,s6-pwrc",
+		.data = &amlogic_secure_s6_pwrc_data,
+	},
+	{
+		.compatible = "amlogic,s7-pwrc",
+		.data = &amlogic_secure_s7_pwrc_data,
+	},
+	{
+		.compatible = "amlogic,s7d-pwrc",
+		.data = &amlogic_secure_s7d_pwrc_data,
+	},
 	{
 		.compatible = "amlogic,t7-pwrc",
 		.data = &amlogic_secure_t7_pwrc_data,

-- 
2.37.1

