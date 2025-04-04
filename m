From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Date: Fri, 04 Apr 2025 17:52:02 +0200
Subject: [PATCH 1/2] dt-bindings: iio: imu: icm42600: add interrupt naming
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250404-iio-imu-inv-icm42600-rework-interrupt-using-names-v1-1-72ed5100da14@tdk.com>
References: <20250404-iio-imu-inv-icm42600-rework-interrupt-using-names-v1-0-72ed5100da14@tdk.com>
In-Reply-To: <20250404-iio-imu-inv-icm42600-rework-interrupt-using-names-v1-0-72ed5100da14@tdk.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1743781928; l=1440;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=X6P4YWLOlhlgH2oiySbrJcpFo5s9IL+DV66p+lLJcwY=;
 b=66OyozigM0/WCOaWLAve7lw3hDs54rZl+Te4eTcUVidKMgfkDjV+WDram63arJQQnyEL+RYWZ
 kdsrqtTRJJBBjPKfGcFfT3NRzUt4UiFuzvdV4AZqkptjHcxOFVBkmme
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add interrupt-names field for specifying interrupt used.
Only INT1 is supported by the driver currently.
---
 .../devicetree/bindings/iio/imu/invensense,icm42600.yaml          | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/imu/invensense,icm42600.yaml b/Documentation/devicetree/bindings/iio/imu/invensense,icm42600.yaml
index 7e4492bbd0278a336587dc5ac04da7153453da29..f19cdfd7450e04e7c984dc987f3c23f5ad89a248 100644
--- a/Documentation/devicetree/bindings/iio/imu/invensense,icm42600.yaml
+++ b/Documentation/devicetree/bindings/iio/imu/invensense,icm42600.yaml
@@ -41,6 +41,12 @@ properties:
   interrupts:
     maxItems: 1
 
+  interrupt-names:
+    enum:
+      - INT1
+    description: |
+      set to "INT1" the only supported interrupts pin
+
   drive-open-drain:
     type: boolean
 
@@ -76,6 +82,7 @@ examples:
             reg = <0x68>;
             interrupt-parent = <&gpio2>;
             interrupts = <7 IRQ_TYPE_EDGE_FALLING>;
+            interrupt-names = "INT1";
             vdd-supply = <&vdd>;
             vddio-supply = <&vddio>;
         };
@@ -95,6 +102,7 @@ examples:
             spi-cpol;
             interrupt-parent = <&gpio1>;
             interrupts = <2 IRQ_TYPE_EDGE_FALLING>;
+            interrupt-names = "INT1";
             vdd-supply = <&vdd>;
             vddio-supply = <&vddio>;
         };

-- 
2.49.0

