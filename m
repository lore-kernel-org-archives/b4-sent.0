From: Armandas Kvietkus <armandas.kvietkus@proton.me>
Date: Tue, 13 Oct 2026 16:42:45 +0200
Subject: [PATCH v3 1/2] dt-bindings: input: awinic,aw86927: Add Awinic
 AW8697
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261013-mainlining-v3-1-fca981f62b57@proton.me>
References: <20261013-mainlining-v3-0-fca981f62b57@proton.me>
In-Reply-To: <20261013-mainlining-v3-0-fca981f62b57@proton.me>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Griffin Kroah-Hartman <griffin.kroah@fairphone.com>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@baylibre.com>, 
 Armandas Kvietkus <armandas.kvietkus@proton.me>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791902565; l=980;
 i=armandas.kvietkus@proton.me; h=from:subject:message-id;
 bh=v2utH8bn4ck8w7y8XqqfjpsT2mkH8/UIQhAb6iOyg4M=;
 b=fwXzgFDvGcAJdXr1aWobB3U2hvv6UAs5ogte3Rnp94GLYLlHqdCK8/4/8c7qvfy3d/xzvKI4l
 eBFMMGAlJSHDW0On6Z96E24/TwCg+xAsxkBPsODzOdU4rAUTT8QJ9pM
X-Developer-Key: i=armandas.kvietkus@proton.me; a=ed25519;
 pk=wuqmImJ9sKlDVcwALOvfGhjj7G8EBjjM4TpCdmlrAf8=
X-Endpoint-Received: by B4 Relay for armandas.kvietkus@proton.me/default with auth_id=974
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The AW8697 uses the same bus, interrupt and reset lines as the AW86927.
The register map is different, so there is no fallback compatible.

Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Signed-off-by: Armandas Kvietkus <armandas.kvietkus@proton.me>
---
 Documentation/devicetree/bindings/input/awinic,aw86927.yaml | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/input/awinic,aw86927.yaml b/Documentation/devicetree/bindings/input/awinic,aw86927.yaml
index bd74b81488f6..f0e26664e3e4 100644
--- a/Documentation/devicetree/bindings/input/awinic,aw86927.yaml
+++ b/Documentation/devicetree/bindings/input/awinic,aw86927.yaml
@@ -12,7 +12,9 @@ maintainers:
 properties:
   compatible:
     oneOf:
-      - const: awinic,aw86927
+      - enum:
+          - awinic,aw8697
+          - awinic,aw86927
       - items:
           - enum:
               - awinic,aw86938

-- 
2.56.0

