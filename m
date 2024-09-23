From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Subject: [PATCH v2 0/2] Add support of IAM-20680 HP & HT
Date: Mon, 23 Sep 2024 16:53:20 +0200
Message-Id: <20240923-inv-mpu6050-add-iam20680-ht-hp-v2-0-48290e0b9931@tdk.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOCA8WYC/x3NwQrCMAyA4VcZORsI6VasryIeMpvZHFZLq0MYe
 /cVj9/l/3doWk0b3IYdqm7W7J07+DLAM0l+KVrsBiYeKbBDyxuu5etpIpQY0WRl8lfC9MFUcJl
 kZAk+ODdDj5Sqi/3+g/vjOE4Vr5wRcAAAAA==
X-Change-ID: 20240923-inv-mpu6050-add-iam20680-ht-hp-f5a42a96933b
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Jean-Baptiste Maneyrol <jmaneyrol@invensense.com>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727103209; l=1076;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=nKwqZC0rEOeleKnqcEnAwn2FC3PO/cMvKnG1Hs4oV0k=;
 b=+fg/gqi4YuYK/P3eSCPIUczNFoHJgDxTpEbozIsYbMS2ZVEdzJv34mt4OWjCG4ILzbcwn6yOl
 n0r6nREKFjiC/Roz6feDjXRkBS/PTLDmWG++uhSXLC6XbDkd33uH/Uq
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support of IAM-20680 HP & HT variants. These chips have better
hardware specs and a bigger FIFO while retaining full compatibility with
IAM-20680.

Changes for v2:
* Send patches to the correct list (devicetree was missing)

Signed-off-by: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
---
Jean-Baptiste Maneyrol (2):
      dt-bindings: iio: imu: mpu6050: Add iam20680ht/hp bindings to mpu6050
      iio: imu: inv_mpu6050: add support for IAM-20680HT/HP

 .../bindings/iio/imu/invensense,mpu6050.yaml         |  5 +++++
 drivers/iio/imu/inv_mpu6050/inv_mpu_core.c           | 20 ++++++++++++++++++++
 drivers/iio/imu/inv_mpu6050/inv_mpu_i2c.c            | 10 ++++++++++
 drivers/iio/imu/inv_mpu6050/inv_mpu_iio.h            |  4 ++++
 drivers/iio/imu/inv_mpu6050/inv_mpu_spi.c            | 10 ++++++++++
 5 files changed, 49 insertions(+)
---
base-commit: 1504ee03b6e48187348d20f6efc74e7d93855728
change-id: 20240923-inv-mpu6050-add-iam20680-ht-hp-f5a42a96933b

Best regards,
-- 
Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>

