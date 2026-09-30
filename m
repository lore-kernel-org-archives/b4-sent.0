From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Wed, 30 Sep 2026 14:41:19 +0800
Subject: [PATCH v2 01/21] dt-bindings: media: ite,it6625: document the
 default CSI-2 bus type
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260930-upstream-it6625-follow-up-patch-v2-1-e353f887e7fa@ite.com.tw>
References: <20260930-upstream-it6625-follow-up-patch-v2-0-e353f887e7fa@ite.com.tw>
In-Reply-To: <20260930-upstream-it6625-follow-up-patch-v2-0-e353f887e7fa@ite.com.tw>
To: Hermes Wu <Hermes.Wu@ite.com.tw>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>
Cc: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790750567; l=1595;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=2GNSGI/SvJJnKRdKfmcthbKtRJOxkaKnD5LBk104cW0=;
 b=gmcEUkr92KQXRx+94bsEWoxMUYXEWR8pqxzO3eQKln5bydnrweTsoFcTTwt9Rl3UGxhliH6aG
 NrcDnbc3g8ZDQHFtKFDjZ/TZTK3n8Z4CiCT8qluKy2rJQVpS6SWO1X7
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

bus-type is optional under port@0 and port@1's endpoint for ite,it6625
(the allOf/if/then clause only requires it for ite,it6626, which
supports both C-PHY and D-PHY and needs disambiguation). With bus-type
omitted, the actual runtime default is D-PHY:
v4l2_fwnode_endpoint_parse_csi2_bus() falls back to
V4L2_MBUS_CSI2_DPHY whenever data-lanes is present, which this binding
already requires. Document that default explicitly instead of leaving
it unstated.

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
Acked-by: Rob Herring (Arm) <robh@kernel.org>
---
 Documentation/devicetree/bindings/media/i2c/ite,it6625.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/media/i2c/ite,it6625.yaml b/Documentation/devicetree/bindings/media/i2c/ite,it6625.yaml
index 756fe655f534f85b23b7741d06710c956f9694d8..9b621f726249189255692da02049ebcbf1d5b43c 100644
--- a/Documentation/devicetree/bindings/media/i2c/ite,it6625.yaml
+++ b/Documentation/devicetree/bindings/media/i2c/ite,it6625.yaml
@@ -65,6 +65,7 @@ properties:
                 enum:
                   - 1 # MEDIA_BUS_TYPE_CSI2_CPHY
                   - 4 # MEDIA_BUS_TYPE_CSI2_DPHY
+                default: 4 # MEDIA_BUS_TYPE_CSI2_DPHY
 
             required:
               - data-lanes
@@ -88,6 +89,7 @@ properties:
                 enum:
                   - 1 # MEDIA_BUS_TYPE_CSI2_CPHY
                   - 4 # MEDIA_BUS_TYPE_CSI2_DPHY
+                default: 4 # MEDIA_BUS_TYPE_CSI2_DPHY
 
             required:
               - data-lanes

-- 
2.34.1

