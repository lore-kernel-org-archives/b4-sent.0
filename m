From: Dumitru Ceclan <dumitru.ceclan@analog.com>
Date: Tue, 04 Aug 2026 11:49:52 +0300
Subject: [PATCH v14 09/22] dt-bindings: media: i2c: max96712: add support
 for MAX96724F/R
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260804-gmsl2-3_serdes-v14-9-763710c884c0@analog.com>
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
 Cosmin Tanislav <demonsingur@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785833430; l=1289;
 i=dumitru.ceclan@analog.com; s=20240313; h=from:subject:message-id;
 bh=ZSTakNbBz4Qus1NiPPbe76vFnVEQ3NLtF7fl+Vgxvf8=;
 b=1zp+vd1f8dmxcPvdYuGLTw3WjF2wGG8yRACmaOzzU790nkLP2tfHA/TeQT5yJobcalXK+z5vi
 SsJnWnPx5RBAbZ9MIkaSrMdWYE1SKyc9xAcsitRp4Jh2NgepinmU3ef
X-Developer-Key: i=dumitru.ceclan@analog.com; a=ed25519;
 pk=HdqMlVyrcazwoiai7oN6ghU+Bj1pusGUFRl30jhS7Bo=
X-Endpoint-Received: by B4 Relay for dumitru.ceclan@analog.com/20240313 with auth_id=140
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Cosmin Tanislav <demonsingur@gmail.com>

MAX96724F/MAX96724R are a lower capability variant of the MAX96724 which
only support a fixed rate of 3Gbps in the forward direction.

Signed-off-by: Cosmin Tanislav <demonsingur@gmail.com>
Acked-by: Rob Herring (Arm) <robh@kernel.org>
Reviewed-by: Niklas Söderlund <niklas.soderlund+renesas@ragnatech.se>
---
 Documentation/devicetree/bindings/media/i2c/maxim,max96712.yaml | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/Documentation/devicetree/bindings/media/i2c/maxim,max96712.yaml b/Documentation/devicetree/bindings/media/i2c/maxim,max96712.yaml
index d2dd72f2e924..161d40acdd28 100644
--- a/Documentation/devicetree/bindings/media/i2c/maxim,max96712.yaml
+++ b/Documentation/devicetree/bindings/media/i2c/maxim,max96712.yaml
@@ -23,12 +23,17 @@ description: |
   MAX96712 can be paired with first-generation 3.12Gbps or 1.5Gbps GMSL1
   serializers or operate up to 3.12Gbps with GMSL2 serializers in GMSL1 mode.
 
+  MAX96724F and MAX96724R only support a fixed rate of 3Gbps in the forward
+  direction.
+
 properties:
   compatible:
     items:
       - enum:
           - maxim,max96712
           - maxim,max96724
+          - maxim,max96724f
+          - maxim,max96724r
 
   reg:
     description: I2C device address

-- 
2.53.0

