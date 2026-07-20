From: Nikolai Burov <nikolai.burov@jolla.com>
Date: Mon, 20 Jul 2026 23:46:47 +0300
Subject: [PATCH v3 2/3] pmdomain: mediatek: Add support for secure modem
 power domain control
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260720-mt6858-pmdomain-v3-2-8966d8de93c8@jolla.com>
References: <20260720-mt6858-pmdomain-v3-0-8966d8de93c8@jolla.com>
In-Reply-To: <20260720-mt6858-pmdomain-v3-0-8966d8de93c8@jolla.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Ulf Hansson <ulfh@kernel.org>
Cc: Matthias Brugger <mbrugger@suse.com>, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, linux-pm@vger.kernel.org, 
 Nikolai Burov <nikolai.burov@jolla.com>, 
 Nikolai Burov <nikolai.burov+review@abscue.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784580408; l=5639;
 i=nikolai.burov@jolla.com; s=20260707; h=from:subject:message-id;
 bh=5fzedbDsvOEQ+tbIFJcPFkJMjBII9+Zs4ulc0FKFtSM=;
 b=w8SvxSigsQlH1XUxPiYE9WlkOvNrUTghaVUa0Xl4qlFnAUFL6G+Zc7sZAG1KEPA4FVaivBQYM
 A9Jnl/H/q7vD2oUcAORV0KR2NFFlWsdCevne1m/5Jqj05fwEXpzyzd7
X-Developer-Key: i=nikolai.burov@jolla.com; a=ed25519;
 pk=yzpa+PD+ovHUFMIOBA9o2QqGwI110jM6hdGHLc7jtoQ=
X-Endpoint-Received: by B4 Relay for nikolai.burov@jolla.com/20260707 with auth_id=859
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On recent MediaTek SoCs such as MT6858, the kernel is required to use
a secure monitor call (SMC) to enable or disable the modem power domain.
The power domain control register can be read, but firmware prevents it
from being modified directly. Some other parts of the power sequence,
such as setting the ext_buck_iso register, still need to be performed on
the kernel side.

In preparation for modem support, add a flag to enable this new power
sequence for SoCs that need it. Power domains using this flag are not
expected to configure any bus protection registers, since these are
handled internally by the SMC call.

Signed-off-by: Nikolai Burov <nikolai.burov@jolla.com>
---
 drivers/pmdomain/mediatek/mtk-pm-domains.c | 50 +++++++++++++++++++++++++++---
 drivers/pmdomain/mediatek/mtk-pm-domains.h |  1 +
 include/linux/soc/mediatek/mtk_sip_svc.h   |  3 ++
 3 files changed, 49 insertions(+), 5 deletions(-)

diff --git a/drivers/pmdomain/mediatek/mtk-pm-domains.c b/drivers/pmdomain/mediatek/mtk-pm-domains.c
index 8309a4b46afb..5b4d860318a4 100644
--- a/drivers/pmdomain/mediatek/mtk-pm-domains.c
+++ b/drivers/pmdomain/mediatek/mtk-pm-domains.c
@@ -57,6 +57,10 @@
 
 #define MTK_SIP_KERNEL_HWCCF_CONTROL	MTK_SIP_SMC_CMD(0x540)
 
+/* Secure MTCMOS commands for modem subsystem */
+#define MTK_MD_MTCMOS_ENABLE		18
+#define MTK_MD_MTCMOS_DISABLE		19
+
 struct scpsys_domain {
 	struct generic_pm_domain genpd;
 	const struct scpsys_domain_data *data;
@@ -668,6 +672,34 @@ static int scpsys_modem_pwrseq_off(struct scpsys_domain *pd)
 	return 0;
 }
 
+static bool scpsys_modem_sec_poll(unsigned long cmd)
+{
+	struct arm_smccc_res res;
+
+	arm_smccc_smc(MTK_SIP_KERNEL_CCCI_CONTROL, cmd, 1, 0, 0, 0, 0, 0, &res);
+
+	return res.a0 == 0;
+}
+
+static int scpsys_modem_sec_power_on(bool on)
+{
+	struct arm_smccc_res res;
+	unsigned long cmd = on ? MTK_MD_MTCMOS_ENABLE : MTK_MD_MTCMOS_DISABLE;
+	bool tmp;
+	int ret;
+
+	arm_smccc_smc(MTK_SIP_KERNEL_CCCI_CONTROL, cmd, 0, 0, 0, 0, 0, 0, &res);
+	if (res.a0 == 0)
+		return 0;
+
+	ret = readx_poll_timeout(scpsys_modem_sec_poll, cmd, tmp, tmp,
+				 MTK_POLL_DELAY_US, MTK_POLL_TIMEOUT);
+	if (ret < 0)
+		return ret;
+
+	return 0;
+}
+
 static int scpsys_power_on(struct generic_pm_domain *genpd)
 {
 	struct scpsys_domain *pd = container_of(genpd, struct scpsys_domain, genpd);
@@ -686,7 +718,9 @@ static int scpsys_power_on(struct generic_pm_domain *genpd)
 		regmap_clear_bits(scpsys->base, pd->data->ext_buck_iso_offs,
 				  pd->data->ext_buck_iso_mask);
 
-	if (MTK_SCPD_CAPS(pd, MTK_SCPD_MODEM_PWRSEQ))
+	if (MTK_SCPD_CAPS(pd, MTK_SCPD_MODEM_SECURE_PWRSEQ))
+		ret = scpsys_modem_sec_power_on(true);
+	else if (MTK_SCPD_CAPS(pd, MTK_SCPD_MODEM_PWRSEQ))
 		ret = scpsys_modem_pwrseq_on(pd);
 	else if (MTK_SCPD_CAPS(pd, MTK_SCPD_SIMPLE_PWRSEQ))
 		ret = scpsys_simple_pwrseq_on(pd);
@@ -717,7 +751,8 @@ static int scpsys_power_on(struct generic_pm_domain *genpd)
 			goto err_pwr_ack;
 	}
 
