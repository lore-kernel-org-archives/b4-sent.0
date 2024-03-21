From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Subject: [PATCH net v2 0/2] Fix EEE support for MT7531 and MT7988 SoC
 switch
Date: Thu, 21 Mar 2024 19:29:12 +0300
Message-Id: <20240321-for-net-mt7530-fix-eee-for-mt7531-mt7988-v2-0-9af9d5041bfe@arinc9.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAFhg/GUC/42NTQ6CMBCFr0Jm7Zj+SmHlPQwLUgeZBa1pCdEQ7
 m5tPICryfve5H07ZEpMGfpmh0QbZ46hBHVqwM9jeBDyvWRQQhmhZYtTTBhoxWVtrRY48QuJqOK
 K5Pd0zuFovTVWey/IQZl7JirPVXWDsgBDgTPnNaZ31W+yVj+T+9+0SRSoJ9kqddHGkLuOiYPvz
 j4uMBzH8QGfp2+35gAAAA==
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
 =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>, 
 Florian Fainelli <florian.fainelli@broadcom.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711038558; l=1342;
 i=arinc.unal@arinc9.com; s=arinc9-patatt; h=from:subject:message-id;
 bh=f2s9m94GQMqwkep6RHvJkC24pYKjgeZXaB8gUvBmMLU=;
 b=/6PP6fK764ZhfuLKywgjtgj/pSH6Pl3WLUSpeldm0cf8TIM2N7wD6Nyxiz1esoC3fNTmSwYep
 kfWBjAIgHnnDt+DUNRcOtb3r9KceZ8aeSscFgEEeQTFI+SDR9nOGJli
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=VmvgMWwm73yVIrlyJYvGtnXkQJy9CvbaeEqPQO9Z4kA=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-patatt with auth_id=115
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi.

This patch series fixes EEE support for MT7531 and the switch on the MT7988
SoC. EEE could not be enabled on MT7531 on most boards using ethtool before
this. On MT7988 SoC switch, EEE is disabled by default but can be turned on
normally using ethtool. EEE is enabled by default on MT7530 and there's no
need to make changes on the DSA subdriver for it. This patch series
disables EEE by default on MT7531 but makes it possible to enable it using
ethtool.

Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
Changes in v2:
- Delegate the patch to the net tree.
- Remove patch 3, it was revealed that it doesn't fix a bug.
- Patch 1
  - Disable EEE advertisement on MT7531 by default.
- Link to v1: https://lore.kernel.org/r/20240318-for-net-mt7530-fix-eee-for-mt7531-mt7988-v1-0-3f17226344e8@arinc9.com

---
Arınç ÜNAL (2):
      net: dsa: mt7530: fix enabling EEE on MT7531 switch on all boards
      net: dsa: mt7530: fix disabling EEE on failure on MT7531 and MT7988

 drivers/net/dsa/mt7530.c | 14 ++++++++++++++
 drivers/net/dsa/mt7530.h |  7 ++++++-
 2 files changed, 20 insertions(+), 1 deletion(-)
---
base-commit: ea80e3ed09ab2c2b75724faf5484721753e92c31
change-id: 20240317-for-net-mt7530-fix-eee-for-mt7531-mt7988-a5c5453cc0e8

Best regards,
-- 
Arınç ÜNAL <arinc.unal@arinc9.com>

