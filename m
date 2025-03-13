From: Cryolitia PukNgae <Cryolitia@gmail.com>
Subject: [PATCH v6 0/2] hwmon: add GPD devices sensor driver
Date: Fri, 14 Mar 2025 04:10:29 +0800
Message-Id: <20250314-gpd_fan-v6-0-1dc992050e42@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIALU702cC/3XMTWrDMBCG4asErasyM/p1Vr1HKEWyRo6gsYNdT
 Erw3asEio1Ll98wz3sXE4+FJ3E83MXIc5nK0NdhXw6iPYe+Y1lS3YKANDi0srumjxx6aVxW0JB
 qvdeifl9HzuX2LJ3e6z6X6WsYv5/hGR/Xv40ZJUilwWBKDgPYt+4SyudrO1zEozHT1rnVUXXZR
 cc2Npkw7p36x6nqfHKcI5JV0e2d3jq/Ol0domWjFYYm896ZX2eAEFdnqrPgsyZjMjBu3bIsP72
 6Rvh+AQAA
X-Change-ID: 20240716-gpd_fan-57f30923c884
To: Jean Delvare <jdelvare@suse.com>, Guenter Roeck <linux@roeck-us.net>, 
 Cryolitia PukNgae <Cryolitia@gmail.com>, Jonathan Corbet <corbet@lwn.net>
Cc: linux-kernel@vger.kernel.org, linux-hwmon@vger.kernel.org, 
 linux-doc@vger.kernel.org, Celeste Liu <CoelacanthusHex@gmail.com>, 
 Yao Zi <ziyao@disroot.org>, Derek John Clark <derekjohn.clark@gmail.com>, 
 =?utf-8?q?Marcin_Str=C4=85gowski?= <marcin@stragowski.com>, 
 someone5678 <someone5678.dev@gmail.com>, 
 Justin Weiss <justin@justinweiss.com>, 
 Antheas Kapenekakis <lkml@antheas.dev>, command_block <mtf@ik.me>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2083; i=Cryolitia@gmail.com;
 s=20250314; h=from:subject:message-id;
 bh=T0rWpFRosU3djnuMSSt9rEefSFjjppoUppZgCBq2n3A=;
 b=LS0tLS1CRUdJTiBQR1AgTUVTU0FHRS0tLS0tCgpvd0VCYlFHUy9wQU5Bd0FJQVQ1ZEYzTDhpb
 zdkQWNzbVlnQm4wenUyT0pEZDkrdVg1WEpmNzRURkhYelBsTDM4CjNXaEFueXd0dHJJNXVVTC90
 SmFKQVRNRUFBRUlBQjBXSVFSME5XMHB5dmR3U0JGOENDWStYUmR5L0lxTzNRVUMKWjlNN3RnQUt
 DUkErWFJkeS9JcU8zVHpvQi80ZytaeDh1Sk9CUU0rakJRNlo4T2tiY2ZjeFU3M1VjNHVFVDN4WA
 pBdi9la3lQYS9KN3NqYjFYekVLUjA0UU9iSFpKckJEWVdDTDFRbUNxWHFtTmh6bkFGSHkyN2Y1a
 VhMMHl5T0FRCnArb1E1eGZuU1lCMkRzQldsS2J1NWMrVWw0YngxMlZWRURVWTMxWUJiR0paQWw3
 VFFQc1hOanl0ZUxETUhteWoKRkJvSEdPT3FQUElZWFdFRXhLcHVndDdoRHhrOVNsV1c3RkIxZmR
 hM3FsTTcwM1VjMStjMWpuUlhDR2w1Q3J4awpmdDJJbVA5OXJIVEVMUUliQ21UU1ZCOEJZRmdJek
 xpOUtYY0tocEN3VGdoTkxSVW16OXYxUnRuRGhLT1piQ3FRCm5RcGhYcTdSd1UrdHJjVmQ5MHVuR
 3RaVGRPTVBWdlVCcFBnSldtVDdyZ2lrYklYMAo9U3paNgotLS0tLUVORCBQR1AgTUVTU0FHRS0t
 LS0tCg==
X-Developer-Key: i=Cryolitia@gmail.com; a=openpgp;
 fpr=1C3C6547538D7152310C0EEA84DD0C0130A54DF7
X-Endpoint-Received: by B4 Relay for Cryolitia@gmail.com/20250314 with auth_id=358
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Sensors driver for GPD Handhelds that expose fan reading and control via
hwmon sysfs.

Shenzhen GPD Technology Co., Ltd. manufactures a series of handheld
devices. This driver implements these functions through x86 port-mapped IO.

Tested-by: Marcin Strągowski <marcin@stragowski.com>
Tested-by: someone5678 <someone5678.dev@gmail.com>
Tested-by: Justin Weiss <justin@justinweiss.com>
Tested-by: Antheas Kapenekakis <lkml@antheas.dev>
Tested-by: command_block <mtf@ik.me>

Signed-off-by: Cryolitia PukNgae <Cryolitia@gmail.com>

---
Changes in v6:
- fix: nullptr and label followed by a declaration
- cleanup: clean up code and rename some function
- format code
- dmi: add 2025 new GPD devices
- Link to v5: https://lore.kernel.org/r/20250211-gpd_fan-v5-0-608f4255f0e1@gmail.com

Changes in v5:
- Rebase on kernel 6.13
- Remove all value-cache related code
- Clean up code
- Link to v4: https://lore.kernel.org/r/20240718-gpd_fan-v4-0-116e5431a9fe@gmail.com

Changes in v4:
- Apply suggest by Krzysztof Kozlowski, thanks!
- Link to v3: https://lore.kernel.org/r/20240717-gpd_fan-v3-0-8d7efb1263b7@gmail.com

Changes in v3:
- Re-arrange code, thanks to Krzysztof Kozlowski, Guenter Roeck, Yao Zi!
- Link to v2: https://lore.kernel.org/r/20240717-gpd_fan-v2-0-f7b7e6b9f21b@gmail.com

Changes in v2:
- Improved documentation, thanks to Randy Dunlap!
- Link to v1: https://lore.kernel.org/r/20240716-gpd_fan-v1-0-34051dd71a06@gmail.com

---
Cryolitia PukNgae (2):
      hwmon: add GPD devices sensor driver
      hwmon: document: add gpd-fan

 Documentation/hwmon/gpd-fan.rst |  71 +++++
 Documentation/hwmon/index.rst   |   1 +
 MAINTAINERS                     |   7 +
 drivers/hwmon/Kconfig           |  10 +
 drivers/hwmon/Makefile          |   1 +
 drivers/hwmon/gpd-fan.c         | 681 ++++++++++++++++++++++++++++++++++++++++
 6 files changed, 771 insertions(+)
---
base-commit: ffd294d346d185b70e28b1a28abe367bbfe53c04
change-id: 20240716-gpd_fan-57f30923c884

Best regards,
-- 
Cryolitia PukNgae <Cryolitia@gmail.com>

