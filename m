From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Subject: [PATCH 0/4] Please apply these MT7530 DSA subdriver patches to 6.1
Date: Sat, 20 Apr 2024 18:59:49 +0300
Message-Id: <20240420-for-stable-6-1-backports-v1-0-0c50ca4324ea@arinc9.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAHXmI2YC/x3MQQqDMBBA0avIrB2IaaqNV5EuYjrWwWJkJogg3
 t3Q5Vv8f4KSMCn01QlCOyuntaCpK4hzWL+E/CkGa6wzzhqckqDmMP4IW2xwDHHZkmTFp4v+4W3
 XvjoPJd+EJj7+6+F9XTeL+m67agAAAA==
To: stable@vger.kernel.org
Cc: Daniel Golle <daniel@makrotopia.org>, 
 =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>, 
 "Russell King (Oracle)" <linux@armlinux.org.uk>, 
 Vladimir Oltean <olteanv@gmail.com>, 
 "Russell King (Oracle)" <rmk+kernel@armlinux.org.uk>, 
 Florian Fainelli <florian.fainelli@broadcom.com>, 
 "David S. Miller" <davem@davemloft.net>, Paolo Abeni <pabeni@redhat.com>, 
 Jakub Kicinski <kuba@kernel.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1713628810; l=1085;
 i=arinc.unal@arinc9.com; s=arinc9-Xeront; h=from:subject:message-id;
 bh=/ed9nH5y17K10P4P954SKyt1HWbeQ6IpmCrsuHQLQyU=;
 b=WRUPxDNFQaGV6hONFMqLFp9O3RYgthoAXxRcy8GTTy1nyFvb4zuuCfpFUM9wv18tu87zkNkpI
 JG8bxp7is9dCTLJDM6J7DOTQaTAOW7jc9p1U3GnResKp2Kbd9AcsdxJ
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=z49tLn29CyiL4uwBTrqH9HO1Wu3sZIuRp4DaLZvtP9M=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-Xeront with auth_id=137
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hello.

These are the remaining bugfix patches for the MT7530 DSA subdriver.
They didn't apply as is to the 6.1 stable tree so I have submitted the
adjusted versions in this thread. Please apply them in the order
they were submitted.

Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
Arınç ÜNAL (3):
      net: dsa: mt7530: set all CPU ports in MT7531_CPU_PMAP
      net: dsa: mt7530: fix improper frames on all 25MHz and 40MHz XTAL MT7530
      net: dsa: mt7530: fix enabling EEE on MT7531 switch on all boards

Vladimir Oltean (1):
      net: dsa: introduce preferred_default_local_cpu_port and use on MT7530

 drivers/net/dsa/mt7530.c | 52 ++++++++++++++++++++++++++++++++++--------------
 drivers/net/dsa/mt7530.h |  2 ++
 include/net/dsa.h        |  8 ++++++++
 net/dsa/dsa2.c           | 24 +++++++++++++++++++++-
 4 files changed, 70 insertions(+), 16 deletions(-)
---
base-commit: 6741e066ec7633450d3186946035c1f80c4226b8
change-id: 20240420-for-stable-6-1-backports-54c939276879

Best regards,
-- 
Arınç ÜNAL <arinc.unal@arinc9.com>

