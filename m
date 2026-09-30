From: Armandas Kvietkus <armandas.kvietkus@proton.me>
Date: Wed, 30 Sep 2026 18:08:03 +0200
Subject: [PATCH 1/2] dt-bindings: input: awinic,aw86927: Add Awinic AW8697
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260930-mainlining-v1-1-c303cbdb00c8@proton.me>
References: <20260930-mainlining-v1-0-c303cbdb00c8@proton.me>
In-Reply-To: <20260930-mainlining-v1-0-c303cbdb00c8@proton.me>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Griffin Kroah-Hartman <griffin.kroah@fairphone.com>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Armandas Kvietkus <armandas.kvietkus@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790784482; l=910;
 i=armandas.kvietkus@proton.me; h=from:subject:message-id;
 bh=vjgADZjYsmMEWYX2/CD2xEyWknfDHe2frU9LLl603ik=;
 b=9H2f/yikka6KgHS/XPF5Uo6dHq3RwBVhhmUB8Scz5Mr5LBR8OUz8x9dqyOdfrW0OB9rEkQqsb
 VrXnZH4LMBkBQu/MOZ08DhhvWSaNBSk+/0tt8Wx3LHX+ij6lkSuR5oQ
X-Developer-Key: i=armandas.kvietkus@proton.me; a=ed25519;
 pk=wuqmImJ9sKlDVcwALOvfGhjj7G8EBjjM4TpCdmlrAf8=
X-Endpoint-Received: by B4 Relay for armandas.kvietkus@proton.me/default with auth_id=974
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The AW8697 uses the same bus, interrupt and reset lines as the AW86927.
The register map is different, so there is no fallback compatible.

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
2.55.0

