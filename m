From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Thu, 02 Jan 2025 19:31:55 +0100
Subject: [PATCH 14/19] powerpc: mpc83xx: Switch to of_platform_populate
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250102-mpc83xx-v1-14-86f78ba2a7af@posteo.net>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735842735; l=1933;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=+IqpHh5XW/bYptAKTy7ofbzqqjbf0TgTP59VXCoHzqo=;
 b=9e/ltqkhbkqoYmAvt8DHPwJqvqjwqUwV7mVFU5GYMkehfc+vd97JJq/T1F6hT+F/IFNl9WZQ3
 aOurraZE/mLDNmRzKchRUir6Kg4EjKmgIvfmKynORihXWTpBQ5uGZnh
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Quoting from drivers/of/platform.c:

> of_platform_populate() - [...]
> Similar to of_platform_bus_probe(), this function walks the device
> tree and creates devices from nodes.  It differs in that it follows
> the modern convention of requiring all device nodes to have a
> 'compatible' property, and it is suitable for creating devices which
> are children of the root node (of_platform_bus_probe will only create
> children of the root which are selected by the @matches argument).

This is useful for new board ports because it means that the C code does
not have to anticipate every node that is placed directly under the root.

As a consequence, the of_bus_ids list can be much shorter, and I've
trimmed it to the necessary parts:

 - device-type = "soc" and compatible = "simple-bus" for the SoC bus
 - compatible = "gianfar" for the Ethernet controller (TSEC), which
   may contain an MDIO bus, which needs to be probed, as a subnode

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 arch/powerpc/platforms/83xx/misc.c | 6 +-----
 1 file changed, 1 insertion(+), 5 deletions(-)

diff --git a/arch/powerpc/platforms/83xx/misc.c b/arch/powerpc/platforms/83xx/misc.c
index 1135c1ab923cc120f377a0d98767fef686cad1fe..bf522ee007bbb1429233355f668fc8563d8ca4e2 100644
--- a/arch/powerpc/platforms/83xx/misc.c
+++ b/arch/powerpc/platforms/83xx/misc.c
@@ -94,18 +94,14 @@ void __init mpc83xx_ipic_init_IRQ(void)
 
 static const struct of_device_id of_bus_ids[] __initconst = {
 	{ .type = "soc", },
-	{ .compatible = "soc", },
 	{ .compatible = "simple-bus" },
 	{ .compatible = "gianfar" },
-	{ .compatible = "gpio-leds", },
-	{ .type = "qe", },
-	{ .compatible = "fsl,qe", },
 	{},
 };
 
 int __init mpc83xx_declare_of_platform_devices(void)
 {
-	of_platform_bus_probe(NULL, of_bus_ids, NULL);
+	of_platform_populate(NULL, of_bus_ids, NULL, NULL);
 	return 0;
 }
 

-- 
2.45.2

