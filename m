From: Vincent Jardin <vjardin@free.fr>
Date: Thu, 01 Oct 2026 23:47:40 +0200
Subject: [PATCH v3 2/2] dt-bindings: hwmon: pmbus: mps,mpq8785: add
 #thermal-sensor-cells
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261001-for-upstream-dt-mpq8785-thermal-sensor-cells-v3-2-bfafba9fcc95@free.fr>
References: <20261001-for-upstream-dt-mpq8785-thermal-sensor-cells-v3-0-bfafba9fcc95@free.fr>
In-Reply-To: <20261001-for-upstream-dt-mpq8785-thermal-sensor-cells-v3-0-bfafba9fcc95@free.fr>
To: Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Charles Hsu <ythsu0511@gmail.com>, 
 Eduardo Valentin <eduval@amazon.com>
Cc: linux-hwmon@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790891264; l=1273;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=DDjneRrrCwg1pEDeBRgiYbnRLHQFomHKDXpTcRftV6A=;
 b=HII73c2NfEVZqTAH1QMvhqIaUsg8cwcKNBue+XRG0aWFmchoQCnwWy57v8Qn0t0XBeZ3IEA1H
 UJK9RWiFFlhA6xDE8XvCFco2QXR0Pu6Qlxd1/UtdnKF5p13uSnCkUci
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Each device of this binding has a single temperature sensor: the
internal sensor of its die, which the device also uses for its
over-temperature protection. It is read over PMBus with
READ_TEMPERATURE_1 (8Dh). The sensor is internal, not an input:
none of these devices has a pin for an external temperature sensor.

Allow a thermal zone to use the device as its sensor, to monitor the
regulator's temperature. With a single sensor per device, no cell is
needed.

The MPM82504 has four channels, each with its own PMBus address set by
its own ADDR pin, so each channel is described by its own node.

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
 Documentation/devicetree/bindings/hwmon/pmbus/mps,mpq8785.yaml | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/Documentation/devicetree/bindings/hwmon/pmbus/mps,mpq8785.yaml b/Documentation/devicetree/bindings/hwmon/pmbus/mps,mpq8785.yaml
index d7a32fb3b7af..6257a8030e53 100644
--- a/Documentation/devicetree/bindings/hwmon/pmbus/mps,mpq8785.yaml
+++ b/Documentation/devicetree/bindings/hwmon/pmbus/mps,mpq8785.yaml
@@ -34,6 +34,9 @@ properties:
     maximum: 4095
     default: 706
 
+  "#thermal-sensor-cells":
+    const: 0
+
 required:
   - compatible
   - reg

-- 
2.43.0

