From: Vincent Jardin <vjardin@free.fr>
Date: Mon, 24 Aug 2026 17:46:36 +0200
Subject: [PATCH] dt-bindings: hwmon: ti,tmp401: add vcc-supply and
 #thermal-sensor-cells
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260824-for-upstream-dt-tmp401-vcc-tsc-v1-1-ecb5ef7898bd@free.fr>
X-B4-Tracking: v=1; b=H4sIAFtnjGoC/x3NwQqDMAyA4VeRnBdou07EV5EdaoxbDmpJqgjiu
 6/s+F3+/wJjFTbomwuUDzHZ1gr/aIC+af0wylQNwYXWdSHivCnu2YpyWnAqWJYcnceDCIsRJt+
 OTN3zFThCjWTlWc7/YHjf9w+FU6QHcAAAAA==
To: Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-hwmon@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787586398; l=1364;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=P+vvtVa9Xt5cHsZaKRS93Aih5rhUVfFYRpn5jmhnpxM=;
 b=tyqh1tD1gWbAy0YYrloa/Zvko1FEsMvJGZPig0Y/hhR72qRY3lPu+U5Y750Qap2yS7PRxopyL
 C4Cmwnwe4M1DBtU9GERurozcJpLm4wnr/e1mcojtfHCg4rkRugJwSh9
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Both properties are used by the driver that backs this binding, and
neither is described, so a board that supplies either fails dtbs_check:

  tmp411@4c (ti,tmp411): '#thermal-sensor-cells', 'vcc-supply' do not
  match any of the regexes: '^pinctrl-[0-9]+$'

vcc-supply is fetched in lm90_probe():

  drivers/hwmon/lm90.c:2777
        err = devm_regulator_get_enable(dev, "vcc");

so a board with the sensor behind a switched rail has no other way to
describe it, and omitting it means the chip is probed with its supply
possibly off.

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
 Documentation/devicetree/bindings/hwmon/ti,tmp401.yaml | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/Documentation/devicetree/bindings/hwmon/ti,tmp401.yaml b/Documentation/devicetree/bindings/hwmon/ti,tmp401.yaml
index 0e8ddf0ad7890..69f77aec01a33 100644
--- a/Documentation/devicetree/bindings/hwmon/ti,tmp401.yaml
+++ b/Documentation/devicetree/bindings/hwmon/ti,tmp401.yaml
@@ -50,6 +50,11 @@ properties:
     minimum: 0
     maximum: 15
 
+  vcc-supply: true
+
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

