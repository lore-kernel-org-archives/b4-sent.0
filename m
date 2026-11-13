From: Ziqiang Xia <xiazq123666@gmail.com>
Date: Fri, 13 Nov 2026 10:01:30 -0800
Subject: [PATCH RFC 1/2] Documentation: ABI: testing: Add emdoor-intel-wmi
 sysfs ABI
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-emdoor-intel-wmi-rfc-v1-1-d77ecf23693b@gmail.com>
References: <20261113-emdoor-intel-wmi-rfc-v1-0-d77ecf23693b@gmail.com>
In-Reply-To: <20261113-emdoor-intel-wmi-rfc-v1-0-d77ecf23693b@gmail.com>
To: Armin Wolf <W_Armin@gmx.de>, Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Guenter Roeck <linux@roeck-us.net>
Cc: platform-driver-x86@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-hwmon@vger.kernel.org, Ziqiang Xia <xiazq123666@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794592890; l=2451;
 i=xiazq123666@gmail.com; s=20261113; h=from:subject:message-id;
 bh=JHu1JfOu+vTVqHRdgjqMlj3/Yz1nLajuOsJbpAPgyKc=;
 b=Mo0Xf4pqFde80uUR9hBzy/qvLAl6CZ370bTKfZ4CZRrZ6ZchimFTmH7ZL2zQ0a2pUkoqC2iCX
 2llfC+aJZfEChggdkmL2qQ42MDDAFTnyT9eUUHKUq/PE4ggyefRxTsP
X-Developer-Key: i=xiazq123666@gmail.com; a=ed25519;
 pk=mrJQOUoyemvqamFAwqXZF59Z8eZnI11ZI+BEtDNxq7Q=
X-Endpoint-Received: by B4 Relay for xiazq123666@gmail.com/20261113 with auth_id=1513
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the fn_lock, win_lock, touchpad_enabled, and auto_power_on
sysfs attributes exposed by the Emdoor Intel EWMI platform driver.

Signed-off-by: Ziqiang Xia <xiazq123666@gmail.com>
---
 .../ABI/testing/sysfs-bus-wmi-devices-emdoor-ewmi  | 28 ++++++++++++++++++++++
 MAINTAINERS                                        |  6 +++++
 2 files changed, 34 insertions(+)

diff --git a/Documentation/ABI/testing/sysfs-bus-wmi-devices-emdoor-ewmi b/Documentation/ABI/testing/sysfs-bus-wmi-devices-emdoor-ewmi
new file mode 100644
index 000000000..e139d2929
--- /dev/null
+++ b/Documentation/ABI/testing/sysfs-bus-wmi-devices-emdoor-ewmi
@@ -0,0 +1,28 @@
+What:		/sys/bus/wmi/devices/0B30FD67-1B62-4FCA-B10B-50DC7ADE6A39-*/fn_lock
+What:		/sys/bus/wmi/devices/0B30FD67-1B62-4FCA-B10B-50DC7ADE6A39-*/win_lock
+Date:		November 2026
+KernelVersion:	7.4
+Contact:	platform-driver-x86@vger.kernel.org
+Description:
+		(RW) Current Fn-lock or Windows-key-lock state ("0" or "1")
+		queried via GFLS (0x03/0x03) / GWLS (0x03/0x01) and updated
+		via SFLS (0x03/0x04) / SWLS (0x03/0x02) followed by settling
+		delay and readback verification.
+
+What:		/sys/bus/wmi/devices/0B30FD67-1B62-4FCA-B10B-50DC7ADE6A39-*/touchpad_enabled
+Date:		November 2026
+KernelVersion:	7.4
+Contact:	platform-driver-x86@vger.kernel.org
+Description:
+		(RO) Firmware touchpad enable state ("0" or "1") queried via
+		GTPS (0x03/0x07).
+
+What:		/sys/bus/wmi/devices/C75665A3-4382-4646-ADC8-C81AE146E455-*/auto_power_on
+Date:		November 2026
+KernelVersion:	7.4
+Contact:	platform-driver-x86@vger.kernel.org
+Description:
+		(RW) AC power-on recovery setting ("0" or "1"), backed by
+		board EC register 0xF5 (0x00=off, 0xa0=on) and updated
+		through standard WMI method WMCC followed by settling delay
+		and EC readback verification.
diff --git a/MAINTAINERS b/MAINTAINERS
index 981eb3fdb..70c976ffe 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -9848,6 +9848,12 @@ T:	git git://linuxtv.org/media.git
 F:	Documentation/admin-guide/media/em28xx*
 F:	drivers/media/usb/em28xx/
 
+EMDOOR INTEL EWMI DRIVER
+M:	Ziqiang Xia <xiazq123666@gmail.com>
+L:	platform-driver-x86@vger.kernel.org
+S:	Maintained
+F:	Documentation/ABI/testing/sysfs-bus-wmi-devices-emdoor-ewmi
+
 EMMC CMDQ HOST CONTROLLER INTERFACE (CQHCI) DRIVER
 M:	Adrian Hunter <adrian.hunter@intel.com>
 M:	Asutosh Das <quic_asutoshd@quicinc.com>

-- 
2.56.1

