From: Alexandre Rapaille <arapaille@atlr-engineering.com>
Date: Thu, 26 Nov 2026 14:45:55 +0100
Subject: [PATCH] soc: qcom: smsm: Don't log an error for hosts without a
 mailbox
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-smsm-null-mbox-v1-1-f6c6dcc2a3bf@atlr-engineering.com>
X-B4-Tracking: v=1; b=H4sIABI4CGsC/yWMQQ6CMBBFr0Jm7SS2FaJexbjolFHG0GI6YkgId
 7fF5Xv5/62gnIUVrs0Kmb+iMqUC5tBAGHx6MkpfGOzRdsbYDjVqxDSPI0aaFnSt872j8+nSMpT
 TO/NDlj14u/9ZZ3px+NRKXZBXRso+haGqvVcdbNsPovVQn44AAAA=
X-Change-ID: 20261126-smsm-null-mbox-353ad3b8495e
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Luca Weiss <luca@lucaweiss.eu>
Cc: linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Alexandre Rapaille <arapaille@atlr-engineering.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795700754; l=2215;
 i=arapaille@atlr-engineering.com; s=20261118; h=from:subject:message-id;
 bh=Zdp/d1BsiH+yO11n7o4Fii3aECRG4vjNTzA34WwBc40=;
 b=13BYSEIoS+XOFPsmtp77zhiYUtKmaFcpglHpR0R/3bySKvdsgiwqY/9s5Oke5937VCsfqUSE6
 MEu+bF7pM/pBD2A0oN4DnRKM1Kbmx+bifboal4M5ss2fwWOc6MvUuRR
X-Developer-Key: i=arapaille@atlr-engineering.com; a=ed25519;
 pk=xskH/sIiNU/aZCeGeBB1TK/AuiG3MXlX0m2wMlbMl08=
X-Endpoint-Received: by B4 Relay for arapaille@atlr-engineering.com/20261118 with auth_id=1560
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

smsm_parse_mbox() calls mbox_request_channel() for every host, so the
mailbox core logs an error for each host that has no mailbox before smsm
falls back to qcom,ipc. On msm8974 SMEM reports 5 hosts while mboxes has
4 entries, the first a null placeholder for the local host, so every
boot prints twice:

  qcom-smsm smsm: mbox_request_channel: can't parse "mboxes" property

Check the entry first and fall back quietly when it is null or missing.

Tested on a Fairphone 2: both lines are gone, hosts 1-3 still use their
mailboxes, and the modem comes back after forced restarts.

Fixes: 75287992f58a ("soc: qcom: smsm: Support using mailbox interface")
Signed-off-by: Alexandre Rapaille <arapaille@atlr-engineering.com>
---
Tested on a 6.18-based tree; smsm_parse_mbox() is identical in linux-next.
Existing DTBs keep the <0> placeholder, so this is needed even if the
binding moves to mbox-names.
---
 drivers/soc/qcom/smsm.c | 11 ++++++++++-
 1 file changed, 10 insertions(+), 1 deletion(-)

diff --git a/drivers/soc/qcom/smsm.c b/drivers/soc/qcom/smsm.c
index f6b7266a5af0..5cc31f1abaca 100644
--- a/drivers/soc/qcom/smsm.c
+++ b/drivers/soc/qcom/smsm.c
@@ -8,6 +8,7 @@
 #include <linux/mailbox_client.h>
 #include <linux/mfd/syscon.h>
 #include <linux/module.h>
+#include <linux/of.h>
 #include <linux/of_irq.h>
 #include <linux/platform_device.h>
 #include <linux/spinlock.h>
@@ -368,7 +369,15 @@ static const struct irq_domain_ops smsm_irq_ops = {
 static int smsm_parse_mbox(struct qcom_smsm *smsm, unsigned int host_id)
 {
 	struct smsm_host *host = &smsm->hosts[host_id];
-	int ret = 0;
+	struct of_phandle_args args;
+	int ret;
+
+	/* Hosts without a mailbox have a null or no entry: fall back quietly */
+	ret = of_parse_phandle_with_args(smsm->dev->of_node, "mboxes", "#mbox-cells",
+					 host_id, &args);
+	if (ret)
+		return ret;
+	of_node_put(args.np);
 
 	host->mbox_chan = mbox_request_channel(&smsm->mbox_client, host_id);
 	if (IS_ERR(host->mbox_chan)) {

---
base-commit: 20eef29b7c8465ac98d7dd6d6f2ac07a8d8056ca
change-id: 20261126-smsm-null-mbox-353ad3b8495e

Best regards,
--  
Alexandre Rapaille <arapaille@atlr-engineering.com>

