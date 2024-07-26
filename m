From: Cryolitia PukNgae <Cryolitia@gmail.com>
Date: Fri, 26 Jul 2024 09:21:14 +0800
Subject: [PATCH] hwmon: document: fix typo in oxp-sensors
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240726-typo-v1-1-3ca3f07f93e9@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAn6omYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDcyMz3ZLKgnxdM0OzpCTzlCSDNDMLJaDSgqLUtMwKsDHRsbW1ADphpSF
 WAAAA
To: Jean Delvare <jdelvare@suse.com>, Guenter Roeck <linux@roeck-us.net>, 
 Jonathan Corbet <corbet@lwn.net>
Cc: linux-hwmon@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, trivial@kernel.org, 
 Cryolitia PukNgae <Cryolitia@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=819; i=Cryolitia@gmail.com;
 h=from:subject:message-id; bh=RoowNEKAO63y2ZFmj969A6C2D0ZaS9bvHWQpvSGXH5I=;
 b=LS0tLS1CRUdJTiBQR1AgTUVTU0FHRS0tLS0tCgpvd0VCYlFHUy9wQU5Bd0FJQVQ1ZEYzTDhpb
 zdkQWNzbVlnQm1vdm9MQ1hCbk5xMU9hRFU5c3pTVlNaWGhFbmFBCkdiN3l5aXRkdkpHbVJhRkJ4
 eWVKQVRNRUFBRUlBQjBXSVFSME5XMHB5dmR3U0JGOENDWStYUmR5L0lxTzNRVUMKWnFMNkN3QUt
 DUkErWFJkeS9JcU8zU2puQi8wUlZHUElLSXd2bWZpUzJzblBHWmp1NFFyMmQrUmhDZnZ6R1ppZg
 pJbzNPS2RWZlI2M2JmQlNlVGU1SG9KR2NweDhaWlRNb3JTT1NWU2NuWXdzbkNlcy85bVhmRFNhQ
 mlWMXFVMy9hCml4TG5Tc3loaEpKL0dXUWxKZU9iOUZHNlFtd3AreU04OFRrR0JVZ1FsRlFiVjlF
 cWh3bTVubFFBckxRaUFoZTEKM2RRWjlqRnIrcW5LbnY2Nm8vcURSUjByNHVraThmR01CQnNadVZ
 NS09mMmNvVk5WaW5FZE1LR3ZuWWdtaHk1QQp3OE0rWkM4bjZLVjMrSkRFL0JERm4xbFk5L1U0Sn
 gxMFV5c1RXa1BIK3JQTWhjN0xRWXVGV0l4MkI1cWN4WTlHCkpaeXhzNGFOOHBJb0I0dUVCRjF5d
 mdLUU93ZXZUNXdOUDJlRDRnQ2VjMHJ4WCtIWAo9RU16UgotLS0tLUVORCBQR1AgTUVTU0FHRS0t
 LS0tCg==
X-Developer-Key: i=Cryolitia@gmail.com; a=openpgp;
 fpr=1C3C6547538D7152310C0EEA84DD0C0130A54DF7
X-Endpoint-Received: by B4 Relay for Cryolitia@gmail.com/default with auth_id=186
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

RMP -> RPM

---
Signed-off-by: Cryolitia PukNgae <Cryolitia@gmail.com>
---
 Documentation/hwmon/oxp-sensors.rst | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/Documentation/hwmon/oxp-sensors.rst b/Documentation/hwmon/oxp-sensors.rst
index 55b1ef61625e..50618f064379 100644
--- a/Documentation/hwmon/oxp-sensors.rst
+++ b/Documentation/hwmon/oxp-sensors.rst
@@ -52,7 +52,7 @@ Sysfs entries
 The following attributes are supported:
 
 fan1_input
-  Read Only. Reads current fan RMP.
+  Read Only. Reads current fan RPM.
 
 pwm1_enable
   Read Write. Enable manual fan control. Write "1" to set to manual, write "0"

---
base-commit: 73f3c33036904bada1b9b6476a883b1a966440cc
change-id: 20240726-typo-616bb7db0f68

Best regards,
-- 
Cryolitia PukNgae <Cryolitia@gmail.com>

