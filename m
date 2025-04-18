From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Fri, 18 Apr 2025 20:48:14 +0200
Subject: [PATCH] powerpc: dts: mpc8315erdb: Add GPIO controller node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250418-mpc-gpio-v1-1-24be2365992a@posteo.net>
X-B4-Tracking: v=1; b=H4sIAG2eAmgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDE0ML3dyCZN30gsx8XXPLlOREyzRzA1MTMyWg8oKi1LTMCrBR0bG1tQA
 w6h8oWgAAAA==
X-Change-ID: 20250418-mpc-gpio-79dca9f70546
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>, 
 Naveen N Rao <naveen@kernel.org>
Cc: devicetree@vger.kernel.org, linuxppc-dev@lists.ozlabs.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745002102; l=1409;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=yIo4OMFzwIHk/Y7Ad7fIh7vacgPJLYwfWJ8zjzP38HI=;
 b=MzF7If4e34vj/JrF+b0JokWfYf8Phq6bZVN/3vliB9QLi2BrnJARDvJb1SwTr4FhTogpGdi+M
 FirkRP7a6TaAqPvGZ9/xqAYQDYkFSgt9bL21NT0rt0QrvtFJl/aFXy7
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MPC8315E SoC and variants have a GPIO controller at IMMR + 0xc00.
This node was previously missing from the device tree.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
A version of this patch was previously part of the series "powerpc:
MPC83xx cleanup and LANCOM NWAPP2 board", but I'm splitting it out to
reduce the size of that series.
---
 arch/powerpc/boot/dts/mpc8315erdb.dts | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/arch/powerpc/boot/dts/mpc8315erdb.dts b/arch/powerpc/boot/dts/mpc8315erdb.dts
index e09b37d7489d01bfd16a26e9786868f630fa0262..a89cb3139ca8c3d4f22e43838a4b7d2dd5109aa5 100644
--- a/arch/powerpc/boot/dts/mpc8315erdb.dts
+++ b/arch/powerpc/boot/dts/mpc8315erdb.dts
@@ -6,6 +6,7 @@
  */
 
 /dts-v1/;
+#include <dt-bindings/interrupt-controller/irq.h>
 
 / {
 	compatible = "fsl,mpc8315erdb";
@@ -358,6 +359,15 @@ pmc: power@b00 {
 			interrupt-parent = <&ipic>;
 			fsl,mpc8313-wakeup-timer = <&gtm1>;
 		};
+
+		gpio: gpio-controller@c00 {
+			compatible = "fsl,mpc8314-gpio";
+			reg = <0xc00 0x100>;
+			interrupts = <74 IRQ_TYPE_LEVEL_LOW>;
+			interrupt-parent = <&ipic>;
+			gpio-controller;
+			#gpio-cells = <2>;
+		};
 	};
 
 	pci0: pci@e0008500 {

---
base-commit: 0af2f6be1b4281385b618cb86ad946eded089ac8
change-id: 20250418-mpc-gpio-79dca9f70546

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

