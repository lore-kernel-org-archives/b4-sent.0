From: Kyle Hendry <khendry@reliablecontrols.com>
Date: Tue, 06 Oct 2026 09:48:12 -0700
Subject: [PATCH net-next v3 2/2] net: pcs: rzn1-miic: Validate dtb
 configuration values
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261006-miic-validate-dtb-v3-v3-2-68617b3dca5c@reliablecontrols.com>
References: <20261006-miic-validate-dtb-v3-v3-0-68617b3dca5c@reliablecontrols.com>
In-Reply-To: <20261006-miic-validate-dtb-v3-v3-0-68617b3dca5c@reliablecontrols.com>
To: =?utf-8?q?Cl=C3=A9ment_L=C3=A9ger?= <clement.leger@bootlin.com>, 
 Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Geert Uytterhoeven <geert+renesas@glider.be>, 
 Magnus Damm <magnus.damm@gmail.com>, 
 Lad Prabhakar <prabhakar.mahadev-lad.rj@bp.renesas.com>
Cc: linux-renesas-soc@vger.kernel.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Kyle Hendry <khendry@reliablecontrols.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791305291; l=2074;
 i=khendry@reliablecontrols.com; s=20260813; h=from:subject:message-id;
 bh=rh2Dcek7AiGyq5ptOIllWqGdXv30G3hZhhl5GyDj+QM=;
 b=q72XgUapW/3WF5cmnfx4FD2xiHg0BZWVXkjtPfoO0AZ901xVBRxYSmS3Wq510X2vb113u5Rbe
 p/jetY+aKdPCbX7GjWwuNH5b1yLpN2JRdo8n+ryd5k/Pec9jhz12EFC
X-Developer-Key: i=khendry@reliablecontrols.com; a=ed25519;
 pk=gbK6oghz3qBlBiaGCsEzALLOtj5VklmsuolHQNhDV5M=
X-Endpoint-Received: by B4 Relay for khendry@reliablecontrols.com/20260813 with auth_id=946
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Bad configuration values from the dtb could result in out of bounds array
access. Verify parsed values are within range for the SoC and fail the
probe if invalid.

Signed-off-by: Kyle Hendry <khendry@reliablecontrols.com>
---
 drivers/net/pcs/pcs-rzn1-miic.c | 29 +++++++++++++++++++++++++++--
 1 file changed, 27 insertions(+), 2 deletions(-)

diff --git a/drivers/net/pcs/pcs-rzn1-miic.c b/drivers/net/pcs/pcs-rzn1-miic.c
index 31716241b58f..10622eb654d2 100644
--- a/drivers/net/pcs/pcs-rzn1-miic.c
+++ b/drivers/net/pcs/pcs-rzn1-miic.c
@@ -693,16 +693,40 @@ static int miic_parse_dt(struct miic *miic, u32 *mode_cfg)
 	memset(dt_val, MIIC_MODCTRL_CONF_NONE,
 	       sizeof(*dt_val) * miic->of_data->conf_conv_count);
 
-	if (of_property_read_u32(np, "renesas,miic-switch-portin", &conf) == 0)
-		dt_val[0] = conf;
+	if (of_property_read_u32(np, "renesas,miic-switch-portin", &conf) == 0) {
+		if (conf >= miic->of_data->conf_to_string_count) {
+			dev_err(miic->dev, "Port input configuration out of range: %d\n",
+				conf);
+			ret = -EINVAL;
+			goto err;
+		} else {
+			dt_val[0] = conf;
+		}
+	}
 
 	for_each_available_child_of_node(np, conv) {
 		if (of_property_read_u32(conv, "reg", &port))
 			continue;
 
+		if (port < miic->of_data->miic_port_start ||
+		    port > miic->of_data->miic_port_last) {
+			dev_err(miic->dev, "Port number out of range: %d\n", port);
+			of_node_put(conv);
+			ret = -EINVAL;
+			goto err;
+		}
+
 		if (of_property_read_u32(conv, "renesas,miic-input", &conf))
 			continue;
 
+		if (conf >= miic->of_data->conf_to_string_count) {
+			dev_err(miic->dev, "Port %d configuration out of range: %d\n",
+				port, conf);
+			of_node_put(conv);
+			ret = -EINVAL;
+			goto err;
+		}
+
 		/* Adjust for 0 based index */
 		dt_val[port + !miic->of_data->miic_port_start] = conf;
 
@@ -712,6 +736,7 @@ static int miic_parse_dt(struct miic *miic, u32 *mode_cfg)
 	}
 
 	ret = miic_match_dt_conf(miic, dt_val, mode_cfg);
+err:
 	kfree(dt_val);
 
 	return ret;

-- 
2.43.0

