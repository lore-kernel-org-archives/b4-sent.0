From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Date: Thu, 03 Oct 2024 09:37:46 +0200
Subject: [PATCH 2/3] dt-bindings: iio: imu: migrate InvenSense email to TDK
 group domain
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241003-invn-maintainers-email-update-v1-2-7e4062ad68cf@tdk.com>
References: <20241003-invn-maintainers-email-update-v1-0-7e4062ad68cf@tdk.com>
In-Reply-To: <20241003-invn-maintainers-email-update-v1-0-7e4062ad68cf@tdk.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727941073; l=1790;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=F+UIybR5ZiJTmjkZOdePj24sU7xNqVC2Dhwx1qKHx3g=;
 b=5C0GyNDf7KUhOGilKnLImaSMt++8/bHgv8QBCfH9DBEPNdBtxmMc4mCdGb+moILX3pwBLjWjg
 GTsBFrxgluFDMIRtEOaATObLv/8L/fengJDhFPxGUEJbv8aF3u3nqfQ
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Migrate maintainer email to TDK domain.
---
 Documentation/devicetree/bindings/iio/imu/invensense,icm42600.yaml | 2 +-
 Documentation/devicetree/bindings/iio/imu/invensense,mpu6050.yaml  | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)

diff --git a/Documentation/devicetree/bindings/iio/imu/invensense,icm42600.yaml b/Documentation/devicetree/bindings/iio/imu/invensense,icm42600.yaml
index 3769f8e8e98cee3db61cc0138f485c488d55a63e..7e4492bbd0278a336587dc5ac04da7153453da29 100644
--- a/Documentation/devicetree/bindings/iio/imu/invensense,icm42600.yaml
+++ b/Documentation/devicetree/bindings/iio/imu/invensense,icm42600.yaml
@@ -7,7 +7,7 @@ $schema: http://devicetree.org/meta-schemas/core.yaml#
 title: InvenSense ICM-426xx Inertial Measurement Unit
 
 maintainers:
-  - Jean-Baptiste Maneyrol <jmaneyrol@invensense.com>
+  - Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
 
 description: |
   6-axis MotionTracking device that combines a 3-axis gyroscope and a 3-axis
diff --git a/Documentation/devicetree/bindings/iio/imu/invensense,mpu6050.yaml b/Documentation/devicetree/bindings/iio/imu/invensense,mpu6050.yaml
index a8d30ef015faaca02a11af7def6e06057bde3909..f91954870a44c60cadc76b5bc3917ee6f23e30a2 100644
--- a/Documentation/devicetree/bindings/iio/imu/invensense,mpu6050.yaml
+++ b/Documentation/devicetree/bindings/iio/imu/invensense,mpu6050.yaml
@@ -7,7 +7,7 @@ $schema: http://devicetree.org/meta-schemas/core.yaml#
 title: InvenSense MPU-6050 Six-Axis (Gyro + Accelerometer) MEMS MotionTracking Device
 
 maintainers:
-  - Jean-Baptiste Maneyrol <jmaneyrol@invensense.com>
+  - Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
 
 description: |
   These devices support both I2C and SPI bus interfaces.

-- 
2.34.1

