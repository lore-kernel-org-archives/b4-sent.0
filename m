From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Subject: [PATCH v2 0/2] iio: imu: inv_icm42600: switch to use generic name
 irq get
Date: Mon, 07 Apr 2025 21:57:15 +0200
Message-Id: <20250407-iio-imu-inv-icm42600-rework-interrupt-using-names-v2-0-c278acf587b2@tdk.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABsu9GcC/52OQQ7CIBBFr2JYOwYoWHXlPUwXFcZ20gANtKhpe
 nex3sDle4v//sISRsLELruFRcyUKPgCcr9jpm99h0C2MJNcal5JDUQByM1APgMZp+SRc4j4DHE
 obsIY53GCOZHvwLcOE9yrc23Q1vJUaVZ2x4gPem3NW1O4pzSF+N4uZPG1v5ri6o9aFsChlmi14
 Ny2Ql0nOxxMcKxZ1/UD/A4HzfAAAAA=
X-Change-ID: 20250325-iio-imu-inv-icm42600-rework-interrupt-using-names-b397ced72835
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744055845; l=1344;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=rIJwEoz8xFlQQVlAO/VsBXMyVwVYpieUYx8Cva0KGTE=;
 b=MVjajOAMvhvW8ch5RkVeX8GmZZbQOrXdcvzHU+tA5GN7UEQXJqDv5QbJVYoJGlajjxAzi4KWT
 pUHelmpxrRwDc34RBXCdat+LH/CkpVmEvi08CPObIilHZCG+niO56pR
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The purpose of this series is to switch to fwnode_irq_get_by_name()
in the core module instead of using irq from the bus parsing.
Add interrupt naming and support only INT1.

Signed-off-by: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
---
Changes in v2:
- Add INT2 in interrupt-names enum and fix enum
- Add fallback to first interrupt if naming is not here to ensure
  backward compatibility
- Link to v1: https://lore.kernel.org/r/20250404-iio-imu-inv-icm42600-rework-interrupt-using-names-v1-0-72ed5100da14@tdk.com

---
Jean-Baptiste Maneyrol (2):
      dt-bindings: iio: imu: icm42600: add interrupt naming support
      iio: imu: inv_icm42600: switch to use generic name irq get

 .../bindings/iio/imu/invensense,icm42600.yaml           | 13 +++++++++++++
 drivers/iio/imu/inv_icm42600/inv_icm42600.h             |  2 +-
 drivers/iio/imu/inv_icm42600/inv_icm42600_core.c        | 17 +++++++++++++++--
 drivers/iio/imu/inv_icm42600/inv_icm42600_i2c.c         |  2 +-
 drivers/iio/imu/inv_icm42600/inv_icm42600_spi.c         |  2 +-
 5 files changed, 31 insertions(+), 5 deletions(-)
---
base-commit: e3ee177e2a3e21ef4502f68336023154049d2acd
change-id: 20250325-iio-imu-inv-icm42600-rework-interrupt-using-names-b397ced72835

Best regards,
-- 
Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>

