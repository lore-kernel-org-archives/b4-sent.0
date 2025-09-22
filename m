From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Tue, 23 Sep 2025 01:10:01 +0200
Subject: [PATCH] dt-bindings: net: ethernet-controller: Fix grammar in
 comment
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250923-dt-net-typo-v1-1-08e1bdd14c74@posteo.net>
X-B4-Tracking: v=1; b=H4sIAEjX0WgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDSyNj3ZQS3bzUEt2SyoJ8XcvU1DRLk1SjNGMDMyWgjoKi1LTMCrBp0bG
 1tQC13EunXQAAAA==
X-Change-ID: 20250923-dt-net-typo-9eef94e2f306
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758582614; l=1216;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=UG1p5Ilscqfsthqo/vFuqDREG76+9qwWwF2C33lkH4U=;
 b=YKEwhNmEE7v9/7DglAAFg5iNOpL05owbfonhI07MdVIUhy1zsCQPerkREszKe6k3OBfRb+quw
 uL4A71PB/lQDY0xKFZI+F3Ixt7FAoPHyOZfJsUo8bbiS31l7594Q84P
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

"difference" is a noun, so "sufficient" is an adjective without "ly".

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 Documentation/devicetree/bindings/net/ethernet-controller.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/net/ethernet-controller.yaml b/Documentation/devicetree/bindings/net/ethernet-controller.yaml
index 66b1cfbbfe221112286af4a14839ea039564113a..812f2c7aaa83777cf8c863e93d9597b951ac54d7 100644
--- a/Documentation/devicetree/bindings/net/ethernet-controller.yaml
+++ b/Documentation/devicetree/bindings/net/ethernet-controller.yaml
@@ -274,7 +274,7 @@ additionalProperties: true
 # specified.
 #
 # One option is to make the clock traces on the PCB longer than the
-# data traces. A sufficiently difference in length can provide the 2ns
+# data traces. A sufficient difference in length can provide the 2ns
 # delay. If both the RX and TX delays are implemented in this manner,
 # 'rgmii' should be used, so indicating the PCB adds the delays.
 #

---
base-commit: 8f5ae30d69d7543eee0d70083daf4de8fe15d585
change-id: 20250923-dt-net-typo-9eef94e2f306

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

