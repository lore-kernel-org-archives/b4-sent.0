From: Juraj Sladek <juraj.sladek@littleit.sk>
Subject: [PATCH net 0/2] net: dsa: realtek: rtl8365mb: fix CPU port on
 HSGMII after boot
Date: Fri, 27 Nov 2026 13:15:53 +0000
Message-Id: <20261127-rtl8365mb-hsgmii-fix-v1-0-f2827126aa6a@littleit.sk>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2M0QpAQBAAf0X7bMudcPyKPDi72HJHd5KSf3d5n
 KmZByIH4Qhd9kDgS6LsPoHKM5jW0S+MQolBF7pWSjcYzs2UdeUsrnFxIjjLjWxbS4oKItNASo/
 ASf/bHjyfMLzvB7iGRn1rAAAA
X-Change-ID: 20261127-rtl8365mb-hsgmii-fix-eb9bd1d0dd87
To: Linus Walleij <linusw@kernel.org>, 
 Luiz Angelo Daros de Luca <luizluca@gmail.com>, 
 =?utf-8?q?Alvin_=C5=A0ipraga?= <alvin.sipraga@analog.com>, 
 Andrew Lunn <andrew@lunn.ch>, Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Russell King <linux@armlinux.org.uk>
Cc: Johan Alvarado <contact@c127.dev>, netdev@vger.kernel.org, 
 Juraj Sladek <juraj.sladek@littleit.sk>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795785355; l=2043;
 i=juraj.sladek@littleit.sk; s=20261127; h=from:subject:message-id;
 bh=H9F3Q62HeH6vV5WQ0vojsmvsWwkasQ3OghHAVC0PSwA=;
 b=ADeoMb/WSnDJx1wGE+TJVNzAL9jIL09GMrqr/qM/1AZfjnDim+67lAnKJzaQnBndKO01SMuH+
 Irp5FzvPBJTDspYJnMPwzNx4ASNDEkoW/Ds8m1KCbQASibVHOPTEMHx
X-Developer-Key: i=juraj.sladek@littleit.sk; a=ed25519;
 pk=AqKiPr9Cm4+alKqIg7OT5xi2bB7LmUEaCQbSaKx1bCs=
X-Endpoint-Received: by B4 Relay for juraj.sladek@littleit.sk/20261127 with auth_id=1667
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On the TP-Link Archer AX55 v1 (Qualcomm IPQ5018, RTL8367S on port 6 over
a 2500base-x/HSGMII fixed link to the IPQ5018 GMAC), wired networking is
dead after a significant share of boots, which OpenWrt users of the
device have been working around with power cycles.

Two different failure modes show up, both on the CPU to switch direction:

 - every frame from the CPU is received by the switch with an FCS error;
   patch 1 fixes this by resetting the SerDes data path again once the
   conduit is up and the link partner transmits;

 - frames from the CPU are received fine but never forwarded (or
   forwarded corrupted); patch 2 fixes this with a switch core soft
   reset a few seconds after the conduit comes up.

The root cause of the second mode is unknown to me. The vendor driver
does not use SW_RST; it does load and start firmware on the embedded
DW8051 for the HSGMII link, which this driver deliberately keeps in
reset, so the firmware may be what normally covers this. If anyone at
Realtek or with documentation can explain what PORT_DEBUG_INFO_CTRL3
(0x091A) reflects, or a more targeted reset, I am happy to test it.

Things I could not verify: whether SW_RST clears the hardware L2 table
(the static FDB entries programmed for the CPU port); traffic and the
VLAN-aware bridge setup keep working after it. Only the HSGMII case on
the IPQ5018 was tested; SGMII uses the same code path.

Test details are in the commit message of patch 2.

Signed-off-by: Juraj Sladek <juraj.sladek@littleit.sk>
---
Juraj Sladek (2):
      net: dsa: realtek: rtl8365mb: reset SerDes data path when conduit comes up
      net: dsa: realtek: rtl8365mb: soft reset switch core after conduit comes up

 drivers/net/dsa/realtek/rtl8365mb_main.c | 116 +++++++++++++++++++++++++++----
 1 file changed, 103 insertions(+), 13 deletions(-)
---
base-commit: 28a371228d4eb4857cc31eeb1a0d7d01e9c3ea2f
change-id: 20261127-rtl8365mb-hsgmii-fix-eb9bd1d0dd87

Best regards,
-- 
Juraj Sladek <juraj.sladek@littleit.sk>

