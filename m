From: Cryolitia PukNgae <Cryolitia@gmail.com>
Subject: [PATCH v4 0/2] hwmon: add GPD devices sensor driver
Date: Thu, 18 Jul 2024 10:22:22 +0800
Message-Id: <20240718-gpd_fan-v4-0-116e5431a9fe@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAF58mGYC/3XMSwrCMBSF4a2UjI3k1dzWkfsQkaRJ2oB9kEhQS
 vdu2olFcXgu9/tnFG3wNqJTMaNgk49+HPIQhwI1nRpai73JGzHCBAEqcTuZm1MDLsFxUjPeVJV
 A+XsK1vnnVrpc8+58fIzhtYUTXa+/jUQxwVyQkhoDVBF5bnvl78dm7NHaSGzv4ONYdg40WKlrx
 6j+dvyP49lVBqzTlEmuYe+WZXkDP8DMAQ4BAAA=
To: Jean Delvare <jdelvare@suse.com>, Guenter Roeck <linux@roeck-us.net>, 
 Cryolitia PukNgae <Cryolitia@gmail.com>, Jonathan Corbet <corbet@lwn.net>
Cc: linux-kernel@vger.kernel.org, linux-hwmon@vger.kernel.org, 
 linux-doc@vger.kernel.org, Celeste Liu <CoelacanthusHex@gmail.com>, 
 Yao Zi <ziyao@disroot.org>, 
 =?utf-8?q?Marcin_Str=C4=85gowski?= <marcin@stragowski.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1481; i=Cryolitia@gmail.com;
 h=from:subject:message-id; bh=LVaqsqmGIy9CINW58oVHBqj5bVtiVxWM9b/S4sE4Wpo=;
 b=LS0tLS1CRUdJTiBQR1AgTUVTU0FHRS0tLS0tCgpvd0VCYlFHUy9wQU5Bd0FJQVQ1ZEYzTDhpb
 zdkQWNzbVlnQm1tSHhnbGpjRlhLYnRNSzNOSWZjaHd0dzEyNmxZClF3MzVmRG5Rd1FaemZUdnY3
 RmVKQVRNRUFBRUlBQjBXSVFSME5XMHB5dmR3U0JGOENDWStYUmR5L0lxTzNRVUMKWnBoOFlBQUt
 DUkErWFJkeS9JcU8zZFpsQ0FDTDdWR1FXWjhaM054OXZFcHhpTlFtd290Y1ZBUFBuQ0lxZHlFNQ
 pNc0tKNjdSSWZwNW1YbWNLaWREdWJveVQ3ckZUOEk5a04rd0lDWlJ6UFNLbnNHQUZNTUhCU0kwc
 nFHdVM4QzZJCi94RnloWkpubzVhVmVBeUJPUEFYNHhobjVjOGhXV1RtVUo1WlNwMXM2N3RzRmpp
 bitiZXJHdmpyMVdzVWtQOC8KZllXK2xpV3VyUk1NZlNMYVpHSVhvUVhtTzZPWnFNendaWTFGdHF
 jSnIrbHZuSURidUFndjU0SjlUUXQ1THVZQgpVMytKNXk0clFYMUhINVNST2VnWk5zeGY2dVM2cl
 pBRGdtNis0VXg4ajA5U2cyL2Iycm1Va2NERlB1a2ZUK2xKCkRGVm9nWDJuMlJuRmJBMDZ2RGdQa
 UpXSHp2NHpPc3B3RnBZVmFUK0dnVHBGTkdlRgo9OTNCSAotLS0tLUVORCBQR1AgTUVTU0FHRS0t
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

 Documentation/hwmon/gpd-fan.rst |  63 ++++
 Documentation/hwmon/index.rst   |   1 +
 MAINTAINERS                     |   7 +
 drivers/hwmon/Kconfig           |  10 +
 drivers/hwmon/Makefile          |   1 +
 drivers/hwmon/gpd-fan.c         | 683 ++++++++++++++++++++++++++++++++++++++++
 6 files changed, 765 insertions(+)
---
base-commit: d67978318827d06f1c0fa4c31343a279e9df6fde
change-id: 20240716-gpd_fan-57f30923c884

Best regards,
-- 
Cryolitia PukNgae <Cryolitia@gmail.com>

