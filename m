From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Subject: [PATCH net-next v3 0/7] MT7530 DSA Subdriver Improvements Act I
Date: Mon, 22 Jan 2024 08:35:51 +0300
Message-Id: <20240122-for-netnext-mt7530-improvements-1-v3-0-042401f2b279@arinc9.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIALf+rWUC/3WNQQ7CIBREr2JYS8P/0NK68h7GRa2/lsRCA0hqm
 t5dZOPK3Uwmb97GAnlDgZ0OG/OUTDDO5iKPBzZMvX0QN/fcGQpUAhD46Dy3FC2tkc9R11JwMy/
 eJZrJxsCBN0rJWnXjTeua5Z/F02jW4riwjPIvy655mUyIzr+LPEHZs0cCQAsoUdQVNk0LXT7tv
 bFD9bL981xiVw1uLicJfyCiFtmudAVCYwf/wX3fP64TAoj8AAAA
To: Daniel Golle <daniel@makrotopia.org>, 
 Landen Chao <Landen.Chao@mediatek.com>, DENG Qingfang <dqfext@gmail.com>, 
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705901755; l=3455;
 i=arinc.unal@arinc9.com; s=arinc9-patatt; h=from:subject:message-id;
 bh=eTYY+evS04ACta4sLOnbAMToYxY7CybRXgNbJ7leYNw=;
 b=17GHcU05i+tBO3+FtLXH7FLTko8AoULh6yvzNTCWphY/pvp9Fd6q9hsjeqHR1Xz5bHD0JlxG4
 uXo5JR8k6j/ACr1ZhmojnGwA0y3n98w8mFm4JqMkj0vIDy3/Oyl1KbC
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=VmvgMWwm73yVIrlyJYvGtnXkQJy9CvbaeEqPQO9Z4kA=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-patatt with auth_id=115
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hello!

This patch series simplifies the MT7530 DSA subdriver and improves the
logic of the support for MT7530, MT7531, and the switch on the MT7988 SoC.

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
Changes in v3:
- Update the patches with the latest received trailers.
- Patch 1
  - Declare the longest variable assignment first.
  - Improve the patch log and the comment on the code.
  - Don't do type cast for __ffs. Implicit type promotion takes place.
- Patch 4
  - Put more relevant information on the comments on the code.
  - Follow the 'commit <12+ chars of sha1> ("<title line>")' style on the
    patch log to satisfy checkpatch errors.
- Patch 6
  - Change the patch log to explain the change better.
- Link to v2: https://lore.kernel.org/r/20231227044347.107291-1-arinc.unal@arinc9.com

Changes in v2:
- Shorten the patch series, include only 7 patches.
- Add the reviewed-by tags given.
- Patch 1
  - Change variable ordering of mt753x_conduit_state_change().
  - Define the mask variable and store BIT(cpu_dp->index) on it.
  - Disable CPU_EN if priv->active_cpu_ports is 0.
- Patch 5
  - On the patch log, take the irrelevant information about the
    mt7530_setup_port5() call from mt7530_setup() out.
- Patch 6
  - Change the patch log to reflect correct information.
- Link to v1: https://lore.kernel.org/r/20231118123205.266819-1-arinc.unal@arinc9.com

---
Arınç ÜNAL (7):
      net: dsa: mt7530: always trap frames to active CPU port on MT7530
      net: dsa: mt7530: use p5_interface_select as data type for p5_intf_sel
      net: dsa: mt7530: store port 5 SGMII capability of MT7531
      net: dsa: mt7530: improve comments regarding switch ports
      net: dsa: mt7530: improve code path for setting up port 5
      net: dsa: mt7530: do not set priv->p5_interface on mt7530_setup_port5()
      net: dsa: mt7530: do not run mt7530_setup_port5() if port 5 is disabled

 drivers/net/dsa/mt7530-mdio.c |   7 +--
 drivers/net/dsa/mt7530.c      | 135 +++++++++++++++++++++++-------------------
 drivers/net/dsa/mt7530.h      |  16 +++--
 3 files changed, 87 insertions(+), 71 deletions(-)
---
base-commit: 736b5545d39ca59d4332a60e56cc8a1a5e264a8e
change-id: 20240121-for-netnext-mt7530-improvements-1-6443549fb775

Best regards,
-- 
Arınç ÜNAL <arinc.unal@arinc9.com>

