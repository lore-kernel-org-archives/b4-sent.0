From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Sat, 18 Jul 2026 19:06:29 +0200
Subject: [PATCH 1/5] dt-bindings: usb: parade,ps8830: Add
 parade,disable-usb4 property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260718-ps883x-disable-usb4-v1-1-cec86d0b909e@oldschoolsolutions.biz>
References: <20260718-ps883x-disable-usb4-v1-0-cec86d0b909e@oldschoolsolutions.biz>
In-Reply-To: <20260718-ps883x-disable-usb4-v1-0-cec86d0b909e@oldschoolsolutions.biz>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-usb@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 stable@vger.kernel.org, "Dr. David Alan Gilbert" <dave@treblig.org>, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784394390; l=1158;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=yrl6VP90X+qBDgzq2kPIZXWW8gy8rpei3j/WcM153qs=;
 b=6G4y8ZLykC2QUUG4dfWiXI32wWerJe6esfFw3KbJfJZLUiI4JDqQYl/7mj88BqmQqJssaMILn
 21ybx/ri+6fDQP7ERROm3WUmrOprk1reEvYPHWR76UqnDwVSutt4EJ2
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document a new optional boolean property "parade,disable-usb4".
When present, the retimer rejects USB4 mode by returning -EOPNOTSUPP,
forcing a fallback to USB3 + DP Alternate Mode.

Assisted-by: Grok(xAI):4.3
Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 Documentation/devicetree/bindings/usb/parade,ps8830.yaml | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/Documentation/devicetree/bindings/usb/parade,ps8830.yaml b/Documentation/devicetree/bindings/usb/parade,ps8830.yaml
index eaeab1c01a594..44242907461eb 100644
--- a/Documentation/devicetree/bindings/usb/parade,ps8830.yaml
+++ b/Documentation/devicetree/bindings/usb/parade,ps8830.yaml
@@ -66,6 +66,12 @@ properties:
           Sideband Use (SBU) AUX lines endpoint to the Type-C connector for the purpose of
           handling altmode muxing and orientation switching.
 
+  parade,disable-usb4:
+    type: boolean
+    description:
+      When present, the retimer rejects USB4 mode (returns -EOPNOTSUPP).
+      This forces the Type-C stack to fall back to USB3 + DP Alternate Mode.
+
 required:
   - compatible
   - reg

-- 
2.53.0

