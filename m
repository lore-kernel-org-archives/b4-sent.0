From: Fan Ye <fy15309206903@gmail.com>
Date: Sun, 09 Aug 2026 02:38:12 +0000
Subject: [PATCH 1/2] thunderbolt: Report DMA path teardown failures to the
 caller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260809-b4-tb-teardown-v1-1-c88bbfe5c127@gmail.com>
References: <20260809-b4-tb-teardown-v1-0-c88bbfe5c127@gmail.com>
In-Reply-To: <20260809-b4-tb-teardown-v1-0-c88bbfe5c127@gmail.com>
To: Andreas Noever <andreas.noever@gmail.com>, 
 Mika Westerberg <westeri@kernel.org>, 
 Yehezkel Bernat <YehezkelShB@gmail.com>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Fan Ye <fy15309206903@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786243091; l=13438;
 i=fy15309206903@gmail.com; s=tbnet3; h=from:subject:message-id;
 bh=5AHRlpfrTSsFCbzNpyLtMvBMw9k0+EuueoiB50mmcF0=;
 b=gw4IgH7ihJ5bILsxJcAMTO/S47Ohk9llAjSilkWSpfnowPTh+bC4CLk/Do1Sds1c0F1cS6Fzl
 k8evFN6TRUCBG+MEqhMkyQ78IqNBmBOdJDAGQcGC2S3bX/M7eczbBbK
X-Developer-Key: i=fy15309206903@gmail.com; a=ed25519;
 pk=6QsQIrI/kruYWIJyCH9ntPMXsHCqF5JtK/DCMtOCzdc=
X-Endpoint-Received: by B4 Relay for fy15309206903@gmail.com/tbnet3 with auth_id=929
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

tb_disconnect_xdomain_paths() returns 0 unconditionally. Everything
below it that could fail is a void function, so when a hop refuses to
drain and __tb_path_deactivate_hop() gives up with -ETIMEDOUT, the only
trace is one tb_port_warn() line; the connection manager reports success.

One of the ICM implementations of the same cm_ops callback,
icm_tr_disconnect_xdomain_paths(), does propagate its errors; the other,
icm_fr_disconnect_xdomain_paths(), returns 0 unconditionally the way the
software one does. So of the three implementations behind that callback
only one tells the caller anything, and callers cannot tell which one
they are talking to. tbnet has

	ret = tb_xdomain_disable_paths(...);
	if (ret)
		netdev_warn(net->dev, "failed to disable DMA paths\n");

which therefore can only ever fire on the ICM hosts that use the _tr
implementation, never on the software connection manager that every USB4
host uses.

Give the software connection manager the same contract: return the first
error seen while deactivating hops, and pass it up through
tb_path_deactivate(), tb_tunnel_deactivate() and
tb_deactivate_and_free_tunnel().

Teardown still runs to completion on failure - the paths are marked
inactive, the credits are released and the tunnel is freed exactly as
before. What changes is that a caller which looks at the return value
now gets told.

One caller already looks, and it is worth spelling out what this does to
it. tb_xdomain_disable_paths() decrements xd->ntunnels only when the
callback returns 0, so on a hop that fails to drain the counter is now
left incremented for a tunnel that is gone. Nothing reads it on this
path - ntunnels is only consulted by the ICM implementations of
approve_xdomain_paths(), which never run on a software connection
manager - so this is inert today. It is still a real difference in what
a nonzero return means between the two connection managers: for ICM it
says the tunnel may still be up, for this one it says the tunnel is gone
but a hop did not drain. If you would rather the counter stayed exact I
can decrement it unconditionally there, but that only makes sense
alongside the guarantee this patch adds, so I left it out.

This matters more than a lost warning. On an ASMedia ASM4242 host router
the Tx path hop reports its pending bit set once the Tx ring has wrapped
once and never clears it again, so every teardown after that burns the
full 500 ms timeout and fails. Cycling the interface down and up 200
times across two such hosts produced 213 and 206 of those timeouts, and
the connection manager reported every one of them as success.

With this patch the first of them arrives at tbnet as well:

  thunderbolt 0000:70:00.0: 0:5: hop deactivation failed for hop 0, index 1
  thunderbolt-net 0-1.0 thunderbolt0: failed to disable DMA paths

