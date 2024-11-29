From: =?utf-8?q?Kry=C5=A1tof_=C4=8Cern=C3=BD?= <cleverline1mc@gmail.com>
Date: Fri, 29 Nov 2024 10:53:16 +0100
Subject: [PATCH v5 1/4] dt-bindings: w1: ds2482: Add vcc-supply property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241129-ds2482-add-reg-v5-1-af8e83d41344@gmail.com>
References: <20241129-ds2482-add-reg-v5-0-af8e83d41344@gmail.com>
In-Reply-To: <20241129-ds2482-add-reg-v5-0-af8e83d41344@gmail.com>
To: Krzysztof Kozlowski <krzk@kernel.org>, Rob Herring <robh@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Stefan Wahren <stefan.wahren@chargebyte.com>, 
 Stefan Wahren <wahrenst@gmx.net>
Cc: Ben Gardner <bgardner@wabtec.com>, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, 
 =?utf-8?q?Kry=C5=A1tof_=C4=8Cern=C3=BD?= <cleverline1mc@gmail.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732874180; l=796;
 i=cleverline1mc@gmail.com; s=20241112; h=from:subject:message-id;
 bh=WhOk1GuCMyF4Uqf/5Sr9VOiQAo2chWTloYZnv0gVBic=;
 b=WC9V7QwlQnfJ2et7H0gmoJCWIRcKCkev7yxGz3F95kNu4L190ZfJr50c/zN6I3kgROm8dgmsf
 SykRZuPd4zVDF/zQ1KIPQR+LElnStnwRyhZuoMCPx1ixf4VUYaRtUNW
X-Developer-Key: i=cleverline1mc@gmail.com; a=ed25519;
 pk=EJoEbw03UiRORQuCiEyNA8gH1Q6fIpEWnn/MyaWOWX0=
X-Endpoint-Received: by B4 Relay for cleverline1mc@gmail.com/20241112 with auth_id=275
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ds2482 has a VCC pin, accepting 2.9-5.5 V.

Signed-off-by: Kryštof Černý <cleverline1mc@gmail.com>
Reviewed-by: Stefan Wahren <wahrenst@gmx.net>
Acked-by: Conor Dooley <conor.dooley@microchip.com>
---
 Documentation/devicetree/bindings/w1/maxim,ds2482.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/w1/maxim,ds2482.yaml b/Documentation/devicetree/bindings/w1/maxim,ds2482.yaml
index 422becc6e1fa8d58665c5586ebdc611cd0b2c760..fe6b3f9a3f8bbd00366c3e36aad3ffa72ec1a31f 100644
--- a/Documentation/devicetree/bindings/w1/maxim,ds2482.yaml
+++ b/Documentation/devicetree/bindings/w1/maxim,ds2482.yaml
@@ -25,6 +25,8 @@ properties:
   reg:
     maxItems: 1
 
+  vcc-supply: true
+
 required:
   - compatible
   - reg

-- 
2.39.5

