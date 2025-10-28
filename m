From: Rohan G Thomas <rohan.g.thomas@altera.com>
Date: Tue, 28 Oct 2025 11:18:45 +0800
Subject: [PATCH net v4 3/3] net: stmmac: est: Fix GCL bounds checks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251028-qbv-fixes-v4-3-26481c7634e3@altera.com>
References: <20251028-qbv-fixes-v4-0-26481c7634e3@altera.com>
In-Reply-To: <20251028-qbv-fixes-v4-0-26481c7634e3@altera.com>
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Jose Abreu <Jose.Abreu@synopsys.com>, 
 Rohan G Thomas <rohan.g.thomas@intel.com>, 
 Boon Khai Ng <boon.khai.ng@altera.com>
Cc: netdev@vger.kernel.org, linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Rohan G Thomas <rohan.g.thomas@altera.com>, 
 Matthew Gerlach <matthew.gerlach@altera.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761621544; l=1340;
 i=rohan.g.thomas@altera.com; s=20250815; h=from:subject:message-id;
 bh=k4E9iK4RiPK/MUr6aNRMEoxEsNmOvrcMsNQIhLkPefA=;
 b=HfSDPmgRlDitrbNjivy6sUn+fYyJqUgImrklCz+82NoRqDphaIwBDiBGGyY0CrBJWNiQZSNVn
 MX41EgUgcl5BCokGi0lBGPv+Zq16SiugloP3OYI08P9v3VN9Ixl2ObO
X-Developer-Key: i=rohan.g.thomas@altera.com; a=ed25519;
 pk=5yZXkXswhfUILKAQwoIn7m6uSblwgV5oppxqde4g4TY=
X-Endpoint-Received: by B4 Relay for rohan.g.thomas@altera.com/20250815 with auth_id=494
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix the bounds checks for the hw supported maximum GCL entry
count and gate interval time.

Fixes: b60189e0392f ("net: stmmac: Integrate EST with TAPRIO scheduler API")
Signed-off-by: Rohan G Thomas <rohan.g.thomas@altera.com>
Reviewed-by: Matthew Gerlach <matthew.gerlach@altera.com>
---
 drivers/net/ethernet/stmicro/stmmac/stmmac_tc.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/net/ethernet/stmicro/stmmac/stmmac_tc.c b/drivers/net/ethernet/stmicro/stmmac/stmmac_tc.c
index ef65cf511f3e25eb512187d52775bb363bb83902..d786527185999db6bb6a18a29eee5ff5282b8ef4 100644
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
+		if (delta_ns > GENMASK(wid - 1, 0))
 			return -ERANGE;
 		if (gates > GENMASK(31 - wid, 0))
 			return -ERANGE;

-- 
2.43.7

