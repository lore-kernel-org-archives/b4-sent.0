From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Mon, 05 Oct 2026 15:01:10 +0800
Subject: [PATCH] dt-bindings: media: ite,it6625: fix I2C address in example
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261005-upstream-it6625-dt-example-i2c-addr-v1-1-11ff60e2293f@ite.com.tw>
X-B4-Tracking: v=1; b=H4sIADVLw2oC/x2N0QrCMAwAf2Xk2UAbbJn+ivgQ2mwG3CxplcHYv
 1v2eHDc7VDFVCrchx1Mflr1s3bwlwHSi9dZUHNnIEfROxfwW2oz4QW1xUgBc0PZeCnvblJCztm
 QriOHafS3FBP0UjGZdDsvj+dx/AET7kEedQAAAA==
X-Change-ID: 20261005-upstream-it6625-dt-example-i2c-addr-248a5f819c6c
To: Hermes Wu <Hermes.Wu@ite.com.tw>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Hans Verkuil <hverkuil+cisco@kernel.org>, linux-media@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791183671; l=1520;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=OrLWDLA4fM9Wv4Fc/STWxB87oF1ekyLlK5DPdsFadMQ=;
 b=KX3ZFIpwstxZAimr7Zlu7TDoTUNviLo5yCwTNEP/fatQ3WXXRNdDtRu6886ZzF0apvOYl4irQ
 kjYNt27xnIvCFs8F6OXkIWG2GCJoqbkdcumZP7ANvRqn3PveuIyW6tH
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The IT6625/IT6626 respond on the I2C bus at the 7-bit address 0x59
(0xB2 in 8-bit write form, as given in the IT6625 SW programming
guide). The binding example used 0x4c, which does not match the
hardware and can mislead board DTS authors copying the example.

Use 0x59 for both the unit address and the reg property.

Fixes: cee2619b011a ("dt-bindings: media: add ITE IT6625/IT6626 HDMI bridge")
Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
Example-only fix; the schema itself is unchanged.
---
 Documentation/devicetree/bindings/media/i2c/ite,it6625.yaml | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/Documentation/devicetree/bindings/media/i2c/ite,it6625.yaml b/Documentation/devicetree/bindings/media/i2c/ite,it6625.yaml
index 9b621f726249189255692da02049ebcbf1d5b43c..b766f075dedd4668446856aceb854b24726a1266 100644
--- a/Documentation/devicetree/bindings/media/i2c/ite,it6625.yaml
+++ b/Documentation/devicetree/bindings/media/i2c/ite,it6625.yaml
@@ -142,9 +142,9 @@ examples:
       #address-cells = <1>;
       #size-cells = <0>;
 
-      hdmi-bridge@4c {
+      hdmi-bridge@59 {
         compatible = "ite,it6625";
-        reg = <0x4c>;
+        reg = <0x59>;
         interrupts = <3 IRQ_TYPE_LEVEL_LOW>;
 
         reset-gpios = <&gpio 2 GPIO_ACTIVE_LOW>;

---
base-commit: 89a3d2a2237e017cdbefcb036db71ce74e67faf5
change-id: 20261005-upstream-it6625-dt-example-i2c-addr-248a5f819c6c

Best regards,
-- 
Hermes Wu <Hermes.wu@ite.com.tw>

