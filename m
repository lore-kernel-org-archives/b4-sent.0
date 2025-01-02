From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Thu, 02 Jan 2025 19:31:52 +0100
Subject: [PATCH 11/19] dt-bindings: gpio: fsl,qoriq-gpio: Add compatible
 string fsl,mpc8314-gpio
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250102-mpc83xx-v1-11-86f78ba2a7af@posteo.net>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735842735; l=808;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=kQbjf8yyMIMYDlp9Ljafq6qH6mq2lFyMb6vI0TaGZAs=;
 b=6WNaCpNbcbNLwRTLw2myVEFq6VrIiHRNr0CdOsGX97lbFkdnQDEHvS2wyUJij1FgVkdkVkiMq
 Uonk+3ZBOeDCWPZf3mcIL66HurU56+XDeg9abRg9o6/0x9Ds3gipzGs
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is for the MPC831{4,5}{,E} SoCs.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 Documentation/devicetree/bindings/gpio/fsl,qoriq-gpio.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/gpio/fsl,qoriq-gpio.yaml b/Documentation/devicetree/bindings/gpio/fsl,qoriq-gpio.yaml
index 84fd82291ee4031a55f704977ee0db084caef08a..f1b60ab3f356b99f936d7d8bd5e03f9ffabd0f93 100644
--- a/Documentation/devicetree/bindings/gpio/fsl,qoriq-gpio.yaml
+++ b/Documentation/devicetree/bindings/gpio/fsl,qoriq-gpio.yaml
@@ -15,6 +15,7 @@ properties:
       - enum:
           - fsl,mpc5121-gpio
           - fsl,mpc5125-gpio
+          - fsl,mpc8314-gpio
           - fsl,mpc8349-gpio
           - fsl,mpc8572-gpio
           - fsl,mpc8610-gpio

-- 
2.45.2

