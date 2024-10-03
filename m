From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Subject: [PATCH v2 0/3] Update email addresses and add missing MAINTAINERS
 entry
Date: Thu, 03 Oct 2024 15:38:21 +0200
Message-Id: <20241003-invn-maintainers-email-update-v2-0-ca5a4928eb22@tdk.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAE2e/mYC/4XNQQ6CMBCF4auQWTumLQ2oK+5hWNR2kIlSSFsbD
 eHuVi7gYhb/LL63QqTAFOFSrRAoc+TZl1CHCuxo/J2QXWlQQmlxVjWyzx4nwz6VoxCRSjzxtTi
 TCI1Vt9q2mvQgoRhLoIHfu3/tS48c0xw++1yWv+8uSyH+yVmiwJa0aJRxzckOXXKPo50n6Ldt+
 wLNRnPByAAAAA==
X-Change-ID: 20240923-invn-maintainers-email-update-ac2b3c74e4f1
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727962711; l=1063;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=lxAM7uyaZBdyhQpXywYiWYh63qBKG5pCaT3tPPxElkA=;
 b=Olhb3bULxIHPQl7WLsmehq+6FZgl/kzmzYgn4uCvXdBuyeijlTIqdrKTKSiFobJ+AMpUzvKb+
 0SFG7Rd0skSBLv0PQhRDUdrU8Xc9nyITTtHc2q/1unBWqTXecCFxJub
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Migrate invensense email addresses to TDK domain. Add missing entry
for iio inv_mpu6050 driver.

Signed-off-by: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
---
Changes in v2:
- Fix missing signed-off
- Link to v1: https://lore.kernel.org/r/20241003-invn-maintainers-email-update-v1-0-7e4062ad68cf@tdk.com

---
Jean-Baptiste Maneyrol (3):
      MAINTAINERS: iio: migrate invensense email address to tdk domain
      dt-bindings: iio: imu: migrate InvenSense email to TDK group domain
      MAINTAINERS: iio: imu: add entry for InvenSense MPU-6050 driver

 .../devicetree/bindings/iio/imu/invensense,icm42600.yaml       |  2 +-
 .../devicetree/bindings/iio/imu/invensense,mpu6050.yaml        |  2 +-
 MAINTAINERS                                                    | 10 +++++++++-
 3 files changed, 11 insertions(+), 3 deletions(-)
---
base-commit: 550aaa170cd9176655382364308d2ff54623b30b
change-id: 20240923-invn-maintainers-email-update-ac2b3c74e4f1

Best regards,
-- 
Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>

