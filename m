From: Cryolitia PukNgae <cryolitia@uniontech.com>
Subject: [PATCH v7 0/2] hwmon: add GPD devices sensor driver
Date: Fri, 01 Aug 2025 15:59:19 +0800
Message-Id: <20250801-gpd_fan-v7-0-548b9d8f57d7@uniontech.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIANdzjGgC/3XMXUvDMBTG8a8ycquVnJO3VhCmFSbovYjISJeki
 9qXtdJujn53s4KsVLx8Duf3P5LWNt625HpxJI3tfOurMgx1uSCbrS5zG3kTNkGKnCqQUV6btdN
 lJJRjNEG2iWNOwnfdWOf3Y+n1Leytb7+q5jCGOzhd/zY6iGjEOBVgjAJN5TIvtP+82lQFOTU6n
 Dp1dhicU5myMkscQjZ37B/HgouNsi4DlCxTc8enLj47HhyAtIIz0Imzcyd+naAIcHYiOEljx1E
 IRy3MnRxdervqq+9+BaztX97TO7l+LnAba0zNw14XF3i4yaHgWB/Kj8fdztw/5cuxM6kNw/ADo
 T3ErcwBAAA=
X-Change-ID: 20240716-gpd_fan-57f30923c884
To: Jean Delvare <jdelvare@suse.com>, Guenter Roeck <linux@roeck-us.net>, 
 Jonathan Corbet <corbet@lwn.net>, 
 Cryolitia PukNgae <cryolitia@uniontech.com>
Cc: linux-kernel@vger.kernel.org, linux-hwmon@vger.kernel.org, 
 linux-doc@vger.kernel.org, Celeste Liu <CoelacanthusHex@gmail.com>, 
 Yao Zi <ziyao@disroot.org>, Derek John Clark <derekjohn.clark@gmail.com>, 
 WangYuli <wangyuli@uniontech.com>, Jun Zhan <zhanjun@uniontech.com>, 
 =?utf-8?q?Marcin_Str=C4=85gowski?= <marcin@stragowski.com>, 
 someone5678 <someone5678.dev@gmail.com>, 
 Justin Weiss <justin@justinweiss.com>, 
 Antheas Kapenekakis <lkml@antheas.dev>, command_block <mtf@ik.me>, 
 derjohn <himself@derjohn.de>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1754035167; l=2352;
 i=cryolitia@uniontech.com; s=20250730; h=from:subject:message-id;
 bh=UPN2BtjFTPrNsAhc0hr0QepQVBNilRoSpsPBwysfjg8=;
 b=qZVC7oDXZenuFnLpeXV1GazobxhLyCgLraqXeNVH2Nr4/qDCoLgdqZeWZ/7hhaHqbOt6vMfjv
 u+VYXmiykzADL53DcBAK/nuEsgS39SyUqnLJDxTv6bLfrvriOe/NrZD
X-Developer-Key: i=cryolitia@uniontech.com; a=ed25519;
 pk=tZ+U+kQkT45GRGewbMSB4VPmvpD+KkHC/Wv3rMOn/PU=
X-Endpoint-Received: by B4 Relay for cryolitia@uniontech.com/20250730 with auth_id=474
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
Tested-by: derjohn <himself@derjohn.de>

Signed-off-by: Cryolitia PukNgae <cryolitia@uniontech.com>

---
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

 Documentation/hwmon/gpd-fan.rst |  71 ++++
 Documentation/hwmon/index.rst   |   1 +
 MAINTAINERS                     |   7 +
 drivers/hwmon/Kconfig           |  10 +
 drivers/hwmon/Makefile          |   1 +
 drivers/hwmon/gpd-fan.c         | 753 ++++++++++++++++++++++++++++++++++++++++
 6 files changed, 843 insertions(+)
---
base-commit: 0db240bc077fd16cc16bcecfd7f4645bc474aa7e
change-id: 20240716-gpd_fan-57f30923c884

Best regards,
-- 
Cryolitia PukNgae <cryolitia@uniontech.com>

