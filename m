From: Samuel Kayode <samuel.kayode@savoirfairelinux.com>
Date: Wed, 11 Jun 2025 16:03:03 -0400
Subject: [PATCH v6 6/6] MAINTAINERS: add an entry for pf1550 mfd driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250611-pf1550-v6-6-34f2ddfe045e@savoirfairelinux.com>
References: <20250611-pf1550-v6-0-34f2ddfe045e@savoirfairelinux.com>
In-Reply-To: <20250611-pf1550-v6-0-34f2ddfe045e@savoirfairelinux.com>
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
 Samuel Kayode <samuel.kayode@savoirfairelinux.com>, 
 Abel Vesa <abelvesa@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749672179; l=1098;
 i=samuel.kayode@savoirfairelinux.com; s=20250527; h=from:subject:message-id;
 bh=A2g1QBfQcrzU9z5M8QRFE0Nrt7Jq7rU2GZY3TiYW/3Y=;
 b=JLty8CjMJicQq1reFnjgmqLmWRGsUdUZlD70w5L2JJ3/RqbojqxbuEUJOX0m75y2zOKN/pV4s
 lyEuI8o+X63CZJH7qjkQDz0W/lu85XMSm4bI6Ix/uK/ycokLGQ2CEBF
X-Developer-Key: i=samuel.kayode@savoirfairelinux.com; a=ed25519;
 pk=TPSQGQ5kywnnPyGs0EQqLajLFbdDu17ahXz8/gxMfio=
X-Endpoint-Received: by B4 Relay for samuel.kayode@savoirfairelinux.com/20250527 with auth_id=412
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add MAINTAINERS entry for pf1550 PMIC.

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Signed-off-by: Samuel Kayode <samuel.kayode@savoirfairelinux.com>
---
v6:
 - Add imx mailing list
---
 MAINTAINERS | 11 +++++++++++
 1 file changed, 11 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 98201e1f4ab5908ff49d32d19275e123cedb4b66..5547fdafa7e1bb11903d5d5bef246c2e1a20fbca 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -17853,6 +17853,17 @@ F:	Documentation/devicetree/bindings/clock/imx*
 F:	drivers/clk/imx/
 F:	include/dt-bindings/clock/imx*
 
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
2.49.0

