From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Subject: [PATCH v4 0/2] iio: imu: inv_icm42600: switch to use generic name
 irq get
Date: Thu, 10 Apr 2025 17:39:39 +0200
Message-Id: <20250410-iio-imu-inv-icm42600-rework-interrupt-using-names-v4-0-19e4e2f8f7eb@tdk.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADvm92cC/53OsW7CMBDG8VdBnnvIOdt16NT3qDo49gEnFBvZi
 dsK5d1rYADWjN8Nv/9dRKHMVMTH5iIyVS6cYhv6bSP80cUDAYe2BUo0UqEB5gQ8zsCxAvtR47u
 UkOkn5VO7TZTzfJ5gLhwPEN1IBQa1s56CxV4Z0dxzpj3/3ppf320fuUwp/91eqN31eq9pqVfUa
 gcSLFIwnZTBdfpzCqetT6O4tio++3aNj833aHvn96a3A7766tnfrfFV84MbeuOksx6Hh78syz/
 8+/aesAEAAA==
X-Change-ID: 20250325-iio-imu-inv-icm42600-rework-interrupt-using-names-b397ced72835
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744299633; l=1934;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=WWPgjrypLq+FtwiDGFQDw69WqwGWqMZd39vBNg9H2Ek=;
 b=3e/zhaM3q8MUpKaDXmv/uRr+PITc98IwwQe13/LQSk4jVoPOcTJJ33hLF96luG1fIYPRXL3Pq
 A3cD4uIaS4LAJM0LAjxh2fSqIfnVUO2DcKzF7rZj9nUexhL/fKD66HO
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The purpose of this series is to switch to fwnode_irq_get_by_name()
in the core module instead of using irq from the bus parsing.

Add in dt binding interrupt naming and up to 2 interrupts support.

Signed-off-by: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
---
Changes in v4:
- Change dt-binding commit message to be more explicit about interrupt
  support.
- Simplify fwnode usage, NULL checking is already done automatically.
- Link to v3: https://lore.kernel.org/r/20250409-iio-imu-inv-icm42600-rework-interrupt-using-names-v3-0-dab85a0a7c2b@tdk.com

Changes in v3:
- Update dt-binding to report support of the 2 interrupts and delete
  remark about driver feature support.
- Link to v2: https://lore.kernel.org/r/20250407-iio-imu-inv-icm42600-rework-interrupt-using-names-v2-0-c278acf587b2@tdk.com

Changes in v2:
- Add INT2 in interrupt-names enum and fix enum
- Add fallback to first interrupt if naming is not here to ensure
  backward compatibility
- Link to v1: https://lore.kernel.org/r/20250404-iio-imu-inv-icm42600-rework-interrupt-using-names-v1-0-72ed5100da14@tdk.com

---
Jean-Baptiste Maneyrol (2):
      dt-bindings: iio: imu: icm42600: add interrupt naming support
      iio: imu: inv_icm42600: switch to use generic name irq get

 .../devicetree/bindings/iio/imu/invensense,icm42600.yaml   | 13 ++++++++++++-
 drivers/iio/imu/inv_icm42600/inv_icm42600.h                |  2 +-
 drivers/iio/imu/inv_icm42600/inv_icm42600_core.c           | 14 ++++++++++++--
 drivers/iio/imu/inv_icm42600/inv_icm42600_i2c.c            |  2 +-
 drivers/iio/imu/inv_icm42600/inv_icm42600_spi.c            |  2 +-
 5 files changed, 27 insertions(+), 6 deletions(-)
---
base-commit: 1c2409fe38d5c19015d69851d15ba543d1911932
change-id: 20250325-iio-imu-inv-icm42600-rework-interrupt-using-names-b397ced72835

Best regards,
-- 
Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>

