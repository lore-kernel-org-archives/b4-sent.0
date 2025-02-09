From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Sun, 09 Feb 2025 23:06:50 +0100
Subject: [PATCH] dt-bindings: leds: Allow differently named multicolor leds
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250209-multi-led-v1-1-5aebccbd2db7@posteo.net>
X-B4-Tracking: v=1; b=H4sIAPkmqWcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDIwNL3dzSnJJM3ZzUFF1LS0vDVCMD06TUtBQloPqCotS0zAqwWdGxtbU
 AW+6O3FsAAAA=
X-Change-ID: 20250209-multi-led-9991e205befd
To: Pavel Machek <pavel@ucw.cz>, Lee Jones <lee@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andrew Davis <afd@ti.com>
Cc: linux-leds@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1739138838; l=1273;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=9DQV3fzmb755ljBlke0ZoorMkJDPL/aQrPGsmH2YR6s=;
 b=RP039EUEyquTEMyQNTLm+9+PhfrD1leUx+R6Jn1isuufyR91nebysUfOTuthgqMwqq5uI7H0b
 0oa6ntbmI4rBwKJKOU4QT1/MC4amAnO2bV3G77+zHucHk4VoTeiJNTp
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In some cases, a board may have multiple multi-leds, which can't be
distinguished by unit address. In such cases it should be possible to
name them differently, for example multi-led-a and multi-led-b.
This patch adds another node name pattern to leds-class-multicolor.yaml
to allow such names.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
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
base-commit: 645b5c24cf8590eea322a4fd79c811817046a2e6
change-id: 20250209-multi-led-9991e205befd

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

