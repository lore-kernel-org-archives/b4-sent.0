From: Ferdinand Schwenk <ferdinand.schwenk@advastore.com>
Subject: [PATCH v2 0/3] hwmon: ina238: add samples and update_interval_us
 support
Date: Mon, 08 Jun 2026 15:03:53 +0200
Message-Id: <20260608-hwmon-ina238-update-interval-us-v2-v2-0-2d939fbb2ea1@advastore.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2N0QqDMAwAf0XyvECWipT9ythDWOMMbFFa7Qbiv
 6/4eHDc7VA0mxa4dTtkrVZs9gZ86eA5ib8ULTUGJh5ooIjT9zM7mguHiNuSZG2Kr5qrvHErWBm
 voe9jUhKKAVpoyTra75zcH8fxB21awOR0AAAA
X-Change-ID: 20260608-hwmon-ina238-update-interval-us-v2-13448de0a083
To: Guenter Roeck <linux@roeck-us.net>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>
Cc: linux-hwmon@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-doc@vger.kernel.org, richard.leitner@linux.dev, 
 ferdinand.schwenk@advastore.com
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780923870; l=2059;
 i=ferdinand.schwenk@advastore.com; h=from:subject:message-id;
 bh=knZSIpSnPyE8xSKnsSBICwc7zFH7EviJsK2ZsdUIYnE=;
 b=karf5InTqgmwXUQey41hm4GWNyEIIzDyLm8CEDUcT6bGJBWHKWYy1U7e84zX0gZvGBv/6TyNa
 SA6Mb74wTlCCpux0f9J1u697Iyv/Tzb26dJLd3/KYJEKyWmwQe6IfFx
X-Developer-Key: i=ferdinand.schwenk@advastore.com; a=ed25519;
 pk=HyA9NdHJ7NystP+1SyuWJeyXNH2EO4A09FXli9mfs9Q=
X-Endpoint-Received: by B4 Relay for ferdinand.schwenk@advastore.com/default with auth_id=788
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The INA238 family exposes ADC averaging and conversion timing controls
through ADC_CONFIG. Add support for the samples and update_interval
chip attributes and introduce a generic update_interval_us companion
attribute for devices that need sub-millisecond resolution.

The shortest INA238 conversion time steps are below 1 ms, so several
valid hardware settings collapse to the same update_interval value when
reported only in milliseconds. Keep update_interval in milliseconds as
required by the existing hwmon ABI and provide update_interval_us to
report and program the same total conversion cycle time with microsecond
resolution.

Patch 1 adds samples and update_interval support for the INA238 family.
Patch 2 adds the generic hwmon update_interval_us attribute and
documents it.
Patch 3 wires the new attribute up in the INA238 driver.

Link: https://lore.kernel.org/all/20260522-hwmon-ina238-add-samples-update-interval-v1-0-e1acfceb447e@advastore.com/
---
v2:
- keep update_interval in milliseconds to preserve the existing ABI
- add the generic update_interval_us hwmon chip attribute and documentation
- implement update_interval_us for ina238
- report and program intervals using the active averaging count

---
Ferdinand Schwenk (3):
      hwmon: ina238: add support for samples and update_interval
      hwmon: Add update_interval_us chip attribute
      hwmon: ina238: add update_interval_us attribute

 Documentation/ABI/testing/sysfs-class-hwmon |  14 +++
 Documentation/hwmon/ina238.rst              |   4 +
 Documentation/hwmon/sysfs-interface.rst     |   4 +
 drivers/hwmon/hwmon.c                       |   1 +
 drivers/hwmon/ina238.c                      | 160 +++++++++++++++++++++++++++-
 include/linux/hwmon.h                       |   2 +
 6 files changed, 183 insertions(+), 2 deletions(-)
---
base-commit: 028ef9c96e96197026887c0f092424679298aae8
change-id: 20260608-hwmon-ina238-update-interval-us-v2-13448de0a083

Best regards,
-- 
Ferdinand Schwenk <ferdinand.schwenk@advastore.com>

