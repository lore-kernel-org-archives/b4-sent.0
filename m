From: Cryolitia PukNgae <cryolitia@uniontech.com>
Subject: [PATCH v8 0/2] hwmon: add GPD devices sensor driver
Date: Thu, 04 Sep 2025 16:33:40 +0800
Message-Id: <20250904-gpd_fan-v8-0-0752584f16da@uniontech.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOROuWgC/3XRXUvDMBgF4L9SeusqefNdQZhOmKD3IjJG0iRt1
 LZbO7vNsf9uVpTOipfnJc/hQA5xaxtv2/gqOsSN7Xzr6yoEOYnirFBVbhNvQo4xwhQJ4Em+Mku
 nqoQJR1CKSSYljcPrVWOd3/VNL4uQC99u6mbfF3dwuv7t6CBBCaGIgTECFOLTvFT+/TKry/jU0
 eFzJwaHg3NCC8t16jDosSP/OBKcNMI6DZgTLcaOnjs5OBocALeMElCps2PHfhxDGGBwLDiOpKO
 YMYcsjB3v3exmvq0/t3Mg7fb5dXbLl08lLqTCM3O/U+UF3l/nUFK82ldvD+u1uXvMp33PqE0MK
 yQ6WyHCCkalTo10TBgx/ajCL29sVvR2En0bjH4bQJlELKw3Wo3M4ng8fgFUBzk1PAIAAA==
X-Change-ID: 20240716-gpd_fan-57f30923c884
To: Jean Delvare <jdelvare@suse.com>, Guenter Roeck <linux@roeck-us.net>, 
 Jonathan Corbet <corbet@lwn.net>, 
 Cryolitia PukNgae <cryolitia@uniontech.com>
Cc: linux-kernel@vger.kernel.org, linux-hwmon@vger.kernel.org, 
 linux-doc@vger.kernel.org, Celeste Liu <CoelacanthusHex@gmail.com>, 
 Yao Zi <ziyao@disroot.org>, Derek John Clark <derekjohn.clark@gmail.com>, 
 Jun Zhan <zhanjun@uniontech.com>, Cheng Nie <niecheng1@uniontech.com>, 
 =?utf-8?q?Marcin_Str=C4=85gowski?= <marcin@stragowski.com>, 
 someone5678 <someone5678.dev@gmail.com>, 
 Justin Weiss <justin@justinweiss.com>, 
 Antheas Kapenekakis <lkml@antheas.dev>, command_block <mtf@ik.me>, 
 derjohn <himself@derjohn.de>, Crashdummyy <crashdummy1337@proton.me>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756974821; l=2686;
 i=cryolitia@uniontech.com; s=20250730; h=from:subject:message-id;
 bh=GNtVXyetoXXsPzwMZdtfYe4Fsl9TGhpYaapAdK05kzk=;
 b=hQp6X46rBJBkxwsH5tVqIvmPgwgbdYjBLI5lafg/qh8job3V4zVJs+gkDeyQ/KS4m7NPM4dXd
 kcpZsuRdjMZA5hIparanpxZALt7sCRJEt12p/enejCFuJrUBEnzUncR
X-Developer-Key: i=cryolitia@uniontech.com; a=ed25519;
 pk=tZ+U+kQkT45GRGewbMSB4VPmvpD+KkHC/Wv3rMOn/PU=
X-Endpoint-Received: by B4 Relay for cryolitia@uniontech.com/20250730 with auth_id=474
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Sensors driver for GPD Handhelds that expose fan reading and control
via hwmon sysfs.

Shenzhen GPD Technology Co., Ltd. manufactures a series of handheld
devices. This driver implements these functions through x86 port-mapped
IO.

Signed-off-by: Cryolitia PukNgae <cryolitia@uniontech.com>

---
Additional explanation: Based on the concerns in the previous version
of the discussion about placing the driver in the x86 subsystem or the
hwmon subsystem, I currently do not see any intention from GPD to
integrate battery management into EC, and would prefer to keep the
driver in the hwmon subsystem until the hardware manufacturers actually
make something practical.

---
Changes in v8:
- add mutex lock to protect an entire hwmon operation sequence
- clear manual model action
- improve error check
- style fix
- Link to v7: https://lore.kernel.org/r/20250820-gpd_fan-v7-0-10c8058f4dba@uniontech.com

Changes in v7:
- Add support for GPD Duo
- Change email from cryolitia@gmail.com to cryolitia@uniontech.com
- Link to v6: https://lore.kernel.org/r/CAGwozwG13swYjCB6_Wm2h8a2CdHxam+2y=g1m42pynkKqqdDLg@mail.gmail.com

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

 Documentation/hwmon/gpd-fan.rst |  79 ++++
 Documentation/hwmon/index.rst   |   1 +
 MAINTAINERS                     |   7 +
 drivers/hwmon/Kconfig           |  10 +
 drivers/hwmon/Makefile          |   1 +
 drivers/hwmon/gpd-fan.c         | 786 ++++++++++++++++++++++++++++++++++++++++
 6 files changed, 884 insertions(+)
---
base-commit: e6b9dce0aeeb91dfc0974ab87f02454e24566182
change-id: 20240716-gpd_fan-57f30923c884

Best regards,
-- 
Cryolitia PukNgae <cryolitia@uniontech.com>

