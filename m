From: Kyle Hendry <khendry@reliablecontrols.com>
Subject: [PATCH net-next 0/2] net: pcs: rzn1-miic: Validate dtb
 configuration values
Date: Fri, 25 Sep 2026 08:12:05 -0700
Message-Id: <20260925-miic-validate-dtb-v1-0-3a6db9bb75ec@reliablecontrols.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEWPtmoC/x3MSQqAMAxA0atI1gZqFaeriIsOUQNapS1FEO9uc
 fkW/z8QyDMFGIsHPCUOfLqMqizAbMqthGyzQQrZikE2eDAbTGpnqyKhjRr1Yhpd90J3vYTcXZ4
 Wvv/nBI4iOrojzO/7AZC82ZJtAAAA
To: =?utf-8?q?Cl=C3=A9ment_L=C3=A9ger?= <clement.leger@bootlin.com>, 
 Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Lad Prabhakar <prabhakar.mahadev-lad.rj@bp.renesas.com>
Cc: linux-renesas-soc@vger.kernel.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Kyle Hendry <khendry@reliablecontrols.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790349149; l=806;
 i=khendry@reliablecontrols.com; s=20260813; h=from:subject:message-id;
 bh=TJ2/gTRiRoF8Qx7Q+GjxSPVmL5qqx28RUz8ON4l6uvw=;
 b=5ywa4mW0gAbU8H+APXL2Ev1Jiq69YYjIbJ8ck0lqbdajhzLPUSlerUEjiR0pU/YhaKU547TxK
 ArfQ2m71h1lBrSykqxWqM9lxVwriiSQ8pOYyB/H5UIcWV1dTJP9DgyK
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
Kyle Hendry (2):
      net: pcs: rzn1-miic: Make usage of miic_port_max consistent
      net: pcs: rzn1-miic: Validate dtb configuration values

 drivers/net/pcs/pcs-rzn1-miic.c | 26 ++++++++++++++++++++++----
 1 file changed, 22 insertions(+), 4 deletions(-)
---
base-commit: 42a9fb3382fc2573e92f41d203b095d9a372cfc9
change-id: 20260924-miic-validate-dtb-bfc4b380b782

Best regards,
-- 
Kyle Hendry <khendry@reliablecontrols.com>

