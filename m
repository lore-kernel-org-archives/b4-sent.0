From: Kyle Hendry <khendry@reliablecontrols.com>
Date: Wed, 02 Sep 2026 11:37:35 -0700
Subject: [PATCH v3 1/2] net: pcs: rzn1-miic: Fix config array
 initialization
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260902-rzn1-miic-fix-array-v3-1-3f7dccffaf5a@reliablecontrols.com>
References: <20260902-rzn1-miic-fix-array-v3-0-3f7dccffaf5a@reliablecontrols.com>
In-Reply-To: <20260902-rzn1-miic-fix-array-v3-0-3f7dccffaf5a@reliablecontrols.com>
To: =?utf-8?q?Cl=C3=A9ment_L=C3=A9ger?= <clement.leger@bootlin.com>, 
 Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: Lad Prabhakar <prabhakar.mahadev-lad.rj@bp.renesas.com>, 
 linux-renesas-soc@vger.kernel.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Kyle Hendry <khendry@reliablecontrols.com>, 
 Geert Uytterhoeven <geert+renesas@glider.be>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788374255; l=1005;
 i=khendry@reliablecontrols.com; s=20260813; h=from:subject:message-id;
 bh=Vsf+EiFzG6nMe9xQ+3XHfq7t6HfrKg+ZnzFZjQBKGmM=;
 b=dKEbW0vShEYPMIX64OSNP6t+EQMXEFA+TMJB6MHuBlvypdp8lxwsgUtNMFWqzPaiZSQd73gW0
 T0F0OWIcuWKB1vlvBMgQ+lFdkGuoeF/ouzrbhth4nYbf0fDVY/Js6t1
X-Developer-Key: i=khendry@reliablecontrols.com; a=ed25519;
 pk=gbK6oghz3qBlBiaGCsEzALLOtj5VklmsuolHQNhDV5M=
X-Endpoint-Received: by B4 Relay for khendry@reliablecontrols.com/20260813 with auth_id=946
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix memset parameters to initialize the entire DT value array

Fixes: f39e968dc168a7bd ("net: pcs: rzn1-miic: Move configuration data to SoC-specific struct")
Reviewed-by: Geert Uytterhoeven <geert+renesas@glider.be>
Reviewed-by: Andrew Lunn <andrew@lunn.ch>
Signed-off-by: Kyle Hendry <khendry@reliablecontrols.com>
---
 drivers/net/pcs/pcs-rzn1-miic.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/net/pcs/pcs-rzn1-miic.c b/drivers/net/pcs/pcs-rzn1-miic.c
index 2b72fa98ddf1..c50b65d064fa 100644
--- a/drivers/net/pcs/pcs-rzn1-miic.c
+++ b/drivers/net/pcs/pcs-rzn1-miic.c
@@ -683,7 +683,7 @@ static int miic_parse_dt(struct miic *miic, u32 *mode_cfg)
 	if (!dt_val)
 		return -ENOMEM;
 
-	memset(dt_val, MIIC_MODCTRL_CONF_NONE, sizeof(*dt_val));
+	memset(dt_val, MIIC_MODCTRL_CONF_NONE, sizeof(*dt_val) * miic->of_data->conf_conv_count);
 
 	if (of_property_read_u32(np, "renesas,miic-switch-portin", &conf) == 0)
 		dt_val[0] = conf;

-- 
2.43.0

