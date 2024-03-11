From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Subject: [PATCH net 0/2] MT7530 DSA subdriver fix VLAN egress and handling
 of all link-local frames
Date: Mon, 11 Mar 2024 14:46:37 +0300
Message-Id: <20240311-b4-for-net-mt7530-fix-link-local-vlan-v1-0-d67e6cc31af2@arinc9.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAB3v7mUC/4WPwQ7CIBBEf6XZs2sKaks9+R/GA1JoN1JogDQa0
 393U717nJndeZk3ZJvIZjhXb0h2oUwxsBC7Csyow2CRetYga3msZa3wfkQXEwZbcCrt6VCjoyd
 6Cg/00WiPi9cBtWts10mle9UDd83J8tnGuQL/wo3NkXKJ6bWxF7FFP4z4jymjLkhhSDbnL9ORL
 zwmDDjHVNgUKFApYYTpmrts3UVzarq9iRPc1nX9AFLj/gX9AAAA
To: Daniel Golle <daniel@makrotopia.org>, DENG Qingfang <dqfext@gmail.com>, 
 Sean Wang <sean.wang@mediatek.com>, Andrew Lunn <andrew@lunn.ch>, 
 Florian Fainelli <f.fainelli@gmail.com>, 
 Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: =?utf-8?q?Alvin_=C5=A0ipraga?= <ALSI@bang-olufsen.dk>, 
 Frank Wunderlich <frank-w@public-files.de>, 
 Bartel Eerdekens <bartel.eerdekens@constell8.be>, mithat.guner@xeront.com, 
 erkin.bozoglu@xeront.com, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, 
 =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1710157606; l=737;
 i=arinc.unal@arinc9.com; s=arinc9-patatt; h=from:subject:message-id;
 bh=90OLEsdfJqu8wgRSuSRNabsqq0MAYE6rL2NiXmGoMtI=;
 b=yEjWff1QAaQVlCGNmDywGXbrJAoO1e6BjBXW4cIqriDctnD1IsQi0KcTnd5CM7arX36Tysqkm
 AJv5bSCJiDzDPFoDPQKux05QW1mtLNNtQ5FjXY+5dgkjdGDyHg95tCA
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=VmvgMWwm73yVIrlyJYvGtnXkQJy9CvbaeEqPQO9Z4kA=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-patatt with auth_id=115
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi.

This patch series fixes the VLAN tag egress procedure for link-local
frames, and fixes handling of all link-local frames.

Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
Arınç ÜNAL (2):
      net: dsa: mt7530: fix link-local frames that ingress vlan filtering ports
      net: dsa: mt7530: fix handling of all link-local frames

 drivers/net/dsa/mt7530.c | 52 ++++++++++++++++++++++++++++++++++++++++--------
 drivers/net/dsa/mt7530.h | 22 +++++++++++++++++++-
 2 files changed, 65 insertions(+), 9 deletions(-)
---
base-commit: c8a5c731fd1223090af57da33838c671a7fc6a78
change-id: 20240208-b4-for-net-mt7530-fix-link-local-vlan-af6e9928ad8d

Best regards,
-- 
Arınç ÜNAL <arinc.unal@arinc9.com>

