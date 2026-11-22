From: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Date: Mon, 23 Nov 2026 00:50:16 +0530
Subject: [PATCH v2 2/2] power: supply: qcom_battmgr: Don't limit the input
 current of chargers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-vantage-battmgr-v2-2-03a419078d0a@yahoo.com>
References: <20261123-vantage-battmgr-v2-0-03a419078d0a@yahoo.com>
In-Reply-To: <20261123-vantage-battmgr-v2-0-03a419078d0a@yahoo.com>
To: Sebastian Reichel <sre@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-pm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Joonhoe Kim <26rote@gmail.com>, 
 phone-devel@vger.kernel.org, Venkat Yadlapati <venkat.yadlapati@yahoo.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795375214; l=1411;
 i=venkat.yadlapati@yahoo.com; s=20261023; h=from:subject:message-id;
 bh=D6CkSLFvs+RdQcscVKpLSyfkBgPa5oeQD51e9q+TG1A=;
 b=HyjNF2dtjBqfc9Ee4iDAPpNooLR6+P9ZUCD6obL1CYuN8Y6xPxkZwKW6MrNvVfT+8Rghzj7Ha
 Vm51iVQ488OCJ5g8bYuDAqpDq5E5+Wpn2sjhfiW3HVOcsXS1wn40Hmw
X-Developer-Key: i=venkat.yadlapati@yahoo.com; a=ed25519;
 pk=e8KStCtEMvUP1Se/riB/KVnDAQFEVR2Dw2PcuA8/eME=
X-Endpoint-Received: by B4 Relay for venkat.yadlapati@yahoo.com/20261023 with auth_id=1303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The input current limit of the USB power supply is meant for the current
a USB host grants, e.g. after enumeration. Like the downstream driver,
only apply it to SDP, CDP and USB PD ports, so that a dedicated charger
is never throttled to what a USB controller reports.

Signed-off-by: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
---
 drivers/power/supply/qcom_battmgr.c | 18 ++++++++++++++++++
 1 file changed, 18 insertions(+)

diff --git a/drivers/power/supply/qcom_battmgr.c b/drivers/power/supply/qcom_battmgr.c
index fde9704d0acd..db117cb64a17 100644
--- a/drivers/power/supply/qcom_battmgr.c
+++ b/drivers/power/supply/qcom_battmgr.c
@@ -1152,6 +1152,24 @@ static int qcom_battmgr_usb_set_icl(struct qcom_battmgr *battmgr, u32 icl)
 {
 	int ret;
 
+	ret = qcom_battmgr_usb_sm8350_update(battmgr, POWER_SUPPLY_PROP_USB_TYPE);
+	if (ret)
+		return ret;
+
+	/*
+	 * The limit is meant for the current a USB host grants, e.g. after
+	 * enumeration, like the downstream driver don't let it throttle
+	 * dedicated chargers.
+	 */
+	switch (battmgr->usb.usb_type) {
+	case POWER_SUPPLY_USB_TYPE_SDP:
+	case POWER_SUPPLY_USB_TYPE_CDP:
+	case POWER_SUPPLY_USB_TYPE_PD:
+		break;
+	default:
+		return -EINVAL;
+	}
+
 	mutex_lock(&battmgr->lock);
 	ret = qcom_battmgr_request_property(battmgr, BATTMGR_USB_PROPERTY_SET,
 					    USB_INPUT_CURR_LIMIT, icl);

-- 
2.56.1

