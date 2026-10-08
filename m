From: Fabricio Akio <fabricioakio@gmail.com>
Date: Thu, 08 Oct 2026 17:56:18 -0300
Subject: [PATCH] power: supply: qcom_smbx: read the charging status without
 the power supply
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261008-qcom-smbx-psy-race-v1-1-cb49fe7b4336@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQqDMBBA4avIrDuQBBTrVaQLM07aKfjTjIoi3
 t1Yl9/ivR2Uo7BCle0QeRGVoU+wjwzo0/RvRmmTwRlXWGNK/NHQoXZ+xVE3jA0x5s7mRRmeFFq
 GFI6Rg6z/af26rbP/Mk3XCY7jBI+mD852AAAA
X-Change-ID: 20261008-qcom-smbx-psy-race-521568f9cfde
To: Casey Connolly <casey.connolly@linaro.org>, 
 Sebastian Reichel <sre@kernel.org>
Cc: Robin Snyders <robin@snyders.xyz>, David Heidelberg <david@ixit.cz>, 
 phone-devel@vger.kernel.org, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 linux-arm-msm@vger.kernel.org, linux-pm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Fabricio Akio <fabricioakio@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791492989; l=1791;
 i=fabricioakio@gmail.com; s=20260928; h=from:subject:message-id;
 bh=O+EdbHvwdTw5M/tHqymi+DAtgrlmZpJcZQoDpxK8xm4=;
 b=lzrFbO7ZYW/uyflmgDKxwI3wZl4APBpTUjgSm5J397NKEwrzL4kQjYeLuu46J9VqTW0F3z3bH
 6YAjHnRfeGmBA1/joWaPTJKng02GLKxuv2oW8IviBrMvplzXbyBVVwa
X-Developer-Key: i=fabricioakio@gmail.com; a=ed25519;
 pk=TlMUT8bPI/ZQzp2q24BIQTb2qSx/jdUTBlGEXIRCm54=
X-Endpoint-Received: by B4 Relay for fabricioakio@gmail.com/20260928 with auth_id=1076
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

smb_get_iio_chan() reads the charging status through
power_supply_get_property(chip->chg_psy), but chip->chg_psy is assigned
only when devm_power_supply_register() returns, and the power supply
core already calls get_property() from inside the registration, for its
uevents. If another driver has taken a reference to the supply by then,
as a fuel gauge naming the charger in power-supplies does, the core lets
the call through, and reading CURRENT_NOW or VOLTAGE_NOW dereferences
the NULL chg_psy.

Read the status from the hardware with smb_get_prop_status(), as the
STATUS property itself does.

Fixes: 8648aeb5d7b7 ("power: supply: add Qualcomm PMI8998 SMB2 Charger driver")
Signed-off-by: Fabricio Akio <fabricioakio@gmail.com>
---
 drivers/power/supply/qcom_smbx.c | 8 +++-----
 1 file changed, 3 insertions(+), 5 deletions(-)

diff --git a/drivers/power/supply/qcom_smbx.c b/drivers/power/supply/qcom_smbx.c
index 3951326f488f..6e0796730c59 100644
--- a/drivers/power/supply/qcom_smbx.c
+++ b/drivers/power/supply/qcom_smbx.c
@@ -607,12 +607,10 @@ static void smb_status_change_work(struct work_struct *work)
 static int smb_get_iio_chan(struct smb_chip *chip, struct iio_channel *chan,
 			     int *val)
 {
-	int rc;
-	union power_supply_propval status;
+	int rc, status;
 
-	rc = power_supply_get_property(chip->chg_psy, POWER_SUPPLY_PROP_STATUS,
-				       &status);
-	if (rc < 0 || status.intval != POWER_SUPPLY_STATUS_CHARGING) {
+	rc = smb_get_prop_status(chip, &status);
+	if (rc < 0 || status != POWER_SUPPLY_STATUS_CHARGING) {
 		*val = 0;
 		return 0;
 	}

---
base-commit: aac26bee2287c88af5be5a5ff96d783b19a28790
change-id: 20261008-qcom-smbx-psy-race-521568f9cfde

Best regards,
--  
Fabricio Akio <fabricioakio@gmail.com>

