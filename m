From: George Neacsu <geocausa@gmail.com>
Date: Fri, 16 Oct 2026 15:56:12 +0100
Subject: [PATCH v3 2/6] phy: Add MIPI C-PHY configuration helpers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261016-x1e-cphy-rfc-v3-2-40a346a72153@gmail.com>
References: <20261016-x1e-cphy-rfc-v3-0-40a346a72153@gmail.com>
In-Reply-To: <20261016-x1e-cphy-rfc-v3-0-40a346a72153@gmail.com>
To: Bryan O'Donoghue <bod@kernel.org>, Vinod Koul <vkoul@kernel.org>, 
 David Heidelberg <david@ixit.cz>
Cc: Neil Armstrong <neil.armstrong@linaro.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Nihal Kumar Gupta <nihal.gupta@oss.qualcomm.com>, 
 Vikram Sharma <vikram.sharma@oss.qualcomm.com>, 
 Suresh Vankadara <svankada@qti.qualcomm.com>, tjose@qti.qualcomm.com, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, linux-phy@lists.infradead.org, 
 linux-media@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 George Neacsu <geocausa@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792162570; l=3247;
 i=geocausa@gmail.com; s=20261015; h=from:subject:message-id;
 bh=oJIZmb5EbeE8l200gX3BwDF2KFgLiUAiv5ow1JJLKdU=;
 b=nWkNKyiE4u4PC0mjrHQeWwEGDHo3uoi48oQ4efl/w+zjSTE3qvz96TEGe3Ew6JKfPIEnG0Vr0
 fqds9NMjATlAbm0NOqwQeBGL+4DtSL7Rtw6/SsMO/alW8BB0roRC65i
X-Developer-Key: i=geocausa@gmail.com; a=ed25519;
 pk=KyQk/iWbxsikewDBh0SwlHI51RvAqahD3loqmRp9DVI=
X-Endpoint-Received: by B4 Relay for geocausa@gmail.com/20261015 with auth_id=1199
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A CSI-2 receiver knows the link frequency of its transmitter, and by the
V4L2 convention a C-PHY link frequency is half the symbol rate on each
trio. Add helpers so that the receiver and the PHY do not each open-code
that conversion, as phy_mipi_dphy_get_default_config_for_hsclk() does
for D-PHY:

- phy_mipi_cphy_get_default_config_for_link_freq() fills a
  configuration from a link frequency and a trio count;
- phy_mipi_cphy_config_validate() checks for a symbol rate and one to
  three trios;
- phy_mipi_cphy_link_freq() gives the link frequency of a configuration.

They are small enough to be inline, so no new Kconfig symbol is needed.

Suggested-by: Bryan O'Donoghue <bod@kernel.org>
Suggested-by: Loic Poulain <loic.poulain@oss.qualcomm.com>
Reviewed-by: Bryan O'Donoghue <bryan.odonoghue@linaro.org>
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: George Neacsu <geocausa@gmail.com>
---
 include/linux/phy/phy-mipi-cphy.h | 60 +++++++++++++++++++++++++++++++++++++++
 1 file changed, 60 insertions(+)

diff --git a/include/linux/phy/phy-mipi-cphy.h b/include/linux/phy/phy-mipi-cphy.h
index 9b748d577b..adc2dcbd2e 100644
--- a/include/linux/phy/phy-mipi-cphy.h
+++ b/include/linux/phy/phy-mipi-cphy.h
@@ -2,8 +2,11 @@
 #ifndef __PHY_MIPI_CPHY_H_
 #define __PHY_MIPI_CPHY_H_
 
+#include <linux/errno.h>
 #include <linux/types.h>
 
+#define PHY_MIPI_CPHY_MAX_TRIOS		3
+
 /**
  * struct phy_configure_opts_mipi_cphy - MIPI C-PHY configuration set
  *
@@ -26,4 +29,61 @@ struct phy_configure_opts_mipi_cphy {
 	u8			trios;
 };
 
+/**
+ * phy_mipi_cphy_config_validate() - Validate a MIPI C-PHY configuration
+ * @cfg: configuration to check
+ *
+ * Return: 0 if @cfg has a symbol rate and one to three trios, -EINVAL
+ * otherwise.
+ */
+static inline int
+phy_mipi_cphy_config_validate(const struct phy_configure_opts_mipi_cphy *cfg)
+{
+	if (!cfg->symbol_rate)
+		return -EINVAL;
+
+	if (cfg->trios < 1 || cfg->trios > PHY_MIPI_CPHY_MAX_TRIOS)
+		return -EINVAL;
+
+	return 0;
+}
+
+/**
+ * phy_mipi_cphy_get_default_config_for_link_freq() - C-PHY configuration
+ * from a link frequency
+ * @link_freq: link frequency in Hz
+ * @trios: number of active trios
+ * @cfg: configuration to fill
+ *
+ * A C-PHY link frequency is half the symbol rate on each trio, the
+ * convention V4L2 uses for the link frequency of a C-PHY transmitter.
+ *
+ * Return: 0 on success, -EINVAL if the resulting configuration is invalid.
+ */
+static inline int
+phy_mipi_cphy_get_default_config_for_link_freq(u64 link_freq,
+					       unsigned int trios,
+					       struct phy_configure_opts_mipi_cphy *cfg)
+{
+	if (trios > PHY_MIPI_CPHY_MAX_TRIOS)
+		return -EINVAL;
+
+	cfg->symbol_rate = link_freq * 2;
+	cfg->trios = trios;
+
+	return phy_mipi_cphy_config_validate(cfg);
+}
+
+/**
+ * phy_mipi_cphy_link_freq() - Link frequency of a MIPI C-PHY configuration
+ * @cfg: configuration
+ *
+ * Return: the link frequency in Hz, half the symbol rate on each trio.
+ */
+static inline u64
+phy_mipi_cphy_link_freq(const struct phy_configure_opts_mipi_cphy *cfg)
+{
+	return cfg->symbol_rate / 2;
+}
+
 #endif /* __PHY_MIPI_CPHY_H_ */

-- 
2.53.0

