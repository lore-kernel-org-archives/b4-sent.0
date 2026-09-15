From: Kyle Hendry <khendry@reliablecontrols.com>
Date: Tue, 15 Sep 2026 10:39:20 -0700
Subject: [PATCH net v5] net: pcs: rzn1-miic: Fix config array
 initialization
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260915-rzn1-miic-fix-array-v5-1-b7173fd5b97d@reliablecontrols.com>
X-B4-Tracking: v=1; b=H4sIAMeCqWoC/33NQW7CMBAF0KsgrzvI4zhx3FXvUbEww7hYCnZlR
 xEU5e412cAiZPnn67+5i8I5cBGfu7vIPIUSUqyh/dgJOrv4wxBONQslVSd7bCD/RYRLCAQ+XMH
 l7G7AnWOtW0USjajL38y1XNRvEXkUh3o8hzKmfFs+TbhUm+iEgHBse3KeyKLhr8xDcMeBKcUxp
 6HsKV0WelJPzkpc5xRIaNhKI7VlY+QG17xyap1rHpw3JyLvnW/dBqdfONTrnK6c7Cyi8szUd2+
 4eZ7/AVtCHJuzAQAA
To: =?utf-8?q?Cl=C3=A9ment_L=C3=A9ger?= <clement.leger@bootlin.com>, 
 Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: Lad Prabhakar <prabhakar.mahadev-lad.rj@bp.renesas.com>, 
 linux-renesas-soc@vger.kernel.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Geert Uytterhoeven <geert+renesas@glider.be>, 
 Kyle Hendry <khendry@reliablecontrols.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789493977; l=2005;
 i=khendry@reliablecontrols.com; s=20260813; h=from:subject:message-id;
 bh=I5i1St31oPo6d7N+HMb7ky+0UtXFiiyAOVC61bDQiwI=;
 b=zw5AD/zG7P/DBb2uXZ1IYVXEZMobeYcifInldvzVGBL52emRFgSyi7IJ1pn44x6B0axvooYqo
 dEOoW+Taqm+B5/AuG/p3mZow7Mk4GGOPHFaQnSF97FCcD+aX+0UGj2r
X-Developer-Key: i=khendry@reliablecontrols.com; a=ed25519;
 pk=gbK6oghz3qBlBiaGCsEzALLOtj5VklmsuolHQNhDV5M=
X-Endpoint-Received: by B4 Relay for khendry@reliablecontrols.com/20260813 with auth_id=946
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix memset parameters to initialize the entire DT value array

Fixes: f39e968dc168a7bd ("net: pcs: rzn1-miic: Move configuration data to SoC-specific struct")
Reviewed-by: Geert Uytterhoeven <geert+renesas@glider.be>
Signed-off-by: Kyle Hendry <khendry@reliablecontrols.com>
---
Fix issues when populating dt_val array from device tree values

Changes in v5:
 * Target memset patch for net 
 * Drop port number validation patch for later submission to net-next 

Changes in v4: https://lore.kernel.org/r/20260914-rzn1-miic-fix-array-v4-0-069112feec86@reliablecontrols.com
 * Fix lines longer than 80 char
 * Add of_node_put() before returning

Changes in v3: https://lore.kernel.org/r/20260902-rzn1-miic-fix-array-v3-0-3f7dccffaf5a@reliablecontrols.com
 * Make invalid port number return error
 * Update commit tags

Changes in v2: https://lore.kernel.org/r/20260901-rzn1-miic-fix-array-v2-0-3e907049e770@reliablecontrols.com
 * Use a more correct array size in memset
 * Ensure that write to dt_val is in range

Link to v1: https://lore.kernel.org/r/20260813-rzn1-miic-fix-array-v1-1-b58cafcc917e@reliablecontrols.com
---
 drivers/net/pcs/pcs-rzn1-miic.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/net/pcs/pcs-rzn1-miic.c b/drivers/net/pcs/pcs-rzn1-miic.c
index 2b72fa98ddf1..cb74861e823c 100644
--- a/drivers/net/pcs/pcs-rzn1-miic.c
+++ b/drivers/net/pcs/pcs-rzn1-miic.c
@@ -683,7 +683,8 @@ static int miic_parse_dt(struct miic *miic, u32 *mode_cfg)
 	if (!dt_val)
 		return -ENOMEM;
 
-	memset(dt_val, MIIC_MODCTRL_CONF_NONE, sizeof(*dt_val));
+	memset(dt_val, MIIC_MODCTRL_CONF_NONE,
+	       sizeof(*dt_val) * miic->of_data->conf_conv_count);
 
 	if (of_property_read_u32(np, "renesas,miic-switch-portin", &conf) == 0)
 		dt_val[0] = conf;

---
base-commit: 83a945a529d6e002dd7339c532288a931f463dba
change-id: 20260813-rzn1-miic-fix-array-e6ae4452c017

Best regards,
-- 
Kyle Hendry <khendry@reliablecontrols.com>

