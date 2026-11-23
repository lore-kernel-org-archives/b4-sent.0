From: Ziqiang Xia <xiazq123666@gmail.com>
Date: Mon, 23 Nov 2026 05:56:51 -0800
Subject: [PATCH v2 1/2] Documentation: ABI: testing: Add emdoor-intel-wmi
 sysfs ABI
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-emdoor-intel-wmi-rfc-v2-1-3f4a03095f2e@gmail.com>
References: <20261123-emdoor-intel-wmi-rfc-v2-0-3f4a03095f2e@gmail.com>
In-Reply-To: <20261123-emdoor-intel-wmi-rfc-v2-0-3f4a03095f2e@gmail.com>
To: Armin Wolf <W_Armin@gmx.de>, Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Guenter Roeck <linux@roeck-us.net>
Cc: platform-driver-x86@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-hwmon@vger.kernel.org, Ziqiang Xia <xiazq123666@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795442211; l=1523;
 i=xiazq123666@gmail.com; s=20261113; h=from:subject:message-id;
 bh=DS8F/t2qcz85jbuQ4iMIKORFvJuKOvOLneJQvWGmXpQ=;
 b=HKTLUecXHruX5UPIKDfQrtx04XgE61GQFo0cmv8GbF1HWu/ma+pF6gbNQQBOfRm6OEMuuRjX0
 wpFRhUJX44tAc/eKNgOHcww+gp7izaMq9rzZX5H+Qnq9WTNitlx3qnJ
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
index 000000000..6cf85db62
--- /dev/null
+++ b/Documentation/ABI/testing/sysfs-bus-wmi-devices-emdoor-ewmi
@@ -0,0 +1,7 @@
+What:		/sys/bus/wmi/devices/0B30FD67-1B62-4FCA-B10B-50DC7ADE6A39-*/touchpad_enabled
+Date:		November 2026
+KernelVersion:	7.4
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

