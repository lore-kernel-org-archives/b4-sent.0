From: Kyle Hendry <khendry@reliablecontrols.com>
Date: Mon, 28 Sep 2026 14:19:05 -0700
Subject: [PATCH net-next v2 3/3] net: pcs: rzn1-miic: Validate dtb
 configuration values
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260928-miic-validate-dtb-v2-3-1ee3d33748e9@reliablecontrols.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790630370; l=1492;
 i=khendry@reliablecontrols.com; s=20260813; h=from:subject:message-id;
 bh=clQZX/3JFDNrGYwhzOKSNQpXnXVFJYWjpbM5PuE95UU=;
 b=y8v1uZmr9LuXEgzQYhC8g8vTHmbAKBAwptdnvlbdZNniLR7rF8LdPiIdge+qTMo/cgyJTmm85
 G3gBUpu9tJoAN1TOWBFnJh+p6tAL1cNtRqUor386OhlMjSbBVxamGeg
X-Developer-Key: i=khendry@reliablecontrols.com; a=ed25519;
 pk=gbK6oghz3qBlBiaGCsEzALLOtj5VklmsuolHQNhDV5M=
X-Endpoint-Received: by B4 Relay for khendry@reliablecontrols.com/20260813 with auth_id=946
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Bad configuration values from the dtb could result in out of bounds array
access. Verify parsed values are within range for the SoC and fail the
probe if invalid.

Signed-off-by: Kyle Hendry <khendry@reliablecontrols.com>
---
 drivers/net/pcs/pcs-rzn1-miic.c | 17 +++++++++++++++++
 1 file changed, 17 insertions(+)

diff --git a/drivers/net/pcs/pcs-rzn1-miic.c b/drivers/net/pcs/pcs-rzn1-miic.c
index 9e830932ce49..9a4c6d3b7d42 100644
--- a/drivers/net/pcs/pcs-rzn1-miic.c
+++ b/drivers/net/pcs/pcs-rzn1-miic.c
@@ -697,9 +697,25 @@ static int miic_parse_dt(struct miic *miic, u32 *mode_cfg)
 		if (of_property_read_u32(conv, "reg", &port))
 			continue;
 
+		if (port < miic->of_data->miic_port_start ||
+		    port > miic->of_data->miic_port_max) {
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
 
@@ -709,6 +725,7 @@ static int miic_parse_dt(struct miic *miic, u32 *mode_cfg)
 	}
 
 	ret = miic_match_dt_conf(miic, dt_val, mode_cfg);
+err:
 	kfree(dt_val);
 
 	return ret;

-- 
2.43.0

