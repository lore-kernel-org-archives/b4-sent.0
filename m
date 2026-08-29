From: Sven Peter <sven@kernel.org>
Date: Sat, 29 Aug 2026 10:08:35 +0200
Subject: [PATCH v3 3/7] thunderbolt: Fix domain reference leak when DPRX
 read is canceled
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260829-b4-tbt-fixes-v3-3-e1fab6ac54fe@kernel.org>
References: <20260829-b4-tbt-fixes-v3-0-e1fab6ac54fe@kernel.org>
In-Reply-To: <20260829-b4-tbt-fixes-v3-0-e1fab6ac54fe@kernel.org>
To: Andreas Noever <andreas.noever@gmail.com>, 
 Mika Westerberg <westeri@kernel.org>, 
 Yehezkel Bernat <YehezkelShB@gmail.com>
Cc: Mika Westerberg <mika.westerberg@linux.intel.com>, 
 Konrad Dybcio <konradybcio@kernel.org>, asahi@lists.linux.dev, 
 linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Sven Peter <sven@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3650; i=sven@kernel.org;
 h=from:subject:message-id; bh=VJZIeF5PZQvYQEjzLXTR8wV0qkJBVGUXFDvmExnY1Y4=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ9akyb0/Jn3P4GkQWJ94yVTRVPWq6ikuhqX5E45cXP3tA
 s+jDdmrOkpZGMS4GGTFFFm277c3ffLwjeDSTZfew8xhZQIZwsDFKQATUWxi+F+ZcTK+ytOhz9ec
 yz+z3pDLtyIx9DJvXIL/3ozvUbOePmD4Z9Eq+FPYOrC9d93Px5sLDh37N2lPhu78+fIHWVZl79/
 twwIA
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

This can be triggered whenever a DP tunnel is torn down before the DPRX
read has completed, e.g. by unplugging within the timeout, and then
unbinding the driver.

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
index 29b9879c40d8..ef4413581b2a 100644
--- a/drivers/thunderbolt/tb.c
+++ b/drivers/thunderbolt/tb.c
@@ -1966,8 +1966,6 @@ static void tb_dp_tunnel_active(struct tb_tunnel *tunnel, void *data)
 		tb_dp_resource_unavailable(tb, in, "DPRX negotiation failed");
 	}
 	mutex_unlock(&tb->lock);
-
-	tb_domain_put(tb);
 }
 
 static void tb_tunnel_one_dp(struct tb *tb, struct tb_port *in,
@@ -2028,8 +2026,7 @@ static void tb_tunnel_one_dp(struct tb *tb, struct tb_port *in,
 	       available_up, available_down);
 
 	tunnel = tb_tunnel_alloc_dp(tb, in, out, link_nr, available_up,
-				    available_down, tb_dp_tunnel_active,
-				    tb_domain_get(tb));
+				    available_down, tb_dp_tunnel_active, tb);
 	if (!tunnel) {
 		tb_port_dbg(out, "could not allocate DP tunnel\n");
 		goto err_reclaim_usb;
@@ -2050,7 +2047,6 @@ static void tb_tunnel_one_dp(struct tb *tb, struct tb_port *in,
 	tb_tunnel_put(tunnel);
 err_reclaim_usb:
 	tb_reclaim_usb3_bandwidth(tb, in, out);
-	tb_domain_put(tb);
 err_detach_group:
 	tb_detach_bandwidth_group(in);
 err_dealloc_dp:
diff --git a/drivers/thunderbolt/tunnel.c b/drivers/thunderbolt/tunnel.c
index 1f978fddaeed..00c5a1933544 100644
--- a/drivers/thunderbolt/tunnel.c
+++ b/drivers/thunderbolt/tunnel.c
@@ -1108,15 +1108,17 @@ static void tb_dp_dprx_work(struct work_struct *work)
 
 	tunnel->callback(tunnel, tunnel->callback_data);
 	tb_tunnel_put(tunnel);
+	tb_domain_put(tb);
 }
 
 static int tb_dp_dprx_start(struct tb_tunnel *tunnel)
 {
 	/*
-	 * Bump up the reference to keep the tunnel around. It will be
-	 * dropped in tb_dp_dprx_stop() once the tunnel is deactivated.
+	 * Bump up the references to keep the tunnel and the domain around
+	 * until the work has run or has been canceled.
 	 */
 	tb_tunnel_get(tunnel);
+	tb_domain_get(tunnel->tb);
 
 	tunnel->dprx_started = true;
 	tunnel->dprx_timeout = dprx_timeout_to_ktime(dprx_timeout);
@@ -1127,11 +1129,15 @@ static int tb_dp_dprx_start(struct tb_tunnel *tunnel)
 
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

