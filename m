From: Fenglin Wu <fenglin.wu@oss.qualcomm.com>
Date: Fri, 23 May 2025 09:39:18 +0800
Subject: [PATCH 1/5] power: supply: core: add resistance power supply
 property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250523-qcom_battmgr_update-v1-1-2bb6d4e0a56e@oss.qualcomm.com>
References: <20250523-qcom_battmgr_update-v1-0-2bb6d4e0a56e@oss.qualcomm.com>
In-Reply-To: <20250523-qcom_battmgr_update-v1-0-2bb6d4e0a56e@oss.qualcomm.com>
To: Sebastian Reichel <sre@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>
Cc: Subbaraman Narayanamurthy <subbaraman.narayanamurthy@oss.qualcomm.com>, 
 David Collins <david.collins@oss.qualcomm.com>, linux-pm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 kernel@oss.qualcomm.com, Fenglin Wu <fenglin.wu@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747964381; l=2414;
 i=fenglin.wu@oss.qualcomm.com; s=20240327; h=from:subject:message-id;
 bh=f6uhUoiZgOE/CV2wIB6Vwbi/lg0mxjoGmX0Qx7uMFHM=;
 b=HavpWuoflKPkvLhIXTCTWteE3MCnA7mz0fzb82RXZsFgESETNfNw2ByeyNax8y4mAlig1LSfN
 YnWlxV4c8TTDjW73aheEdDmchvfPruEN+IFVlXXbax9vPMrKgKR63G/
X-Developer-Key: i=fenglin.wu@oss.qualcomm.com; a=ed25519;
 pk=BF8SA4IVDk8/EBCwlBehKtn2hp6kipuuAuDAHh9s+K4=
X-Endpoint-Received: by B4 Relay for fenglin.wu@oss.qualcomm.com/20240327 with auth_id=406
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some battery drivers provide the ability to export resistance as a
parameter. Add resistance power supply property for that purpose.

Signed-off-by: Fenglin Wu <fenglin.wu@oss.qualcomm.com>
---
 Documentation/ABI/testing/sysfs-class-power | 10 ++++++++++
 drivers/power/supply/power_supply_sysfs.c   |  1 +
 include/linux/power_supply.h                |  1 +
 3 files changed, 12 insertions(+)

diff --git a/Documentation/ABI/testing/sysfs-class-power b/Documentation/ABI/testing/sysfs-class-power
index 560124cc31770cde03bcdbbba0d85a5bd78b15a0..22a565a6a1c509461b8c483e12975295765121d6 100644
--- a/Documentation/ABI/testing/sysfs-class-power
+++ b/Documentation/ABI/testing/sysfs-class-power
@@ -552,6 +552,16 @@ Description:
 			Integer > 0: representing full cycles
 			Integer = 0: cycle_count info is not available
 
+What:		/sys/class/power_supply/<supply_name>/resistance
+Date:		May 2025
+Contact:	linux-arm-msm@vger.kernel.org
+Description:
+		Reports the resistance of the battery power supply.
+
+		Access: Read
+
+		Valid values: Represented in microohms
+
 **USB Properties**
 
 What:		/sys/class/power_supply/<supply_name>/input_current_limit
diff --git a/drivers/power/supply/power_supply_sysfs.c b/drivers/power/supply/power_supply_sysfs.c
index a438f7983d4f6a832e9d479184c7c35453e1757c..dd829148eb6fda5dcd7eab53fc70f99081763714 100644
--- a/drivers/power/supply/power_supply_sysfs.c
+++ b/drivers/power/supply/power_supply_sysfs.c
@@ -220,6 +220,7 @@ static struct power_supply_attr power_supply_attrs[] __ro_after_init = {
 	POWER_SUPPLY_ATTR(MANUFACTURE_YEAR),
 	POWER_SUPPLY_ATTR(MANUFACTURE_MONTH),
 	POWER_SUPPLY_ATTR(MANUFACTURE_DAY),
+	POWER_SUPPLY_ATTR(RESISTANCE),
 	/* Properties of type `const char *' */
 	POWER_SUPPLY_ATTR(MODEL_NAME),
 	POWER_SUPPLY_ATTR(MANUFACTURER),
diff --git a/include/linux/power_supply.h b/include/linux/power_supply.h
index c4cb854971f53a244ba7742a15ce7a5515da6199..de3e88810e322546470b21258913abc7707c86a7 100644
--- a/include/linux/power_supply.h
+++ b/include/linux/power_supply.h
@@ -174,6 +174,7 @@ enum power_supply_property {
 	POWER_SUPPLY_PROP_MANUFACTURE_YEAR,
 	POWER_SUPPLY_PROP_MANUFACTURE_MONTH,
 	POWER_SUPPLY_PROP_MANUFACTURE_DAY,
+	POWER_SUPPLY_PROP_RESISTANCE,
 	/* Properties of type `const char *' */
 	POWER_SUPPLY_PROP_MODEL_NAME,
 	POWER_SUPPLY_PROP_MANUFACTURER,

-- 
2.34.1

