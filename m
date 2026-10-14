From: Kyle Hendry <khendry@reliablecontrols.com>
Date: Wed, 14 Oct 2026 08:32:37 -0700
Subject: [PATCH net-next v4 1/2] net: pcs: rzn1-miic: Update port numbering
 for RZ/T2H
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261014-miic-validate-dtb-v3-v4-1-b7da71b3a106@reliablecontrols.com>
References: <20261014-miic-validate-dtb-v3-v4-0-b7da71b3a106@reliablecontrols.com>
In-Reply-To: <20261014-miic-validate-dtb-v3-v4-0-b7da71b3a106@reliablecontrols.com>
To: =?utf-8?q?Cl=C3=A9ment_L=C3=A9ger?= <clement.leger@bootlin.com>, 
 Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Geert Uytterhoeven <geert+renesas@glider.be>, 
 Magnus Damm <magnus.damm@gmail.com>, 
 Lad Prabhakar <prabhakar.mahadev-lad.rj@bp.renesas.com>
Cc: linux-renesas-soc@vger.kernel.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Kyle Hendry <khendry@reliablecontrols.com>, 
 Simon Horman <horms@kernel.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791992021; l=3420;
 i=khendry@reliablecontrols.com; s=20260813; h=from:subject:message-id;
 bh=NbAhI/930UTKOHE1+KiQcIf4bFDLOz50/D7XQzywphU=;
 b=YJZwhw1N9i08o1HJNveHFRMf1fvUUTPq0YhmUirjWvd3QS8iYftyvznPKQRdV4KxbbEEabmUZ
 VfFz+Ztu7HGA+SVmPg8xxN+Z/A6ZgdIgEjldRc+4qovlcBU5H7MuSI/
X-Developer-Key: i=khendry@reliablecontrols.com; a=ed25519;
 pk=gbK6oghz3qBlBiaGCsEzALLOtj5VklmsuolHQNhDV5M=
X-Endpoint-Received: by B4 Relay for khendry@reliablecontrols.com/20260813 with auth_id=946
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The port numbers on the RZ/T2H are documented as 0 to 3. Update the info
structure and change the member name to miic_port_last to be more accurate.

This value was being used as the number of miic registers when setting
default values. Add logic to get the total port count and loop over that.

Reviewed-by: Lad Prabhakar <prabhakar.mahadev-lad.rj@bp.renesas.com>
Reviewed-by: Simon Horman <horms@kernel.org>
Signed-off-by: Kyle Hendry <khendry@reliablecontrols.com>
---
 drivers/net/pcs/pcs-rzn1-miic.c | 16 ++++++++++------
 1 file changed, 10 insertions(+), 6 deletions(-)

diff --git a/drivers/net/pcs/pcs-rzn1-miic.c b/drivers/net/pcs/pcs-rzn1-miic.c
index 3aa513467060..31716241b58f 100644
--- a/drivers/net/pcs/pcs-rzn1-miic.c
+++ b/drivers/net/pcs/pcs-rzn1-miic.c
@@ -222,7 +222,7 @@ enum miic_type {
  * @index_to_string: String representations of the index values
  * @index_to_string_count: Number of entries in the index_to_string array
  * @miic_port_start: MIIC port start number
- * @miic_port_max: Maximum MIIC supported
+ * @miic_port_last: MIIC port last number
  * @sw_mode_mask: Switch mode mask
  * @reset_ids: Reset names array
  * @reset_count: Number of entries in the reset_ids array
@@ -240,7 +240,7 @@ struct miic_of_data {
 	const char * const *index_to_string;
 	u8 index_to_string_count;
 	u8 miic_port_start;
-	u8 miic_port_max;
+	u8 miic_port_last;
 	u8 sw_mode_mask;
 	const char * const *reset_ids;
 	u8 reset_count;
@@ -485,7 +485,7 @@ struct phylink_pcs *miic_create(struct device *dev, struct device_node *np)
 
 	miic = platform_get_drvdata(pdev);
 	of_data = miic->of_data;
-	if (port > of_data->miic_port_max || port < of_data->miic_port_start) {
+	if (port > of_data->miic_port_last || port < of_data->miic_port_start) {
 		put_device(&pdev->dev);
 		return ERR_PTR(-EINVAL);
 	}
@@ -523,6 +523,7 @@ EXPORT_SYMBOL(miic_destroy);
 static int miic_init_hw(struct miic *miic, u32 cfg_mode)
 {
 	u8 sw_mode_mask = miic->of_data->sw_mode_mask;
+	int num_ports;
 	int port;
 
 	/* Unlock write access to accessory registers (cf datasheet). If this
@@ -538,7 +539,10 @@ static int miic_init_hw(struct miic *miic, u32 cfg_mode)
 	miic_reg_writel(miic, MIIC_MODCTRL,
 			((cfg_mode << __ffs(sw_mode_mask)) & sw_mode_mask));
 
-	for (port = 0; port < miic->of_data->miic_port_max; port++) {
+	num_ports = miic->of_data->miic_port_last -
+		miic->of_data->miic_port_start + 1;
+
+	for (port = 0; port < num_ports; port++) {
 		miic_converter_enable(miic, port, 0);
 		/* Disable speed/duplex control from these registers, datasheet
 		 * says switch registers should be used to setup switch port
@@ -825,7 +829,7 @@ static struct miic_of_data rzn1_miic_of_data = {
 	.index_to_string = index_to_string,
 	.index_to_string_count = ARRAY_SIZE(index_to_string),
 	.miic_port_start = 1,
-	.miic_port_max = 5,
+	.miic_port_last = 5,
 	.sw_mode_mask = GENMASK(4, 0),
 	.init_unlock_lock_regs = true,
 	.miic_write = miic_reg_writel_unlocked,
@@ -841,7 +845,7 @@ static struct miic_of_data rzt2h_miic_of_data = {
 	.index_to_string = rzt2h_index_to_string,
 	.index_to_string_count = ARRAY_SIZE(rzt2h_index_to_string),
 	.miic_port_start = 0,
-	.miic_port_max = 4,
+	.miic_port_last = 3,
 	.sw_mode_mask = GENMASK(2, 0),
 	.reset_ids = rzt2h_reset_ids,
 	.reset_count = ARRAY_SIZE(rzt2h_reset_ids),

-- 
2.43.0

