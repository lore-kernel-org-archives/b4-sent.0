From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Fri, 27 Nov 2026 13:14:24 +0300
Subject: [PATCH net-next v4 3/3] MAINTAINERS: Add Cortina CS7542 MDIO
 controller entry
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-b4-cs7542-mdio-v4-3-0e37fc0c47d5@gmail.com>
References: <20261127-b4-cs7542-mdio-v4-0-0e37fc0c47d5@gmail.com>
In-Reply-To: <20261127-b4-cs7542-mdio-v4-0-0e37fc0c47d5@gmail.com>
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@kernel.org>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, Andrew Lunn <andrew+netdev@lunn.ch>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795774461; l=883;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=pa+eVVj3dWWEgeMEgkzxsEwVYcHck8BeW/HLISWO33s=;
 b=g3Jh+Pl43tdz0C+cublxzG/7UDeZdbFb6hlWy5KmyBJ7fjcb4Qt3oAb4LKCYibO5VT4VsOVoI
 nI2Yhed+wepC7RTsVQNwrtrpXR5yQiBThyf/kS9nm8g4WsKXyRIHE5z
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

List the binding and driver under the author maintaining the Almond+
platform support, together with the appropriate subsystem mailing list.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>

Reviewed-by: Andrew Lunn <andrew@lunn.ch>
---
 MAINTAINERS | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 44540a1eb..312d3b4af 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -6918,6 +6918,13 @@ S:	Maintained
 F:	Documentation/hwmon/corsair-psu.rst
 F:	drivers/hwmon/corsair-psu.c
 
+CORTINA SYSTEMS CS7542 MDIO CONTROLLER
+M:	Fil Dunsky <filipp.dunsky@gmail.com>
+L:	netdev@vger.kernel.org
+S:	Maintained
+F:	Documentation/devicetree/bindings/net/cortina,cs7542-mdio.yaml
+F:	drivers/net/mdio/mdio-cs75xx.c
+
 COUNTER SUBSYSTEM
 M:	William Breathitt Gray <wbg@kernel.org>
 L:	linux-iio@vger.kernel.org

-- 
2.53.0

