From: David Heidelberg <david@ixit.cz>
Date: Sun, 15 Mar 2026 20:40:16 +0100
Subject: [PATCH] power: supply: qcom_smbx: allow disabling charging
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260315-smb2-cherry-pick-v1-1-b2710e470490@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAB8Lt2kC/x3MSQqAMAxA0atI1gZqHBZeRVzYNtogDqQgivTuF
 pdv8f8LkVU4Ql+8oHxJlGPPqMoCXJj2hVF8NpChztRVi3GzhC6w6oOnuBUb65i8p9lbhpydyrP
 c/3IYU/oAQZYYgmIAAAA=
X-Change-ID: 20260315-smb2-cherry-pick-4bce2dd2fdbe
To: Casey Connolly <casey.connolly@linaro.org>, 
 Sebastian Reichel <sre@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 David Heidelberg <david@ixit.cz>
Cc: linux-arm-msm@vger.kernel.org, linux-pm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1907; i=david@ixit.cz;
 h=from:subject:message-id; bh=4AjGJKwbJXe+JB86/acJqUuqP6FV9Wr+oAVrVaq0fiI=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBptwshPIdiXezEZzCVg9hmuCN0irJHRc9S1JKO8
 J7d6Gt30iWJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCabcLIQAKCRBgAj/E00kg
 cj0OD/wNTfuFuEMJsk5ORkTHCYwFuvW/caJm+clwHiwTJyjDjmOFg31ilRGxWEil0ZymBh9WiC2
 S1t0ydvEC9JVrHIrXC5CsJCuugFxuRDGmPlWagNhYQgHtkz65H9jFgbtCQLkc7OpN8bBcAzGn1+
 +tFiNt7MbutiIn1ZZ/WeZCm4U3k+Jbo2tvYHLZqjBsrBRJNh4mbYKK0l99r/29lQOvX7lpoGtTh
 kgW5KDEWIl0FCqodmmTI6ELsLPekaDZX+mZuFlqYkturHE3C2L6xfktdHRdN+0WbDDr4ylYA49U
 gCXHEygE6VNwPn2bsZtEJD8+/1+RUDXEjts3HGz+W2Jcr+TKHeOhI935PKZYpV70gCJpw13S7K3
 NnVlQoqpJR0lTKdNtHwDP0g9YqrOItx6mZTzL95DatWTsj+8IF1Qvc5151XNcjhvImxUjBm/6Kz
 boxeSXnVIFoT3/RinblE3YgqcYFV7E+9OwKGIdLU4Em8oc6fnEJ0EgcPxgUVizK9pxDBXQHOlRt
 7+EKR6Pvq7R0dBIrjP6Mmr2tIsdCydkbU+aAPI/kgZIYouzftHI+s+yykxqRuV2727IcosT7zl8
 bOk99aY7D8ml21Mxm4q4CbmJOpKBtglkLvCcExsTP78bL41b+mj1J3rWirAKeNxaeJZsexi3nJB
 6cKB3OZJohwWO4A==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Casey Connolly <casey.connolly@linaro.org>

Hook up USBIN_CMD_IL so that writing "0" to the status register will
disable charging, this is useful to let users limit charging
automatically.

Signed-off-by: Casey Connolly <casey.connolly@linaro.org>
Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
[David]
 - adapted from:
 https://lore.kernel.org/all/20250619-smb2-smb5-support-v1-5-ac5dec51b6e1@linaro.org/
 - moved USBIN defines into the right place inside this patch
---
 drivers/power/supply/qcom_smbx.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/drivers/power/supply/qcom_smbx.c b/drivers/power/supply/qcom_smbx.c
index b1cb925581ec6..bf2e2ccc454a6 100644
--- a/drivers/power/supply/qcom_smbx.c
+++ b/drivers/power/supply/qcom_smbx.c
@@ -134,6 +134,9 @@
 #define OCP_CHARGER_BIT					BIT(1)
 #define SDP_CHARGER_BIT					BIT(0)
 
+#define USBIN_CMD_IL					0x340
+#define USBIN_SUSPEND_BIT				BIT(0)
+
 #define TYPE_C_STATUS_1					0x30B
 #define UFP_TYPEC_MASK					GENMASK(7, 5)
 #define UFP_TYPEC_RDSTD_BIT				BIT(7)
@@ -693,6 +696,9 @@ static int smb_set_property(struct power_supply *psy,
 	struct smb_chip *chip = power_supply_get_drvdata(psy);
 
 	switch (psp) {
+	case POWER_SUPPLY_PROP_STATUS:
+		return regmap_update_bits(chip->regmap, chip->base + USBIN_CMD_IL,
+					  USBIN_SUSPEND_BIT, !val->intval);
 	case POWER_SUPPLY_PROP_CURRENT_MAX:
 		return smb_set_current_limit(chip, val->intval);
 	default:
@@ -705,6 +711,7 @@ static int smb_property_is_writable(struct power_supply *psy,
 				     enum power_supply_property psp)
 {
 	switch (psp) {
+	case POWER_SUPPLY_PROP_STATUS:
 	case POWER_SUPPLY_PROP_CURRENT_MAX:
 		return 1;
 	default:

---
base-commit: b84a0ebe421ca56995ff78b66307667b62b3a900
change-id: 20260315-smb2-cherry-pick-4bce2dd2fdbe

Best regards,
-- 
David Heidelberg <david@ixit.cz>

