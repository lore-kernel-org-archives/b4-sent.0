From: Vincent Jardin <vjardin@free.fr>
Date: Thu, 01 Oct 2026 23:47:39 +0200
Subject: [PATCH v3 1/2] hwmon: (pmbus/core) Register the thermal sensors
 with a 0-based index
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261001-for-upstream-dt-mpq8785-thermal-sensor-cells-v3-1-bfafba9fcc95@free.fr>
References: <20261001-for-upstream-dt-mpq8785-thermal-sensor-cells-v3-0-bfafba9fcc95@free.fr>
In-Reply-To: <20261001-for-upstream-dt-mpq8785-thermal-sensor-cells-v3-0-bfafba9fcc95@free.fr>
To: Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Charles Hsu <ythsu0511@gmail.com>, 
 Eduardo Valentin <eduval@amazon.com>
Cc: linux-hwmon@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Vincent Jardin <vjardin@free.fr>, 
 stable+noautosel@kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790891264; l=1633;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=mG65M6EasOH/v1ceIH1BpodMnyEQw2kyvmfq+6YKBMg=;
 b=hWMOs2Oc1wBtE35LiijSma8llAZhS0oY2npML0aD8qw/ZS6RHruuUhciyRvn8WsGEt44R9xYB
 lT9gu/eHu6yAJuh9TyCVf3Bcwwh8bYZj/WQLeTao1QrjXZRVsdDCNJB
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit
  3aa74796cfd0 ("hwmon: (pmbus) Register with thermal for PSC_TEMPERATURE")
pmbus_core registers each temperature input with the thermal core using
its hwmon index as the sensor id. That index starts at 1, so temp1 is
registered as sensor 1.

The thermal core expects a 0-based id, which is what the hwmon core
passes for the drivers that set HWMON_C_REGISTER_TZ:
thermal_of matches a thermal-sensors phandle without cells as id 0, so a
PMBus device with a single temperature input cannot
use #thermal-sensor-cells = <0>.

Cc: stable+noautosel@kernel.org # changes the DT-visible sensor id, no in-tree user
Fixes: 3aa74796cfd0 ("hwmon: (pmbus) Register with thermal for PSC_TEMPERATURE")
Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
 drivers/hwmon/pmbus/pmbus_core.c | 7 ++++++-
 1 file changed, 6 insertions(+), 1 deletion(-)

diff --git a/drivers/hwmon/pmbus/pmbus_core.c b/drivers/hwmon/pmbus/pmbus_core.c
index d69f1bde1795..af13408c62f9 100644
--- a/drivers/hwmon/pmbus/pmbus_core.c
+++ b/drivers/hwmon/pmbus/pmbus_core.c
@@ -1524,7 +1524,12 @@ static int pmbus_thermal_add_sensor(struct pmbus_data *pmbus_data,
 	tdata->sensor = sensor;
 	tdata->pmbus_data = pmbus_data;
 
-	tzd = devm_thermal_of_zone_register(dev, index, tdata,
+	/*
+	 * The PMBus core numbers its temperature sensors from 1, as the
+	 * hwmon tempN attributes, while the thermal core expects a 0-based
+	 * sensor index.
+	 */
+	tzd = devm_thermal_of_zone_register(dev, index - 1, tdata,
 					    &pmbus_thermal_ops);
 	/*
 	 * If CONFIG_THERMAL_OF is disabled, this returns -ENODEV,

-- 
2.43.0

