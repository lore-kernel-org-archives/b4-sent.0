From: Rohan G Thomas <rohan.g.thomas@altera.com>
Date: Thu, 11 Sep 2025 16:22:59 +0800
Subject: [PATCH net 1/2] net: stmmac: est: Fix GCL bounds checks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250911-qbv-fixes-v1-1-e81e9597cf1f@altera.com>
References: <20250911-qbv-fixes-v1-0-e81e9597cf1f@altera.com>
In-Reply-To: <20250911-qbv-fixes-v1-0-e81e9597cf1f@altera.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1757579008; l=1329;
 i=rohan.g.thomas@altera.com; s=20250815; h=from:subject:message-id;
 bh=08KV5iTtWBP58r0AMyc5QP0+5U8/3Bb20vU2hpRSVqk=;
 b=RKVL8L4shTtsE0yMWktLB7UBTuTa5UWJgk5bAXN9GwEGjDkZuaPg7txbFStG1fwxJBY0LIErS
 eYMjClFcT76BBd+UOuHoOQAlvwTtkpfhVFDcJ60tcbGH5COJq7AZ5kT
X-Developer-Key: i=rohan.g.thomas@altera.com; a=ed25519;
 pk=5yZXkXswhfUILKAQwoIn7m6uSblwgV5oppxqde4g4TY=
X-Endpoint-Received: by B4 Relay for rohan.g.thomas@altera.com/20250815 with auth_id=494
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Rohan G Thomas <rohan.g.thomas@intel.com>

Fix the bounds checks for the hw supported maximum GCL entry
count and gate interval time.

Fixes: b60189e0392f ("net: stmmac: Integrate EST with TAPRIO scheduler API")
Signed-off-by: Rohan G Thomas <rohan.g.thomas@intel.com>
Reviewed-by: Matthew Gerlach <matthew.gerlach@altera.com>
---
 drivers/net/ethernet/stmicro/stmmac/stmmac_tc.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/net/ethernet/stmicro/stmmac/stmmac_tc.c b/drivers/net/ethernet/stmicro/stmmac/stmmac_tc.c
index 694d6ee1438197bd4434af6e9b78f022e94ff98f..89d094abb6be5c993c81901e3f79a6b03f310511 100644
--- a/drivers/net/ethernet/stmicro/stmmac/stmmac_tc.c
+++ b/drivers/net/ethernet/stmicro/stmmac/stmmac_tc.c
@@ -981,7 +981,7 @@ static int tc_taprio_configure(struct stmmac_priv *priv,
 	if (qopt->cmd == TAPRIO_CMD_DESTROY)
 		goto disable;
 
-	if (qopt->num_entries >= dep)
+	if (qopt->num_entries > dep)
 		return -EINVAL;
 	if (!qopt->cycle_time)
 		return -ERANGE;
@@ -1012,7 +1012,7 @@ static int tc_taprio_configure(struct stmmac_priv *priv,
 		s64 delta_ns = qopt->entries[i].interval;
 		u32 gates = qopt->entries[i].gate_mask;
 
-		if (delta_ns > GENMASK(wid, 0))
+		if (delta_ns >= BIT(wid))
 			return -ERANGE;
 		if (gates > GENMASK(31 - wid, 0))
 			return -ERANGE;

-- 
2.25.1

