From: Remi Buisson <remi.buisson@tdk.com>
Date: Fri, 11 Apr 2025 13:28:40 +0000
Subject: [PATCH 8/8] MAINTAINERS: add entry for inv_icm45600 6-axis imu
 sensor
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250411-add_newport_driver-v1-8-15082160b019@tdk.com>
References: <20250411-add_newport_driver-v1-0-15082160b019@tdk.com>
In-Reply-To: <20250411-add_newport_driver-v1-0-15082160b019@tdk.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, Remi Buisson <remi.buisson@tdk.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744378119; l=1004;
 i=remi.buisson@tdk.com; s=20250411; h=from:subject:message-id;
 bh=kZKXeMI2KjRSPBEamKTN7FTc+Klt4KAQtMhrcXfCwTE=;
 b=IfheCnRVke3TO/1sC7BKOQBfcx8MRmhZxO40Wzel1Rw8pIIhLmJ1HRv8hMIwimGglnkaWY+U1
 JjDeXdxmdAPA25jU8DvmoGjUiUNRWSsy5wi78s0uiFc9TQ1aEevNdBl
X-Developer-Key: i=remi.buisson@tdk.com; a=ed25519;
 pk=yDVMi4C7RpXN4dififo42A7fDDt3THYzoZoNq9lUZuo=
X-Endpoint-Received: by B4 Relay for remi.buisson@tdk.com/20250411 with auth_id=372
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add MAINTAINERS entry for InvenSense ICM-456xx IMU device.

Signed-off-by: Remi Buisson <remi.buisson@tdk.com>
---
 MAINTAINERS | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 030d90d383411bbfe949cfff4f5bce27e3dd37c4..2d4b6755a9e240432ec1abfb131358ae4df48362 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -12397,6 +12397,15 @@ F:	Documentation/ABI/testing/sysfs-bus-iio-inv_icm42600
 F:	Documentation/devicetree/bindings/iio/imu/invensense,icm42600.yaml
 F:	drivers/iio/imu/inv_icm42600/
 
+INVENSENSE ICM-456xx IMU DRIVER
+M:	Remi Buisson <remi.buisson@tdk.com>
+L:	linux-iio@vger.kernel.org
+S:	Maintained
+W:	https://invensense.tdk.com/
+F:	Documentation/ABI/testing/sysfs-bus-iio-inv_icm45600
+F:	Documentation/devicetree/bindings/iio/imu/invensense,icm45600.yaml
+F:	drivers/iio/imu/inv_icm45600/
+
 INVENSENSE MPU-3050 GYROSCOPE DRIVER
 M:	Linus Walleij <linus.walleij@linaro.org>
 L:	linux-iio@vger.kernel.org

-- 
2.34.1

