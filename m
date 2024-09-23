From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Date: Mon, 23 Sep 2024 16:53:21 +0200
Subject: [PATCH v2 1/2] dt-bindings: iio: imu: mpu6050: Add iam20680ht/hp
 bindings to mpu6050
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240923-inv-mpu6050-add-iam20680-ht-hp-v2-1-48290e0b9931@tdk.com>
References: <20240923-inv-mpu6050-add-iam20680-ht-hp-v2-0-48290e0b9931@tdk.com>
In-Reply-To: <20240923-inv-mpu6050-add-iam20680-ht-hp-v2-0-48290e0b9931@tdk.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Jean-Baptiste Maneyrol <jmaneyrol@invensense.com>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727103209; l=1050;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=ZthZoNTpOuOO9Sxm7Iz9x4o4wm0yXFBWMbSVi9NoBzI=;
 b=9NRRBdsm61njSLL+FGMFNqtKsoZxxk5X04Is3Rkh4MQV8Be8u58UIDow0kURXWFosWRtJJRFt
 QLNd/k7A5apBPS0F9AjdtHnr6PCd9AJArEo2khEkakFhGe/jsgo9+Z7
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

IAM-20680HT & HP are 2 variants of IAM-20680 fully compatible.
They just have better specs, temperature range and a bigger FIFO.

Signed-off-by: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
---
 Documentation/devicetree/bindings/iio/imu/invensense,mpu6050.yaml | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/imu/invensense,mpu6050.yaml b/Documentation/devicetree/bindings/iio/imu/invensense,mpu6050.yaml
index 587ff2bced2ddd42e767f72b8e84c334d0e90481..a8d30ef015faaca02a11af7def6e06057bde3909 100644
--- a/Documentation/devicetree/bindings/iio/imu/invensense,mpu6050.yaml
+++ b/Documentation/devicetree/bindings/iio/imu/invensense,mpu6050.yaml
@@ -36,6 +36,11 @@ properties:
       - items:
           - const: invensense,icm20608d
           - const: invensense,icm20608
+      - items:
+          - enum:
+              - invensense,iam20680hp
+              - invensense,iam20680ht
+          - const: invensense,iam20680
 
   reg:
     maxItems: 1

-- 
2.34.1

