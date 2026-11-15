From: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Date: Mon, 16 Nov 2026 01:50:33 +0530
Subject: [PATCH 2/2] power: supply: qcom_battmgr: Don't limit the input
 current of chargers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-vantage-battmgr-v1-2-7b59157377b7@yahoo.com>
References: <20261116-vantage-battmgr-v1-0-7b59157377b7@yahoo.com>
In-Reply-To: <20261116-vantage-battmgr-v1-0-7b59157377b7@yahoo.com>
To: Sebastian Reichel <sre@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-pm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Joonhoe Kim <26rote@gmail.com>, 
 Venkat Yadlapati <venkat.yadlapati@yahoo.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794774031; l=1429;
 i=venkat.yadlapati@yahoo.com; s=20261023; h=from:subject:message-id;
 bh=FqtZ6Ic0uBzRQpyOLlJNs89UZMKR/UNotpRv7fpbq6E=;
 b=Q7DruqLx/KJquJ7DPNj1BoiGG4039NxLXtMsgHhpeT6UM4qqx5k4RqBuqZznf2rKDHj0YmfLN
 7TrQ3a7mzhyBnukDcsYPxdDcdEGksyS3BmMIAWhaPn/VFLGBoyIClr3
X-Developer-Key: i=venkat.yadlapati@yahoo.com; a=ed25519;
 pk=e8KStCtEMvUP1Se/riB/KVnDAQFEVR2Dw2PcuA8/eME=
X-Endpoint-Received: by B4 Relay for venkat.yadlapati@yahoo.com/20261023 with auth_id=1303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The input current limit of the USB power supply is meant for the current
a USB host grants, e.g. after enumeration. Like the downstream driver,
only apply it to SDP, CDP and USB PD ports, so that a dedicated charger
is never throttled to what a USB controller reports.

Assisted-by: LLM
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
2.56.0

