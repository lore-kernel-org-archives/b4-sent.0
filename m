From: Kyle Hendry <khendry@reliablecontrols.com>
Date: Mon, 28 Sep 2026 14:19:04 -0700
Subject: [PATCH net-next v2 2/3] net: pcs: rzn1-miic: Fix miic register
 initialization loop
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260928-miic-validate-dtb-v2-2-1ee3d33748e9@reliablecontrols.com>
References: <20260928-miic-validate-dtb-v2-0-1ee3d33748e9@reliablecontrols.com>
In-Reply-To: <20260928-miic-validate-dtb-v2-0-1ee3d33748e9@reliablecontrols.com>
To: =?utf-8?q?Cl=C3=A9ment_L=C3=A9ger?= <clement.leger@bootlin.com>, 
 Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Lad Prabhakar <prabhakar.mahadev-lad.rj@bp.renesas.com>
Cc: linux-renesas-soc@vger.kernel.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Kyle Hendry <khendry@reliablecontrols.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790630370; l=1506;
 i=khendry@reliablecontrols.com; s=20260813; h=from:subject:message-id;
 bh=MeWwaPFPGgQ87CIdgWZjV/qJ5i7/Sn8eqK39QKBx+dg=;
 b=P9B0WRGYWgL47uKob0ASKkRxyPSYsKI1IB4Df8MMYW8pQDVkDcON+wMUMfm7a+xNK5MvCkpq0
 UW/9sSe73TgDBiDbJ1ISSNMaCEf0MldaNlM48VSzvlRbO0Vy0M4TXo+
X-Developer-Key: i=khendry@reliablecontrols.com; a=ed25519;
 pk=gbK6oghz3qBlBiaGCsEzALLOtj5VklmsuolHQNhDV5M=
X-Endpoint-Received: by B4 Relay for khendry@reliablecontrols.com/20260813 with auth_id=946
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The function to write default values to miic registers was looping from
zero to miic_port_max, which might not cover all ports depending on SoC
numbering. Determine the port count from SoC data and loop over that.

Fixes: c112520de041758e ("net: pcs: rzn1-miic: move port range handling into SoC data")
Signed-off-by: Kyle Hendry <khendry@reliablecontrols.com>
---
 drivers/net/pcs/pcs-rzn1-miic.c | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)

diff --git a/drivers/net/pcs/pcs-rzn1-miic.c b/drivers/net/pcs/pcs-rzn1-miic.c
index df70309c2d97..9e830932ce49 100644
--- a/drivers/net/pcs/pcs-rzn1-miic.c
+++ b/drivers/net/pcs/pcs-rzn1-miic.c
@@ -520,6 +520,7 @@ EXPORT_SYMBOL(miic_destroy);
 static int miic_init_hw(struct miic *miic, u32 cfg_mode)
 {
 	u8 sw_mode_mask = miic->of_data->sw_mode_mask;
+	int num_ports;
 	int port;
 
 	/* Unlock write access to accessory registers (cf datasheet). If this
@@ -535,7 +536,10 @@ static int miic_init_hw(struct miic *miic, u32 cfg_mode)
 	miic_reg_writel(miic, MIIC_MODCTRL,
 			((cfg_mode << __ffs(sw_mode_mask)) & sw_mode_mask));
 
-	for (port = 0; port < miic->of_data->miic_port_max; port++) {
+	num_ports = miic->of_data->miic_port_max -
+		miic->of_data->miic_port_start + 1;
+
+	for (port = 0; port < num_ports; port++) {
 		miic_converter_enable(miic, port, 0);
 		/* Disable speed/duplex control from these registers, datasheet
 		 * says switch registers should be used to setup switch port

-- 
2.43.0

