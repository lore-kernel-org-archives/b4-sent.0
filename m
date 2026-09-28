From: Kyle Hendry <khendry@reliablecontrols.com>
Subject: [PATCH net-next v2 0/3] net: pcs: rzn1-miic: Validate dtb
 configuration values
Date: Mon, 28 Sep 2026 14:19:02 -0700
Message-Id: <20260928-miic-validate-dtb-v2-0-1ee3d33748e9@reliablecontrols.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMbZumoC/22NywrCMBBFf6XM2khM3678D+kij6kdSBNJQqiU/
 ruhuHR5ONxzd4gYCCPcqx0CZorkXQFxqUAv0r2QkSkMgouOj6JhK5FmWVoyMiEzSTE160bVA1f
 9IKDs3gFn2s7mExwm5nBLMBWzUEw+fM6zfDv9r9v+6eYb46yWnVGjUn2L+hHQklQWtXcpeBuv2
 q8wHcfxBbi7mR/HAAAA
To: =?utf-8?q?Cl=C3=A9ment_L=C3=A9ger?= <clement.leger@bootlin.com>, 
 Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Lad Prabhakar <prabhakar.mahadev-lad.rj@bp.renesas.com>
Cc: linux-renesas-soc@vger.kernel.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Kyle Hendry <khendry@reliablecontrols.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790630370; l=1083;
 i=khendry@reliablecontrols.com; s=20260813; h=from:subject:message-id;
 bh=iRVAveAkN4lPEVWRQS+tEuxrYtH4+i3EDxsR7o9RjZ0=;
 b=qrz/MSsI7PE74TwbQ6TijW5nwDtWRzcnZRvgr5mo+Exqx+4rRNYoXk7QWy/Rd5ir6lFE1HiHu
 Lx8lvFSv3kxACdeqXc1IIEA3N6GJ7/thkUHQprN9KOKU5W9OaiV0pFo
X-Developer-Key: i=khendry@reliablecontrols.com; a=ed25519;
 pk=gbK6oghz3qBlBiaGCsEzALLOtj5VklmsuolHQNhDV5M=
X-Endpoint-Received: by B4 Relay for khendry@reliablecontrols.com/20260813 with auth_id=946
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series addresses issues found when reviewing another fix:
https://lore.kernel.org/netdev/20260915-rzn1-miic-fix-array-v5-1-b7173fd5b97d@reliablecontrols.com/

Invalid values from the dtb could cause out of bounds array access. Checking
the values as they're parsed should prevent this.

Signed-off-by: Kyle Hendry <khendry@reliablecontrols.com>
---
Changes in v2:
- Simplify fixes by making miic_port_max the last documented port number
- Add fixes tags
- Link to v1: https://lore.kernel.org/r/20260925-miic-validate-dtb-v1-0-3a6db9bb75ec@reliablecontrols.com

---
Kyle Hendry (3):
      net: pcs: rzn1-miic: Fix port numbering on RZ/T2H
      net: pcs: rzn1-miic: Fix miic register initialization loop
      net: pcs: rzn1-miic: Validate dtb configuration values

 drivers/net/pcs/pcs-rzn1-miic.c | 25 +++++++++++++++++++++++--
 1 file changed, 23 insertions(+), 2 deletions(-)
---
base-commit: 014d795c73837ea2339a4ea8e8f82c6e959b845d
change-id: 20260924-miic-validate-dtb-bfc4b380b782

Best regards,
-- 
Kyle Hendry <khendry@reliablecontrols.com>

