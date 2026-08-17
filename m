From: Sven Peter <sven@kernel.org>
Date: Mon, 17 Aug 2026 21:54:01 +0200
Subject: [PATCH 4/5] thunderbolt: Don't access a DP tunnel after its DPRX
 read was canceled
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260817-b4-tbt-fixes-v1-4-eded2461f5fc@kernel.org>
References: <20260817-b4-tbt-fixes-v1-0-eded2461f5fc@kernel.org>
In-Reply-To: <20260817-b4-tbt-fixes-v1-0-eded2461f5fc@kernel.org>
To: Andreas Noever <andreas.noever@gmail.com>, 
 Mika Westerberg <westeri@kernel.org>, 
 Yehezkel Bernat <YehezkelShB@gmail.com>
Cc: asahi@lists.linux.dev, linux-usb@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Konrad Dybcio <konradybcio@kernel.org>, 
 Sven Peter <sven@kernel.org>, stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3140; i=sven@kernel.org;
 h=from:subject:message-id; bh=Wvk/GoG5BUNG7j62FvnpVbC2KSxj9mBYK7LX+M98XUw=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ1Zz2j3RWz+WHPqf/6gjIbvVb2nfokfamiHuEz9eZrsZv
 eNjavTZjlIWBjEuBlkxRZbt++1Nnzx8I7h006X3MHNYmUCGMHBxCsBEwr4yMjzta3nyKXDTgU3l
 m9vftK2Li+gyK79/VWZlmuaxjc4nN+9nZJgoVvZEoOTMUq5m70MH7T4sXPRF0/bYvJ1/Us24BDq
 l73ADAA==
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

tb_dp_dprx_work checks dprx_canceled before it takes tb->lock so it
misses a tb_dp_dprx_stop that could not cancel the already running
work. It then polls the DPRX capabilities and runs the callback for a
tunnel that is being torn down and touches routers that may already be
gone after an unplug.

Check the flag with tb->lock held instead and check it again in
tb_dp_tunnel_active because the callback runs after the lock has been
dropped again.

Also clear the flag in tb_dp_dprx_start so that it only ever describes
the work that is currently in flight.

Fixes: d6d458d42e1e ("thunderbolt: Handle DisplayPort tunnel activation asynchronously")
Cc: stable@vger.kernel.org
Signed-off-by: Sven Peter <sven@kernel.org>
---
 drivers/thunderbolt/tb.c     | 12 ++++++++++++
 drivers/thunderbolt/tunnel.c | 11 +++++++++--
 2 files changed, 21 insertions(+), 2 deletions(-)

diff --git a/drivers/thunderbolt/tb.c b/drivers/thunderbolt/tb.c
index fb9da53fe391..e368a6b53f64 100644
--- a/drivers/thunderbolt/tb.c
+++ b/drivers/thunderbolt/tb.c
@@ -1910,6 +1910,18 @@ static void tb_dp_tunnel_active(struct tb_tunnel *tunnel, void *data)
 	struct tb *tb = data;
 
 	mutex_lock(&tb->lock);
+
+	/*
+	 * If the DPRX read was canceled the tunnel is already being torn
+	 * down by whoever canceled it. Do not touch the adapters here
+	 * because the routers may be gone by now.
+	 */
+	if (tunnel->dprx_canceled) {
+		tb_tunnel_dbg(tunnel, "DPRX read canceled, not activating\n");
+		mutex_unlock(&tb->lock);
+		return;
+	}
+
 	if (tb_tunnel_is_active(tunnel)) {
 		int consumed_up, consumed_down, ret;
 
diff --git a/drivers/thunderbolt/tunnel.c b/drivers/thunderbolt/tunnel.c
index 82d9c0b556dd..52fa90786ff8 100644
--- a/drivers/thunderbolt/tunnel.c
+++ b/drivers/thunderbolt/tunnel.c
@@ -1090,8 +1090,14 @@ static void tb_dp_dprx_work(struct work_struct *work)
 	struct tb_tunnel *tunnel = container_of(work, typeof(*tunnel), dprx_work.work);
 	struct tb *tb = tunnel->tb;
 
+	/*
+	 * The DPRX read can be canceled while this work is waiting for
+	 * tb->lock. Check the flag only once it is held: while the lock is
+	 * held the tunnel cannot be torn down under us and the adapters are
+	 * safe to access.
+	 */
+	mutex_lock(&tb->lock);
 	if (!tunnel->dprx_canceled) {
-		mutex_lock(&tb->lock);
 		if (tb_dp_is_usb4(tunnel->src_port->sw) &&
 		    tb_dp_wait_dprx(tunnel, TB_DPRX_WAIT_TIMEOUT)) {
 			if (ktime_before(ktime_get(), tunnel->dprx_timeout)) {
@@ -1103,8 +1109,8 @@ static void tb_dp_dprx_work(struct work_struct *work)
 		} else {
 			tb_tunnel_set_active(tunnel, true);
 		}
-		mutex_unlock(&tb->lock);
 	}
+	mutex_unlock(&tb->lock);
 
 	if (tunnel->callback)
 		tunnel->callback(tunnel, tunnel->callback_data);
@@ -1123,6 +1129,7 @@ static int tb_dp_dprx_start(struct tb_tunnel *tunnel)
 		tb_domain_get(tunnel->tb);
 
 		tunnel->dprx_started = true;
+		tunnel->dprx_canceled = false;
 		tunnel->dprx_timeout = dprx_timeout_to_ktime(dprx_timeout);
 		queue_delayed_work(tunnel->tb->wq, &tunnel->dprx_work, 0);
 		return -EINPROGRESS;

-- 
2.55.0