Both lines are from the same second and the same teardown, the first from
__tb_path_deactivate_hops() and the second from tbnet, which had no way
of hearing about it before.

Signed-off-by: Fan Ye <fy15309206903@gmail.com>

---
These four came out of one investigation on a pair of ASMedia ASM4242
hosts wired to each other. Apply them in this order: the second one
touches lines the first one adds, so it needs that one underneath to
apply at all, and the last two want the first two under them for the
reason below.

  1 net: thunderbolt: Release the Rx HopID that was handed out on mismatch
  2 net: thunderbolt: Mark the connection down when bringing it up fails
  3 thunderbolt: Report DMA path teardown failures to the caller
  4 thunderbolt: Stop waiting on a path pending bit that never clears

This one is number 3 on that list.

1 and 2 fix two separate things that happen to be reached through the
same branch. Neither depends on the other for correctness - each leaves
the other's defect in place - but 2 edits the lines 1 adds, so it will
not apply on its own.

1 and 2 were posted to netdev separately and are not in this series:
https://lore.kernel.org/netdev/20260809-b4-tbnet-hopid-v1-0-97aaf2aa0fc7@gmail.com/

3 and 4 do want 1 and 2 underneath: the warning splat that 2 removes
fires throughout any prolonged run of link cycling, which is what 3 and 4
have to be measured across. 3 makes teardown failures visible to the
caller at all; 4 stops the teardown paying for one that cannot succeed.
Note what that pair does on this particular router - 4 leaves the first
failure to be reported and silences the rest, so 3's new signal fires
once per adapter here rather than on every teardown. 4 is the one I am
least sure of, for the reasons in its own notes.

This widens three signatures, across fifteen call sites of which twelve
still ignore the value:

  tb_path_deactivate()            2 sites, 1 collects
  tb_tunnel_deactivate()          8 sites, 1 collects
  tb_deactivate_and_free_tunnel() 5 sites, 1 collects

The one tb_path_deactivate() site that does not collect is in
tb_tunnel_activate(), which disables each hop before programming it and
has nothing to do with a teardown failing; I left it alone deliberately.
The twelve behaved the same before and behave the same now. The
alternative I could see was threading a separate out-parameter down to
the one caller that cares, which seemed worse.

tb_path_deactivate() also gains a second error return: it now answers
-EINVAL for a path that is not activated, where it used to warn and
return void. Both callers guard on paths[i]->activated so nothing can
reach it today, but it does travel the same channel as a real hop
failure if a future caller stops guarding.

The direction here is a judgement call and I may have it backwards. I
made the software connection manager match ICM because tbnet and
dma_test are both written as if the callback returns errors, and on ICM
it does. The other way round - having ICM stop propagating - would also
make the two agree, and would not touch as much code. If that is the
preferred direction, say so and I will send that instead.
---
 drivers/thunderbolt/path.c   | 21 +++++++++++++++------
 drivers/thunderbolt/tb.c     | 35 +++++++++++++++++++++++------------
 drivers/thunderbolt/tb.h     |  2 +-
 drivers/thunderbolt/tunnel.c | 19 +++++++++++++++----
 drivers/thunderbolt/tunnel.h |  2 +-
 5 files changed, 55 insertions(+), 24 deletions(-)

diff --git a/drivers/thunderbolt/path.c b/drivers/thunderbolt/path.c
index b2c322e76b8a..81a79c78777e 100644
--- a/drivers/thunderbolt/path.c
+++ b/drivers/thunderbolt/path.c
@@ -448,26 +448,33 @@ int tb_path_deactivate_hop(struct tb_port *port, int hop_index)
 	return __tb_path_deactivate_hop(port, hop_index, true);
 }
 
-static void __tb_path_deactivate_hops(struct tb_path *path, int first_hop)
+static int __tb_path_deactivate_hops(struct tb_path *path, int first_hop)
 {
-	int i, res;
+	int i, res, ret = 0;
 
 	for (i = first_hop; i < path->path_length; i++) {
 		res = __tb_path_deactivate_hop(path->hops[i].in_port,
 					       path->hops[i].in_hop_index,
 					       path->clear_fc);
-		if (res && res != -ENODEV)
+		if (res && res != -ENODEV) {
 			tb_port_warn(path->hops[i].in_port,
 				     "hop deactivation failed for hop %d, index %d\n",
 				     i, path->hops[i].in_hop_index);
+			if (!ret)
+				ret = res;
+		}
 	}
+
+	return ret;
 }
 
