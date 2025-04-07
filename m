From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Date: Mon, 07 Apr 2025 21:57:16 +0200
Subject: [PATCH v2 1/2] dt-bindings: iio: imu: icm42600: add interrupt
 naming support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250407-iio-imu-inv-icm42600-rework-interrupt-using-names-v2-1-c278acf587b2@tdk.com>
References: <20250407-iio-imu-inv-icm42600-rework-interrupt-using-names-v2-0-c278acf587b2@tdk.com>
In-Reply-To: <20250407-iio-imu-inv-icm42600-rework-interrupt-using-names-v2-0-c278acf587b2@tdk.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744055845; l=1747;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=1qQnOijHkXW1Hp6AoL8pvONp5bnvT1kXFXKqEP9j4Mk=;
 b=rQ4NkV5spC2UdhZNwqF+1M9qINLIg72QUnqO0x/jde1Cheat9cnvpclLdIuncJYC7fuN/SeRn
 okKLyYxUAiFAQ5dt4TUpcNTVNqGud+ERBZtpPjFEJ6I1YmCiUxXMxT8
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add interrupt-names field for specifying interrupt used. Only INT1
is supported by the driver currently.

Add minItems 1 for interrupts since interrupt is mandatory for the driver.

Signed-off-by: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
---
 .../devicetree/bindings/iio/imu/invensense,icm42600.yaml    | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/imu/invensense,icm42600.yaml b/Documentation/devicetree/bindings/iio/imu/invensense,icm42600.yaml
index 7e4492bbd0278a336587dc5ac04da7153453da29..707f2169ce9a3ca41d81560bed15786fe010109e 100644
--- a/Documentation/devicetree/bindings/iio/imu/invensense,icm42600.yaml
+++ b/Documentation/devicetree/bindings/iio/imu/invensense,icm42600.yaml
@@ -41,6 +41,17 @@ properties:
   interrupts:
     maxItems: 1
 
+  interrupt-names:
+    minItems: 1
+    maxItems: 1
+    items:
+      enum:
+        - INT1
+        - INT2
+    description: |
+      choose chip interrupt pin to be used as interrupt input, beware that the
+      only support interrupt pin is INT1 for the moment.
+
   drive-open-drain:
     type: boolean
 
@@ -76,6 +87,7 @@ examples:
             reg = <0x68>;
             interrupt-parent = <&gpio2>;
             interrupts = <7 IRQ_TYPE_EDGE_FALLING>;
+            interrupt-names = "INT1";
             vdd-supply = <&vdd>;
             vddio-supply = <&vddio>;
         };
@@ -95,6 +107,7 @@ examples:
             spi-cpol;
             interrupt-parent = <&gpio1>;
             interrupts = <2 IRQ_TYPE_EDGE_FALLING>;
+            interrupt-names = "INT1";
             vdd-supply = <&vdd>;
             vddio-supply = <&vddio>;
         };

-- 
2.49.0

