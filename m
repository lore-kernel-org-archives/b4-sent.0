From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Subject: [PATCH net-next v5 0/7] MT7530 DSA Subdriver Improvements Act II
Date: Tue, 06 Feb 2024 01:08:01 +0300
Message-Id: <20240206-for-netnext-mt7530-improvements-2-v5-0-d7d92a185cb1@arinc9.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAEFcwWUC/43OTW7DIBAF4KtErDsWv46dVe8RZQFmaJBqiICiV
 JHvXkoXTZVFs0GMRu97cyMZk8dMDrsbSVh99jG0Qb3syHLW4Q3B2zYTTrmkjDNwMUHAEvBaYC1
 7JSj49ZJixRVDycDBSCfFODIjJ0Wac0no/LV3HEmLwneWnNrm7HOJ6bOXV9b3Pz1MMMoVn4eJi
 j0DBjr5sAwfQb+/9u88LHHtRuV3uXbM//dVDhSMpqNT1s5o6AMpfsn2PEOKRo7CKm01zvOiH0h
 5T8pnSNlIyo2j2mhtzfSH3LbtC79DbtO7AQAA
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
 =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>, 
 "Russell King (Oracle)" <rmk+kernel@armlinux.org.uk>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707170890; l=3529;
 i=arinc.unal@arinc9.com; s=arinc9-patatt; h=from:subject:message-id;
 bh=A+6R9ZDS9UjRyWJgxuvz/fapj4AM3nXOKkH2EGth9G0=;
 b=lMad3J70PLiCdiP2RqMA7W8I4o6zA0ejht2u6w5ckUlGJy2YN1gQn4f5EwDCdQphg/ouy3+dp
 BWUoF08vFkSBD7U/W9T3fZ5Zd+bPGbdXnK/FCfXthlaTVPPhRXSkQzm
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=VmvgMWwm73yVIrlyJYvGtnXkQJy9CvbaeEqPQO9Z4kA=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-patatt with auth_id=115
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hello!

This is the second patch series with the goal of simplifying the MT7530 DSA
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
Changes in v5:
- Update the patches with the latest received trailers.
- Patch 3
  - Replace "return;" with "return 0;".
- Patch 4
  - Remove the stray brace.
- Link to v4: https://lore.kernel.org/r/20240204-for-netnext-mt7530-improvements-2-v4-0-02bf0abaadb8@arinc9.com

Changes in v4:
- Update the patches with the latest received trailers.
- Leave no error returns on mt7530_pad_clk_setup() before renaming it to
  mt7530_setup_port6() and moving it to under mt7530_mac_config().
- Link to v3: https://lore.kernel.org/r/20240202-for-netnext-mt7530-improvements-2-v3-0-63d5adae99ca@arinc9.com

Changes in v3:
- Update the patches with the latest received trailers.
- Patch 5
  - Disable TRGMII clocks for all cases.
- Link to v2: https://lore.kernel.org/r/20240130-for-netnext-mt7530-improvements-2-v2-0-ba06f5dd9eb0@arinc9.com

Changes in v2:
- Update the patches with the latest received trailers.
- Remove 'net: dsa: mt7530: move enabling port 6 to mt7530_setup_port6()'
  which was patch 5. I will bring a more appropriate change with a later
  patch series.
- Patch 5
  - Set P6_INTF_MODE(0) and explain why on the patch log.
- Patch 6
  - Mention the MT7988 document and explain more on the patch log.
- Patch 7
  - Explain more on the patch log.
- Link to v1: https://lore.kernel.org/r/20240113102529.80371-1-arinc.unal@arinc9.com

---
Arınç ÜNAL (7):
      net: dsa: mt7530: empty default case on mt7530_setup_port5()
      net: dsa: mt7530: move XTAL check to mt7530_setup()
      net: dsa: mt7530: simplify mt7530_pad_clk_setup()
      net: dsa: mt7530: call port 6 setup from mt7530_mac_config()
      net: dsa: mt7530: remove pad_setup function pointer
      net: dsa: mt7530: correct port capabilities of MT7988
      net: dsa: mt7530: do not clear config->supported_interfaces

 drivers/net/dsa/mt7530.c | 152 +++++++++++++++++------------------------------
 drivers/net/dsa/mt7530.h |   3 -
 2 files changed, 53 insertions(+), 102 deletions(-)
---
base-commit: 4acf4e62cd572b0c806035046b3698f5585ab821
change-id: 20240121-for-netnext-mt7530-improvements-2-b4f43661b485

Best regards,
-- 
Arınç ÜNAL <arinc.unal@arinc9.com>