-void tb_path_deactivate(struct tb_path *path)
+int tb_path_deactivate(struct tb_path *path)
 {
+	int ret;
+
 	if (!path->activated) {
 		tb_WARN(path->tb, "trying to deactivate an inactive path\n");
-		return;
+		return -EINVAL;
 	}
 	tb_dbg(path->tb,
 	       "deactivating %s path from %llx:%u to %llx:%u\n",
@@ -475,9 +482,11 @@ void tb_path_deactivate(struct tb_path *path)
 	       path->hops[0].in_port->port,
 	       tb_route(path->hops[path->path_length - 1].out_port->sw),
 	       path->hops[path->path_length - 1].out_port->port);
-	__tb_path_deactivate_hops(path, 0);
+	ret = __tb_path_deactivate_hops(path, 0);
 	__tb_path_deallocate_nfc(path, 0);
 	path->activated = false;
+
+	return ret;
 }
 
 /**
diff --git a/drivers/thunderbolt/tb.c b/drivers/thunderbolt/tb.c
index f43f2d952372..d5bc31a8b184 100644
--- a/drivers/thunderbolt/tb.c
+++ b/drivers/thunderbolt/tb.c
@@ -1719,15 +1719,16 @@ static void tb_discover_tunnels(struct tb *tb)
 	}
 }
 
-static void tb_deactivate_and_free_tunnel(struct tb_tunnel *tunnel)
+static int tb_deactivate_and_free_tunnel(struct tb_tunnel *tunnel)
 {
 	struct tb_port *src_port, *dst_port;
 	struct tb *tb;
+	int ret;
 
 	if (!tunnel)
-		return;
+		return 0;
 
-	tb_tunnel_deactivate(tunnel);
+	ret = tb_tunnel_deactivate(tunnel);
 	list_del(&tunnel->list);
 
 	tb = tunnel->tb;
@@ -1767,6 +1768,8 @@ static void tb_deactivate_and_free_tunnel(struct tb_tunnel *tunnel)
 	}
 
 	tb_tunnel_put(tunnel);
+
+	return ret;
 }
 
 /*
@@ -2365,14 +2368,15 @@ static int tb_approve_xdomain_paths(struct tb *tb, struct tb_xdomain *xd,
 	return ret;
 }
 
-static void __tb_disconnect_xdomain_paths(struct tb *tb, struct tb_xdomain *xd,
-					  int transmit_path, int transmit_ring,
-					  int receive_path, int receive_ring)
+static int __tb_disconnect_xdomain_paths(struct tb *tb, struct tb_xdomain *xd,
+					 int transmit_path, int transmit_ring,
+					 int receive_path, int receive_ring)
 {
 	struct tb_cm *tcm = tb_priv(tb);
 	struct tb_port *nhi_port, *dst_port;
 	struct tb_tunnel *tunnel, *n;
 	struct tb_switch *sw;
+	int res, ret = 0;
 
 	sw = tb_to_switch(xd->dev.parent);
 	dst_port = tb_port_at(xd->route, sw);
@@ -2385,8 +2389,11 @@ static void __tb_disconnect_xdomain_paths(struct tb *tb, struct tb_xdomain *xd,
 			continue;
 
 		if (tb_tunnel_match_dma(tunnel, transmit_path, transmit_ring,
-					receive_path, receive_ring))
-			tb_deactivate_and_free_tunnel(tunnel);
+					receive_path, receive_ring)) {
+			res = tb_deactivate_and_free_tunnel(tunnel);
+			if (res && !ret)
+				ret = res;
+		}
 	}
 
 	/*
@@ -2395,20 +2402,24 @@ static void __tb_disconnect_xdomain_paths(struct tb *tb, struct tb_xdomain *xd,
 	 * the same host router USB4 downstream port.
 	 */
 	tb_enable_clx(sw);
