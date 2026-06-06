From: Sam Day <me@samcday.com>
Date: Sat, 06 Jun 2026 18:47:36 +1000
Subject: [PATCH 05/11] sysreset: qcom-pshold: PM8916 PON reset type support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260606-pm8916-pon-v1-5-170c9cbe5099@samcday.com>
References: <20260606-pm8916-pon-v1-0-170c9cbe5099@samcday.com>
In-Reply-To: <20260606-pm8916-pon-v1-0-170c9cbe5099@samcday.com>
To: u-boot@lists.denx.de, Sumit Garg <sumit.garg@kernel.org>, 
 u-boot-qcom@groups.io
Cc: Tom Rini <trini@konsulko.com>, 
 Casey Connolly <casey.connolly@linaro.org>, Peng Fan <peng.fan@nxp.com>, 
 Leo Yu-Chi Liang <ycliang@andestech.com>, Anshul Dalal <anshuld@ti.com>, 
 Kever Yang <kever.yang@rock-chips.com>, 
 Neha Malcom Francis <n-francis@ti.com>, 
 Justin Klaassen <justin@tidylabs.net>, 
 Jamie Gibbons <jamie.gibbons@microchip.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Andrew Goodbody <andrew.goodbody@linaro.org>, 
 Aswin Murugan <aswin.murugan@oss.qualcomm.com>, 
 Varadarajan Narayanan <varadarajan.narayanan@oss.qualcomm.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, 
 Mateus Lima Alves <mateuslima.ti@gmail.com>, 
 Sughosh Ganu <sughosh.ganu@arm.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 George Chan <gchan9527@gmail.com>, 
 Antony Kurniawan Soemardi <linux@smankusors.com>, 
 Mattijs Korpershoek <mkorpershoek@kernel.org>, 
 Peter Robinson <pbrobinson@gmail.com>, 
 Ariel D'Alessandro <ariel.dalessandro@collabora.com>, 
 Dmitrii Merkurev <dimorinny@google.com>, Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780735669; l=1606;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=lMO6yWOp/proHsUHO0eKk6GQnq/J24pQ78nHP3WriT8=;
 b=pCuRpkfL2dEQ4kuRHwatlVXeoKfJbeI5zV48QE5bh2H6VF/r0//T9Lhs1ftNiDofw+Zq1AIJD
 WtZxteJJWTEDNLX3LXLxKPT6r5+2ng2a+BXASQBHbSSmLmh0LK3Aa3R
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Before de-asserting PS_HOLD, PM8916 PMIC can be informed of what kind of
reset should take place.

This might seem a little hacky/weird, but it's a byproduct of how the DT
nodes are structured, and the way u-boot handles sysreset.

The qcom,pshold node does not belong to the PMIC hierarchy. If U-Boot's
sysreset infra was a little more flexible, we might be able to model the
qcom,pm8916-pon driver as UCLASS_SYSRESET in order to catch the sysreset
type and set the appropriate bits in the PMIC, before chaining to the
pshold driver to de-assert PS_HOLD (which actually triggers the reset
type that was written in the previous step).

Signed-off-by: Sam Day <me@samcday.com>
---
 drivers/sysreset/sysreset_qcom-pshold.c | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/drivers/sysreset/sysreset_qcom-pshold.c b/drivers/sysreset/sysreset_qcom-pshold.c
index 45290478536..20ddb4ae4ec 100644
--- a/drivers/sysreset/sysreset_qcom-pshold.c
+++ b/drivers/sysreset/sysreset_qcom-pshold.c
@@ -13,6 +13,8 @@
 #include <sysreset.h>
 #include <asm/io.h>
 #include <linux/delay.h>
+#include <dm/device_compat.h>
+#include "pm8916_pon.h"
 
 struct qcom_pshold_priv {
 	phys_addr_t base;
@@ -22,6 +24,13 @@ static int qcom_pshold_request(struct udevice *dev, enum sysreset_t type)
 {
 	struct qcom_pshold_priv *priv = dev_get_priv(dev);
 
+	if (CONFIG_IS_ENABLED(PM8916_PON)) {
+		int ret = pm8916_pon_set_reboot_type(type);
+
+		if (ret)
+			dev_err(dev, "Failed to set reboot type: %d\n", ret);
+	}
+
 	writel(0, priv->base);
 	mdelay(10000);
 

-- 
2.54.0

