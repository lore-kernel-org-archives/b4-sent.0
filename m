From: Rohan G Thomas <rohan.g.thomas@altera.com>
Subject: [PATCH net 0/2] net: stmmac: Minor fixes for stmmac EST
 implementation
Date: Thu, 11 Sep 2025 16:22:58 +0800
Message-Id: <20250911-qbv-fixes-v1-0-e81e9597cf1f@altera.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOKGwmgC/x3KSwqAIBRG4a3IHSdo2HMr0cDqr+7ESkOCcO9Jw
 49zXgrwjEC9eMkjcuDDZehC0Lxbt0Hykk2lKivVaS2vKcqVHwRpLGqzoK2BhvJ/evwh7wM53DS
 m9AHmLbwtYAAAAA==
X-Change-ID: 20250911-qbv-fixes-4ae64de86ee7
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Jose Abreu <Jose.Abreu@synopsys.com>, 
 Rohan G Thomas <rohan.g.thomas@intel.com>
Cc: netdev@vger.kernel.org, linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Rohan G Thomas <rohan.g.thomas@altera.com>, 
 Matthew Gerlach <matthew.gerlach@altera.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1757579008; l=729;
 i=rohan.g.thomas@altera.com; s=20250815; h=from:subject:message-id;
 bh=1NTqCYvC1K8jjPMv2VYdraK1iRDgvz7FsY1W+cOys54=;
 b=/0L8KgDwlzFCr8RVOL5SgK/pXkurP0ELzcipg5jz0KqFqfz7OjcBHkJi9PknfxYLHM1GdYnME
 v5v0C/w9B7TBnsTcDbFxJQY0Jdl7+CyWmJD9rD5EXlB2gHxKlKOoeeO
X-Developer-Key: i=rohan.g.thomas@altera.com; a=ed25519;
 pk=5yZXkXswhfUILKAQwoIn7m6uSblwgV5oppxqde4g4TY=
X-Endpoint-Received: by B4 Relay for rohan.g.thomas@altera.com/20250815 with auth_id=494
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patchset includes following minor fixes for stmmac EST
implementation:
   1. Fix GCL bounds checks
   2. Consider Tx VLAN offload tag length for maxSDU

Signed-off-by: Rohan G Thomas <rohan.g.thomas@altera.com>
---
Rohan G Thomas (2):
      net: stmmac: est: Fix GCL bounds checks
      net: stmmac: Consider Tx VLAN offload tag length for maxSDU

 drivers/net/ethernet/stmicro/stmmac/stmmac_main.c | 25 ++++++++++++++++-------
 drivers/net/ethernet/stmicro/stmmac/stmmac_tc.c   |  4 ++--
 2 files changed, 20 insertions(+), 9 deletions(-)
---
base-commit: 1f24a240974589ce42f70502ccb3ff3f5189d69a
change-id: 20250911-qbv-fixes-4ae64de86ee7

Best regards,
-- 
Rohan G Thomas <rohan.g.thomas@altera.com>

