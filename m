From: Cryolitia PukNgae <Cryolitia@gmail.com>
Subject: [PATCH v3 0/2] hwmon: add GPD devices sensor driver
Date: Wed, 17 Jul 2024 14:46:25 +0800
Message-Id: <20240717-gpd_fan-v3-0-8d7efb1263b7@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAMFol2YC/2WMyQqDMBRFf0XeuikZNNGu+h+llGgGH9SBpIQW8
 d8b3VTo8lzuOQtEG9BGuBQLBJsw4jRmEKcCul6P3hI0mYFTXlLFJPGzeTg9kko5QRsuurouIb/
 nYB2+99LtnrnH+JrCZw8ntq3/jcQIJaKkFTNGMU3l1Q8an+duGmBrJH701M/j2XOqVVa2jeOsP
 Xrrun4BYCwYZtYAAAA=
To: Jean Delvare <jdelvare@suse.com>, Guenter Roeck <linux@roeck-us.net>, 
 Cryolitia PukNgae <Cryolitia@gmail.com>, Jonathan Corbet <corbet@lwn.net>
Cc: linux-kernel@vger.kernel.org, linux-hwmon@vger.kernel.org, 
 linux-doc@vger.kernel.org, Celeste Liu <CoelacanthusHex@gmail.com>, 
 Yao Zi <ziyao@disroot.org>, 
 =?utf-8?q?Marcin_Str=C4=85gowski?= <marcin@stragowski.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1328; i=Cryolitia@gmail.com;
 h=from:subject:message-id; bh=uMqIIpyBOEqt0CJmGAlMj+e7wF3ct3u+0A8IBPGTYoU=;
 b=LS0tLS1CRUdJTiBQR1AgTUVTU0FHRS0tLS0tCgpvd0VCYlFHUy9wQU5Bd0FJQVQ1ZEYzTDhpb
 zdkQWNzbVlnQm1sMmpGNjY3UjRtOGNzS1BDOXJxOXRzeU1sVXVwCkVpVzlYQnhLRWlpQTRwcVR1
 M0tKQVRNRUFBRUlBQjBXSVFSME5XMHB5dmR3U0JGOENDWStYUmR5L0lxTzNRVUMKWnBkb3hRQUt
 DUkErWFJkeS9JcU8zVC9HQi85a0l3eitoUEE3NXd3V3ZrWUdSTjYzQXJkQW1hNDRoeHExS2JuZQ
 ppNjFxS0k4RWs2M20xbCt5ZXlrQ29HczZ3SFZRZVI2UjQ3Q2kvTDFhcUUzSFVFalRubW1vc2E1R
 UFTNitPenhUCi9qNU1OWG11QlY5WVdmZDl4U0lGNmQyY2JFOEw1NkZaK0U5cU9NUmFjWmxaSUlS
 UGFPUU1EdEFKbHcreUE4S0UKT0hxYjBTVStQSW9Oc0FwbVlsamNmdlhkWXh0MlV0dDlSSEpZZ3E
 zZUJNMGttY2ZSUm9Dd0NCVDhTVDVCejhCbgpWVCtuV08vc1lUOVFwdXZodDhiNUozcFl5anRDZl
 JyZy8xYkNxNmprUm1NdnZVTEt3NGl6Q1U2Y1ZJYUZxbEd6CjZ5cXQ1SmZQM1JGY05YQzUzcjRUc
 0phbVArajAwSjNIQkVEbTZYS2hFb0J3TDk2WAo9dzdnUQotLS0tLUVORCBQR1AgTUVTU0FHRS0t
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
 drivers/hwmon/gpd-fan.c         | 674 ++++++++++++++++++++++++++++++++++++++++
 6 files changed, 756 insertions(+)
---
base-commit: d67978318827d06f1c0fa4c31343a279e9df6fde
change-id: 20240716-gpd_fan-57f30923c884

Best regards,
-- 
Cryolitia PukNgae <Cryolitia@gmail.com>

