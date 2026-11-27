From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Fri, 27 Nov 2026 15:53:46 +0300
Subject: [PATCH net-next v4 3/3] MAINTAINERS: Add CS7542 network engine
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-b4-cs7542-ethernet-v4-3-ea4d8cd6ef18@gmail.com>
References: <20261127-b4-cs7542-ethernet-v4-0-ea4d8cd6ef18@gmail.com>
In-Reply-To: <20261127-b4-cs7542-ethernet-v4-0-ea4d8cd6ef18@gmail.com>
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Linus Walleij <linusw@kernel.org>, 
 "David S. Miller" <davem@davemloft.net>, 
 Hans Ulli Kroll <ulli.kroll@googlemail.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Russell King <linux@armlinux.org.uk>
Cc: Philipp Zabel <p.zabel@pengutronix.de>, 
 Hans Ulli Kroll <ulli.kroll@googlemail.com>, 
 Russell King <linux@armlinux.org.uk>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795784023; l=937;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=DBRJjVV3hiiIbRTZ8foq3X1SNngfkVeImNSp0P0VJEI=;
 b=6Re59bHObrOCuxL2LAcVczKsLZk5Fkw6w4rUxaF1POtulDz+bIIzOv9zUKg+xhTADpNoGpgON
 RvOPA2pnOG8BCAD/Fv7yyyZ49lK9YKxcb5ctt5myf0RFFb9yPxXOapy
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Cover the Ethernet binding and network engine datapath. The shared
global reset provider is maintained separately under global control.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 MAINTAINERS | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 703e95e83..53d482457 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -2961,6 +2961,13 @@ F:	drivers/reset/reset-cs7542.c
 F:	include/dt-bindings/clock/cortina,cs7542-clock.h
 F:	include/dt-bindings/reset/cortina,cs7542-reset.h
 
+ARM/CORTINA SYSTEMS CS7542 NETWORK ENGINE
+M:	Fil Dunsky <filipp.dunsky@gmail.com>
+L:	netdev@vger.kernel.org
+S:	Maintained
+F:	Documentation/devicetree/bindings/net/cortina,cs7542-ethernet.yaml
+F:	drivers/net/ethernet/cortina/cs752x_*
+
 ARM/CORTINA SYSTEMS GEMINI ARM ARCHITECTURE
 M:	Hans Ulli Kroll <ulli.kroll@googlemail.com>
 M:	Linus Walleij <linusw@kernel.org>

-- 
2.53.0

