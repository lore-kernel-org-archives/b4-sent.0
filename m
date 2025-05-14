From: Alejandro Enrique <alejandroe1@geotab.com>
Date: Wed, 14 May 2025 13:55:54 +0200
Subject: [PATCH 1/2] dt-bindings: gnss: add u-blox,neo-9m compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250514-ubx-m9-v1-1-193973a4f3ca@geotab.com>
References: <20250514-ubx-m9-v1-0-193973a4f3ca@geotab.com>
In-Reply-To: <20250514-ubx-m9-v1-0-193973a4f3ca@geotab.com>
To: Johan Hovold <johan@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Alejandro Enrique <alejandroe1@geotab.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747223768; l=746;
 i=alejandroe1@geotab.com; s=20250514; h=from:subject:message-id;
 bh=3xJpnPbRisAKL2+dPmneQBdkYHGq5g2cneB0rP+Fuic=;
 b=63IpCvQdkbBYkX0QTX0yjWJPaRm8LjZ6cUlPCKhvTUdIEoLLNVv0Vw08upHRK3rV/fghhc+QD
 Q1JftRbJlOlCW3069s5l46Y8yLR1FmfPU4uVd/P9BCdocsGqBINdEjE
X-Developer-Key: i=alejandroe1@geotab.com; a=ed25519;
 pk=xzHMPbqczL/tMsjXr26iLoHwIzLveHVnT+GIU4p1k38=
X-Endpoint-Received: by B4 Relay for alejandroe1@geotab.com/20250514 with auth_id=404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add compatible for u-blox NEO-9M GPS module.

Signed-off-by: Alejandro Enrique <alejandroe1@geotab.com>
---
 Documentation/devicetree/bindings/gnss/u-blox,neo-6m.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/gnss/u-blox,neo-6m.yaml b/Documentation/devicetree/bindings/gnss/u-blox,neo-6m.yaml
index 7d4b6d49e5eea2201ac05ba6d54b1c1721172f26..cf5ff051b9ab03e5bfed8156a72170965929bb7e 100644
--- a/Documentation/devicetree/bindings/gnss/u-blox,neo-6m.yaml
+++ b/Documentation/devicetree/bindings/gnss/u-blox,neo-6m.yaml
@@ -22,6 +22,7 @@ properties:
       - u-blox,neo-6m
       - u-blox,neo-8
       - u-blox,neo-m8
+      - u-blox,neo-m9
 
   reg:
     description: >

-- 
2.34.1

