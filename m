From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Thu, 02 Jan 2025 19:31:53 +0100
Subject: [PATCH 12/19] powerpc: dts: mpc8315e: Add GPIO controller node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250102-mpc83xx-v1-12-86f78ba2a7af@posteo.net>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735842735; l=867;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=53IPkv/+qKgm0/DViEM4D8nVx9tPgdRG/PC4lnN6+fc=;
 b=grga97ENyMGY97nIZwfxEfbacZt96cEOsFzwdrvwrUslDs8ieVW4MRzpzYExkcZ8F3W/eVin6
 JigBllwbn/YDXqHVrrZjnesI72P8Hf5rc+QgiKZ0KM9ibGG5RuJEr76
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This node das previously missing from the device tree.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 arch/powerpc/boot/dts/mpc8315e.dtsi | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/arch/powerpc/boot/dts/mpc8315e.dtsi b/arch/powerpc/boot/dts/mpc8315e.dtsi
index f9d1b48b08799822d33f5e7606030019a19b4743..ad6131d913fd45ec5b693d85e031ec520fb28b2f 100644
--- a/arch/powerpc/boot/dts/mpc8315e.dtsi
+++ b/arch/powerpc/boot/dts/mpc8315e.dtsi
@@ -302,6 +302,15 @@ pmc: power@b00 {
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

-- 
2.45.2

