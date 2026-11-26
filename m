From: Ziqiang Xia <xiazq123666@gmail.com>
Date: Thu, 26 Nov 2026 00:21:18 -0800
Subject: [PATCH v3 1/2] Documentation: ABI: testing: Add emdoor-intel-wmi
 sysfs ABI
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-emdoor-intel-wmi-rfc-v3-1-7dfbb70f04a9@gmail.com>
References: <20261126-emdoor-intel-wmi-rfc-v3-0-7dfbb70f04a9@gmail.com>
In-Reply-To: <20261126-emdoor-intel-wmi-rfc-v3-0-7dfbb70f04a9@gmail.com>
To: Armin Wolf <W_Armin@gmx.de>, Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Guenter Roeck <linux@roeck-us.net>
Cc: platform-driver-x86@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-hwmon@vger.kernel.org, Ziqiang Xia <xiazq123666@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795681277; l=1523;
 i=xiazq123666@gmail.com; s=20261113; h=from:subject:message-id;
 bh=YPi53SRn/Zh9Q5N54bVHsdt2ZfThIXfpmrAzoI0vBJY=;
 b=C/j2PX+YZMe0uKjwAg0oKJnbrWGLRUGBOYU8aXASycCm1WyE77qxwuIXgAnPhnFSaGC521sSf
 nodJ7nUwcq2CnYnVQBnrnno04ovyUAYxKfXbY72GGk8F/srKpH5UaZu
X-Developer-Key: i=xiazq123666@gmail.com; a=ed25519;
 pk=mrJQOUoyemvqamFAwqXZF59Z8eZnI11ZI+BEtDNxq7Q=
X-Endpoint-Received: by B4 Relay for xiazq123666@gmail.com/20261113 with auth_id=1513
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the read-only touchpad_enabled sysfs attribute exposed by
the Emdoor Intel EWMI platform driver.

Signed-off-by: Ziqiang Xia <xiazq123666@gmail.com>
---
 Documentation/ABI/testing/sysfs-bus-wmi-devices-emdoor-ewmi | 7 +++++++
 MAINTAINERS                                                 | 6 ++++++
 2 files changed, 13 insertions(+)

diff --git a/Documentation/ABI/testing/sysfs-bus-wmi-devices-emdoor-ewmi b/Documentation/ABI/testing/sysfs-bus-wmi-devices-emdoor-ewmi
new file mode 100644
index 000000000..9dd1c6d6c
--- /dev/null
+++ b/Documentation/ABI/testing/sysfs-bus-wmi-devices-emdoor-ewmi
@@ -0,0 +1,7 @@
+What:		/sys/bus/wmi/devices/0B30FD67-1B62-4FCA-B10B-50DC7ADE6A39-*/touchpad_enabled
+Date:		November 2026
+KernelVersion:	7.5
+Contact:	platform-driver-x86@vger.kernel.org
+Description:
+		(RO) Firmware touchpad enable state ("0" or "1") queried via
+		WMCD GTPS (0x03/0x07).
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

