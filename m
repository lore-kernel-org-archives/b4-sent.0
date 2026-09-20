From: Armandas Kvietkus <armandas.kvietkus@proton.me>
Subject: [PATCH 0/2] media: i2c: Samsung S5K3T2 image sensor
Date: Sun, 20 Sep 2026 16:58:23 +0200
Message-Id: <20260920-upstream-s5k3t2-v1-0-d640740f4013@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQqDMBBA4avIrBuIMyjUq0gXiU7rVPwhk4gg3
 t3YLr/FewcoB2GFpjgg8CYqy5xRPgroBjd/2EifDWixtk+0Jq0aA7vJaDVSRIPkiXrnLZUV5Go
 N/Jb9d2xff2vyX+7ivYHzvADTVXXlcwAAAA==
X-Change-ID: 20260920-upstream-s5k3t2-23b33dab0315
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Armandas Kvietkus <armandas.kvietkus@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789916304; l=1412;
 i=armandas.kvietkus@proton.me; h=from:subject:message-id;
 bh=OcnOhEG7PexZxJ63qOQ2GyWcWihQ0eDxN/OoJZmu2EM=;
 b=kuJhV7vdtN3I0R63sX1vEWBHhmOa1Qz6cwGwnjcb3Ba9spBCpIwBWqDLWGf48YbA/hY00/BcT
 vO6i9H/3vakClchwZYh4rEhUaZkU7nfVJDU8lHCtQcUUGtmN4LuGFmT
X-Developer-Key: i=armandas.kvietkus@proton.me; a=ed25519;
 pk=wuqmImJ9sKlDVcwALOvfGhjj7G8EBjjM4TpCdmlrAf8=
X-Endpoint-Received: by B4 Relay for armandas.kvietkus@proton.me/default with auth_id=974
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds a binding and a driver for the Samsung S5K3T2, a
20 Mpixel CMOS image sensor with four MIPI D-PHY lanes.

The sensor is the front camera of the Xiaomi POCO F3. That phone has no
device tree in mainline, so this series adds no user for the binding.
The driver was written and tested on the phone with the Qualcomm CAMSS
driver.

Tested:

  v4l2-compliance on the sensor sub-device, 46 tests, 46 passed
  capture in all three modes, eleven runs, no kernel error
  the sensor returns to runtime suspend after every run
  exposure and gain sweeps checked on the captured frames
  Bayer order checked for both flips

Signed-off-by: Armandas Kvietkus <armandas.kvietkus@proton.me>
---
Armandas Kvietkus (2):
      dt-bindings: media: i2c: Add Samsung S5K3T2 image sensor
      media: i2c: Add Samsung S5K3T2 image sensor driver

 .../bindings/media/i2c/samsung,s5k3t2.yaml         |  101 ++
 MAINTAINERS                                        |    8 +
 drivers/media/i2c/Kconfig                          |   10 +
 drivers/media/i2c/Makefile                         |    1 +
 drivers/media/i2c/s5k3t2.c                         | 1360 ++++++++++++++++++++
 5 files changed, 1480 insertions(+)
---
base-commit: 518e5b794c06c0f0eb40df3e202274a66202c137
change-id: 20260920-upstream-s5k3t2-23b33dab0315

Best regards,
--  
Armandas Kvietkus <armandas.kvietkus@proton.me>

