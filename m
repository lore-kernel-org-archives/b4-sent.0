From: Kyle Hendry <khendry@reliablecontrols.com>
Subject: [PATCH net-next v3 0/2] net: pcs: rzn1-miic: Validate dtb
 configuration values
Date: Tue, 06 Oct 2026 09:48:10 -0700
Message-Id: <20261006-miic-validate-dtb-v3-v3-0-68617b3dca5c@reliablecontrols.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEomxWoC/x3MSwqDMBRG4a3IHfdCHihttyIdxORXL7SpJCEI4
 t4NDr/BOQdlJEGmd3dQQpUs/9hgHx351cUFLKGZjDKDVqrnn4jn6r4SXAGHMnG17Gern0b5SeN
 FLd0SZtnv7UgRhSP2Qp/zvACslybCcAAAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791305291; l=1340;
 i=khendry@reliablecontrols.com; s=20260813; h=from:subject:message-id;
 bh=zXSXQbCwcrgf1rnHXh1JMPBFTzcV1b9TDrQgc1cAtkQ=;
 b=+gvUdgGmUhXtWwCRIbXud22BVaXjP4blOyp0hcOw5wX7yqK/y3BIbqys32ea3CA7CiOWi9Q9j
 gOySn5oEgfSCeKdjy/BBUM1hP5HrgABZ9r7kzPLgTGaY6a0VhAy/Xmv
X-Developer-Key: i=khendry@reliablecontrols.com; a=ed25519;
 pk=gbK6oghz3qBlBiaGCsEzALLOtj5VklmsuolHQNhDV5M=
X-Endpoint-Received: by B4 Relay for khendry@reliablecontrols.com/20260813 with auth_id=946
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series addresses issues found when reviewing another fix:
https://lore.kernel.org/netdev/20260915-rzn1-miic-fix-array-v5-1-b7173fd5b97d@reliablecontrols.com/

Invalid values from the dtb could cause out of bounds array access. Checking
the values as they're parsed should prevent this.

Changes in v3:
- Squash patches changing miic_port_max
- Change name of miic_port_max to miic_port_last
- Remove fixes tags
- Add another check for configuration value of miic-switch-portin
- Link to v2: https://lore.kernel.org/r/20260928-miic-validate-dtb-v2-0-1ee3d33748e9@reliablecontrols.com/

Changes in v2:
- Simplify fixes by making miic_port_max the last documented port number
- Add fixes tags
- Link to v1: https://lore.kernel.org/r/20260925-miic-validate-dtb-v1-0-3a6db9bb75ec@reliablecontrols.com

Signed-off-by: Kyle Hendry <khendry@reliablecontrols.com>
---
Kyle Hendry (2):
      net: pcs: rzn1-miic: Update port numbering for RZ/T2H
      net: pcs: rzn1-miic: Validate dtb configuration values

 drivers/net/pcs/pcs-rzn1-miic.c | 45 +++++++++++++++++++++++++++++++++--------
 1 file changed, 37 insertions(+), 8 deletions(-)
---
base-commit: a5e7d8e446af9803e37a3b6a4d416fb41178348f
change-id: 20261005-miic-validate-dtb-v3-cf31820cb1e9

Best regards,
-- 
Kyle Hendry <khendry@reliablecontrols.com>

