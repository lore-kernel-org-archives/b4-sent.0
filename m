From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Date: Thu, 03 Oct 2024 09:37:47 +0200
Subject: [PATCH 3/3] MAINAINERS: iio: imu: add entry for InvenSense
 MPU-6050 driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241003-invn-maintainers-email-update-v1-3-7e4062ad68cf@tdk.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727941073; l=880;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=FPt7EcUZXhPizT6dYgXIa8fkCzyGqvv1//+R8PUl5hI=;
 b=zhopDH4uki864JdnXdglGMv8Z14ALLQ5SUsfqRU/nSMllLqWEd7VJDUSXJg9nEH1lWOMSFNQN
 G10JTUKZvQTDgUF0XdCNJHuR+rLmHe9FNduHwcQ4f3SGnm1v5rGBVLU
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add entry for inv_mpu6050 iio driver supporting InvenSense MPU-6xxx
and ICM-206xxx devices.
---
 MAINTAINERS | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index b6b252b991a514e225df309485c708c2af547f57..fba699e27612997ed1465ae080632dbeb0639be5 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -11913,6 +11913,14 @@ S:	Maintained
 F:	Documentation/devicetree/bindings/iio/gyroscope/invensense,mpu3050.yaml
 F:	drivers/iio/gyro/mpu3050*
 
+INVENSENSE MPU-6050 IMU DRIVER
+M:	Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
+L:	linux-iio@vger.kernel.org
+S:	Maintained
+W:	https://invensense.tdk.com/
+F:	Documentation/devicetree/bindings/iio/imu/invensense,mpu6050.yaml
+F:	drivers/iio/imu/inv_mpu6050/
+
 IOC3 ETHERNET DRIVER
 M:	Ralf Baechle <ralf@linux-mips.org>
 L:	linux-mips@vger.kernel.org

-- 
2.34.1

