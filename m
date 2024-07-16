From: Cryolitia PukNgae <Cryolitia@gmail.com>
Subject: [PATCH 0/2] hwmon: add GPD devices sensor driver
Date: Tue, 16 Jul 2024 19:49:52 +0800
Message-Id: <20240716-gpd_fan-v1-0-34051dd71a06@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAGBelmYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDc0Mz3fSClPi0xDxdU/M0YwNLI+NkCwsTJaDqgqLUtMwKsEnRsbW1AJA
 bDxZZAAAA
To: Jean Delvare <jdelvare@suse.com>, Guenter Roeck <linux@roeck-us.net>, 
 Cryolitia PukNgae <Cryolitia@gmail.com>, Jonathan Corbet <corbet@lwn.net>
Cc: linux-kernel@vger.kernel.org, linux-hwmon@vger.kernel.org, 
 linux-doc@vger.kernel.org, Celeste Liu <CoelacanthusHex@gmail.com>, 
 =?utf-8?q?Marcin_Str=C4=85gowski?= <marcin@stragowski.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=990; i=Cryolitia@gmail.com;
 h=from:subject:message-id; bh=4KobWHo0k49SwsqBfr87hnXmB1Gdn8DzYlrHyKptLB8=;
 b=LS0tLS1CRUdJTiBQR1AgTUVTU0FHRS0tLS0tCgpvd0VCYlFHUy9wQU5Bd0FJQVQ1ZEYzTDhpb
 zdkQWNzbVlnQm1sbDVqL3BKaS9EZk9pYlNzRXpvK01WZEFlanBHCks5WGF5QVo4a3NDb0tIRjJM
 NCtKQVRNRUFBRUlBQjBXSVFSME5XMHB5dmR3U0JGOENDWStYUmR5L0lxTzNRVUMKWnBaZVl3QUt
 DUkErWFJkeS9JcU8zVUIzQ0FDNG5pRVcxTnUzMG00am5idDBvRmtXTlBKdHdyNUJVY3lDS29uVQ
 pIcXhkSVlNYUNlL1RPQUJPRnE3eFNPSnl5MU8xRnFEbVYvQjJuQXBIWmxvdHRCWjh4RSsrMmNNb
 DZZR3FEZkx3ClIvOFEzVVo3ektqUnMxZml1T1lXcldPL0NUZVluNkJpaWZpK1FveVpObUZUK2w2
 Y1hudmZXUzVuOWI2NXp4TTIKSXNUalhhVW9qM2JraWFtM003emkwSnpPNlE3YmNsREJDaHZidXN
 xekg3VTE5TFJreTFZKzNRSXBnbThkc2NQMQpPSDUyRFgxYmp6MVFKNEZOSVVPRFJINjZVOXk0bj
 FrV3B1bEdWT3VYR1RlMFdFTnhRMzZDb0RsbjFzWGRLY21vCkJqY2pSN0ptWWwrSGtSdVF2d05Rb
 lVucHJvQXBwVWxXVXIwRWIxT2cybDNxdVJCUAo9K21haQotLS0tLUVORCBQR1AgTUVTU0FHRS0t
 LS0tCg==
X-Developer-Key: i=Cryolitia@gmail.com; a=openpgp;
 fpr=1C3C6547538D7152310C0EEA84DD0C0130A54DF7
X-Endpoint-Received: by B4 Relay for Cryolitia@gmail.com/default with auth_id=186
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Sensors driver for GPD Handhelds that expose fan reading and control via
hwmon sysfs.

Shenzhen GPD Technology Co., Ltd. manufactures a series of handheld
devices. This driver implements these functions through x86 port-mapped IO.
I have tested it on my device.

Tested-by: Marcin Strągowski <marcin@stragowski.com>
Signed-off-by: Cryolitia PukNgae <Cryolitia@gmail.com>

---
Cryolitia PukNgae (2):
      hwmon: add GPD devices sensor driver
      hwmon: document: add gpd-fan

 Documentation/hwmon/gpd-fan.rst |  68 ++++
 Documentation/hwmon/index.rst   |   1 +
 MAINTAINERS                     |   7 +
 drivers/hwmon/Kconfig           |  10 +
 drivers/hwmon/Makefile          |   1 +
 drivers/hwmon/gpd-fan.c         | 759 ++++++++++++++++++++++++++++++++++++++++
 6 files changed, 846 insertions(+)
---
base-commit: d67978318827d06f1c0fa4c31343a279e9df6fde
change-id: 20240716-gpd_fan-57f30923c884

Best regards,
-- 
Cryolitia PukNgae <Cryolitia@gmail.com>