+
+	return ret;
 }
 
 static int tb_disconnect_xdomain_paths(struct tb *tb, struct tb_xdomain *xd,
 				       int transmit_path, int transmit_ring,
 				       int receive_path, int receive_ring)
 {
+	int ret = 0;
+
 	if (!xd->is_unplugged) {
 		mutex_lock(&tb->lock);
-		__tb_disconnect_xdomain_paths(tb, xd, transmit_path,
-					      transmit_ring, receive_path,
-					      receive_ring);
+		ret = __tb_disconnect_xdomain_paths(tb, xd, transmit_path,
+						    transmit_ring, receive_path,
+						    receive_ring);
 		mutex_unlock(&tb->lock);
 	}
-	return 0;
+	return ret;
 }
 
 /* hotplug handling */
diff --git a/drivers/thunderbolt/tb.h b/drivers/thunderbolt/tb.h
index ec9192b61bc0..a9a32b64fe2a 100644
--- a/drivers/thunderbolt/tb.h
+++ b/drivers/thunderbolt/tb.h
@@ -1197,7 +1197,7 @@ struct tb_path *tb_path_alloc(struct tb *tb, struct tb_port *src, int src_hopid,
 			      const char *name);
 void tb_path_free(struct tb_path *path);
 int tb_path_activate(struct tb_path *path);
-void tb_path_deactivate(struct tb_path *path);
+int tb_path_deactivate(struct tb_path *path);
 int tb_path_deactivate_hop(struct tb_port *port, int hop_index);
 bool tb_path_is_invalid(struct tb_path *path);
 bool tb_path_port_on_path(const struct tb_path *path,
diff --git a/drivers/thunderbolt/tunnel.c b/drivers/thunderbolt/tunnel.c
index b7f32305f14a..21d866476379 100644
--- a/drivers/thunderbolt/tunnel.c
+++ b/drivers/thunderbolt/tunnel.c
@@ -2454,10 +2454,16 @@ int tb_tunnel_activate(struct tb_tunnel *tunnel)
 /**
  * tb_tunnel_deactivate() - deactivate a tunnel
  * @tunnel: Tunnel to deactivate
+ *
+ * Deactivates all paths of the tunnel. This always runs to completion,
+ * even if a path fails to deactivate.
+ *
+ * Return: %0 on success, or the first error seen while deactivating the
+ * paths.
  */
-void tb_tunnel_deactivate(struct tb_tunnel *tunnel)
+int tb_tunnel_deactivate(struct tb_tunnel *tunnel)
 {
-	int i;
+	int i, res, ret = 0;
 
 	tb_tunnel_dbg(tunnel, "deactivating\n");
 
@@ -2465,14 +2471,19 @@ void tb_tunnel_deactivate(struct tb_tunnel *tunnel)
 		tunnel->activate(tunnel, false);
 
 	for (i = 0; i < tunnel->npaths; i++) {
-		if (tunnel->paths[i] && tunnel->paths[i]->activated)
-			tb_path_deactivate(tunnel->paths[i]);
+		if (tunnel->paths[i] && tunnel->paths[i]->activated) {
+			res = tb_path_deactivate(tunnel->paths[i]);
+			if (res && !ret)
+				ret = res;
+		}
 	}
 
 	if (tunnel->post_deactivate)
 		tunnel->post_deactivate(tunnel);
 
 	tb_tunnel_set_active(tunnel, false);
+
+	return ret;
 }
 
 /**
diff --git a/drivers/thunderbolt/tunnel.h b/drivers/thunderbolt/tunnel.h
index 4878763a82b3..deb07af85ab2 100644
--- a/drivers/thunderbolt/tunnel.h
+++ b/drivers/thunderbolt/tunnel.h
@@ -137,7 +137,7 @@ struct tb_tunnel *tb_tunnel_alloc_usb3(struct tb *tb, struct tb_port *up,
 
 void tb_tunnel_put(struct tb_tunnel *tunnel);
 int tb_tunnel_activate(struct tb_tunnel *tunnel);
-void tb_tunnel_deactivate(struct tb_tunnel *tunnel);
+int tb_tunnel_deactivate(struct tb_tunnel *tunnel);
 
 /**
  * tb_tunnel_is_active() - Is tunnel fully activated

-- 
2.43.0

