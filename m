From: Samuel Kayode <samuel.kayode@savoirfairelinux.com>
Date: Wed, 01 Oct 2025 11:42:42 -0400
Subject: [PATCH v12 6/6] MAINTAINERS: add an entry for pf1550 mfd driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251001-pf1550-v12-6-a3302aa41687@savoirfairelinux.com>
References: <20251001-pf1550-v12-0-a3302aa41687@savoirfairelinux.com>
In-Reply-To: <20251001-pf1550-v12-0-a3302aa41687@savoirfairelinux.com>
To: Lee Jones <lee@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Liam Girdwood <lgirdwood@gmail.com>, 
 Mark Brown <broonie@kernel.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Sebastian Reichel <sre@kernel.org>, Frank Li <Frank.li@nxp.com>
Cc: imx@lists.linux.dev, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-input@vger.kernel.org, 
 linux-pm@vger.kernel.org, Abel Vesa <abelvesa@kernel.org>, 
 Abel Vesa <abelvesa@linux.com>, Robin Gong <b38343@freescale.com>, 
 Robin Gong <yibin.gong@nxp.com>, 
 Enric Balletbo i Serra <eballetbo@gmail.com>, 
 Sean Nyekjaer <sean@geanix.com>, 
 Christophe JAILLET <christophe.jaillet@wanadoo.fr>, 
 Samuel Kayode <samuel.kayode@savoirfairelinux.com>, 
 Abel Vesa <abelvesa@kernel.org>, Frank Li <Frank.Li@nxp.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1759333360; l=1229;
 i=samuel.kayode@savoirfairelinux.com; s=20250527; h=from:subject:message-id;
 bh=GUpwedwZ6iTM/9T8xwTWsw5t21VrPDOJAhQDVkmdBtI=;
 b=2WpW9lNVxnpyGsfvRtsbtDpNK6l2vH8C+8r+KLHpzefyxsWELgNa2VO1R6dhsXCuawvudv3dg
 wpUIgtg1lJKBm+N7Z+21QXTnU0Y4Ff2vUKhqfFEczjiZU9ln+KhAtiV
X-Developer-Key: i=samuel.kayode@savoirfairelinux.com; a=ed25519;
 pk=TPSQGQ5kywnnPyGs0EQqLajLFbdDu17ahXz8/gxMfio=
X-Endpoint-Received: by B4 Relay for samuel.kayode@savoirfairelinux.com/20250527 with auth_id=412
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add MAINTAINERS entry for pf1550 PMIC.

Reviewed-by: Frank Li <Frank.Li@nxp.com>
Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Tested-by: Sean Nyekjaer <sean@geanix.com>
Signed-off-by: Samuel Kayode <samuel.kayode@savoirfairelinux.com>
---
v9:
 - Pick up Frank's `Reviewed-by` tag
v6:
 - Add imx mailing list
---
 MAINTAINERS | 11 +++++++++++
 1 file changed, 11 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 97d958c945e4ffa3031590823f7a2867f577ebf3..5cc042b7ffe31a79bbbcbfd1fec7831b3546054d 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -18293,6 +18293,17 @@ F:	Documentation/devicetree/bindings/clock/*imx*
 F:	drivers/clk/imx/
 F:	include/dt-bindings/clock/*imx*
 
+NXP PF1550 PMIC MFD DRIVER
+M:	Samuel Kayode <samuel.kayode@savoirfairelinux.com>
+L:	imx@lists.linux.dev
+S:	Maintained
+F:	Documentation/devicetree/bindings/mfd/nxp,pf1550.yaml
+F:	drivers/input/misc/pf1550-onkey.c
+F:	drivers/mfd/pf1550.c
+F:	drivers/power/supply/pf1550-charger.c
+F:	drivers/regulator/pf1550-regulator.c
+F:	include/linux/mfd/pfd1550.h
+
 NXP PF8100/PF8121A/PF8200 PMIC REGULATOR DEVICE DRIVER
 M:	Jagan Teki <jagan@amarulasolutions.com>
 S:	Maintained

-- 
2.50.1

