From: Ferdinand Schwenk <ferdinand.schwenk@advastore.com>
Date: Mon, 08 Jun 2026 15:03:55 +0200
Subject: [PATCH v2 2/3] hwmon: Add update_interval_us chip attribute
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260608-hwmon-ina238-update-interval-us-v2-v2-2-2d939fbb2ea1@advastore.com>
References: <20260608-hwmon-ina238-update-interval-us-v2-v2-0-2d939fbb2ea1@advastore.com>
In-Reply-To: <20260608-hwmon-ina238-update-interval-us-v2-v2-0-2d939fbb2ea1@advastore.com>
To: Guenter Roeck <linux@roeck-us.net>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>
Cc: linux-hwmon@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-doc@vger.kernel.org, richard.leitner@linux.dev, 
 ferdinand.schwenk@advastore.com
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780923870; l=3761;
 i=ferdinand.schwenk@advastore.com; h=from:subject:message-id;
 bh=ELOnjfl7Dn3Giu687ra69+/+CdOra2o1Nm0Uowf4NgA=;
 b=DWmKn7iigDqsaqFGdT15Qyzg8ASYqenNdUqsJphTmIWTlVq41CDJF3aYq86BmIVIEvoJOkfAP
 hy2YyOuvUQOD76sfnpjhRToLtDmDOHOkZPaE+aT04m1f9RDa+dcCbww
X-Developer-Key: i=ferdinand.schwenk@advastore.com; a=ed25519;
 pk=HyA9NdHJ7NystP+1SyuWJeyXNH2EO4A09FXli9mfs9Q=
X-Endpoint-Received: by B4 Relay for ferdinand.schwenk@advastore.com/default with auth_id=788
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some hardware monitoring chips support update intervals below one
millisecond. The existing update_interval attribute uses millisecond
granularity, which causes sub-millisecond steps to round to the same
value and become inaccessible from userspace.

Introduce update_interval_us, a companion chip-level attribute that
expresses the same update interval in microseconds. Drivers
implementing this attribute should also implement update_interval for
compatibility with millisecond-based userspace interfaces.
---
 Documentation/ABI/testing/sysfs-class-hwmon | 14 ++++++++++++++
 Documentation/hwmon/sysfs-interface.rst     |  4 ++++
 drivers/hwmon/hwmon.c                       |  1 +
 include/linux/hwmon.h                       |  2 ++
 4 files changed, 21 insertions(+)

diff --git a/Documentation/ABI/testing/sysfs-class-hwmon b/Documentation/ABI/testing/sysfs-class-hwmon
index cfd0d0bab483..b185bdfc7186 100644
--- a/Documentation/ABI/testing/sysfs-class-hwmon
+++ b/Documentation/ABI/testing/sysfs-class-hwmon
@@ -27,6 +27,20 @@ Description:
 		Some devices have a variable update rate or interval.
 		This attribute can be used to change it to the desired value.
 
+What:		/sys/class/hwmon/hwmonX/update_interval_us
+Description:
+		The interval at which the chip will update readings,
+		expressed in microseconds.
+		Unit: microsecond
+
+		RW
+
+		Some devices have a variable update rate or interval and
+		require finer-than-millisecond control.
+		This attribute can be used to change it to the desired value.
+		Drivers implementing this attribute should also implement
+		update_interval for millisecond-based userspace interfaces.
+
 What:		/sys/class/hwmon/hwmonX/inY_min
 Description:
 		Voltage min value.
diff --git a/Documentation/hwmon/sysfs-interface.rst b/Documentation/hwmon/sysfs-interface.rst
index f76e9f8cc1ad..94e1bbce172a 100644
--- a/Documentation/hwmon/sysfs-interface.rst
+++ b/Documentation/hwmon/sysfs-interface.rst
@@ -106,6 +106,10 @@ Global attributes
 `update_interval`
 		The interval at which the chip will update readings.
 
+`update_interval_us`
+		The interval at which the chip will update readings,
+		expressed in microseconds for finer resolution.
+
 
 ********
 Voltages
diff --git a/drivers/hwmon/hwmon.c b/drivers/hwmon/hwmon.c
index 9695dca62a7e..c481bb535e35 100644
--- a/drivers/hwmon/hwmon.c
+++ b/drivers/hwmon/hwmon.c
@@ -572,6 +572,7 @@ static const char * const hwmon_chip_attrs[] = {
 	[hwmon_chip_curr_reset_history] = "curr_reset_history",
 	[hwmon_chip_power_reset_history] = "power_reset_history",
 	[hwmon_chip_update_interval] = "update_interval",
+	[hwmon_chip_update_interval_us] = "update_interval_us",
 	[hwmon_chip_alarms] = "alarms",
 	[hwmon_chip_samples] = "samples",
 	[hwmon_chip_curr_samples] = "curr_samples",
diff --git a/include/linux/hwmon.h b/include/linux/hwmon.h
index 301a83afbd66..5a5882fee299 100644
--- a/include/linux/hwmon.h
+++ b/include/linux/hwmon.h
@@ -39,6 +39,7 @@ enum hwmon_chip_attributes {
 	hwmon_chip_power_reset_history,
 	hwmon_chip_register_tz,
 	hwmon_chip_update_interval,
+	hwmon_chip_update_interval_us,
 	hwmon_chip_alarms,
 	hwmon_chip_samples,
 	hwmon_chip_curr_samples,
@@ -55,6 +56,7 @@ enum hwmon_chip_attributes {
 #define HWMON_C_POWER_RESET_HISTORY	BIT(hwmon_chip_power_reset_history)
 #define HWMON_C_REGISTER_TZ		BIT(hwmon_chip_register_tz)
 #define HWMON_C_UPDATE_INTERVAL		BIT(hwmon_chip_update_interval)
+#define HWMON_C_UPDATE_INTERVAL_US	BIT(hwmon_chip_update_interval_us)
 #define HWMON_C_ALARMS			BIT(hwmon_chip_alarms)
 #define HWMON_C_SAMPLES			BIT(hwmon_chip_samples)
 #define HWMON_C_CURR_SAMPLES		BIT(hwmon_chip_curr_samples)

-- 
2.54.0

