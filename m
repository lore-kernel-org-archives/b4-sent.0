From: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Date: Mon, 16 Nov 2026 01:50:32 +0530
Subject: [PATCH 1/2] power: supply: qcom_battmgr: Apply a USB input current
 limit set early
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-vantage-battmgr-v1-1-7b59157377b7@yahoo.com>
References: <20261116-vantage-battmgr-v1-0-7b59157377b7@yahoo.com>
In-Reply-To: <20261116-vantage-battmgr-v1-0-7b59157377b7@yahoo.com>
To: Sebastian Reichel <sre@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-pm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Joonhoe Kim <26rote@gmail.com>, 
 Venkat Yadlapati <venkat.yadlapati@yahoo.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794774031; l=3206;
 i=venkat.yadlapati@yahoo.com; s=20261023; h=from:subject:message-id;
 bh=X+AIq+fbPAzYnRwecAS8d+FO3Yj8+xtS8ZnJK+o2XnM=;
 b=1cTGhpH/zgCODx/8HqAWHqYqLH69ys6ZdUEfiixrF1PWjYy+WsI+Q9SISk7skES9t+ieJEHRQ
 iwP5BdEMykZBwQFtmS/iygkGCCA4LgVyYKbzN09s7gLuk8hRjm0Up9t
X-Developer-Key: i=venkat.yadlapati@yahoo.com; a=ed25519;
 pk=e8KStCtEMvUP1Se/riB/KVnDAQFEVR2Dw2PcuA8/eME=
X-Endpoint-Received: by B4 Relay for venkat.yadlapati@yahoo.com/20261023 with auth_id=1303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The USB controller can report the current a USB host grants, e.g. with
the usb-psy-name property of dwc3, before the battery manager service
is up. The input current limit is then rejected with -EAGAIN and the
firmware keeps the 100 mA allowed before enumeration, so a phone that is
in use discharges while it is connected to a computer.

Remember the limit while the service is down and send it once the
service comes up.

Assisted-by: LLM
Signed-off-by: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
---
 drivers/power/supply/qcom_battmgr.c | 45 +++++++++++++++++++++++++++++--------
 1 file changed, 36 insertions(+), 9 deletions(-)

diff --git a/drivers/power/supply/qcom_battmgr.c b/drivers/power/supply/qcom_battmgr.c
index 431a35bcac80..fde9704d0acd 100644
--- a/drivers/power/supply/qcom_battmgr.c
+++ b/drivers/power/supply/qcom_battmgr.c
@@ -329,6 +329,10 @@ struct qcom_battmgr {
 
 	bool service_up;
 
+	/* USB input current limit set before the service was up, in uA */
+	bool usb_icl_pending;
+	u32 usb_icl;
+
 	struct qcom_battmgr_info info;
 	struct qcom_battmgr_status status;
 	struct qcom_battmgr_ac ac;
@@ -1144,25 +1148,40 @@ static const struct power_supply_desc sc8280xp_usb_psy_desc = {
 		     BIT(POWER_SUPPLY_USB_TYPE_APPLE_BRICK_ID),
 };
 
+static int qcom_battmgr_usb_set_icl(struct qcom_battmgr *battmgr, u32 icl)
+{
+	int ret;
+
+	mutex_lock(&battmgr->lock);
+	ret = qcom_battmgr_request_property(battmgr, BATTMGR_USB_PROPERTY_SET,
+					    USB_INPUT_CURR_LIMIT, icl);
+	mutex_unlock(&battmgr->lock);
+
+	return ret;
+}
+
 static int qcom_battmgr_usb_set_property(struct power_supply *psy,
 					 enum power_supply_property psp,
 					 const union power_supply_propval *pval)
 {
 	struct qcom_battmgr *battmgr = power_supply_get_drvdata(psy);
-	int ret;
-
-	if (!battmgr->service_up)
-		return -EAGAIN;
 
 	if (psp != POWER_SUPPLY_PROP_INPUT_CURRENT_LIMIT || pval->intval < 0)
 		return -EINVAL;
 
-	mutex_lock(&battmgr->lock);
-	ret = qcom_battmgr_request_property(battmgr, BATTMGR_USB_PROPERTY_SET,
-					    USB_INPUT_CURR_LIMIT, pval->intval);
-	mutex_unlock(&battmgr->lock);
+	/*
+	 * The USB controller can report the current a host grants before the
+	 * firmware service is up, apply it once the service comes up.
+	 */
+	if (!battmgr->service_up) {
+		battmgr->usb_icl = pval->intval;
+		battmgr->usb_icl_pending = true;
+		return 0;
+	}
 
-	return ret;
+	battmgr->usb_icl_pending = false;
+
+	return qcom_battmgr_usb_set_icl(battmgr, pval->intval);
 }
 
 static int qcom_battmgr_usb_is_writeable(struct power_supply *psy,
@@ -1742,6 +1761,14 @@ static void qcom_battmgr_enable_worker(struct work_struct *work)
 	ret = qcom_battmgr_request(battmgr, &req, sizeof(req));
 	if (ret)
 		dev_err(battmgr->dev, "failed to request power notifications\n");
+
+	if (battmgr->usb_icl_pending) {
+		battmgr->usb_icl_pending = false;
+		ret = qcom_battmgr_usb_set_icl(battmgr, battmgr->usb_icl);
+		if (ret)
+			dev_warn(battmgr->dev,
+				 "failed to set the USB input current limit: %d\n", ret);
+	}
 }
 
 static void qcom_battmgr_pdr_notify(void *priv, int state)

-- 
2.56.0

