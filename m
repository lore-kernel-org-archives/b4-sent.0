From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Thu, 01 Jan 2026 18:19:26 +0100
Subject: [PATCH v3] dt-bindings: leds: Allow differently named multicolor
 leds
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260101-multi-led-v3-1-e29ca8dedd37@posteo.net>
X-B4-Tracking: v=1; b=H4sIAJ2sVmkC/22Myw6CMBBFf4XM2pp25FVW/odxQekgTZCStjYaw
 r9b2KiJy3Nzz1nAkzPkockWcBSNN3ZKcDpk0A3tdCNmdGJAjgVHLtn9MQbDRtJMSikIeaGo15D
 +s6PePPfW5Zp4MD5Y99rTUWzrv0oUTLCiJdV1SqNW1Xm2PpA9ThRgy0T8qLnAbxU3tWz7upS8r
 vL8R13X9Q1MC2Tr3gAAAA==
X-Change-ID: 20250209-multi-led-9991e205befd
To: Pavel Machek <pavel@ucw.cz>, Lee Jones <lee@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andrew Davis <afd@ti.com>, 
 Pavel Machek <pavel@kernel.org>
Cc: linux-leds@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>, 
 Krzysztof Kozlowski <krzk@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767287972; l=1829;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=mXBr8+Rkn2am3xPSPchutPQF/ATdJJQ3PJqfCR/tUHk=;
 b=w+z4hvQeQdjdUS91KVFVKDjebkNbSuZ9D2a8S5kQjv5G5RTCNGyK4l6OGL2dM+mMiake3QbLz
 y1cZT6nxyJFBKJ06nfnjBuAWaoN3w0pZjN0fCbPDYUugTA61gEzvxV0
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In some cases, for example when using multiple instances of
leds-group-multicolor, a board may have multiple multi-leds which can't
be distinguished by unit address. In such cases it should be possible to
name them differently, for example multi-led-0 and multi-led-1. This
patch adds another node name pattern to leds-class-multicolor.yaml to
allow such names.

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
V3:
- Combine patterns into one, instead of using oneOf schema
- Change examples in commit message to use numeric suffixes
- Restrict pattern to allow only numeric suffixes after the dash
  following Rob Herring's suggestion

V2:
- Link: https://lore.kernel.org/r/20250412-multi-led-v2-1-56af86908744@posteo.net
- Add Krzysztof's review tag
- mention leds-group-multicolor in the commit message
- rebase on 6.15-rc1

Link to v1: https://lore.kernel.org/r/20250209-multi-led-v1-1-5aebccbd2db7@posteo.net
---
 Documentation/devicetree/bindings/leds/leds-class-multicolor.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/leds/leds-class-multicolor.yaml b/Documentation/devicetree/bindings/leds/leds-class-multicolor.yaml
index bb40bb9e036ee0..7bfc3d807acae3 100644
--- a/Documentation/devicetree/bindings/leds/leds-class-multicolor.yaml
+++ b/Documentation/devicetree/bindings/leds/leds-class-multicolor.yaml
@@ -21,7 +21,7 @@ description: |
 
 properties:
   $nodename:
-    pattern: "^multi-led(@[0-9a-f])?$"
+    pattern: "^multi-led(@[0-9a-f]|-[0-9]+)?$"
 
   color:
     description: |

---
base-commit: 9448598b22c50c8a5bb77a9103e2d49f134c9578
change-id: 20250209-multi-led-9991e205befd

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

