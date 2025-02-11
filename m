From: Cryolitia PukNgae <Cryolitia@gmail.com>
Subject: [PATCH v5 0/2] hwmon: add GPD devices sensor driver
Date: Tue, 11 Feb 2025 15:01:16 +0800
Message-Id: <20250211-gpd_fan-v5-0-608f4255f0e1@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIALz1qmcC/3XMTQqDMBCG4atI1k3JJDHRrnqPUkpiJhqoP2iRF
 vHujW4US5ffMM87kQH7gAO5JBPpcQxDaJs40lNCiso0JdLg4iaccck0KFp27uFNQ1PtBcu5KLJ
 Mkvjd9ejDey3d7nFXYXi1/WcNj7BcfxsjUEaFZCk4p8EwdS1rE57noq3J0hj53unN8ei8thqVz
 T0He3TijxPRZU6jt8CVsPro5N5lm5PRAShMpQCTe9y7eZ6/0xxiWkYBAAA=
X-Change-ID: 20240716-gpd_fan-57f30923c884
To: Jean Delvare <jdelvare@suse.com>, Guenter Roeck <linux@roeck-us.net>, 
 Cryolitia PukNgae <Cryolitia@gmail.com>, Jonathan Corbet <corbet@lwn.net>
Cc: linux-kernel@vger.kernel.org, linux-hwmon@vger.kernel.org, 
 linux-doc@vger.kernel.org, Celeste Liu <CoelacanthusHex@gmail.com>, 
 Yao Zi <ziyao@disroot.org>, Derek John Clark <derekjohn.clark@gmail.com>, 
 =?utf-8?q?Marcin_Str=C4=85gowski?= <marcin@stragowski.com>, 
 someone5678 <someone5678.dev@gmail.com>, 
 Justin Weiss <justin@justinweiss.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1739; i=Cryolitia@gmail.com;
 h=from:subject:message-id; bh=oYkNhz60aIpUdONo8K56ubZU0soRSKZnPCi9UC8ZksY=;
 b=LS0tLS1CRUdJTiBQR1AgTUVTU0FHRS0tLS0tCgpvd0did012TXdDV1dQRU9OYzFGS3JRM2phY
 lVraHZSVlgwL0Y4emZ6UmhvVXNoK0xucXMxUi9ULzFUVlRWcnYyCm0rd3VPbS9rNk50L1I4T3Bv
 NVNGUVl5TFFWWk1rV1dGalBYRXVwS3U3Q3Z5TFh0ZzVyQXlnUXhoNE9JVWdJbWMKWTJaa1dNaTl
 3dFBGNEV4OGNEdkxsbmZkS2hjMnh6Y212THNrYUhPdjZaamRFVjFaUTBhR055V1d2YkVHbkYrdQ
 ovWDlqTnIxU1pkR0N6V1hTdTl1M3A4Ymx0dWYyUGd4Z0JBQT0KPWJFQTAKLS0tLS1FTkQgUEdQI
 E1FU1NBR0UtLS0tLQo=
X-Developer-Key: i=Cryolitia@gmail.com; a=openpgp;
 fpr=1C3C6547538D7152310C0EEA84DD0C0130A54DF7
X-Endpoint-Received: by B4 Relay for Cryolitia@gmail.com/default with auth_id=186
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Sensors driver for GPD Handhelds that expose fan reading and control via
hwmon sysfs.

Shenzhen GPD Technology Co., Ltd. manufactures a series of handheld
devices. This driver implements these functions through x86 port-mapped IO.

Tested-by: Marcin Strągowski <marcin@stragowski.com>
Tested-by: someone5678 <someone5678.dev@gmail.com>
Tested-by: Justin Weiss <justin@justinweiss.com>

Signed-off-by: Cryolitia PukNgae <Cryolitia@gmail.com>

---
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

 Documentation/hwmon/gpd-fan.rst |  63 +++++
 Documentation/hwmon/index.rst   |   1 +
 MAINTAINERS                     |   7 +
 drivers/hwmon/Kconfig           |  10 +
 drivers/hwmon/Makefile          |   1 +
 drivers/hwmon/gpd-fan.c         | 611 ++++++++++++++++++++++++++++++++++++++++
 6 files changed, 693 insertions(+)
---
base-commit: ffd294d346d185b70e28b1a28abe367bbfe53c04
change-id: 20240716-gpd_fan-57f30923c884

Best regards,
-- 
Cryolitia PukNgae <Cryolitia@gmail.com>

