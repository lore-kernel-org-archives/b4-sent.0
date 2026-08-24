From: Vincent Jardin <vjardin@free.fr>
Date: Tue, 25 Aug 2026 00:13:18 +0200
Subject: [PATCH v2] dt-bindings: hwmon: ti,tmp401: add
 #thermal-sensor-cells
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260825-for-upstream-dt-tmp401-vcc-tsc-v2-1-cbc360ec51d9@free.fr>
X-B4-Tracking: v=1; b=H4sIAP3BjGoC/42NQQ6CMBAAv0L27BpaC1ZO/sNwoGUrPQDNtjYaw
 t+tvMDjzGFmg0jsKUJXbcCUffTrUkCeKrDTsDwJ/VgYZC3bWkuFbmV8hZiYhhnHhGkOqhaYrcU
 ULQ6iNWT1pZGkoEQCk/PvY/DoC08+ppU/xy+Ln/07nQUKJGsacld902a8OyY6O4Z+3/cvYiyKd
 MoAAAA=
To: Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-hwmon@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787609598; l=1359;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=7IqoE5ZhPOxL10nbXpkCyJzoAu6XP+fD0RzWcN2r5M0=;
 b=FUecG8K2/KSvdtWoot2MzPZMd10LKgOCutZ3Ibve2Tw8iklA7KBFKzC4XRGE6aYixuT6MTf/B
 Fz1OS0VcCQ8B3eARhsiJ/9oMUdqm2/gFH3fTRzpYkLWuxCxgQ/Mo79q
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The property is missing, so a board that uses it with a thermal zone fails
with dtbs_check:

  tmp411@4c (ti,tmp411): '#thermal-sensor-cells' does not match any of the
  regexes: '^pinctrl-[0-9]+$'

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
Changes in v2:
- Drop vcc-supply: tmp401.c has no regulator code, every hwmon binding
  that declares vcc-supply today has a driver consuming it, so declaring it
  as description only does not belong to this patch (Sashiko)
- Adapt the commit message
- Link to v1: https://lore.kernel.org/r/20260824-for-upstream-dt-tmp401-vcc-tsc-v1-1-ecb5ef7898bd@free.fr
---
 Documentation/devicetree/bindings/hwmon/ti,tmp401.yaml | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/Documentation/devicetree/bindings/hwmon/ti,tmp401.yaml b/Documentation/devicetree/bindings/hwmon/ti,tmp401.yaml
index 0e8ddf0ad7890..f283b567d5b6c 100644
--- a/Documentation/devicetree/bindings/hwmon/ti,tmp401.yaml
+++ b/Documentation/devicetree/bindings/hwmon/ti,tmp401.yaml
@@ -50,6 +50,9 @@ properties:
     minimum: 0
     maximum: 15
 
+  "#thermal-sensor-cells":
+    const: 1
+
 allOf:
   - if:
       properties:

---
base-commit: 0a0d1d55dad570724bf8c7ea83409639cfb4be9b
change-id: 20260824-for-upstream-dt-tmp401-vcc-tsc-a16bec8352e4

Best regards,
-- 
Vincent Jardin <vjardin@free.fr>

