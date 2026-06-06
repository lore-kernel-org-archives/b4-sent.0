From: Sam Day <me@samcday.com>
Date: Sat, 06 Jun 2026 18:47:32 +1000
Subject: [PATCH 01/11] button: qcom-pmic: introduce exported setup method
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260606-pm8916-pon-v1-1-170c9cbe5099@samcday.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780735669; l=2256;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=oTF4eBQpgeurSjGv0sN01MsXdq3y55kE5LVS7G1ONMw=;
 b=JrFh35c8rOLG6/VBROQi+EqmMPeDVSDSc0Ba6wjxWWaiIdtcfypmHpEWqHw5A6ynBOu62JS/t
 pW4mwq4kGr2D5F+SMmizY3LF43JuSoJS0tRNIuocvAwTwsclsoX41bu
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The qcom_pwrkey driver is currently binding to both the individual
pwrkey/resin nodes, as well as the parent pon node.

In the next commit, a new glue driver will be introduced for pm8916_pon,
which will continue binding these buttons, as well as additional
drivers.

button_qcom_pmic_bind was renamed to button_qcom_pmic_setup and exported
in a shared header, which the new pm8916_pon driver will call.

Signed-off-by: Sam Day <me@samcday.com>
---
 drivers/button/button-qcom-pmic.c |  6 +++---
 include/button/qcom-pmic.h        | 17 +++++++++++++++++
 2 files changed, 20 insertions(+), 3 deletions(-)

diff --git a/drivers/button/button-qcom-pmic.c b/drivers/button/button-qcom-pmic.c
index b823490d6d5..d9ac6a51df5 100644
--- a/drivers/button/button-qcom-pmic.c
+++ b/drivers/button/button-qcom-pmic.c
@@ -13,9 +13,9 @@
 #include <dm/lists.h>
 #include <log.h>
 #include <power/pmic.h>
-#include <spmi/spmi.h>
 #include <linux/bitops.h>
 #include <time.h>
+#include "button/qcom-pmic.h"
 
 #define REG_TYPE		0x4
 #define REG_SUBTYPE		0x5
@@ -174,7 +174,7 @@ static int qcom_pwrkey_probe(struct udevice *dev)
 	return 0;
 }
 
-static int button_qcom_pmic_bind(struct udevice *parent)
+int button_qcom_pmic_setup(struct udevice *parent)
 {
 	struct udevice *dev;
 	ofnode node;
@@ -227,7 +227,7 @@ U_BOOT_DRIVER(qcom_pwrkey) = {
 	.name = "qcom_pwrkey",
 	.id = UCLASS_BUTTON,
 	.of_match = qcom_pwrkey_ids,
-	.bind = button_qcom_pmic_bind,
+	.bind = button_qcom_pmic_setup,
 	.probe = qcom_pwrkey_probe,
 	.ops = &button_qcom_pmic_ops,
 	.priv_auto = sizeof(struct qcom_pmic_btn_priv),
diff --git a/include/button/qcom-pmic.h b/include/button/qcom-pmic.h
new file mode 100644
index 00000000000..d321bbab460
--- /dev/null
+++ b/include/button/qcom-pmic.h
@@ -0,0 +1,17 @@
+/* SPDX-License-Identifier: GPL-2.0+ */
+
+#include <dm/device.h>
+#include <linux/errno.h>
+
+#if CONFIG_IS_ENABLED(BUTTON_QCOM_PMIC)
+/**
+ * Binds the qcom_pwrkey driver to compatible pwrkey/resin child nodes
+ * belonging to @parent
+ */
+int button_qcom_pmic_setup(struct udevice *parent);
+#else
+static int button_qcom_pmic_setup(struct udevice *parent)
+{
+	return -ENOSYS;
+}
+#endif

-- 
2.54.0

