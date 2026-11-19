From: Kyle Hendry <khendry@reliablecontrols.com>
Date: Thu, 19 Nov 2026 09:57:47 -0800
Subject: [PATCH 5/6] net: pcs: rzn1-miic: Add resets to rzn1 info structure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-rzn1-miic-resets-v1-5-feee2bb28bb4@reliablecontrols.com>
References: <20261119-rzn1-miic-resets-v1-0-feee2bb28bb4@reliablecontrols.com>
In-Reply-To: <20261119-rzn1-miic-resets-v1-0-feee2bb28bb4@reliablecontrols.com>
To: Geert Uytterhoeven <geert+renesas@glider.be>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Magnus Damm <magnus.damm@gmail.com>, 
 Fabrizio Castro <fabrizio.castro.jz@renesas.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 =?utf-8?q?Cl=C3=A9ment_L=C3=A9ger?= <clement.leger@bootlin.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Lad Prabhakar <prabhakar.mahadev-lad.rj@bp.renesas.com>, 
 Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>
Cc: linux-renesas-soc@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 netdev@vger.kernel.org, Kyle Hendry <khendry@reliablecontrols.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795111097; l=1138;
 i=khendry@reliablecontrols.com; s=20260813; h=from:subject:message-id;
 bh=J27gezGON7U1BSPHR97CeYos8JNMDptm1U9mPf2DCsA=;
 b=Vz5uGN4jIeTJ/CkeTD/1x37t5B6Ma5MB2Y+rjOEBO77+UJW3NMgViLHlU/WL/8ogQ2YuD04Te
 Lad8nu/LlflCkZPMcbhl7NLBiJIugLWelfCnW9pdQY7H0Dv0GanamHr
X-Developer-Key: i=khendry@reliablecontrols.com; a=ed25519;
 pk=gbK6oghz3qBlBiaGCsEzALLOtj5VklmsuolHQNhDV5M=
X-Endpoint-Received: by B4 Relay for khendry@reliablecontrols.com/20260813 with auth_id=946
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Update the rzn1 info structure to include the resets that the driver needs
to deassert

Signed-off-by: Kyle Hendry <khendry@reliablecontrols.com>
---
 drivers/net/pcs/pcs-rzn1-miic.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/drivers/net/pcs/pcs-rzn1-miic.c b/drivers/net/pcs/pcs-rzn1-miic.c
index f8bafce26bf1..38164502c08c 100644
--- a/drivers/net/pcs/pcs-rzn1-miic.c
+++ b/drivers/net/pcs/pcs-rzn1-miic.c
@@ -128,6 +128,11 @@ static const char * const index_to_string[] = {
 	"CONV5",
 };
 
+static const char * const rzn1_reset_ids[] = {
+	"rst_ts",
+	"rst_miic",
+};
+
 static struct modctrl_match rzt2h_modctrl_match_table[] = {
 	{0x0, {ETHSS_GMAC0_PORT, ETHSS_ETHSW_PORT0, ETHSS_ETHSW_PORT1,
 	       ETHSS_ETHSW_PORT2, ETHSS_GMAC1_PORT}},
@@ -855,6 +860,8 @@ static struct miic_of_data rzn1_miic_of_data = {
 	.miic_port_start = 1,
 	.miic_port_last = 5,
 	.sw_mode_mask = GENMASK(4, 0),
+	.reset_ids = rzn1_reset_ids,
+	.reset_count = ARRAY_SIZE(rzn1_reset_ids),
 	.init_unlock_lock_regs = true,
 	.miic_write = miic_reg_writel_unlocked,
 	.type = MIIC_TYPE_RZN1,

-- 
2.53.0

