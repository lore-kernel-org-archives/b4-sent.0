From: Vincent Jardin <vjardin@free.fr>
Date: Wed, 30 Sep 2026 15:44:51 +0200
Subject: [PATCH] dt-bindings: hwmon: jedec,jc42: add #thermal-sensor-cells
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260930-for-upstream-dt-jc42-thermal-sensor-cells-v1-1-ef6365cae23e@free.fr>
X-B4-Tracking: v=1; b=H4sIAFISvWoC/x2N0QrCMAwAf2Xk2UBbtaC/Ij6UNHORrhtJJ8LYv
 1t8PA7udjBWYYP7sIPyR0yW2sGfBqAp1Rej5M4QXIjudnY4Lorbak05zZgbvukSsE2scypoXK1
 74lIMU/bE7upj9AS9tyqP8v2/Hs/j+AGZsob2ewAAAA==
To: Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jean Delvare <jdelvare@suse.com>
Cc: linux-hwmon@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790775894; l=1166;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=mSc3Y85qyReq6ISJzbowfHld4A9js6Xfg/xK6HlzA8U=;
 b=pzPvbaToTilm9X2F2TEQuBc2nuZx6ABlJi3v5wZtop5UROQYGrf2BfCD9FYuD2n7VIEVx+ZLN
 cjrewKPNguJDHjYaLrUmadbxs7B41Ny/Y/r3P7Z12tUqvLMDmUxnqjo
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since the commit
  032c1623c9de ("hwmon: (jc42) add HWMON_C_TZ_REGISTER")
the driver sets HWMON_C_REGISTER_TZ, so the hwmon core calls
devm_thermal_of_zone_register() for its temperature channel and the
device can be referenced as a thermal sensor.

The chip has a single temperature channel, registered as sensor 0, so
no cell is needed.

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
 Documentation/devicetree/bindings/hwmon/jedec,jc42.yaml | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/Documentation/devicetree/bindings/hwmon/jedec,jc42.yaml b/Documentation/devicetree/bindings/hwmon/jedec,jc42.yaml
index bf3332153ad8..d835664a926b 100644
--- a/Documentation/devicetree/bindings/hwmon/jedec,jc42.yaml
+++ b/Documentation/devicetree/bindings/hwmon/jedec,jc42.yaml
@@ -59,6 +59,9 @@ properties:
       supported on all chips.
     type: boolean
 
+  "#thermal-sensor-cells":
+    const: 0
+
 required:
   - compatible
   - reg

---
base-commit: 4781ca52761e666cf18b591e6bb0478396c90320
change-id: 20260930-for-upstream-dt-jc42-thermal-sensor-cells-ad1ce051661c

Best regards,
-- 
Vincent Jardin <vjardin@free.fr>

