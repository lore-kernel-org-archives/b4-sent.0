From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Date: Sun, 28 Apr 2024 12:19:58 +0300
Subject: [PATCH net-next v2] net: dsa: mt7530: do not set MT7530_P5_DIS
 when PHY muxing is being used
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240428-for-netnext-mt7530-do-not-disable-port5-when-phy-muxing-v2-1-bb7c37d293f8@arinc9.com>
X-B4-Tracking: v=1; b=H4sIAL0ULmYC/6WOQQqDMBBFryKz7pQYlZCueo/iwpqJDtREktQq4
 t2beoUuHx/e+ztECkwRbsUOgRaO7F0GeSmgHzs3ELLJDFLIWtRSofUBHSVHa8IpqaYSaDw6n9B
 w7J4vwtmH1OBnJIfzuOH0XtkNqKxtrBFaN0ZBts+BLK9n+QFZiD8jtHkZOSYftvPSUp773/Wlx
 BKVrnpjtVFKqHsX2PX62vsJ2uM4voIqUjcJAQAA
To: Daniel Golle <daniel@makrotopia.org>, DENG Qingfang <dqfext@gmail.com>, 
 Sean Wang <sean.wang@mediatek.com>, Andrew Lunn <andrew@lunn.ch>, 
 Florian Fainelli <f.fainelli@gmail.com>, 
 Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1714295997; l=2134;
 i=arinc.unal@arinc9.com; s=arinc9-patatt; h=from:subject:message-id;
 bh=mooBBatpyIktEez2DpRO7+tS0DbjK7qafqYlayMk1R4=;
 b=EH/F59K96vk3QVfn9tauaQDX4oX1KGLZrhENnMQ3zPIzdDGpVuG9d19WaDUmDkSL9oXlKYEUD
 RqTQzjjJFslCKXPH20Nulu1HorEX1WU6Kmh1q5sJpvuvG/541ly6mX6
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=VmvgMWwm73yVIrlyJYvGtnXkQJy9CvbaeEqPQO9Z4kA=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-patatt with auth_id=115
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

DSA initalises the ds->num_ports amount of ports in
dsa_switch_touch_ports(). When the PHY muxing feature is in use, port 5
won't be defined in the device tree. Because of this, the type member of
the dsa_port structure for this port will be assigned DSA_PORT_TYPE_UNUSED.
The dsa_port_setup() function calls ds->ops->port_disable() when the port
type is DSA_PORT_TYPE_UNUSED.

The MT7530_P5_DIS bit is unset in mt7530_setup() when PHY muxing is being
used. mt7530_port_disable() which is assigned to ds->ops->port_disable() is
called afterwards. Currently, mt7530_port_disable() sets MT7530_P5_DIS
which breaks network connectivity when PHY muxing is being used.

Therefore, do not set MT7530_P5_DIS when PHY muxing is being used.

Fixes: 377174c5760c ("net: dsa: mt7530: move MT753X_MTRAP operations for MT7530")
Reported-by: Daniel Golle <daniel@makrotopia.org>
Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
Hello.

I've sent this to net-next as the patch it fixes is on the current
development cycle.
---
Changes in v2:
- Add a comment to the code.
- Improve the patch log.
- Link to v1: https://lore.kernel.org/r/20240427-for-netnext-mt7530-do-not-disable-port5-when-phy-muxing-v1-1-793cdf9d7707@arinc9.com
---
 drivers/net/dsa/mt7530.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/net/dsa/mt7530.c b/drivers/net/dsa/mt7530.c
index 2b9f904a98f0..2090f34e5289 100644
--- a/drivers/net/dsa/mt7530.c
+++ b/drivers/net/dsa/mt7530.c
@@ -1220,7 +1220,8 @@ mt7530_port_disable(struct dsa_switch *ds, int port)
 	if (priv->id != ID_MT7530 && priv->id != ID_MT7621)
 		return;
 
-	if (port == 5)
+	/* Do not set MT7530_P5_DIS when port 5 is being used for PHY muxing. */
+	if (port == 5 && priv->p5_mode == GMAC5)
 		mt7530_set(priv, MT753X_MTRAP, MT7530_P5_DIS);
 	else if (port == 6)
 		mt7530_set(priv, MT753X_MTRAP, MT7530_P6_DIS);

---
base-commit: 5c4c0edca68a5841a8d53ccd49596fe199c8334c
change-id: 20240427-for-netnext-mt7530-do-not-disable-port5-when-phy-muxing-7ff5fd0995d7

Best regards,
-- 
Arınç ÜNAL <arinc.unal@arinc9.com>

