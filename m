From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Date: Thu, 10 Apr 2025 17:39:40 +0200
Subject: [PATCH v4 1/2] dt-bindings: iio: imu: icm42600: add interrupt
 naming support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250410-iio-imu-inv-icm42600-rework-interrupt-using-names-v4-1-19e4e2f8f7eb@tdk.com>
References: <20250410-iio-imu-inv-icm42600-rework-interrupt-using-names-v4-0-19e4e2f8f7eb@tdk.com>
In-Reply-To: <20250410-iio-imu-inv-icm42600-rework-interrupt-using-names-v4-0-19e4e2f8f7eb@tdk.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744299633; l=1667;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=VSawZ1o/QxRqL4fWVfjdTFoB12VpEf7tP4qn663WfY4=;
 b=gUvwd/ULfhOmpGyt3CLCntXqU0MwammUU8dArCBjf2oGClGJdG0UkKE91jcnvQCFuNMA+oEJL
 g+3L8Ye1gzzCR9FBmWseJTNowQooT6CXGFVVQwKujx36Ze02YmmyqMx
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add interrupt-names field for specifying interrupt pin configured.

Chips are supporting up to 2 interrupt pins with configurable interrupt
sources. Change interrupt to support 1 or 2 entries.

Signed-off-by: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
---
 .../devicetree/bindings/iio/imu/invensense,icm42600.yaml    | 13 ++++++++++++-
 1 file changed, 12 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/iio/imu/invensense,icm42600.yaml b/Documentation/devicetree/bindings/iio/imu/invensense,icm42600.yaml
index 7e4492bbd0278a336587dc5ac04da7153453da29..d4d4e5c3d8562523872a737864610c26c8fccd82 100644
--- a/Documentation/devicetree/bindings/iio/imu/invensense,icm42600.yaml
+++ b/Documentation/devicetree/bindings/iio/imu/invensense,icm42600.yaml
@@ -39,7 +39,16 @@ properties:
     maxItems: 1
 
   interrupts:
-    maxItems: 1
+    minItems: 1
+    maxItems: 2
+
+  interrupt-names:
+    minItems: 1
+    maxItems: 2
+    items:
+      enum:
+        - INT1
+        - INT2
 
   drive-open-drain:
     type: boolean
@@ -76,6 +85,7 @@ examples:
             reg = <0x68>;
             interrupt-parent = <&gpio2>;
             interrupts = <7 IRQ_TYPE_EDGE_FALLING>;
+            interrupt-names = "INT1";
             vdd-supply = <&vdd>;
             vddio-supply = <&vddio>;
         };
@@ -95,6 +105,7 @@ examples:
             spi-cpol;
             interrupt-parent = <&gpio1>;
             interrupts = <2 IRQ_TYPE_EDGE_FALLING>;
+            interrupt-names = "INT1";
             vdd-supply = <&vdd>;
             vddio-supply = <&vddio>;
         };

-- 
2.49.0

