From: George Neacsu <geocausa@gmail.com>
Date: Thu, 15 Oct 2026 22:25:09 +0100
Subject: [PATCH RFC 1/2] dt-bindings: media: sony,imx681: Allow a C-PHY bus
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261015-imx681-x1e-v1-1-fd22f5f3b0c5@gmail.com>
References: <20261015-imx681-x1e-v1-0-fd22f5f3b0c5@gmail.com>
In-Reply-To: <20261015-imx681-x1e-v1-0-fd22f5f3b0c5@gmail.com>
To: Sergey Lebedev <lsa.uz@pm.me>, 
 Andre Gilerson <andre.gilerson@gmail.com>
Cc: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bryan O'Donoghue <bod@kernel.org>, 
 German Pablo Lindo <germanpapulindez@gmail.com>, 
 linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 George Neacsu <geocausa@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792099508; l=2232;
 i=geocausa@gmail.com; s=20261015; h=from:subject:message-id;
 bh=kOFZyF2sftuWkEwjRC1kUSRJpQArgwBXcX+9V+TFh00=;
 b=GlVhz2vLlBxWU8P/XA69q8ENPtQ/nBkpo2eu7ffi/jd12L2Xm7Ky1FS+lq6kB5gS+7WCgoDmN
 /ZAZa5vxgcfCq68pFkfJPMvNdiVl5ievvf+7YyR/DZALTPNYWt6GP3L
X-Developer-Key: i=geocausa@gmail.com; a=ed25519;
 pk=KyQk/iWbxsikewDBh0SwlHI51RvAqahD3loqmRp9DVI=
X-Endpoint-Received: by B4 Relay for geocausa@gmail.com/20261015 with auth_id=1199
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On the Surface Pro 11 with a Snapdragon X Elite, the IMX681 reaches the
CAMSS CSIPHY over one MIPI C-PHY trio rather than over the two D-PHY
lanes of the Intel model. Let bus-type select C-PHY, and with it a single
data lane, keeping two D-PHY lanes as the default.

Assisted-by: Claude:claude-opus-5-5
Signed-off-by: George Neacsu <geocausa@gmail.com>
---
 .../devicetree/bindings/media/i2c/sony,imx681.yaml | 26 ++++++++++++++++++++--
 1 file changed, 24 insertions(+), 2 deletions(-)

diff --git a/Documentation/devicetree/bindings/media/i2c/sony,imx681.yaml b/Documentation/devicetree/bindings/media/i2c/sony,imx681.yaml
index 62e7eae..51256a7 100644
--- a/Documentation/devicetree/bindings/media/i2c/sony,imx681.yaml
+++ b/Documentation/devicetree/bindings/media/i2c/sony,imx681.yaml
@@ -14,8 +14,8 @@ description:
   The Sony IMX681 is a CMOS active pixel image sensor with a square pixel
   array, used as the user-facing camera on several Microsoft Surface devices.
   It operates from analog 2.8 V, digital 1.05 V and interface 1.8 V supplies,
-  is programmable over I2C, and outputs 10-bit Bayer data over a two-lane
-  MIPI CSI-2 D-PHY interface.
+  is programmable over I2C, and outputs 10-bit Bayer data over MIPI CSI-2,
+  either on two D-PHY lanes or on one C-PHY trio.
 
 allOf:
   - $ref: /schemas/media/video-interface-devices.yaml#
@@ -54,7 +54,14 @@ properties:
         unevaluatedProperties: false
 
         properties:
+          bus-type:
+            enum:
+              - 1 # MEDIA_BUS_TYPE_CSI2_CPHY
+              - 4 # MEDIA_BUS_TYPE_CSI2_DPHY
+            default: 4
+
           data-lanes:
+            minItems: 1
             items:
               - const: 1
               - const: 2
@@ -63,6 +70,21 @@ properties:
           - data-lanes
           - link-frequencies
 
+        if:
+          properties:
+            bus-type:
+              const: 1
+          required:
+            - bus-type
+        then:
+          properties:
+            data-lanes:
+              maxItems: 1
+        else:
+          properties:
+            data-lanes:
+              minItems: 2
+
     required:
       - endpoint
 

-- 
2.53.0

