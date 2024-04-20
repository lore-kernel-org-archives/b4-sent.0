From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Subject: [PATCH 0/4] Please apply these MT7530 DSA subdriver patches to
 5.15
Date: Sat, 20 Apr 2024 19:46:02 +0300
Message-Id: <20240420-for-stable-5-15-backports-v1-0-007bfa19d044@arinc9.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAErxI2YC/x3MMQqAMAxA0atIZgNtUVCvIg61phoUK4mIIN7d4
 viG/x9QEiaFrnhA6GLltGfYsoCw+H0m5CkbnHGVqZzBmAT19ONGWKOtcfRhPZKcipONwdtI1IQ
 Wcn8IRb7/dz+87wfBYEZSawAAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1713631565; l=1085;
 i=arinc.unal@arinc9.com; s=arinc9-Xeront; h=from:subject:message-id;
 bh=U5w5XLDjKEPCeq7w47hHR25jd0gkNMbwdkJrMl+gd8Y=;
 b=EFbit9hXHwWbmlJ1EswPFwHGJIXqp1jO6dkGKDAXa1r/N3xaxt7m98Y3b/FBduIYz+C43Peur
 FH0O6jBKVZ5BqiE519an+/Y0J6QCN4Yi95tpkeXxc3709bPyesnOose
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=z49tLn29CyiL4uwBTrqH9HO1Wu3sZIuRp4DaLZvtP9M=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-Xeront with auth_id=137
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hello.

These are the remaining bugfix patches for the MT7530 DSA subdriver. They
didn't apply as is to the 5.15 stable tree so I have submitted the adjusted
versions in this thread. Please apply them in the order they were
submitted.

Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
Arınç ÜNAL (3):
      net: dsa: mt7530: set all CPU ports in MT7531_CPU_PMAP
      net: dsa: mt7530: fix improper frames on all 25MHz and 40MHz XTAL MT7530
      net: dsa: mt7530: fix enabling EEE on MT7531 switch on all boards

Vladimir Oltean (1):
      net: dsa: introduce preferred_default_local_cpu_port and use on MT7530

 drivers/net/dsa/mt7530.c | 54 ++++++++++++++++++++++++++++++++++--------------
 drivers/net/dsa/mt7530.h |  2 ++
 include/net/dsa.h        |  8 +++++++
 net/dsa/dsa2.c           | 24 ++++++++++++++++++++-
 4 files changed, 71 insertions(+), 17 deletions(-)
---
base-commit: c52b9710c83d3b8ab63bb217cc7c8b61e13f12cd
change-id: 20240420-for-stable-5-15-backports-d1fca1fee8c9

Best regards,
-- 
Arınç ÜNAL <arinc.unal@arinc9.com>

