From: Remi Buisson <remi.buisson@tdk.com>
Date: Tue, 07 Oct 2025 07:20:10 +0000
Subject: [PATCH v7 9/9] MAINTAINERS: add entry for inv_icm45600 6-axis imu
 sensor
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251007-add_newport_driver-v7-9-137223a1f79e@tdk.com>
References: <20251007-add_newport_driver-v7-0-137223a1f79e@tdk.com>
In-Reply-To: <20251007-add_newport_driver-v7-0-137223a1f79e@tdk.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, Remi Buisson <remi.buisson@tdk.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1759821607; l=945;
 i=remi.buisson@tdk.com; s=20250411; h=from:subject:message-id;
 bh=d1EOGq7hV4R8ODh9Pkno9yFBZYn1snN6feaEcuqfxYw=;
 b=tKrTxuseMaAskCaKxAZPF8nMN0Z5k6k74/sZWArRLHJ27luTecHTDRrRn1P3eMZT8RdKsk0NM
 0pyETsL6HUZB8yE9lFbOsWrOpuwjdYm2mz5CQITKoG7ZXzem+klS6Q+
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
index f090c2f6e63a0d255a025885cc4573f5802ef159..02d8787ab768a2d0b8b72a2c909e56a0f2010c04 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -12815,6 +12815,14 @@ F:	Documentation/ABI/testing/sysfs-bus-iio-inv_icm42600
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

