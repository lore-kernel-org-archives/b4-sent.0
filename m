From: Kyle Hendry <khendry@reliablecontrols.com>
Date: Tue, 01 Sep 2026 08:25:14 -0700
Subject: [PATCH v2 2/2] net: pcs: rzn1-miic: Verify port number from dtb
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260901-rzn1-miic-fix-array-v2-2-3e907049e770@reliablecontrols.com>
References: <20260901-rzn1-miic-fix-array-v2-0-3e907049e770@reliablecontrols.com>
In-Reply-To: <20260901-rzn1-miic-fix-array-v2-0-3e907049e770@reliablecontrols.com>
To: =?utf-8?q?Cl=C3=A9ment_L=C3=A9ger?= <clement.leger@bootlin.com>, 
 Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: linux-renesas-soc@vger.kernel.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Kyle Hendry <khendry@reliablecontrols.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788276361; l=849;
 i=khendry@reliablecontrols.com; s=20260813; h=from:subject:message-id;
 bh=MhdDRNQknn2In7ONbA9ybldet9EPrQ6NvlgOYYQTM4g=;
 b=PDONzxbysOXtFlP/eLhwwV0o5qxPXT3oW1m5JDIuv5AbKKGB+X1XTBDh6CfwYbmjNLDQ2/0qW
 2EZLXU1tUwIBmldJn5youpLenDxmqqBHjHT+JMIYlfdW7n7m0xssT6p
X-Developer-Key: i=khendry@reliablecontrols.com; a=ed25519;
 pk=gbK6oghz3qBlBiaGCsEzALLOtj5VklmsuolHQNhDV5M=
X-Endpoint-Received: by B4 Relay for khendry@reliablecontrols.com/20260813 with auth_id=946
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add check to make sure port number is in range before writing
to dt_val array

Signed-off-by: Kyle Hendry <khendry@reliablecontrols.com>
---
 drivers/net/pcs/pcs-rzn1-miic.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/drivers/net/pcs/pcs-rzn1-miic.c b/drivers/net/pcs/pcs-rzn1-miic.c
index c50b65d064fa..ebd73ed63896 100644
--- a/drivers/net/pcs/pcs-rzn1-miic.c
+++ b/drivers/net/pcs/pcs-rzn1-miic.c
@@ -692,6 +692,11 @@ static int miic_parse_dt(struct miic *miic, u32 *mode_cfg)
 		if (of_property_read_u32(conv, "reg", &port))
 			continue;
 
+		if (port < miic->of_data->miic_port_start || port > miic->of_data->miic_port_max) {
+			dev_err(miic->dev, "Port number out of range: %d\n", port);
+			continue;
+		}
+
 		if (of_property_read_u32(conv, "renesas,miic-input", &conf))
 			continue;
 

-- 
2.43.0

