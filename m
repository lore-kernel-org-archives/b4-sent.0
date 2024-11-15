From: =?utf-8?q?Kry=C5=A1tof_=C4=8Cern=C3=BD?= <cleverline1mc@gmail.com>
Date: Fri, 15 Nov 2024 15:58:06 +0100
Subject: [PATCH 3/3] dt-bindings: w1: ds2482: Add vcc-supply property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241115-ds2482-add-reg-v1-3-cc84b9aba126@gmail.com>
References: <20241115-ds2482-add-reg-v1-0-cc84b9aba126@gmail.com>
In-Reply-To: <20241115-ds2482-add-reg-v1-0-cc84b9aba126@gmail.com>
To: Krzysztof Kozlowski <krzk@kernel.org>, Rob Herring <robh@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Stefan Wahren <stefan.wahren@chargebyte.com>
Cc: Ben Gardner <bgardner@wabtec.com>, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, 
 =?utf-8?q?Kry=C5=A1tof_=C4=8Cern=C3=BD?= <cleverline1mc@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1731682735; l=781;
 i=cleverline1mc@gmail.com; s=20241112; h=from:subject:message-id;
 bh=UCNjIrPX7cETnGBQGIv8oPibmNQ+Ah/w0u0cd9E5Xfw=;
 b=fnkTpsmCVfDQgbR4yJ50Yo8UWgWnRZrm+QvcKqLoMy+VNV0jyThRFwjYkNxO3TCPTqmMwIoim
 OST8Plmv159D68kesgnzORJvorsWkIkAFvDssk9upp22e2KDYRuDseX
X-Developer-Key: i=cleverline1mc@gmail.com; a=ed25519;
 pk=EJoEbw03UiRORQuCiEyNA8gH1Q6fIpEWnn/MyaWOWX0=
X-Endpoint-Received: by B4 Relay for cleverline1mc@gmail.com/20241112 with auth_id=275
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adds the newly added vcc-supply property to bindings.

Signed-off-by: Kryštof Černý <cleverline1mc@gmail.com>
---
 Documentation/devicetree/bindings/w1/maxim,ds2482.yaml | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/Documentation/devicetree/bindings/w1/maxim,ds2482.yaml b/Documentation/devicetree/bindings/w1/maxim,ds2482.yaml
index 422becc6e1fa8d58665c5586ebdc611cd0b2c760..a6b9e0658ec858cb24b21cf64443a061bb43e4ef 100644
--- a/Documentation/devicetree/bindings/w1/maxim,ds2482.yaml
+++ b/Documentation/devicetree/bindings/w1/maxim,ds2482.yaml
@@ -25,6 +25,9 @@ properties:
   reg:
     maxItems: 1
 
+  vcc-supply:
+    description: phandle of the regulator that provides the supply voltage.
+
 required:
   - compatible
   - reg

-- 
2.39.5

