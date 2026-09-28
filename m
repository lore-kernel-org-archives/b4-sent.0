From: Vincent Jardin <vjardin@free.fr>
Date: Mon, 28 Sep 2026 16:01:04 +0200
Subject: [PATCH 2/3] dt-bindings: crypto: fsl,sec-v4.0: add
 fsl,qi2-crypto-priority
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260928-for-upstream-caam-qi2-priority-v1-2-e4a8e5f01dbc@free.fr>
References: <20260928-for-upstream-caam-qi2-priority-v1-0-e4a8e5f01dbc@free.fr>
In-Reply-To: <20260928-for-upstream-caam-qi2-priority-v1-0-e4a8e5f01dbc@free.fr>
To: =?utf-8?q?Horia_Geant=C4=83?= <horia.geanta@nxp.com>, 
 Pankaj Gupta <pankaj.gupta@nxp.com>, 
 Sahil Malhotra <sahil.malhotra@nxp.com>, 
 Herbert Xu <herbert@gondor.apana.org.au>, 
 "David S. Miller" <davem@davemloft.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Gaurav Jain <gaurav.jain@nxp.com>
Cc: linux-crypto@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790604073; l=1266;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=14RLdogArJ3g8dT8zr0+nx/DICrh8YFGpKTsKBxlPRo=;
 b=bqXI0S0xMmAYCpfL9E7bpJIfPD3dsRqR1is6HT9SASQArZPs2FLs90E4sdi0mQY/3J9mKbaI6
 Ca54EWx4dGfCChneC+MS83wXOkm8L7QxXggVvftV3/5c/EbFQRV5lMQ
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Let a board set the crypto API priority of the algorithms the DPAA2
front end (dpaa2_caam) registers.

Benefits: Its DTS decides whether the SEC or the CPU is the default for
in-kernel crypto.

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
 Documentation/devicetree/bindings/crypto/fsl,sec-v4.0.yaml | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/Documentation/devicetree/bindings/crypto/fsl,sec-v4.0.yaml b/Documentation/devicetree/bindings/crypto/fsl,sec-v4.0.yaml
index dcc755d2709a..0231fe3853b0 100644
--- a/Documentation/devicetree/bindings/crypto/fsl,sec-v4.0.yaml
+++ b/Documentation/devicetree/bindings/crypto/fsl,sec-v4.0.yaml
@@ -86,6 +86,15 @@ properties:
     description: Defines the 'ERA' of the SEC device.
     $ref: /schemas/types.yaml#/definitions/uint32
 
+  fsl,qi2-crypto-priority:
+    description:
+      Crypto API priority of the algorithms the DPAA2 (QI2) front end
+      registers. Below the CPU's own implementations, the SEC is used only
+      when asked for by driver name. The dpaa2_caam.priority module
+      parameter overrides it.
+    $ref: /schemas/types.yaml#/definitions/uint32
+    default: 2000
+
 patternProperties:
   '^jr@[0-9a-f]+$':
     type: object

-- 
2.43.0

