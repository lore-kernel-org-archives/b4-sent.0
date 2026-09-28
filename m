From: Kyle Hendry <khendry@reliablecontrols.com>
Date: Mon, 28 Sep 2026 14:19:03 -0700
Subject: [PATCH net-next v2 1/3] net: pcs: rzn1-miic: Fix port numbering on
 RZ/T2H
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260928-miic-validate-dtb-v2-1-1ee3d33748e9@reliablecontrols.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790630370; l=911;
 i=khendry@reliablecontrols.com; s=20260813; h=from:subject:message-id;
 bh=IeosEy2220CsO/HfUbuKH2ER3bJwKIrqImDfBfTHa5c=;
 b=44tZkjaG38VvzANRTfwqSvQcjhG8i9NeLc5hJj4t67SbtutaOTMaTg3wGFqxpuXIsIN4rq+Ub
 rxi7wE1m38uDsL/gIzqojAelmOlDbu2MjCzxB2PyUKD76PE157Ai0NA
X-Developer-Key: i=khendry@reliablecontrols.com; a=ed25519;
 pk=gbK6oghz3qBlBiaGCsEzALLOtj5VklmsuolHQNhDV5M=
X-Endpoint-Received: by B4 Relay for khendry@reliablecontrols.com/20260813 with auth_id=946
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The port numbers on the RZ/T2H are documented as 0 to 3. Update the info
structure to reflect this.

Fixes: 08f89e42121d421b ("net: pcs: rzn1-miic: Add RZ/T2H MIIC support")
Signed-off-by: Kyle Hendry <khendry@reliablecontrols.com>
---
 drivers/net/pcs/pcs-rzn1-miic.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/net/pcs/pcs-rzn1-miic.c b/drivers/net/pcs/pcs-rzn1-miic.c
index cb74861e823c..df70309c2d97 100644
--- a/drivers/net/pcs/pcs-rzn1-miic.c
+++ b/drivers/net/pcs/pcs-rzn1-miic.c
@@ -838,7 +838,7 @@ static struct miic_of_data rzt2h_miic_of_data = {
 	.index_to_string = rzt2h_index_to_string,
 	.index_to_string_count = ARRAY_SIZE(rzt2h_index_to_string),
 	.miic_port_start = 0,
-	.miic_port_max = 4,
+	.miic_port_max = 3,
 	.sw_mode_mask = GENMASK(2, 0),
 	.reset_ids = rzt2h_reset_ids,
 	.reset_count = ARRAY_SIZE(rzt2h_reset_ids),

-- 
2.43.0

