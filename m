From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Fri, 18 Sep 2026 16:57:16 +0800
Subject: [PATCH 01/21] media: dt-bindings: ite,it6625: document the default
 CSI-2 bus type
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260918-upstream-it6625-follow-up-patch-v1-1-78d72d7886a5@ite.com.tw>
References: <20260918-upstream-it6625-follow-up-patch-v1-0-78d72d7886a5@ite.com.tw>
In-Reply-To: <20260918-upstream-it6625-follow-up-patch-v1-0-78d72d7886a5@ite.com.tw>
To: Hermes Wu <Hermes.Wu@ite.com.tw>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789721837; l=1548;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=9JG2gnHxv5HEk2OflV4GnhtoGwENcuutmXv8NLZl2zU=;
 b=2+6GDfh7bjm2quDcWDEExkXG0+2/O5n/T5weM/DqTYqUWm4G/Xgsyr3lIKcXiXqd9AFif6Srj
 0RilO9sog2cBrts5V5y1zGd2ZyCA53rP1Ev1FVXxSBCdmrNpuG1EYgp
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

