From: Vincent Jardin <vjardin@free.fr>
Date: Mon, 24 Aug 2026 17:42:59 +0200
Subject: [PATCH] dt-bindings: hwmon: microchip,emc2305: add vcc-supply and
 #cooling-cells
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260824-for-upstream-dt-emc2305-vcc-cooling-v1-1-cd3b53dfb5d4@free.fr>
X-B4-Tracking: v=1; b=H4sIAIJmjGoC/x3NwQqDMAyA4VeRnA3UbBXdq8gOElMNzFZSJwPx3
 Vc8fpf/PyGLqWR4VSeYHJo1xYKmroCXMc6COhUDOWpdR08MyfC75d1kXHHaUVamh/N4MCOn9NE
 4I/mm9Z77XkIHpbSZBP3dl+F9XX/VYcEJdQAAAA==
To: Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Michael Shych <michaelsh@nvidia.com>
Cc: linux-hwmon@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787586189; l=1919;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=OmD5dPXn6kP0dHQvQO+WQZsrUb0dqokp2zQV0VNm5M8=;
 b=4G02U1j9qsh/7z1101Y2ZOFcREgjfyaxV5RyC576UKmi5xTmFKqlPMRltcsjvqNE3CO7zTbt9
 o7k55ogWrPUAH4Eq0kVDsG0QOUVT7sfq80KsoDK0+MM+LeE9a6hHvKx
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Both properties are missing, so a board that supplies either fails with
dtbs_check:

  fan-controller@2c (microchip,emc2305): '#cooling-cells', 'vcc-supply'
  do not match any of the regexes: '^fan@[0-4]$', '^pinctrl-[0-9]+$'

The #cooling-cells property belongs to the controller node, which is
where the driver actually registers.

Two cells is what that registration needs: a cooling-maps entry
references the fan as <&emc2305 min max>.

Two cells also documents what the driver supports today. The
pwm-separate path registers one cooling device per PWM against the same
node, and they all get cdev_id 0, so no cell count can tell them apart.
That is a driver issue, noted here but not addressed.

The examples in this binding put that property on the fan@N subnodes
instead, which does not match what the driver does: they are left alone
here rather than changed blind.

vcc-supply describes the chip's own rail, which matters on boards where
the sensor sits behind a switched supply.

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
 Documentation/devicetree/bindings/hwmon/microchip,emc2305.yaml | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/Documentation/devicetree/bindings/hwmon/microchip,emc2305.yaml b/Documentation/devicetree/bindings/hwmon/microchip,emc2305.yaml
index 8c2548539d7fd..47640214de100 100644
--- a/Documentation/devicetree/bindings/hwmon/microchip,emc2305.yaml
+++ b/Documentation/devicetree/bindings/hwmon/microchip,emc2305.yaml
@@ -44,6 +44,11 @@ properties:
            - 0 (Open-Drain)
            - 1 (Push-Pull)
 
+  vcc-supply: true
+
+  "#cooling-cells":
+    const: 2
+
 patternProperties:
   '^fan@[0-4]$':
     $ref: fan-common.yaml#

---
base-commit: 0a0d1d55dad570724bf8c7ea83409639cfb4be9b
change-id: 20260824-for-upstream-dt-emc2305-vcc-cooling-251655c99ef8

Best regards,
-- 
Vincent Jardin <vjardin@free.fr>

