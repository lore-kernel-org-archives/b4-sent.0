From: Remi Buisson <remi.buisson@tdk.com>
Date: Thu, 14 Aug 2025 08:57:23 +0000
Subject: [PATCH v4 9/9] MAINTAINERS: add entry for inv_icm45600 6-axis imu
 sensor
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250814-add_newport_driver-v4-9-4464b6600972@tdk.com>
References: <20250814-add_newport_driver-v4-0-4464b6600972@tdk.com>
In-Reply-To: <20250814-add_newport_driver-v4-0-4464b6600972@tdk.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, Remi Buisson <remi.buisson@tdk.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755161842; l=945;
 i=remi.buisson@tdk.com; s=20250411; h=from:subject:message-id;
 bh=8YxNmTOrgJXwqprkXECUw3/UJ3Lll4HOZd/QYkpH/Pw=;
 b=PnHrPRyoGlz9PBwE30dXa9D/cZTopUEHxiJM1dzIZEcevILmolfkMtzgXy/qoJZKRFnpYOOXq
 ao05Ai3Gm2kDJUdggm1zcgIBO1WlNYMtR8RV20VKSloZUCufwd5kNkx
X-Developer-Key: i=remi.buisson@tdk.com; a=ed25519;
 pk=yDVMi4C7RpXN4dififo42A7fDDt3THYzoZoNq9lUZuo=
X-Endpoint-Received: by B4 Relay for remi.buisson@tdk.com/20250411 with auth_id=372
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add MAINTAINERS entry for InvenSense ICM-45600 IMU device.

Signed-off-by: Remi Buisson <remi.buisson@tdk.com>
---
 MAINTAINERS | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index e3b0109a23045926d6a7e9659afdab0a6dbf7bed..c4aa2102ef398130074d20dd5b9367ce3fa51968 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -12621,6 +12621,14 @@ F:	Documentation/ABI/testing/sysfs-bus-iio-inv_icm42600
 F:	Documentation/devicetree/bindings/iio/imu/invensense,icm42600.yaml
 F:	drivers/iio/imu/inv_icm42600/
 
+INVENSENSE ICM-456xx IMU DRIVER
+M:	Remi Buisson <remi.buisson@tdk.com>
+L:	linux-iio@vger.kernel.org
+S:	Maintained
+W:	https://invensense.tdk.com/
+F:	Documentation/devicetree/bindings/iio/imu/invensense,icm45600.yaml
+F:	drivers/iio/imu/inv_icm45600/
+
 INVENSENSE MPU-3050 GYROSCOPE DRIVER
 M:	Linus Walleij <linus.walleij@linaro.org>
 L:	linux-iio@vger.kernel.org

-- 
2.34.1

