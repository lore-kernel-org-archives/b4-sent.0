From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Thu, 02 Jan 2025 19:31:56 +0100
Subject: [PATCH 15/19] dt-bindings: vendor-prefixes: Add LANCOM Systems
 GmbH
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250102-mpc83xx-v1-15-86f78ba2a7af@posteo.net>
References: <20250102-mpc83xx-v1-0-86f78ba2a7af@posteo.net>
In-Reply-To: <20250102-mpc83xx-v1-0-86f78ba2a7af@posteo.net>
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>, 
 Naveen N Rao <naveen@kernel.org>, Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Frank Li <Frank.Li@nxp.com>
Cc: linuxppc-dev@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-gpio@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735842735; l=888;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=cPDycNl9By3Hm5+1t2n1h/bJeTOlBcJ2oe1IgSAfN6U=;
 b=JRK8A4LytpWFYp4wFnkZVdi329GFgJOOHAqqi81i/HoTMERuo7v01lvfwpwuGoeDe15XGIdFE
 kebxru9TD1CBOOAasWFhF3rU6HfzY4Rac07KuLWFyVyBs2GeaUMP2bo
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

LANCOM Systems is a manufacturer of networking equipment.

  https://www.lancom-systems.com/

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 Documentation/devicetree/bindings/vendor-prefixes.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/vendor-prefixes.yaml b/Documentation/devicetree/bindings/vendor-prefixes.yaml
index da01616802c76830a520594a69bd6a2e0231df0d..56d88162b184e45d6b05fc749d77ca952a5eb2e2 100644
--- a/Documentation/devicetree/bindings/vendor-prefixes.yaml
+++ b/Documentation/devicetree/bindings/vendor-prefixes.yaml
@@ -812,6 +812,8 @@ patternProperties:
     description: Laird PLC
   "^lamobo,.*":
     description: Ketai Huajie Technology Co., Ltd.
+  "^lancom,.*":
+    description: LANCOM Systems GmbH
   "^lantiq,.*":
     description: Lantiq Semiconductor
   "^lattice,.*":

-- 
2.45.2

