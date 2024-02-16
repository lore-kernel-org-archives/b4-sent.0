From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Subject: [PATCH net-next v2 0/8] MT7530 DSA Subdriver Improvements Act III
Date: Fri, 16 Feb 2024 14:05:28 +0300
Message-Id: <20240216-for-netnext-mt7530-improvements-3-v2-0-094cae3ff23b@arinc9.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAHhBz2UC/42NQQ6DIBBFr2Jm3WkANWpXvUfjgsBQWQAGCLEx3
 r2UE3T58vL/OyFRtJTg0Z0Qqdhkg68gbh2oTfo3odWVQTAxMN5zNCGip+zpyOjyNPYMrdtjKOT
 I54Q9ylmqYdGDmZSA+rNHMvZojRfUKf62sFaz2ZRD/LR44c23jmDzH53CkaGeFFdGj0wo+ZTRe
 rXcVXCwXtf1BUYpan/dAAAA
To: Daniel Golle <daniel@makrotopia.org>, DENG Qingfang <dqfext@gmail.com>, 
 Sean Wang <sean.wang@mediatek.com>, Andrew Lunn <andrew@lunn.ch>, 
 Florian Fainelli <f.fainelli@gmail.com>, 
 Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Russell King <linux@armlinux.org.uk>
Cc: mithat.guner@xeront.com, erkin.bozoglu@xeront.com, 
 Bartel Eerdekens <bartel.eerdekens@constell8.be>, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, 
 =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708081540; l=2534;
 i=arinc.unal@arinc9.com; s=arinc9-patatt; h=from:subject:message-id;
 bh=1FS8ZPPLPybCi3YVj/4MOwJosG7TrEfNHZ4uB1ISjOk=;
 b=4YDBIR62fslTZb8yk0gux/BhP0YkemDBzqxqJr4mpU0FNWNGZw9VDzR7jHpWd4cmtwufLDsHb
 QLrKPdaGchfAzq7A0QN6KKwoE16uM87Qn8Xnzy1OW4EH4H2up+5HIvx
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=VmvgMWwm73yVIrlyJYvGtnXkQJy9CvbaeEqPQO9Z4kA=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-patatt with auth_id=115
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hello!

This is the third patch series with the goal of simplifying the MT7530 DSA
subdriver and improving support for MT7530, MT7531, and the switch on the
MT7988 SoC.

I have done a simple ping test to confirm basic communication on all switch
ports on MCM and standalone MT7530, and MT7531 switch with this patch
series applied.

MT7621 Unielec, MCM MT7530:

rgmii-only-gmac0-mt7621-unielec-u7621-06-16m.dtb
gmac0-and-gmac1-mt7621-unielec-u7621-06-16m.dtb

tftpboot 0x80008000 mips-uzImage.bin; tftpboot 0x83000000 mips-rootfs.cpio.uboot; tftpboot 0x83f00000 $dtb; bootm 0x80008000 0x83000000 0x83f00000

MT7622 Bananapi, MT7531:

gmac0-and-gmac1-mt7622-bananapi-bpi-r64.dtb

tftpboot 0x40000000 arm64-Image; tftpboot 0x45000000 arm64-rootfs.cpio.uboot; tftpboot 0x4a000000 $dtb; booti 0x40000000 0x45000000 0x4a000000

MT7623 Bananapi, standalone MT7530:

rgmii-only-gmac0-mt7623n-bananapi-bpi-r2.dtb
gmac0-and-gmac1-mt7623n-bananapi-bpi-r2.dtb

tftpboot 0x80008000 arm-zImage; tftpboot 0x83000000 arm-rootfs.cpio.uboot; tftpboot 0x83f00000 $dtb; bootz 0x80008000 0x83000000 0x83f00000

This patch series is the continuation of the patch series linked below.

https://lore.kernel.org/r/20230522121532.86610-1-arinc.unal@arinc9.com

Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
Changes in v2:
- Patch 8
  - Use a single mt7530_rmw() instead of two mt7530_clear() and
    mt7530_set() commands.
- Link to v1: https://lore.kernel.org/r/20240208-for-netnext-mt7530-improvements-3-v1-0-d7c1cfd502ca@arinc9.com

---
Arınç ÜNAL (8):
      net: dsa: mt7530: remove .mac_port_config for MT7988 and make it optional
      net: dsa: mt7530: set interrupt register only for MT7530
      net: dsa: mt7530: do not use SW_PHY_RST to reset MT7531 switch
      net: dsa: mt7530: get rid of useless error returns on phylink code path
      net: dsa: mt7530: get rid of priv->info->cpu_port_config()
      net: dsa: mt7530: get rid of mt753x_mac_config()
      net: dsa: mt7530: put initialising PCS devices code back to original order
      net: dsa: mt7530: simplify link operations and force link down on all ports

 drivers/net/dsa/mt7530.c | 259 ++++++++---------------------------------------
 drivers/net/dsa/mt7530.h |  19 +---
 2 files changed, 47 insertions(+), 231 deletions(-)
---
base-commit: b6b614558ed5b2ca50edacc0f2fbf5f52158c86c
change-id: 20240131-for-netnext-mt7530-improvements-3-a8ac49d4f7c2

Best regards,
-- 
Arınç ÜNAL <arinc.unal@arinc9.com>

