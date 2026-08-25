From: Vincent Jardin <vjardin@free.fr>
Date: Tue, 25 Aug 2026 11:41:57 +0200
Subject: [PATCH v3] dt-bindings: gpio: fsl,qoriq-gpio: allow gpio-hog child
 nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260825-for-upstream-dt-qoriq-gpio-hog-v3-1-b99bda4f44d7@free.fr>
X-B4-Tracking: v=1; b=H4sIAGRjjWoC/5XNOxKCMBSF4a0wqb1OCKDByn04FnncQAoJ3GBGh
 2HvBhpbLf9TfGdhEcljZJdiYYTJRx+GHNWhYKZXQ4fgbW4muDhxKWpwgeA5xplQPcDOMAXyE3S
 jD9CHDhreCsVdbblsWUZGQudf+8Htnrv3cQ703v9Sua0/06mEEuy5aUWlDRplr44Qj47YBifxH
 yYy1kitjRRayhK/2LquH4rh2OAXAQAA
To: Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Frank Li <Frank.Li@nxp.com>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Alexander Stein <alexander.stein@ew.tq-group.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787650917; l=1854;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=0aUt4yW36dUGRIwt7A7v+to/nNSwTzzg2q1QEySGXKY=;
 b=zGwXo46K0v1/ao7QgvXl1HZAZNNOzJg/2a3Akb69xALbYZURxU4pC2oco3ldfdEPyrHwGKtQp
 CH8atLhhJ5WC/EZZ2R/fP3HFQhZLQCffXiWnqrVecI7GKp0r7nRtUmn
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

QorIQ GPIO controllers may have hogs in device nodes, so let's expose
it.

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
Changes in v3:
- Shorten the commit message, former one tried too much on QorIQ (Krzysztof Kozlowski)
- Drop redundant brackets from the pattern (Krzysztof Kozlowski)
- No change to the schema semantics
- Link to v2: https://lore.kernel.org/r/20260824-for-upstream-dt-qoriq-gpio-hog-v2-1-58bbc82b881e@free.fr

Changes in v2:
- Change the commit message. Drop the dmesg excerpt: those hog names come
  from my out-of-tree dev git repo and are not in the tree (Frank Li)
- Note: the hog call path is: gpiochip_hog_lines(), called from gpiochip_add_data_with_key()
- Explain why these QorIQ SoCs need it
- No change to the diff
- Link to v1: https://lore.kernel.org/r/20260824-for-upstream-dt-qoriq-gpio-hog-v1-1-d75923bcecad@free.fr
---
 Documentation/devicetree/bindings/gpio/fsl,qoriq-gpio.yaml | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/Documentation/devicetree/bindings/gpio/fsl,qoriq-gpio.yaml b/Documentation/devicetree/bindings/gpio/fsl,qoriq-gpio.yaml
index 4cb2a6b9fabfb..1e61e17b0ee35 100644
--- a/Documentation/devicetree/bindings/gpio/fsl,qoriq-gpio.yaml
+++ b/Documentation/devicetree/bindings/gpio/fsl,qoriq-gpio.yaml
@@ -63,6 +63,13 @@ properties:
       GPIO registers are used as little endian. If not
       present registers are used as big endian by default.
 
+patternProperties:
+  "^.+-hog(-[0-9]+)?$":
+    type: object
+
+    required:
+      - gpio-hog
+
 required:
   - compatible
   - reg

---
base-commit: 0a0d1d55dad570724bf8c7ea83409639cfb4be9b
change-id: 20260824-for-upstream-dt-qoriq-gpio-hog-5092a0f4d089

Best regards,
-- 
Vincent Jardin <vjardin@free.fr>

