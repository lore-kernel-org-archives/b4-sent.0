From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Date: Mon, 22 Jun 2026 22:55:37 -0700
Subject: [PATCH 1/3] Documentation/hwmon: Add onsemi's FD5121 controllers'
 documentation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260622-support-fd5121-from-onsemi-v1-1-b31767689c65@onsemi.com>
References: <20260622-support-fd5121-from-onsemi-v1-0-b31767689c65@onsemi.com>
In-Reply-To: <20260622-support-fd5121-from-onsemi-v1-0-b31767689c65@onsemi.com>
To: Guenter Roeck <linux@roeck-us.net>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Selva Rajagopal <selvamani.rajagopal@onsemi.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-hwmon@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782194144; l=3746;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=l3mddVpwX89BP8nbkB8koBCUlnFqhcKDoQv/wT6r2qM=;
 b=4IHLg7/aahxiwHgxdxx33rxojvmOEHcIidSdvprGZyj6g/yGiRL04lvxBZPFdQ3N+pHb008q9
 MxBWcQ8MKIiDY3iZat6aLT8loKuCcoV1mno5nQFGTAmXwkzVrHrOwlG
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the hardware monitoring support for the FD5121, FD5123, and
FD5125 devices.

Documentation describes the supported telemetry data exposed via
the sysfs for the hwmon subsystem, including voltage, current,
power and temperature measurements.

Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
---
 Documentation/hwmon/fd5121.rst | 93 ++++++++++++++++++++++++++++++++++++++++++
 Documentation/hwmon/index.rst  |  1 +
 2 files changed, 94 insertions(+)

diff --git a/Documentation/hwmon/fd5121.rst b/Documentation/hwmon/fd5121.rst
new file mode 100644
index 000000000000..c279db4641e4
--- /dev/null
+++ b/Documentation/hwmon/fd5121.rst
@@ -0,0 +1,93 @@
+.. SPDX-License-Identifier: GPL-2.0-only
+
+Kernel driver fd5121
+=====================
+
+Supported chips:
+
+  * onsemi FD5121
+
+    Prefix: 'fd5121'
+
+    Datasheet: Datasheet is not publicly available.
+
+  * onsemi FD5123
+
+    Prefix: 'fd5121'
+
+    Datasheet: Datasheet is not publicly available.
+
+  * onsemi FD5125
+
+    Prefix: 'fd5121'
+
+    Datasheet: Datasheet is not publicly available.
+
+Author: Selva Rajagopal <selvamani.rajagopal@onsemi.com>
+
+Description
+-----------
+
+FD5121, FD5123, FD5125 are dual-rail, multi-phase controllers
+and compliant to
+
+  - AVS and AMD proprietary SVI3 protocol.
+  - PMBus rev 1.4.1 interface.
+
+Used as multi-phase voltage regulators for CPUs, high performance
+ASICs, SoCs or graphic cores.
+
+Gives full telemetry options including input/output voltage
+and current, as well as fault handling and identifications.
+
+Usage Notes
+-----------
+
+This driver does not probe for PMBus devices. You will have
+to instantiate devices explicitly.
+
+Example: the following commands will load the driver for the
+controller at address 0x50 on I2C bus #1::
+
+    # modprobe fd5121
+    # echo fd5121 0x50 > /sys/bus/i2c/devices/i2c-1/new_device
+
+It can also be instantiated by declaring in device tree
+
+Sysfs attributes
+----------------
+
+The following attributes are supported:
+
+======================  ====================================
+curr[1-2]_label		"iin[1-2]"
+curr[3-4]_label		"iout[1-2]"
+curr[1-2]_input		Measured input current.
+curr[3-4]_input		Measured output current.
+curr[1-4]_crit_alarm	Output current critical high alarm.
+curr[1-4]_max_alarm	Output current high alarm.
+
+in[1-2]_label		"vin[1-2]"
+in[3-4]_label		"vout[1-2]"
+in[1-4]_lcrit_alarm	Input voltage critical low alarm.
+in[1-4]_crit_alarm	Input voltage critical high alarm.
+in[1-2]_max_alarm	Input voltage high alarm.
+in[1-2]_input           Measured input voltage.
+in[3-4]_input           Measured output voltage.
+
+power[1-2]_label	"pin[1-2]"
+power[3-4]_label	"pout[1-2]"
+power[3-4]_crit_alarm	Output power critical high alarm.
+power[1-2]_max_alarm	Output power high alarm.
+power[1-4]_max          Power limit.
+power[1-4]_input        Measured input power.
+power[3-4]_crit         Critical maximum output power.
+
+temp[1-2]_crit_alarm	Chip temperature critical high alarm.
+temp[1-2]_max_alarm	Chip temperature high alarm.
+temp[1-2]_input         Measured temperature.
+temp[1-2]_max           Maximum temperature.
+temp[1-2]_crit          Critical high temperature.
+
+======================  ====================================
+
diff --git a/Documentation/hwmon/index.rst b/Documentation/hwmon/index.rst
index 4aa910569c31..451f5433fa60 100644
--- a/Documentation/hwmon/index.rst
+++ b/Documentation/hwmon/index.rst
@@ -79,6 +79,7 @@ Hardware Monitoring Kernel Drivers
    f71805f
    f71882fg
    fam15h_power
+   fd5121
    fsp-3y
    ftsteutates
    g760a

-- 
2.43.0

