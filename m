From: Fenglin Wu <fenglin.wu@oss.qualcomm.com>
Date: Tue, 26 Aug 2025 15:18:29 +0800
Subject: [PATCH v3 2/8] power: supply: core: Add state_of_health power
 supply property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250826-qcom_battmgr_update-v3-2-74ea410ef146@oss.qualcomm.com>
References: <20250826-qcom_battmgr_update-v3-0-74ea410ef146@oss.qualcomm.com>
In-Reply-To: <20250826-qcom_battmgr_update-v3-0-74ea410ef146@oss.qualcomm.com>
To: Sebastian Reichel <sre@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Cc: Subbaraman Narayanamurthy <subbaraman.narayanamurthy@oss.qualcomm.com>, 
 David Collins <david.collins@oss.qualcomm.com>, 
 =?utf-8?q?Gy=C3=B6rgy_Kurucz?= <me@kuruczgy.com>, linux-pm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 kernel@oss.qualcomm.com, devicetree@vger.kernel.org, 
 linux-usb@vger.kernel.org, Fenglin Wu <fenglin.wu@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756192715; l=2652;
 i=fenglin.wu@oss.qualcomm.com; s=20240327; h=from:subject:message-id;
 bh=RoS25nFVJl76zUEzPkYpvp8qPvjRe2//mJxGa0TPgJY=;
 b=8H/7E8QTWCiSp8Hx6ijyJyMdV7f51F5qEFZ6Z2gxHT2EptXAGs9AyJ1FltUjeUvIuNL0J+C28
 /3V1Y00ona5CYcRS5aWR+91NmIljna7PovTftznmQt+KjboJvIJnSCK
X-Developer-Key: i=fenglin.wu@oss.qualcomm.com; a=ed25519;
 pk=BF8SA4IVDk8/EBCwlBehKtn2hp6kipuuAuDAHh9s+K4=
X-Endpoint-Received: by B4 Relay for fenglin.wu@oss.qualcomm.com/20240327 with auth_id=406
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add state_of_health power supply property to represent battery
health percentage.

Signed-off-by: Fenglin Wu <fenglin.wu@oss.qualcomm.com>
---
 Documentation/ABI/testing/sysfs-class-power | 15 +++++++++++++++
 drivers/power/supply/power_supply_sysfs.c   |  1 +
 include/linux/power_supply.h                |  1 +
 3 files changed, 17 insertions(+)

diff --git a/Documentation/ABI/testing/sysfs-class-power b/Documentation/ABI/testing/sysfs-class-power
index cea1a38f5a8fb754d4e6323967ef6cf2e20a68ce..04f82e3e33aad6e16dc4fbace066b5d26069bf44 100644
--- a/Documentation/ABI/testing/sysfs-class-power
+++ b/Documentation/ABI/testing/sysfs-class-power
@@ -568,6 +568,21 @@ Description:
 
 		Valid values: Represented in microohms
 
+What:		/sys/class/power_supply/<supply_name>/state_of_health
+Date:		August 2025
+Contact:	linux-arm-msm@vger.kernel.org
+Description:
+		The state_of_health parameter quantifies the overall condition
+		of a battery as a percentage, reflecting its ability to deliver
+		rated performance relative to its original specifications. It is
+		dynamically computed using a combination of learned capacity
+		and impedance-based degradation indicators, both of which evolve
+		over the battery's lifecycle.
+
+		Access: Read
+
+		Valid values: 0 - 100 (percent)
+
 **USB Properties**
 
 What:		/sys/class/power_supply/<supply_name>/input_current_limit
diff --git a/drivers/power/supply/power_supply_sysfs.c b/drivers/power/supply/power_supply_sysfs.c
index cfa8f90a88ebc8fc1c7447198f138e5d2e699e5a..d96a8578308e3af60cc1a352845662aa922c29b3 100644
--- a/drivers/power/supply/power_supply_sysfs.c
+++ b/drivers/power/supply/power_supply_sysfs.c
@@ -221,6 +221,7 @@ static struct power_supply_attr power_supply_attrs[] __ro_after_init = {
 	POWER_SUPPLY_ATTR(MANUFACTURE_MONTH),
 	POWER_SUPPLY_ATTR(MANUFACTURE_DAY),
 	POWER_SUPPLY_ATTR(INTERNAL_RESISTANCE),
+	POWER_SUPPLY_ATTR(STATE_OF_HEALTH),
 	/* Properties of type `const char *' */
 	POWER_SUPPLY_ATTR(MODEL_NAME),
 	POWER_SUPPLY_ATTR(MANUFACTURER),
diff --git a/include/linux/power_supply.h b/include/linux/power_supply.h
index 8bc3b7a67eb5693a16db9b7d123e7881711c6bf4..ccb43fe44381965069dc3bd9505d45050b9b1bd8 100644
--- a/include/linux/power_supply.h
+++ b/include/linux/power_supply.h
@@ -175,6 +175,7 @@ enum power_supply_property {
 	POWER_SUPPLY_PROP_MANUFACTURE_MONTH,
 	POWER_SUPPLY_PROP_MANUFACTURE_DAY,
 	POWER_SUPPLY_PROP_INTERNAL_RESISTANCE,
+	POWER_SUPPLY_PROP_STATE_OF_HEALTH,
 	/* Properties of type `const char *' */
 	POWER_SUPPLY_PROP_MODEL_NAME,
 	POWER_SUPPLY_PROP_MANUFACTURER,

-- 
2.34.1

