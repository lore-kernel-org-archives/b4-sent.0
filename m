From: Dumitru Ceclan <dumitru.ceclan@analog.com>
Date: Tue, 04 Aug 2026 11:49:53 +0300
Subject: [PATCH v14 10/22] dt-bindings: media: i2c: max96712: add
 control-channel-port property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260804-gmsl2-3_serdes-v14-10-763710c884c0@analog.com>
References: <20260804-gmsl2-3_serdes-v14-0-763710c884c0@analog.com>
In-Reply-To: <20260804-gmsl2-3_serdes-v14-0-763710c884c0@analog.com>
To: Tomi Valkeinen <tomi.valkeinen+renesas@ideasonboard.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Julien Massot <julien.massot@collabora.com>, Rob Herring <robh@kernel.org>, 
 =?utf-8?q?Niklas_S=C3=B6derlund?= <niklas.soderlund@ragnatech.se>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: mitrutzceclan@gmail.com, linux-media@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-staging@lists.linux.dev, linux-gpio@vger.kernel.org, 
 =?utf-8?q?Niklas_S=C3=B6derlund?= <niklas.soderlund+renesas@ragnatech.se>, 
 Martin Hecht <Martin.Hecht@avnet.eu>, 
 Vivekananda Dayananda <vivekana@amd.com>, 
 Dumitru Ceclan <dumitru.ceclan@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785833430; l=1210;
 i=dumitru.ceclan@analog.com; s=20240313; h=from:subject:message-id;
 bh=zHQWciR44LLL2n9JRuufsEezIBfNdUsq5fR2eFezGHc=;
 b=JVYhaLCC7VJh8CuG+Gh9lha1FWZE51cGaxuWoo3SnlfYnUHFpF79LXwA4ghCIUKg5w3C9+ulD
 2DMqyv90Ze9DubBJtw11TZJ/qccq5fP/Jndp/FByD8l+PqEsIM7lRdX
X-Developer-Key: i=dumitru.ceclan@analog.com; a=ed25519;
 pk=HdqMlVyrcazwoiai7oN6ghU+Bj1pusGUFRl30jhS7Bo=
X-Endpoint-Received: by B4 Relay for dumitru.ceclan@analog.com/20240313 with auth_id=140
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add maxim,control-channel-port property to allow platforms choose which
control-channel port MAX96724 exposes to the upstream I2C host.

Suggested-by: Vivekananda Dayananda <vivekana@amd.com>
Signed-off-by: Dumitru Ceclan <dumitru.ceclan@analog.com>
Acked-by: Rob Herring (Arm) <robh@kernel.org>
---
 Documentation/devicetree/bindings/media/i2c/maxim,max96712.yaml | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/Documentation/devicetree/bindings/media/i2c/maxim,max96712.yaml b/Documentation/devicetree/bindings/media/i2c/maxim,max96712.yaml
index 161d40acdd28..ab1dcd8ff8e7 100644
--- a/Documentation/devicetree/bindings/media/i2c/maxim,max96712.yaml
+++ b/Documentation/devicetree/bindings/media/i2c/maxim,max96712.yaml
@@ -41,6 +41,15 @@ properties:
 
   enable-gpios: true
 
+  maxim,control-channel-port:
+    description:
+      Selects which deserializer control-channel port is connected to the
+      upstream I2C segment when the device resets. 0 selects port 0, 1 selects
+      port 1. Defaults to 0 when omitted.
+    $ref: /schemas/types.yaml#/definitions/uint32
+    enum: [0, 1]
+    default: 0
+
   i2c-alias-pool:
     maxItems: 4
 

-- 
2.53.0

