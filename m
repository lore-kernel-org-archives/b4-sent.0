From: Vincent Jardin <vjardin@free.fr>
Date: Fri, 24 Jul 2026 01:09:12 +0200
Subject: [PATCH 1/2] dt-bindings: dpll: zl3073x: add ZL30643 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260724-for-upstream-zl30643-v1-1-ea93ba4d85c8@free.fr>
References: <20260724-for-upstream-zl30643-v1-0-ea93ba4d85c8@free.fr>
In-Reply-To: <20260724-for-upstream-zl30643-v1-0-ea93ba4d85c8@free.fr>
To: Ivan Vecera <ivecera@redhat.com>, 
 Prathosh Satish <Prathosh.Satish@microchip.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Vadim Fedorenko <vadim.fedorenko@linux.dev>, 
 Arkadiusz Kubalewski <arkadiusz.kubalewski@intel.com>, 
 Jiri Pirko <jiri@resnulli.us>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784848154; l=819;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=Dlh4xhCfEnokysm2lyYGJyxT/l4Fz9ZHB7O0gaUNLfE=;
 b=fYEvgmTReR29OMQGo4G0nw6hXS0kUMbVhtMfHuwyddR0FAMgXbtfyuDiUHybBbD/e4Cr0kysD
 K+NeFJmlg1jBu0LZoVZjn13yS7w2dxoOKUn2dBNBcx7IdTWXjB6i/2b
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Microchip ZL30643 (chip ID 0x0E3B) is a 3 DPLL channel member
of the ZL3073x family. Add its compatible string to the binding enum.

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
 Documentation/devicetree/bindings/dpll/microchip,zl30731.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/dpll/microchip,zl30731.yaml b/Documentation/devicetree/bindings/dpll/microchip,zl30731.yaml
index fa5a8f8e390c..13ea55c2c146 100644
--- a/Documentation/devicetree/bindings/dpll/microchip,zl30731.yaml
+++ b/Documentation/devicetree/bindings/dpll/microchip,zl30731.yaml
@@ -18,6 +18,7 @@ description:
 properties:
   compatible:
     enum:
+      - microchip,zl30643
       - microchip,zl30731
       - microchip,zl30732
       - microchip,zl30733

-- 
2.43.0

