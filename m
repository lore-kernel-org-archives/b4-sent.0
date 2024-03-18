From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Subject: [PATCH 0/3] Fix EEE support for MT7531 and MT7988 SoC switch
Date: Mon, 18 Mar 2024 10:46:22 +0300
Message-Id: <20240318-for-net-mt7530-fix-eee-for-mt7531-mt7988-v1-0-3f17226344e8@arinc9.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAE7x92UC/x2NQQqDMBREryJ/7YfEGJL2KtKFxIn+RWNJpBTEu
 zdmNbzHMHNSQRYUenYnZXylyJ4q6L6jsM1pBctSmQY1jMpox3HPnHDw+3DWKI7yYwBNN6XveHj
 Psw12tCYEBU917pNRy+1qel3XH2pcu9x6AAAA
To: Daniel Golle <daniel@makrotopia.org>, DENG Qingfang <dqfext@gmail.com>, 
 Sean Wang <sean.wang@mediatek.com>, Andrew Lunn <andrew@lunn.ch>, 
 Florian Fainelli <f.fainelli@gmail.com>, 
 Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 =?utf-8?q?Ren=C3=A9_van_Dorst?= <opensource@vdorst.com>, 
 Russell King <linux@armlinux.org.uk>, 
 SkyLake Huang <SkyLake.Huang@mediatek.com>, 
 Heiner Kallweit <hkallweit1@gmail.com>
Cc: Bartel Eerdekens <bartel.eerdekens@constell8.be>, 
 mithat.guner@xeront.com, erkin.bozoglu@xeront.com, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, 
 =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1710748010; l=899;
 i=arinc.unal@arinc9.com; s=arinc9-patatt; h=from:subject:message-id;
 bh=0IileY4KTERKAEQx1LyPEiRlXaWXwOgaikBtQNDncX8=;
 b=MvoN53hH2wrfbvyDLe2J5XZFtp6mqVf4l86LIsFblVBKfoyUfPbX/amdemD8asCtN6EGZKuEz
 u42E5pne4MiDXlAfYr/fO4zn5HkWlZDvIGDC85H9eXfauPMi8AW1P5J
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=VmvgMWwm73yVIrlyJYvGtnXkQJy9CvbaeEqPQO9Z4kA=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-patatt with auth_id=115
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi.

This patch series fixes EEE support for MT7531 and the switch on the MT7988
SoC. EEE did not work on MT7531 on most boards before this, it is unclear
what's the status on MT7988 SoC switch as I don't have the hardware.

Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
Arınç ÜNAL (3):
      net: dsa: mt7530: fix enabling EEE on MT7531 switch on all boards
      net: dsa: mt7530: fix disabling EEE on failure on MT7531 and MT7988
      net: phy: mediatek-ge: do not disable EEE advertisement

 drivers/net/dsa/mt7530.c      | 7 +++++++
 drivers/net/dsa/mt7530.h      | 7 ++++++-
 drivers/net/phy/mediatek-ge.c | 3 ---
 3 files changed, 13 insertions(+), 4 deletions(-)
---
base-commit: ea80e3ed09ab2c2b75724faf5484721753e92c31
change-id: 20240317-for-net-mt7530-fix-eee-for-mt7531-mt7988-a5c5453cc0e8

Best regards,
-- 
Arınç ÜNAL <arinc.unal@arinc9.com>

