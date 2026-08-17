From: Sven Peter <sven@kernel.org>
Date: Mon, 17 Aug 2026 21:54:02 +0200
Subject: [PATCH 5/5] thunderbolt: Cancel the DPRX read when the domain is
 stopped
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260817-b4-tbt-fixes-v1-5-eded2461f5fc@kernel.org>
References: <20260817-b4-tbt-fixes-v1-0-eded2461f5fc@kernel.org>
In-Reply-To: <20260817-b4-tbt-fixes-v1-0-eded2461f5fc@kernel.org>
To: Andreas Noever <andreas.noever@gmail.com>, 
 Mika Westerberg <westeri@kernel.org>, 
 Yehezkel Bernat <YehezkelShB@gmail.com>
Cc: asahi@lists.linux.dev, linux-usb@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Konrad Dybcio <konradybcio@kernel.org>, 
 Sven Peter <sven@kernel.org>, stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3116; i=sven@kernel.org;
 h=from:subject:message-id; bh=xAAxDyvnDi8yNJ6ByWgjRWlh3/HZjKsKtAZ8OmkRJfM=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ1Zz2v3HMVJchkYPVucEcU2w2VV2NLYnJ/+X0mGDrZp95
 RfXmct0lLIwiHExyIopsmzfb2/65OEbwaWbLr2HmcPKBDKEgYtTACai4sTI8Cg2d5/x75PfSv+t
 KXjgpv52v9D6nir1uEc1Mf3S3TuM7jP8ZDyfHekRmVYR+rytTcJ7Y9Z2z2/v+/tul5oF6nf3vO/
 hAAA=
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

tb_stop only tears down DMA tunnels so a DP tunnel that is still
waiting for dprx_work to complete keeps that work queued while the
routers are removed and the control channel is stopped. The work only
stops once the DPRX timeout has passed and because it requeues itself
until then the flush_workqueue in tb_domain_remove won't wait for its
final run. The callback then runs against a domain that is already torn
down. A reference to that domain is kept so the completion waiting for
that domain to disappear in unbind will block until the timeout is
eventually reached.

Just cancel the work in tb_stop. This doesn't affect DP tunnels that are
already alive and keeps those displays working.

Fixes: d6d458d42e1e ("thunderbolt: Handle DisplayPort tunnel activation asynchronously")
Cc: stable@vger.kernel.org
Signed-off-by: Sven Peter <sven@kernel.org>
---
I also didn't run into this but noticed it when fixing the hop alloc thing
and think it makes sense to fix it anyway.
---
 drivers/thunderbolt/tb.c     | 5 ++++-
 drivers/thunderbolt/tunnel.c | 9 +++++++++
 drivers/thunderbolt/tunnel.h | 1 +
 3 files changed, 14 insertions(+), 1 deletion(-)

diff --git a/drivers/thunderbolt/tb.c b/drivers/thunderbolt/tb.c
index e368a6b53f64..f7e68372da09 100644
--- a/drivers/thunderbolt/tb.c
+++ b/drivers/thunderbolt/tb.c
@@ -2958,10 +2958,13 @@ static void tb_stop(struct tb *tb)
 		/*
 		 * DMA tunnels require the driver to be functional so we
 		 * tear them down. Other protocol tunnels can be left
-		 * intact.
+		 * intact but a DPRX capabilities read that is still in
+		 * flight has to be canceled before the routers go away.
 		 */
 		if (tb_tunnel_is_dma(tunnel))
 			tb_tunnel_deactivate(tunnel);
+		else if (tb_tunnel_is_dp(tunnel))
+			tb_tunnel_cancel_dprx(tunnel);
 		tb_tunnel_put(tunnel);
 	}
 	tb_switch_remove(tb->root_switch);
diff --git a/drivers/thunderbolt/tunnel.c b/drivers/thunderbolt/tunnel.c
index 52fa90786ff8..5b1ae5a0c12b 100644
--- a/drivers/thunderbolt/tunnel.c
+++ b/drivers/thunderbolt/tunnel.c
@@ -2487,6 +2487,15 @@ void tb_tunnel_deactivate(struct tb_tunnel *tunnel)
 	tb_tunnel_set_active(tunnel, false);
 }
 
+/**
+ * tb_tunnel_cancel_dprx() - Cancel the DPRX capabilities read work
+ * @tunnel: tunnel to cancel the DPRX capabilities read work for
+ */
+void tb_tunnel_cancel_dprx(struct tb_tunnel *tunnel)
+{
+	tb_dp_dprx_stop(tunnel);
+}
+
 /**
  * tb_tunnel_port_on_path() - Does the tunnel go through port
  * @tunnel: Tunnel to check
diff --git a/drivers/thunderbolt/tunnel.h b/drivers/thunderbolt/tunnel.h
index 4878763a82b3..9de5fac04269 100644
--- a/drivers/thunderbolt/tunnel.h
+++ b/drivers/thunderbolt/tunnel.h
@@ -138,6 +138,7 @@ struct tb_tunnel *tb_tunnel_alloc_usb3(struct tb *tb, struct tb_port *up,
 void tb_tunnel_put(struct tb_tunnel *tunnel);
 int tb_tunnel_activate(struct tb_tunnel *tunnel);
 void tb_tunnel_deactivate(struct tb_tunnel *tunnel);
+void tb_tunnel_cancel_dprx(struct tb_tunnel *tunnel);
 
 /**
  * tb_tunnel_is_active() - Is tunnel fully activated

-- 
2.55.0

