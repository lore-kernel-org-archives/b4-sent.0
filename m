From: Cryolitia PukNgae <Cryolitia@gmail.com>
Subject: [PATCH v2 0/2] hwmon: add GPD devices sensor driver
Date: Wed, 17 Jul 2024 00:58:06 +0800
Message-Id: <20240717-gpd_fan-v2-0-f7b7e6b9f21b@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAJ6mlmYC/2XMSwrCMBSF4a2UOzaSV5vqyH1IkZBXL9imJBKUk
 r0bO3X4Hw7fDtkldBmu3Q7JFcwY1xb81IGZ9RocQdsaOOWSKjaQsNmH1yvplRf0woUZRwntvSX
 n8X1I96n1jPkV0+eAC/ut/0ZhhBIhac+sVUzT4RYWjc+ziQtMtdYvbXdH2p4AAAA=
To: Jean Delvare <jdelvare@suse.com>, Guenter Roeck <linux@roeck-us.net>, 
 Cryolitia PukNgae <Cryolitia@gmail.com>, Jonathan Corbet <corbet@lwn.net>
Cc: linux-kernel@vger.kernel.org, linux-hwmon@vger.kernel.org, 
 linux-doc@vger.kernel.org, Celeste Liu <CoelacanthusHex@gmail.com>, 
 =?utf-8?q?Marcin_Str=C4=85gowski?= <marcin@stragowski.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1150; i=Cryolitia@gmail.com;
 h=from:subject:message-id; bh=93hyIkgIDDXYRKPYLb1eE1CU46ivjzLvtL28cInJllk=;
 b=LS0tLS1CRUdJTiBQR1AgTUVTU0FHRS0tLS0tCgpvd0did012TXdNRm9GeXRlOUtlcjd5N2phY
 lVraHJScHkxWmZlTU9hdlVoTWc3TjNBZWVudTlON2lrNnFTT3hiClkyWndiaVhqckl6TFAxU2tP
 aG1OV1JnWU9SaGt4UlJaU2t4ek5VOTlML0FRck9GUWd4bkV5Z1F5aFlHTFV3QW0KY2p1T2c2SHJ
 wUGdOaTNWclEvelNFdFpaZW5PV3NiREpQZE9zbjZhZVhhSmJFcmNrNC9Udi9SbGErNExVdnJ5Yw
 prS3NlYzBYK0UvL3JMbmNHeG4rSDh2OTV5THlUbUo3L3JmL0dua0JkUFYrSHF3SVQyeVFDS2lZM
 nN4cDFmRnZwCjc4cTY0RTdoMzlmclBrKzQ2dEh3MDlOMmM1ZFoyNnhjc3hNYk93MFNxN3ozcHdU
 dmZGTVpvM3RHU1REMTQrTkgKdFp5aWRzTHErU0tIMmU5SjdWN1Z5QlVhc0c5WDc5dDBxZC9UMjl
 OQzVTWkdCS3haZGVwWjJWbVJHck5QOWZyNgpsV2V5dXFwMENsMkM5cGZ5emRuOXlQZkZSOE91M3
 NOMy94OW01ZG44Ym83bjFjUGJOTmZPUzdmOWZZdXpUcGJKCnZjN3BucnpkdnZNNzZ0cDlhNmI4O
 HVvSnlmajV4dUt5bWh5L2wzcDhVcFk0QUE9PQo9cDZFSAotLS0tLUVORCBQR1AgTUVTU0FHRS0t
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
Changes in v2:
- Improved documentation, thanks to Randy Dunlap!
- Link to v1: https://lore.kernel.org/r/20240716-gpd_fan-v1-0-34051dd71a06@gmail.com

---
Cryolitia PukNgae (2):
      hwmon: add GPD devices sensor driver
      hwmon: document: add gpd-fan

 Documentation/hwmon/gpd-fan.rst |  69 ++++
 Documentation/hwmon/index.rst   |   1 +
 MAINTAINERS                     |   7 +
 drivers/hwmon/Kconfig           |  10 +
 drivers/hwmon/Makefile          |   1 +
 drivers/hwmon/gpd-fan.c         | 759 ++++++++++++++++++++++++++++++++++++++++
 6 files changed, 847 insertions(+)
---
base-commit: d67978318827d06f1c0fa4c31343a279e9df6fde
change-id: 20240716-gpd_fan-57f30923c884

Best regards,
-- 
Cryolitia PukNgae <Cryolitia@gmail.com>

