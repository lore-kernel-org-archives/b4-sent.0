From: Fabricio Akio <fabricioakio@gmail.com>
Date: Fri, 02 Oct 2026 22:29:32 -0300
Subject: [PATCH] power: supply: qcom_smbx: set the charge enable after
 software control
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261002-qcom-smbx-enable-order-v1-1-7df92bd809db@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CMBBA0auQWTtJW5LSeBXjgpZBx0irM2hIC
 Hen6PIt/l9BSZgUzs0KQl9WLrnCnhpI9z7fCHmoBmect8Y4fKcyoU5xQcp9fBIWGUgwWN+F0Lb
 d6DzU+CU08vIbX65/6yc+KM3HDbZtBx/XLcV6AAAA
X-Change-ID: 20261002-qcom-smbx-enable-order-816788337f26
To: Casey Connolly <casey.connolly@linaro.org>, 
 Sebastian Reichel <sre@kernel.org>
Cc: Robin Snyders <robin@snyders.xyz>, David Heidelberg <david@ixit.cz>, 
 phone-devel@vger.kernel.org, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 linux-arm-msm@vger.kernel.org, linux-pm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Fabricio Akio <fabricioakio@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790990971; l=2731;
 i=fabricioakio@gmail.com; s=20260928; h=from:subject:message-id;
 bh=KF/MJVvh/TX0FU51WaZ1SUC1yakDAzVQ6C7beULA/UI=;
 b=l5oD2SkijJfDZhB9ybMIQSXgbIlnwBVRejdsrj36b5XFz1cfy43ct74UAces2MqLqa/OT0LS9
 6qqirKakBFvC8D3viGO/N5tGXO2WfCmREh6GDnZu5R0ykEPNrgyoiLS
X-Developer-Key: i=fabricioakio@gmail.com; a=ed25519;
 pk=TlMUT8bPI/ZQzp2q24BIQTb2qSx/jdUTBlGEXIRCm54=
X-Endpoint-Received: by B4 Relay for fabricioakio@gmail.com/20260928 with auth_id=1076
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The init sequence sets CHARGING_ENABLE_CMD before CHGR_CFG2 selects
software control of the charge enable.

The Motorola Moto X4's bootloader leaves the charger watchdog armed to
disable charging when it bites, which it does after a few minutes in
fastboot. Charging then stays disabled in the next boot until the cable
is replugged. Setting the command after CHGR_CFG2 re-enables it.

Fixes: 8648aeb5d7b7 ("power: supply: add Qualcomm PMI8998 SMB2 Charger driver")
Cc: stable@vger.kernel.org
Signed-off-by: Fabricio Akio <fabricioakio@gmail.com>
---
Tested on a Motorola Moto X4 (XT1900-6, SDM630 with PM660) with the
sdm660-mainline 7.2.3 tree. After the bootloader's charger watchdog had
bitten, in a boot without this driver or after three to five minutes in
fastboot, the charger stayed in DISABLE_CHARGE without this patch. With
it, charging resumed with no cable replug: 0.7 A into the battery at
89%. Other boards are untested.

Robin Snyders' pending SMB5 series renames smb_init_seq[], so whichever
of the two lands second needs a trivial rebase. Applies unchanged to
next-20261001.
---
 drivers/power/supply/qcom_smbx.c | 11 +++++++----
 1 file changed, 7 insertions(+), 4 deletions(-)

diff --git a/drivers/power/supply/qcom_smbx.c b/drivers/power/supply/qcom_smbx.c
index f5557b8cc92a..8c6b7c46b85f 100644
--- a/drivers/power/supply/qcom_smbx.c
+++ b/drivers/power/supply/qcom_smbx.c
@@ -819,11 +819,7 @@ static const struct smb_init_register smb_init_seq[] = {
 	  .mask = SOC_LT_CHG_RECHARGE_THRESH_SEL_BIT |
 		  VBT_LT_CHG_RECHARGE_THRESH_SEL_BIT,
 	  .val = VBT_LT_CHG_RECHARGE_THRESH_SEL_BIT },
-	/* Enable charging */
 	{ .addr = USBIN_OPTIONS_1_CFG, .mask = HVDCP_EN_BIT, .val = 0 },
-	{ .addr = CHARGING_ENABLE_CMD,
-	  .mask = CHARGING_ENABLE_CMD_BIT,
-	  .val = CHARGING_ENABLE_CMD_BIT },
 	/*
 	 * Match downstream defaults
 	 * CHG_EN_SRC_BIT - charger enable is controlled by software
@@ -844,6 +840,13 @@ static const struct smb_init_register smb_init_seq[] = {
 		  AUTO_RECHG_BIT | EN_ANALOG_DROP_IN_VBATT_BIT |
 		  CHARGER_INHIBIT_BIT,
 	  .val = CHARGER_INHIBIT_BIT },
+	/*
+	 * Set the enable command only once CHGR_CFG2 has selected software
+	 * control, or a charger its watchdog has disabled stays disabled.
+	 */
+	{ .addr = CHARGING_ENABLE_CMD,
+	  .mask = CHARGING_ENABLE_CMD_BIT,
+	  .val = CHARGING_ENABLE_CMD_BIT },
 	/* STAT pin software override, match downstream. Parallel charging? */
 	{ .addr = STAT_CFG,
 	  .mask = STAT_SW_OVERRIDE_CFG_BIT,

---
base-commit: 9f24d789f03b22941b905ded43cb5ff8eea9ce62
change-id: 20261002-qcom-smbx-enable-order-816788337f26

Best regards,
--  
Fabricio Akio <fabricioakio@gmail.com>

