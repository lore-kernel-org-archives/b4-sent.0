From: Vincent Jardin <vjardin@free.fr>
Date: Thu, 01 Oct 2026 23:58:14 +0200
Subject: [PATCH v2] dt-bindings: hwmon: jedec,jc42: add
 #thermal-sensor-cells
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261001-for-upstream-dt-jc42-thermal-sensor-cells-v2-1-6edd30b082f3@free.fr>
X-B4-Tracking: v=1; b=H4sIAHXXvmoC/52NSwrCMBRFt1Iy9kmS2oCO3Id0ENIbG+lH3otFK
 d27sUtweO6Fc1Yl4ARRl2pVjCVJmqcC9lCp0PvpDkpdYWW1dfpca4oz0+spmeFH6jI9wslS7sG
 jH0gwSfkDhkHIdyZAN8Y5E1TxPRkxvffWrS3cJ8kzf/b0Yn7rP5XFkCFEV7smeNga18jAMbJqt
 237AgxynOHgAAAA
To: Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jean Delvare <jdelvare@suse.com>
Cc: linux-hwmon@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790891894; l=1440;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=8mjDlcGI3Cj4EQONFKljx6GXc0o6W4X1o0EOPy1FmU4=;
 b=tKsE662/gABLgXKroy1YEXHqY5YCQC7VXTP/I3yUuywSdQriE/UBFNhmEBRoVb/pKmW/i2UfI
 orl/JKz0dw/BoIgFBXa8GdxIaJ5qVpRoS27HfBG/mQeH0AWhgOv6S62
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit 032c1623c9de ("hwmon: (jc42) add HWMON_C_TZ_REGISTER") the
driver sets HWMON_C_REGISTER_TZ, so the hwmon core calls
devm_thermal_of_zone_register() for its temperature channel and the
device can be referenced as a thermal sensor.

The chip has a single temperature channel, registered as sensor 0, so
no cell is needed.

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
Changes in v2:
- fix sentence format (Krzysztof)
- record Krzysztof's Reviewed-by
- Link to v1: https://lore.kernel.org/r/20260930-for-upstream-dt-jc42-thermal-sensor-cells-v1-1-ef6365cae23e@free.fr
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

