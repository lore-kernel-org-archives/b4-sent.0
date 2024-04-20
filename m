From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Date: Sat, 20 Apr 2024 19:46:03 +0300
Subject: [PATCH 1/4] net: dsa: mt7530: set all CPU ports in MT7531_CPU_PMAP
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240420-for-stable-5-15-backports-v1-1-007bfa19d044@arinc9.com>
References: <20240420-for-stable-5-15-backports-v1-0-007bfa19d044@arinc9.com>
In-Reply-To: <20240420-for-stable-5-15-backports-v1-0-007bfa19d044@arinc9.com>
To: stable@vger.kernel.org
Cc: Daniel Golle <daniel@makrotopia.org>, 
 =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>, 
 "Russell King (Oracle)" <linux@armlinux.org.uk>, 
 Vladimir Oltean <olteanv@gmail.com>, 
 "Russell King (Oracle)" <rmk+kernel@armlinux.org.uk>, 
 Florian Fainelli <florian.fainelli@broadcom.com>, 
 "David S. Miller" <davem@davemloft.net>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1713631565; l=3098;
 i=arinc.unal@arinc9.com; s=arinc9-Xeront; h=from:subject:message-id;
 bh=1jifdxkrWQYraf0PSB8VTfdoDio0BvKtiHEyMvaYCdI=;
 b=4BMgQZs4PpjdeH+nDfWCSWtnnNaYqfiPmtjxwmcsxaMdhSjpXG6F15eQPsrlkZN0GNedMJjMm
 F1otPAYA3SQBWyKhhEJZAxBw3KXA7k1ynGl6pwOMOBM9jLqx0MX9QlN
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=z49tLn29CyiL4uwBTrqH9HO1Wu3sZIuRp4DaLZvtP9M=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-Xeront with auth_id=137
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

[ Upstream commit ff221029a51fd54cacac66e193e0c75e4de940e7 ]

MT7531_CPU_PMAP represents the destination port mask for trapped-to-CPU
frames (further restricted by PCR_MATRIX).

Currently the driver sets the first CPU port as the single port in this bit
mask, which works fine regardless of whether the device tree defines port
5, 6 or 5+6 as CPU ports. This is because the logic coincides with DSA's
logic of picking the first CPU port as the CPU port that all user ports are
affine to, by default.

An upcoming change would like to influence DSA's selection of the default
CPU port to no longer be the first one, and in that case, this logic needs
adaptation.

Since there is no observed leakage or duplication of frames if all CPU
ports are defined in this bit mask, simply include them all.

Suggested-by: Russell King (Oracle) <linux@armlinux.org.uk>
Suggested-by: Vladimir Oltean <olteanv@gmail.com>
Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
Reviewed-by: Vladimir Oltean <olteanv@gmail.com>
Reviewed-by: Russell King (Oracle) <rmk+kernel@armlinux.org.uk>
Reviewed-by: Florian Fainelli <florian.fainelli@broadcom.com>
Signed-off-by: David S. Miller <davem@davemloft.net>
Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
 drivers/net/dsa/mt7530.c | 15 +++++++--------
 drivers/net/dsa/mt7530.h |  1 +
 2 files changed, 8 insertions(+), 8 deletions(-)

diff --git a/drivers/net/dsa/mt7530.c b/drivers/net/dsa/mt7530.c
index f291d1e70f80..e3852cb48369 100644
--- a/drivers/net/dsa/mt7530.c
+++ b/drivers/net/dsa/mt7530.c
@@ -1232,6 +1232,13 @@ mt753x_cpu_port_enable(struct dsa_switch *ds, int port)
 	if (priv->id == ID_MT7530 || priv->id == ID_MT7621)
 		mt7530_rmw(priv, MT7530_MFC, CPU_MASK, CPU_EN | CPU_PORT(port));
 
+	/* Add the CPU port to the CPU port bitmap for MT7531. Trapped frames
+	 * will be forwarded to the CPU port that is affine to the inbound user
+	 * port.
+	 */
+	if (priv->id == ID_MT7531)
+		mt7530_set(priv, MT7531_CFC, MT7531_CPU_PMAP(BIT(port)));
+
 	/* CPU port gets connected to all user ports of
 	 * the switch.
 	 */
@@ -2507,16 +2514,8 @@ static int
 mt7531_setup_common(struct dsa_switch *ds)
 {
 	struct mt7530_priv *priv = ds->priv;
-	struct dsa_port *cpu_dp;
 	int ret, i;
 
-	/* BPDU to CPU port */
-	dsa_switch_for_each_cpu_port(cpu_dp, ds) {
-		mt7530_rmw(priv, MT7531_CFC, MT7531_CPU_PMAP_MASK,
-			   BIT(cpu_dp->index));
-		break;
-	}
-
 	mt753x_trap_frames(priv);
 
 	/* Enable and reset MIB counters */
diff --git a/drivers/net/dsa/mt7530.h b/drivers/net/dsa/mt7530.h
index 299a26ad5809..22152d74b327 100644
--- a/drivers/net/dsa/mt7530.h
+++ b/drivers/net/dsa/mt7530.h
@@ -54,6 +54,7 @@ enum mt753x_id {
 #define  MT7531_MIRROR_PORT_GET(x)	(((x) >> 16) & MIRROR_MASK)
 #define  MT7531_MIRROR_PORT_SET(x)	(((x) & MIRROR_MASK) << 16)
 #define  MT7531_CPU_PMAP_MASK		GENMASK(7, 0)
+#define  MT7531_CPU_PMAP(x)		FIELD_PREP(MT7531_CPU_PMAP_MASK, x)
 
 #define MT753X_MIRROR_REG(id)		(((id) == ID_MT7531) ? \
 					 MT7531_CFC : MT7530_MFC)

-- 
2.40.1

