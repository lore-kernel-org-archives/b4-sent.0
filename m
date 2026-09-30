From: Vincent Jardin <vjardin@free.fr>
Date: Wed, 30 Sep 2026 15:56:41 +0200
Subject: [PATCH] dt-bindings: hwmon: pmbus: mps,mpq8785: add
 #thermal-sensor-cells
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260930-for-upstream-dt-mpq8785-thermal-sensor-cells-v1-1-6573c765eef8@free.fr>
X-B4-Tracking: v=1; b=H4sIABgVvWoC/x2NQQrDIBAAvxL23AWbNpr2K6EH0bUR1NhdWwohf
 6/0ODDM7CDEkQTuww5MnyhxKx3OpwHcasuTMPrOMKpRq9tFYdgY31Uak83oG+b6ms08YVuJs00
 oVKQrjlISdMYEq72drkpDT1amEL//3fI4jh+/nZ1xfgAAAA==
To: Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Charles Hsu <ythsu0511@gmail.com>
Cc: linux-hwmon@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790776603; l=1384;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=fJu0E0lhwn4WY7ROYdjtoIwXJWiiVnoOzna2Uqs/R6o=;
 b=S6v23x2y4mhv6bbX+x4IkpdMvC+sfYk/SsxbSh62xvhhP49+cA/mPtYtXG3oOUdxwc9xlsLEg
 FzUHhNvdjjuBPWNJvP58qKCee6m7m+bpvh1PnxlI9q7Ox5FR/tu4T07
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit
  3aa74796cfd0 ("hwmon: (pmbus) Register with thermal for PSC_TEMPERATURE")
the PMBus core calls devm_thermal_of_zone_register() for every
temperature input, so the devices of this binding can be referenced as
thermal sensors.

By code review, it should work for the MPQ and MPM device bindings.
They register a single page with PMBUS_HAVE_TEMP through
pmbus_do_probe(), it means that one device has one
temperature input, temp1.

The sensor id is the hwmon index of the input (temp1 is 1), so one cell
is needed.

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
 Documentation/devicetree/bindings/hwmon/pmbus/mps,mpq8785.yaml | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/Documentation/devicetree/bindings/hwmon/pmbus/mps,mpq8785.yaml b/Documentation/devicetree/bindings/hwmon/pmbus/mps,mpq8785.yaml
index d7a32fb3b7af..36760d89f665 100644
--- a/Documentation/devicetree/bindings/hwmon/pmbus/mps,mpq8785.yaml
+++ b/Documentation/devicetree/bindings/hwmon/pmbus/mps,mpq8785.yaml
@@ -34,6 +34,9 @@ properties:
     maximum: 4095
     default: 706
 
+  "#thermal-sensor-cells":
+    const: 1
+
 required:
   - compatible
   - reg

---
base-commit: 4781ca52761e666cf18b591e6bb0478396c90320
change-id: 20260930-for-upstream-dt-mpq8785-thermal-sensor-cells-c77fa6da5406

Best regards,
-- 
Vincent Jardin <vjardin@free.fr>

