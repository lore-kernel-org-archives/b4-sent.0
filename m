From: Kyle Hendry <khendry@reliablecontrols.com>
Subject: [PATCH net-next v4 0/2] net: pcs: rzn1-miic: Validate dtb
 configuration values
Date: Wed, 14 Oct 2026 08:32:36 -0700
Message-Id: <20261014-miic-validate-dtb-v3-v4-0-b7da71b3a106@reliablecontrols.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJSgz2oC/22NywrCMBREf6XctZG0sbG68j+kizxu7YU0kSSES
 um/G4pLYTaHYc5skDASJrg3G0QslCj4CpdTA2ZW/oWMbGXoeCdbznu2EBlWlCOrMjKbNSuCmUm
 0Q8eNbvEGdfqOONF6aJ/gMTOPa4axNjOlHOLn+Cvi6H9q+V9dw5kcZHvVwhrVm0dER0o7NMHnG
 Fw6m7DAuO/7F8fWy9XNAAAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791992021; l=1495;
 i=khendry@reliablecontrols.com; s=20260813; h=from:subject:message-id;
 bh=mK7HAM4nMy4eEc0HHmNewb99Ljc1vlTbcL9mEAk0cf8=;
 b=iQkkI44ZNIWO2ba6mqSz9/slYIXSk9aYbVZBhy9HGZyz/1OfIshgOsbZG7CieLxdkoQN2coYy
 IgVCN2TP9zUCtQh6vccqZ25NReIH+WqzHB9rCh5473buUPLgBj2H+5r
X-Developer-Key: i=khendry@reliablecontrols.com; a=ed25519;
 pk=gbK6oghz3qBlBiaGCsEzALLOtj5VklmsuolHQNhDV5M=
X-Endpoint-Received: by B4 Relay for khendry@reliablecontrols.com/20260813 with auth_id=946
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series addresses issues found when reviewing another fix:
https://lore.kernel.org/netdev/20260915-rzn1-miic-fix-array-v5-1-b7173fd5b97d@reliablecontrols.com/

Invalid values from the dtb could cause out of bounds array access. Checking
the values as they're parsed should prevent this.

Changes in v4:
- Remove unnecessary else
- Link to v3: https://lore.kernel.org/r/20261006-miic-validate-dtb-v3-v3-0-68617b3dca5c@reliablecontrols.com

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

 drivers/net/pcs/pcs-rzn1-miic.c | 42 ++++++++++++++++++++++++++++++++++-------
 1 file changed, 35 insertions(+), 7 deletions(-)
---
base-commit: 05b5019b01fb9443b09ae4ed34af1135a80a84c8
change-id: 20261005-miic-validate-dtb-v3-cf31820cb1e9

Best regards,
-- 
Kyle Hendry <khendry@reliablecontrols.com>

