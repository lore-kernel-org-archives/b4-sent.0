From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Tue, 22 Sep 2026 14:20:21 +0200
Subject: [PATCH v4 3/3] usb: typec: mux: ps883x: disable USB4 on incomplete
 USB4 platforms
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260922-ps883x-disable-usb4-v4-3-0a7b5b70cba3@oldschoolsolutions.biz>
References: <20260922-ps883x-disable-usb4-v4-0-0a7b5b70cba3@oldschoolsolutions.biz>
In-Reply-To: <20260922-ps883x-disable-usb4-v4-0-0a7b5b70cba3@oldschoolsolutions.biz>
To: Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Abel Vesa <abelvesa@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Sebastian Reichel <sre@kernel.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, stable@vger.kernel.org, 
 "Dr. David Alan Gilbert" <dave@treblig.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790079631; l=3472;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=1iyfmiUDL9sgFDlX61zRTpyxAquXyuctxtavKjTdzIc=;
 b=J0IUqClEUZPz1wWom/lQCMTO4v8fyoIfQF/bbD/d9SuXRG/vyp8zSbreuHbgUP3MVqnOqEMvJ
 x3waPJ0VHuuCK2otyRIwSyjXtCTf42dUM6dCdz72OG7HzVNCfIFrHjy
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On Qualcomm X1E80100 / X1P42100 platforms using the Parade PS883x
retimer, hotplugging USB4-capable docks such as the Lenovo 40B0 can
result in working USB but no DisplayPort output.

When the dock negotiates USB4, the retimer receives TYPEC_MODE_USB4
and forwards it via typec_mux_set(). The qmp-combo PHY then selects
USB3-only because no classic DP altmode SVID is present in the state,
leaving the DP transmitter and AUX channel disabled.

Reject USB4 with -EOPNOTSUPP on platforms whose USB4 / DP-tunneling
stack is not ready yet. The Type-C stack then falls back to USB3 + DP
Alt Mode. DP altmode configuration continues to use the existing
ps883x_set() path.

Use a machine-compatible table rather than a DT property so the quirk
stays inside the kernel and can be removed later without creating ABI.

Assisted-by: Grok(xAI):4.6
Tested-by: Dr. David Alan Gilbert <dave@treblig.org>
Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 drivers/usb/typec/mux/ps883x.c | 37 +++++++++++++++++++++++++++++++++++++
 1 file changed, 37 insertions(+)

diff --git a/drivers/usb/typec/mux/ps883x.c b/drivers/usb/typec/mux/ps883x.c
index 15aee1d613b1a..2ec57cfe748a9 100644
--- a/drivers/usb/typec/mux/ps883x.c
+++ b/drivers/usb/typec/mux/ps883x.c
@@ -13,6 +13,7 @@
 #include <linux/kernel.h>
 #include <linux/module.h>
 #include <linux/mutex.h>
+#include <linux/of.h>
 #include <linux/regmap.h>
 #include <linux/regulator/consumer.h>
 #include <linux/usb/pd.h>
@@ -42,6 +43,22 @@
 #define CONN_STATUS_2_TBT_UNIDIR_LSRX_ACT_LT	BIT(4)
 #define CONN_STATUS_2_USB4_CONNECTED		BIT(7)
 
+/*
+ * Platforms where the USB4 / DP-tunneling stack is not ready yet. Rejecting
+ * USB4 here lets the Type-C stack fall back to USB3 + DP Alt Mode instead of
+ * negotiating USB4 and then failing to drive DisplayPort.
+ *
+ * This is a temporary, kernel-contained quirk (not DT ABI). Drop the entries
+ * once the corresponding USB4 support is complete.
+ */
+static const char * const ps883x_disable_usb4_compats[] = {
+	"qcom,x1e80100",
+	"qcom,x1p42100",
+	"qcom,hamoa",
+	"qcom,purwa",
+	NULL,
+};
+
 struct ps883x_retimer {
 	struct i2c_client *client;
 	struct gpio_desc *reset_gpio;
@@ -63,8 +80,21 @@ struct ps883x_retimer {
 
 	enum typec_orientation orientation;
 	bool in_reset;
+	bool disable_usb4;
 };
 
+static bool ps883x_should_disable_usb4(void)
+{
+	const char * const *compat;
+
+	for (compat = ps883x_disable_usb4_compats; *compat; compat++) {
+		if (of_machine_is_compatible(*compat))
+			return true;
+	}
+
+	return false;
+}
+
 static int ps883x_enable_vregs(struct ps883x_retimer *retimer)
 {
 	struct device *dev = &retimer->client->dev;
@@ -260,6 +290,9 @@ static int ps883x_set(struct ps883x_retimer *retimer, struct typec_retimer_state
 			cfg0 |= CONN_STATUS_0_USB_3_1_CONNECTED;
 			break;
 		case TYPEC_MODE_USB4:
+			if (retimer->disable_usb4)
+				return -EOPNOTSUPP;
+
 			eudo_data = state->data;
 
 			cfg2 |= CONN_STATUS_2_USB4_CONNECTED;
@@ -389,6 +422,10 @@ static int ps883x_retimer_probe(struct i2c_client *client)
 
 	retimer->client = client;
 
+	retimer->disable_usb4 = ps883x_should_disable_usb4();
+	if (retimer->disable_usb4)
+		dev_info(dev, "USB4 disabled until platform USB4 support is complete\n");
+
 	mutex_init(&retimer->lock);
 
 	retimer->regmap = devm_regmap_init_i2c(client, &ps883x_retimer_regmap);

-- 
2.53.0

