From: Anthony Ruhier <aruhier@mailbox.org>
Date: Thu, 13 Feb 2025 17:51:38 +0100
Subject: [PATCH RESEND] power: supply: qcom_battmgr: abs() on POWER_NOW
 property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250213-patch-qcomm-bat-uint-power-v1-1-16e7e2a77a02@mailbox.org>
To: Sebastian Reichel <sre@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-pm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Anthony Ruhier <aruhier@mailbox.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2103; i=aruhier@mailbox.org;
 h=from:subject:message-id; bh=lSOxkdOf6gRdpUszCsRF5pZ7uZYHKUdsGgP+kJrQraU=;
 b=owGbwMvMwCVW2Nrw47jsO3/G02pJDOnrlLUlpUtWJmwo37z5H7fgTxWLRTtP/zPi65D4fydhx
 9Te0vlmHaUsDGJcDLJiiiwl+6OEb6t03HdYu5wFZg4rE8gQBi5OAZhIzgqGfwq3Mw1zP1pMVFH7
 X3J796T3nvfVzJimaOUbqQVOsknYzMLIsPPMo7TopmVuYQ0bZtTt2a3VZcVRcyjm86W1T3z1JTW
 ZWAA=
X-Developer-Key: i=aruhier@mailbox.org; a=openpgp;
 fpr=F4A378DD8D494AE48EBA554CB00FBC7D08D231D9
X-Endpoint-Received: by B4 Relay for aruhier@mailbox.org/default with auth_id=302
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The value for the POWER_NOW property is by default negative when the
battery is discharging, positive when charging.

However on x1e laptops it breaks several userland tools that give a
prediction of the battery run time (such as the acpi command, powertop
or the waybar battery module), as these tools do not expect a negative
value for /sys/class/power_supply/qcom-battmgr-bat/power_now. They
estimate the battery run time by dividing the value of energy_full by
power_now. The battery percentage is calculated by dividing energy_full
by energy_now, therefore it is not impacted.

While having a negative number during discharge makes sense, it is not
standard with how other battery drivers expose it. Instead, it seems
standard to have a positive value for power_now, and rely on the status
file instead to know if the battery is charging or discharging. It is
what other x86 laptops do.

Without the patch:
    $ acpi
    Battery 0: Discharging, 98%, discharging at zero rate - will never fully discharge.

With the patch:
    $ acpi
    Battery 0: Discharging, 97%, 10:18:27 remaining

---
Signed-off-by: Anthony Ruhier <aruhier@mailbox.org>
---
 drivers/power/supply/qcom_battmgr.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/power/supply/qcom_battmgr.c b/drivers/power/supply/qcom_battmgr.c
index 47d29271ddf400b76dd5b0a1b8d1ba86c017afc0..3e2e0c5af2814df0eb0bfc408d4b3d26399ab4e4 100644
--- a/drivers/power/supply/qcom_battmgr.c
+++ b/drivers/power/supply/qcom_battmgr.c
@@ -530,7 +530,7 @@ static int qcom_battmgr_bat_get_property(struct power_supply *psy,
 		val->intval = battmgr->status.current_now;
 		break;
 	case POWER_SUPPLY_PROP_POWER_NOW:
-		val->intval = battmgr->status.power_now;
+		val->intval = abs(battmgr->status.power_now);
 		break;
 	case POWER_SUPPLY_PROP_CHARGE_FULL_DESIGN:
 		if (unit != QCOM_BATTMGR_UNIT_mAh)

---
base-commit: ffd294d346d185b70e28b1a28abe367bbfe53c04
change-id: 20250128-patch-qcomm-bat-uint-power-5793f3638c56

Best regards,
-- 
Anthony Ruhier <aruhier@mailbox.org>

