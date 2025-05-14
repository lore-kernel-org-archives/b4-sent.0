From: Alejandro Enrique <alejandroe1@geotab.com>
Date: Wed, 14 May 2025 15:54:41 +0200
Subject: [PATCH 1/2] dt-bindings: gnss: u-blox: add "safeboot-gpios"
 binding
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250514-ubx-safeboot-v1-1-1ae771335356@geotab.com>
References: <20250514-ubx-safeboot-v1-0-1ae771335356@geotab.com>
In-Reply-To: <20250514-ubx-safeboot-v1-0-1ae771335356@geotab.com>
To: Johan Hovold <johan@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Alejandro Enrique <alejandroe1@geotab.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747230900; l=1203;
 i=alejandroe1@geotab.com; s=20250514; h=from:subject:message-id;
 bh=BxkYd/2jGt2UwnlIuZQlH4ljP/UW6C5OfMYMSn4bkPk=;
 b=wzJsfMUDFEUX3vvMjMqmR/SPpPnEQ67e+HbfeA0b/2D6NioGz9QHUtye9B5Ppld6BWafjefvl
 rfSa8Q3RBJ/AxNlRJIwpBHiNM51jwtmz9JMynDcssJC0y/A/MsbfDbF
X-Developer-Key: i=alejandroe1@geotab.com; a=ed25519;
 pk=xzHMPbqczL/tMsjXr26iLoHwIzLveHVnT+GIU4p1k38=
X-Endpoint-Received: by B4 Relay for alejandroe1@geotab.com/20250514 with auth_id=404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

U-Blox M8/M9 chip have a pin to start it in safeboot mode, to be used
to recover from situations where the flash content has become
corrupted and needs to be restored. Introduce a binding to support
this safeboot pin.

Signed-off-by: Alejandro Enrique <alejandroe1@geotab.com>
---
 Documentation/devicetree/bindings/gnss/u-blox,neo-6m.yaml | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/Documentation/devicetree/bindings/gnss/u-blox,neo-6m.yaml b/Documentation/devicetree/bindings/gnss/u-blox,neo-6m.yaml
index 7d4b6d49e5eea2201ac05ba6d54b1c1721172f26..16d922279def99257c194520a7ac820f2a26e9c7 100644
--- a/Documentation/devicetree/bindings/gnss/u-blox,neo-6m.yaml
+++ b/Documentation/devicetree/bindings/gnss/u-blox,neo-6m.yaml
@@ -32,6 +32,9 @@ properties:
   reset-gpios:
     maxItems: 1
 
+  safeboot-gpios:
+    maxItems: 1
+
   vcc-supply:
     description: >
       Main voltage regulator
@@ -61,5 +64,6 @@ examples:
             v-bckp-supply = <&gnss_v_bckp_reg>;
             vcc-supply = <&gnss_vcc_reg>;
             reset-gpios = <&gpio 1 GPIO_ACTIVE_LOW>;
+            safeboot-gpios = <&gpio 2 GPIO_ACTIVE_LOW>;
         };
     };

-- 
2.34.1

