From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Sat, 12 Apr 2025 15:04:32 +0200
Subject: [PATCH v2] dt-bindings: leds: Allow differently named multicolor
 leds
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250412-multi-led-v2-1-56af86908744@posteo.net>
X-B4-Tracking: v=1; b=H4sIAN9k+mcC/23MQQrDIBCF4auEWdeiA1LsqvcoWUSdNAOpBrXSE
 rx7bdZd/o/Ht0OmxJThOuyQqHLmGHrgaQC3TOFBgn1vQIlaojTi+VoLi5W8MMYoQqktzR76f0s
 08/uw7mPvhXOJ6XPQVf3Wf0pVQgk9kXXOevT2cttiLhTPgQqMrbUvPNjQD6MAAAA=
X-Change-ID: 20250209-multi-led-9991e205befd
To: Pavel Machek <pavel@ucw.cz>, Lee Jones <lee@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andrew Davis <afd@ti.com>, 
 Pavel Machek <pavel@kernel.org>
Cc: linux-leds@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744463086; l=1614;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=a7MVW7lJ84PcK32/7G3ucUp7YIndCA/M048QSEAkvoA=;
 b=zq7jcq7nd/DWtjq3QNRNbNkPq+8Cpldi//o2EfFdnuzk/jWfS9b4gQM91iSibxLnntRxLBri0
 gY+s92S2WluAzm0JVz3NuHogrRGZqWd9Kp5xv99Pby9mXchLd65lnPw
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In some cases, for example when using multiple instances of
leds-group-multicolor, a board may have multiple multi-leds which can't
be distinguished by unit address. In such cases it should be possible to
name them differently, for example multi-led-a and multi-led-b. This
patch adds another node name pattern to leds-class-multicolor.yaml to
allow such names.

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
V2:
- Add Krzysztof's review tag
- mention leds-group-multicolor in the commit message
- rebase on 6.15-rc1

Link to v1: https://lore.kernel.org/r/20250209-multi-led-v1-1-5aebccbd2db7@posteo.net
---
 Documentation/devicetree/bindings/leds/leds-class-multicolor.yaml | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/leds/leds-class-multicolor.yaml b/Documentation/devicetree/bindings/leds/leds-class-multicolor.yaml
index bb40bb9e036ee00e06d21e2321ecd5a7d471c408..c22af25b6430be71300c0e37f696cd61112ea190 100644
--- a/Documentation/devicetree/bindings/leds/leds-class-multicolor.yaml
+++ b/Documentation/devicetree/bindings/leds/leds-class-multicolor.yaml
@@ -21,7 +21,9 @@ description: |
 
 properties:
   $nodename:
-    pattern: "^multi-led(@[0-9a-f])?$"
+    oneOf:
+      - pattern: "^multi-led(@[0-9a-f])?$"
+      - pattern: "^multi-led-.*$"
 
   color:
     description: |

---
base-commit: 0af2f6be1b4281385b618cb86ad946eded089ac8
change-id: 20250209-multi-led-9991e205befd

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

