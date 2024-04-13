From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Subject: [PATCH net 0/2] Fix port mirroring on MT7530 DSA subdriver
Date: Sat, 13 Apr 2024 16:01:38 +0300
Message-Id: <20240413-b4-for-net-mt7530-fix-mirroring-to-local-port-and-mt7988-v1-0-476deff8cc06@arinc9.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIADKCGmYC/x2NQQqDMBBFryKz7kA00cReRbpIY7QDmpFJKAXx7
 k27fPD++yfkKBQz3JsTJL4pE6cK7a2B8PJpjUhzZehUZ5RpNT4NLiyYYsG92F4rXOiDO4mwUFq
 xMG4c/IYHS0Gf5p82Oofa+t51YRhG66HmD4l1+b+eoObgcV1f7Wt53Y8AAAA=
To: Daniel Golle <daniel@makrotopia.org>, DENG Qingfang <dqfext@gmail.com>, 
 Sean Wang <sean.wang@mediatek.com>, Andrew Lunn <andrew@lunn.ch>, 
 Florian Fainelli <f.fainelli@gmail.com>, 
 Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: Holger Stadali <hs@giax.de>, 
 Bartel Eerdekens <bartel.eerdekens@constell8.be>, mithat.guner@xeront.com, 
 erkin.bozoglu@xeront.com, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, 
 =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1713013352; l=731;
 i=arinc.unal@arinc9.com; s=arinc9-patatt; h=from:subject:message-id;
 bh=tIwVcmzfuWrvRXOL2CNVlGRiqUSlmA862fC7CswLoWc=;
 b=AIrFvlQc3tcxviGzOLIGmBqZmIxEahKHRc9YPMCzCUupD2yadJp90xxhu93W3CrPfWgGyLLED
 MCUb176IfZaDE61ysaeVKABk/KB1+fYyhH9GXZ9wKbm+94vAREIVkeP
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=VmvgMWwm73yVIrlyJYvGtnXkQJy9CvbaeEqPQO9Z4kA=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-patatt with auth_id=115
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi.

This patch series fixes the frames received on the local port (monitor
port) not being mirrored, and port mirroring for the MT7988 SoC switch.

Arınç

Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
Arınç ÜNAL (2):
      net: dsa: mt7530: fix mirroring frames received on local port
      net: dsa: mt7530: fix port mirroring for MT7988 SoC switch

 drivers/net/dsa/mt7530.c | 16 ++++++++++++----
 drivers/net/dsa/mt7530.h |  4 ++++
 2 files changed, 16 insertions(+), 4 deletions(-)
---
base-commit: 4e1ad31ce3205d9400816e08cf14b7c96295d22e
change-id: 20240413-b4-for-net-mt7530-fix-mirroring-to-local-port-and-mt7988-37a582c6697a

Best regards,
-- 
Arınç ÜNAL <arinc.unal@arinc9.com>