-	if (!MTK_SCPD_CAPS(pd, MTK_SCPD_SIMPLE_PWRSEQ)) {
+	if (!MTK_SCPD_CAPS(pd, MTK_SCPD_SIMPLE_PWRSEQ) &&
+	    !MTK_SCPD_CAPS(pd, MTK_SCPD_MODEM_SECURE_PWRSEQ)) {
 		ret = scpsys_sram_enable(pd);
 		if (ret < 0)
 			goto err_disable_subsys_clks;
@@ -739,7 +774,8 @@ static int scpsys_power_on(struct generic_pm_domain *genpd)
 err_enable_bus_protect:
 	scpsys_bus_protect_enable(pd, 0);
 err_disable_sram:
-	if (!MTK_SCPD_CAPS(pd, MTK_SCPD_SIMPLE_PWRSEQ))
+	if (!MTK_SCPD_CAPS(pd, MTK_SCPD_SIMPLE_PWRSEQ) &&
+	    !MTK_SCPD_CAPS(pd, MTK_SCPD_MODEM_SECURE_PWRSEQ))
 		scpsys_sram_disable(pd);
 err_disable_subsys_clks:
 	if (!MTK_SCPD_CAPS(pd, MTK_SCPD_STRICT_BUS_PROTECTION))
@@ -761,7 +797,11 @@ static int scpsys_power_off_internal(struct scpsys_domain *pd)
 	if (ret < 0)
 		return ret;
 
-	if (!MTK_SCPD_CAPS(pd, MTK_SCPD_SIMPLE_PWRSEQ)) {
+	if (MTK_SCPD_CAPS(pd, MTK_SCPD_MODEM_SECURE_PWRSEQ)) {
+		ret = scpsys_modem_sec_power_on(false);
+		if (ret)
+			return ret;
+	} else if (!MTK_SCPD_CAPS(pd, MTK_SCPD_SIMPLE_PWRSEQ)) {
 		ret = scpsys_sram_disable(pd);
 		if (ret < 0)
 			return ret;
@@ -781,7 +821,7 @@ static int scpsys_power_off_internal(struct scpsys_domain *pd)
 		ret = scpsys_modem_pwrseq_off(pd);
 	else if (MTK_SCPD_CAPS(pd, MTK_SCPD_SIMPLE_PWRSEQ))
 		ret = scpsys_simple_pwrseq_off(pd);
-	else
+	else if (!MTK_SCPD_CAPS(pd, MTK_SCPD_MODEM_SECURE_PWRSEQ))
 		ret = scpsys_ctl_pwrseq_off(pd);
 
 	if (ret < 0) {
diff --git a/drivers/pmdomain/mediatek/mtk-pm-domains.h b/drivers/pmdomain/mediatek/mtk-pm-domains.h
index 092403de66fa..8690690335ad 100644
--- a/drivers/pmdomain/mediatek/mtk-pm-domains.h
+++ b/drivers/pmdomain/mediatek/mtk-pm-domains.h
@@ -18,6 +18,7 @@
 #define MTK_SCPD_SKIP_RESET_B		BIT(11)
 #define MTK_SCPD_INFRA_PWR_CTL		BIT(12)
 #define MTK_SCPD_SIMPLE_PWRSEQ		BIT(13)
+#define MTK_SCPD_MODEM_SECURE_PWRSEQ	BIT(14)
 #define MTK_SCPD_CAPS(_scpd, _x)	((_scpd)->data ?		\
 					 (_scpd)->data->caps & (_x) :	\
 					 (_scpd)->hwv_data->caps & (_x))
diff --git a/include/linux/soc/mediatek/mtk_sip_svc.h b/include/linux/soc/mediatek/mtk_sip_svc.h
index abe24a73ee19..6c95a29b79fa 100644
--- a/include/linux/soc/mediatek/mtk_sip_svc.h
+++ b/include/linux/soc/mediatek/mtk_sip_svc.h
@@ -22,6 +22,9 @@
 	ARM_SMCCC_CALL_VAL(ARM_SMCCC_FAST_CALL, MTK_SIP_SMC_CONVENTION, \
 			   ARM_SMCCC_OWNER_SIP, fn_id)
 
+/* Modem related SMC call */
+#define MTK_SIP_KERNEL_CCCI_CONTROL	MTK_SIP_SMC_CMD(0x505)
+
 /* DVFSRC SMC calls */
 #define MTK_SIP_DVFSRC_VCOREFS_CONTROL	MTK_SIP_SMC_CMD(0x506)
 

-- 
2.54.0

