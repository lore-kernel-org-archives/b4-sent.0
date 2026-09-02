From: Vincent Jardin <vjardin@free.fr>
Date: Wed, 02 Sep 2026 03:54:00 +0200
Subject: [PATCH v3] dt-bindings: hwmon: ti,tmp401: add
 #thermal-sensor-cells
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260902-for-upstream-dt-tmp401-vcc-tsc-v3-1-49c484d2f08b@free.fr>
X-B4-Tracking: v=1; b=H4sIALeBl2oC/43NvQ7CIBSG4VtpmD0GaKmtk/dhHMrhYBn6E0Cia
 Xrv0i666fh+w/MtLJB3FNi5WJin5IKbxhzloWDYd+OdwJncTHJZ80ZWYCcPjzlET90AJkIc5oo
 LSIgQA0Inak3YlEpSxTIye7LuuR9cb7l7F+LkX/tfEtv6N50ECCDUiuypaRttLtYTHa1nG5zkN
 6Z+YjJjqLGsOaESpv1g67q+AR7SCHoXAQAA
To: Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-hwmon@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788314042; l=1832;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=7R3pcu6eseDa7fzzVvZHfd5ptFboQq6wZTkdZSwBKr4=;
 b=ifr4eNv2wadubCmVyxfaX6jr9pERAMOm+qJqkhJXZlWlgfvo3mfSl/ukqc5N9ujyID5g7C0/R
 pdRNAGAXfLlB+KBbo2B4GDjVmHwkiH5WvytTVm52ut5QMCGvt0hUvSh
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit
  a3b61ba2558e ("hwmon: (tmp401) register with thermal subsystem")
the driver sets HWMON_C_REGISTER_TZ, so the hwmon core calls
devm_thermal_of_zone_register() for every temperature channel and the
device can be referenced as a thermal sensor.

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
Changes in v3:
- Rewrite the commit message: justify the property from the driver,
  which sets HWMON_C_REGISTER_TZ since a3b61ba2558e
  (Krzysztof Kozlowski)
- Keep "const: 1": every chip in this binding has at least two
  temperature channels, see national,lm90.yaml
- No change to the diff/code
- Link to v2: https://lore.kernel.org/r/20260825-for-upstream-dt-tmp401-vcc-tsc-v2-1-cbc360ec51d9@free.fr

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
base-commit: 89a312991dc6e638a36adc43ccb91dbc25504c04
change-id: 20260824-for-upstream-dt-tmp401-vcc-tsc-a16bec8352e4

Best regards,
-- 
Vincent Jardin <vjardin@free.fr>

