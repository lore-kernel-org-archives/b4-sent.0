From: Vincent Jardin <vjardin@free.fr>
Date: Thu, 01 Oct 2026 09:28:23 +0200
Subject: [PATCH v2 2/2] dt-bindings: hwmon: pmbus: mps,mpq8785: add
 #thermal-sensor-cells
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261001-for-upstream-dt-mpq8785-thermal-sensor-cells-v2-2-07d368dcc662@free.fr>
References: <20261001-for-upstream-dt-mpq8785-thermal-sensor-cells-v2-0-07d368dcc662@free.fr>
In-Reply-To: <20261001-for-upstream-dt-mpq8785-thermal-sensor-cells-v2-0-07d368dcc662@free.fr>
To: Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Charles Hsu <ythsu0511@gmail.com>, 
 Eduardo Valentin <eduval@amazon.com>
Cc: linux-hwmon@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790839710; l=1207;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=eUACogoOzN7KH0RZ64dJTRG0jM5WEIXL8p7BWtlD+1c=;
 b=P6Eevym8r4AST3C2BvKlz+p6AtnuCeFhPK+3u2/layzRDgXBvLUjdAh5V8ekmkFKTG+WI4W2m
 /nx+nYTxalVDKgh4fED7WVF5oTtxjpq7Wj8HEqJhGDoyVmAXhpI/kEt
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

The PMBus core registers the first temperature input as sensor 0, so no
cell is needed.

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

