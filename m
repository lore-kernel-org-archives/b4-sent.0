From: Sven Peter <sven@kernel.org>
Date: Mon, 17 Aug 2026 21:54:00 +0200
Subject: [PATCH 3/5] thunderbolt: Fix domain reference leak when DPRX read
 is canceled
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260817-b4-tbt-fixes-v1-3-eded2461f5fc@kernel.org>
References: <20260817-b4-tbt-fixes-v1-0-eded2461f5fc@kernel.org>
In-Reply-To: <20260817-b4-tbt-fixes-v1-0-eded2461f5fc@kernel.org>
To: Andreas Noever <andreas.noever@gmail.com>, 
 Mika Westerberg <westeri@kernel.org>, 
 Yehezkel Bernat <YehezkelShB@gmail.com>
Cc: asahi@lists.linux.dev, linux-usb@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Konrad Dybcio <konradybcio@kernel.org>, 
 Sven Peter <sven@kernel.org>, stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3515; i=sven@kernel.org;
 h=from:subject:message-id; bh=zjk4QT3VNOWscQLSaRMfjv/7SUgD1nm1RUMMr8V4Hf8=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ1Zz2l2GHUW8VzdH1G3el8+Td29KjMzFzOZdRhkiHZPLP
 5/jXt3eUcrCIMbFICumyLJ9v73pk4dvBJduuvQeZg4rE9gQLk4BmMi+lwz/ffmOXfo8Y+63Nas/
 HlJI45xu2VSvnKnLq3DnnHWDH9/U34wMryYXFXL1rvQ8zTcxgydL8MfGxY0S/LcqBM6/TXS2Lt7
 GCQA=
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

tb_tunnel_one_dp takes a domain reference which is only dropped once
tb_dp_tunnel_active has run on the work queue. If that work is
cancelled that reference is leaked. Since
commit f5cc545f5969 ("thunderbolt: Wait for tb_domain_release() to
complete when driver is removed") instead of just leaking memory this
now also blocks in the completion wait forever when unbinding the
driver.

That reference only exists to keep the domain around while the DPRX work
is scheduled so let the work itself own it: take it in tb_dp_dprx_start
and drop it in both places that end the work. Get/put are then paired
inside the same file and it doesn't matter anymore if the callback ever
runs.

Fixes: d6d458d42e1e ("thunderbolt: Handle DisplayPort tunnel activation asynchronously")
Cc: stable@vger.kernel.org
Signed-off-by: Sven Peter <sven@kernel.org>
---
 drivers/thunderbolt/tb.c     |  6 +-----
 drivers/thunderbolt/tunnel.c | 12 +++++++++---
 2 files changed, 10 insertions(+), 8 deletions(-)

diff --git a/drivers/thunderbolt/tb.c b/drivers/thunderbolt/tb.c
index f43f2d952372..fb9da53fe391 100644
--- a/drivers/thunderbolt/tb.c
+++ b/drivers/thunderbolt/tb.c
@@ -1964,8 +1964,6 @@ static void tb_dp_tunnel_active(struct tb_tunnel *tunnel, void *data)
 		tb_dp_resource_unavailable(tb, in, "DPRX negotiation failed");
 	}
 	mutex_unlock(&tb->lock);
-
-	tb_domain_put(tb);
 }
 
 static void tb_tunnel_one_dp(struct tb *tb, struct tb_port *in,
@@ -2026,8 +2024,7 @@ static void tb_tunnel_one_dp(struct tb *tb, struct tb_port *in,
 	       available_up, available_down);
 
 	tunnel = tb_tunnel_alloc_dp(tb, in, out, link_nr, available_up,
-				    available_down, tb_dp_tunnel_active,
-				    tb_domain_get(tb));
+				    available_down, tb_dp_tunnel_active, tb);
 	if (!tunnel) {
 		tb_port_dbg(out, "could not allocate DP tunnel\n");
 		goto err_reclaim_usb;
@@ -2048,7 +2045,6 @@ static void tb_tunnel_one_dp(struct tb *tb, struct tb_port *in,
 	tb_tunnel_put(tunnel);
 err_reclaim_usb:
 	tb_reclaim_usb3_bandwidth(tb, in, out);
-	tb_domain_put(tb);
 err_detach_group:
 	tb_detach_bandwidth_group(in);
 err_dealloc_dp:
diff --git a/drivers/thunderbolt/tunnel.c b/drivers/thunderbolt/tunnel.c
index 50580ebdac4b..82d9c0b556dd 100644
--- a/drivers/thunderbolt/tunnel.c
+++ b/drivers/thunderbolt/tunnel.c
@@ -1109,16 +1109,18 @@ static void tb_dp_dprx_work(struct work_struct *work)
 	if (tunnel->callback)
 		tunnel->callback(tunnel, tunnel->callback_data);
 	tb_tunnel_put(tunnel);
+	tb_domain_put(tb);
 }
 
 static int tb_dp_dprx_start(struct tb_tunnel *tunnel)
 {
 	if (tunnel->callback) {
 		/*
-		 * Bump up the reference to keep the tunnel around until the
-		 * work has run or has been canceled.
+		 * Bump up the references to keep the tunnel and the domain
+		 * around until the work has run or has been canceled.
 		 */
 		tb_tunnel_get(tunnel);
+		tb_domain_get(tunnel->tb);
 
 		tunnel->dprx_started = true;
 		tunnel->dprx_timeout = dprx_timeout_to_ktime(dprx_timeout);
@@ -1132,11 +1134,15 @@ static int tb_dp_dprx_start(struct tb_tunnel *tunnel)
 
 static void tb_dp_dprx_stop(struct tb_tunnel *tunnel)
 {
+	struct tb *tb = tunnel->tb;
+
 	if (tunnel->dprx_started) {
 		tunnel->dprx_started = false;
 		tunnel->dprx_canceled = true;
-		if (cancel_delayed_work(&tunnel->dprx_work))
+		if (cancel_delayed_work(&tunnel->dprx_work)) {
 			tb_tunnel_put(tunnel);
+			tb_domain_put(tb);
+		}
 	}
 }
 

-- 
2.55.0

