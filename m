From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Subject: [PATCH 0/2] Please apply these MT7530 DSA subdriver patches to 6.8
Date: Sat, 20 Apr 2024 13:51:51 +0300
Message-Id: <20240420-for-stable-6-8-backports-v1-0-4dafb598aa3b@arinc9.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAEeeI2YC/x3MwQqDMAyA4VeRnBdIi8rwVWSHtku3MGklERmI7
 27x+B3+/wBjFTaYugOUdzGppcE9OkjfUD6M8m4GT76n3hPmqmhbiAvjiE+MIf3WqpvhELyjPKY
 cKUHLV+Us/3s9v87zAhe0ShJqAAAA
To: stable@vger.kernel.org
Cc: Daniel Golle <daniel@makrotopia.org>, 
 =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>, 
 Paolo Abeni <pabeni@redhat.com>, 
 Florian Fainelli <florian.fainelli@broadcom.com>, 
 Jakub Kicinski <kuba@kernel.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1713610341; l=797;
 i=arinc.unal@arinc9.com; s=arinc9-Xeront; h=from:subject:message-id;
 bh=DP9OpOeXRPwntTaq8fa0UBaputP6jYZlg/h2/DT83TQ=;
 b=rbKN+LolXtsdp2/H6lsyjNyvwYK/9Ol2EDcAlYlQOUTRKV5E5Gze+uJGBHJCqyuO542+A7zIL
 Fy0jXQIml0KAR/5lksMi9LJA5g+JLSLieBje3mD3b+esrM5sK1LUEJb
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=z49tLn29CyiL4uwBTrqH9HO1Wu3sZIuRp4DaLZvtP9M=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-Xeront with auth_id=137
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hello.

These are the remaining bugfix patches for the MT7530 DSA subdriver.
They didn't apply as is to the 6.8 stable tree so I have submitted the
adjusted versions in this thread. Please apply them in the order
they were submitted.

Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
Arınç ÜNAL (2):
      net: dsa: mt7530: fix improper frames on all 25MHz and 40MHz XTAL MT7530
      net: dsa: mt7530: fix enabling EEE on MT7531 switch on all boards

 drivers/net/dsa/mt7530.c | 22 +++++++++++++++-------
 drivers/net/dsa/mt7530.h |  1 +
 2 files changed, 16 insertions(+), 7 deletions(-)
---
base-commit: 12dadc409c2bd8538c6ee0e56e191efde6d92007
change-id: 20240420-for-stable-6-8-backports-5a210f6cfb0c

Best regards,
-- 
Arınç ÜNAL <arinc.unal@arinc9.com>

