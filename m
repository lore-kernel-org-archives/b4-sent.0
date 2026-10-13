From: Brandon Williams <turbine.bmw@gmail.com>
Date: Tue, 13 Oct 2026 13:34:51 -0400
Subject: [PATCH] power: supply: qcom_battmgr: Notify charger supplies of
 online changes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261013-upstream-battmgr-charger-online-v1-1-731973e133a0@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXNQQqDMBCF4avIrDtgYpHaq5QuknSMU2qUmSiCe
 HfTdvnB4387KAmTwr3aQWhl5SkVmEsFYXApEvKrGGxtW1ObBpdZs5Ab0bucxyhYZhJJcEofToS
 hs7YxvnfXWwelMgv1vP0eHs+/dfFvCvmbheM4ARFO3mKDAAAA
X-Change-ID: 20261013-upstream-battmgr-charger-online-c92231bfa489
To: Sebastian Reichel <sre@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>
Cc: Sebastian Reichel <sebastian.reichel@collabora.com>, 
 linux-arm-msm@vger.kernel.org, linux-pm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Brandon Williams <turbine.bmw@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791912902; l=3326;
 i=turbine.bmw@gmail.com; s=20261013; h=from:subject:message-id;
 bh=2nahTR5uEsrzwi6gEYo9VL4sGI7ylJdvvKlUHbSEfWM=;
 b=LM56MtNNV6v+m7qf2P94pum++gKuqCP+2iZYUeT0ZwrYUbcRp4vk1/EeN/2uHg1OKY7eQ8nj4
 kevYfc+h5ziAyRr/Ifq8E3uREv8SLLuU13AvHBQeYaI/pV8TaeJpTEG
X-Developer-Key: i=turbine.bmw@gmail.com; a=ed25519;
 pk=Bpa28klX84MV14dvc8stQXHQtbFQK0xDK15qggaz3JA=
X-Endpoint-Received: by B4 Relay for turbine.bmw@gmail.com/20261013 with auth_id=1171
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On SC8280XP and X1E80100 the AC, USB and wireless supplies take their
online state from the charging source in the battery status response.
The firmware sends no notification for those supplies when the charging
source changes, and the driver only announces the battery, so userspace
never learns that the charger was plugged in or out. UPower keeps the
state it read at startup: a laptop booted on the charger never goes on
battery.

Call power_supply_changed() for a supply whose online state changes when
a status response is parsed. A supply that is not registered yet, when
the battery is read during probe, reports its state when it registers.

Tested on a Microsoft Surface Pro 11 (X1E80100): after restarting UPower
on the charger, unplugging now sets OnBattery, and plugging in clears it.

Fixes: 29e8142b5623 ("power: supply: Introduce Qualcomm PMIC GLINK power supply")
Cc: stable@vger.kernel.org
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Brandon Williams <turbine.bmw@gmail.com>
---
 drivers/power/supply/qcom_battmgr.c | 26 +++++++++++++++++++++++---
 1 file changed, 23 insertions(+), 3 deletions(-)

diff --git a/drivers/power/supply/qcom_battmgr.c b/drivers/power/supply/qcom_battmgr.c
index a7237ba09be1..4ca340981922 100644
--- a/drivers/power/supply/qcom_battmgr.c
+++ b/drivers/power/supply/qcom_battmgr.c
@@ -1255,6 +1255,23 @@ static unsigned int qcom_battmgr_sc8280xp_convert_temp(unsigned int temperature)
 	return DIV_ROUND_CLOSEST(temperature, 10);
 }
 
+/*
+ * The charger supplies' online state comes from the battery status response,
+ * and the firmware sends no notification of its own when it changes, so
+ * announce the change here. A supply that is not registered yet announces its
+ * state when it is.
+ */
+static void qcom_battmgr_sc8280xp_set_online(struct power_supply *psy,
+					     bool *online, bool value)
+{
+	if (*online == value)
+		return;
+
+	*online = value;
+	if (psy)
+		power_supply_changed(psy);
+}
+
 static void qcom_battmgr_sc8280xp_callback(struct qcom_battmgr *battmgr,
 					   const struct qcom_battmgr_message *resp,
 					   size_t len)
@@ -1324,9 +1341,12 @@ static void qcom_battmgr_sc8280xp_callback(struct qcom_battmgr *battmgr,
 		battmgr->status.temperature = qcom_battmgr_sc8280xp_convert_temp(le32_to_cpu(resp->status.temperature));
 
 		source = le32_to_cpu(resp->status.charging_source);
-		battmgr->ac.online = source == BATTMGR_CHARGING_SOURCE_AC;
-		battmgr->usb.online = source == BATTMGR_CHARGING_SOURCE_USB;
-		battmgr->wireless.online = source == BATTMGR_CHARGING_SOURCE_WIRELESS;
+		qcom_battmgr_sc8280xp_set_online(battmgr->ac_psy, &battmgr->ac.online,
+						 source == BATTMGR_CHARGING_SOURCE_AC);
+		qcom_battmgr_sc8280xp_set_online(battmgr->usb_psy, &battmgr->usb.online,
+						 source == BATTMGR_CHARGING_SOURCE_USB);
+		qcom_battmgr_sc8280xp_set_online(battmgr->wls_psy, &battmgr->wireless.online,
+						 source == BATTMGR_CHARGING_SOURCE_WIRELESS);
 		if (battmgr->info.last_full_capacity != 0) {
 			/*
 			 * 100 * battmgr->status.capacity can overflow a 32bit

---
base-commit: 4eb2586bd40db27d77cc5b724ca9386ed0c71d53
change-id: 20261013-upstream-battmgr-charger-online-c92231bfa489

Best regards,
--  
Brandon Williams <turbine.bmw@gmail.com>

