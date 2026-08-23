From: Sven Peter <sven@kernel.org>
Date: Sun, 23 Aug 2026 18:09:14 +0200
Subject: [PATCH v2 1/7] thunderbolt: Hold a router reference for each path
 hop
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260823-b4-tbt-fixes-v2-1-26a18a426c9f@kernel.org>
References: <20260823-b4-tbt-fixes-v2-0-26a18a426c9f@kernel.org>
In-Reply-To: <20260823-b4-tbt-fixes-v2-0-26a18a426c9f@kernel.org>
To: Andreas Noever <andreas.noever@gmail.com>, 
 Mika Westerberg <westeri@kernel.org>, 
 Yehezkel Bernat <YehezkelShB@gmail.com>
Cc: Mika Westerberg <mika.westerberg@linux.intel.com>, 
 Konrad Dybcio <konradybcio@kernel.org>, asahi@lists.linux.dev, 
 linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Sven Peter <sven@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3958; i=sven@kernel.org;
 h=from:subject:message-id; bh=esh7Wy98o9M7H1i80O38p9rP0EepwdyMIe/Wn+DxPis=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ1a3dGzWuevXcjTCqnavfG+S4bxzQZjNYxdjrzpmFqvfi
 /SPL7jfUcrCIMbFICumyLJ9v73pk4dvBJduuvQeZg4rE8gQBi5OAZiItSsjw4JquxC9k7WOgpvM
 JvmeFLAtr7634LrM2Ri+fV5/8i1lPBkZLtrNq5x3ne3gm7uPqmOWGYs2HbrHsenemfs/zodI1PA
 HMgAA
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

tb_stop drops the reference to all DP tunnels but does not deactivate
them, thus nothing cancels a dprx_work still in flight (which holds its
own tunnel reference) and the tunnel can outlive tb_switch_remove. The
HopID releases in tb_path_free then operate on freed IDAs and trigger
warnings like

  ida_free called for id=8 which is not allocated.

This can be triggered by unbinding the driver while a DP tunnel is still
waiting for the DPRX capabilities read to finish. On the Apple NHI
unplugging the cable runs into just that reliably because the read can
never finish right now and because the unplug powers down the
entire USB4 complex and removes the NHI device.

Take or release a reference for both ports of each hop whenever the
HopIDs are allocated or released to ensure they have the same lifetime.

The KUnit tests allocate their switches without ever registering them so
initialize the embedded struct device there as well to make these
references work.

Fixes: d6d458d42e1e ("thunderbolt: Handle DisplayPort tunnel activation asynchronously")
Cc: stable@vger.kernel.org
Signed-off-by: Sven Peter <sven@kernel.org>
---
 drivers/thunderbolt/path.c | 21 +++++++++++++++++++++
 drivers/thunderbolt/test.c | 12 ++++++++++++
 2 files changed, 33 insertions(+)

diff --git a/drivers/thunderbolt/path.c b/drivers/thunderbolt/path.c
index b2c322e76b8a..02c5e7a2101e 100644
--- a/drivers/thunderbolt/path.c
+++ b/drivers/thunderbolt/path.c
@@ -196,6 +196,12 @@ struct tb_path *tb_path_discover(struct tb_port *src, int src_hopid,
 		path->hops[i].out_port = out_port;
 		path->hops[i].next_hop_index = next_hop;
 
+		/* Keep the ports alive, see tb_path_free() */
+		if (alloc_hopid) {
+			tb_switch_get(path->hops[i].in_port->sw);
+			tb_switch_get(path->hops[i].out_port->sw);
+		}
+
 		tb_dump_hop(&path->hops[i], &hop);
 
 		h = next_hop;
@@ -323,6 +329,10 @@ struct tb_path *tb_path_alloc(struct tb *tb, struct tb_port *src, int src_hopid,
 		path->hops[i].out_port = out_port;
 		path->hops[i].next_hop_index = out_hopid;
 
+		/* Keep the ports alive, see tb_path_free() */
+		tb_switch_get(path->hops[i].in_port->sw);
+		tb_switch_get(path->hops[i].out_port->sw);
+
 		in_hopid = out_hopid;
 	}
 
@@ -356,6 +366,17 @@ void tb_path_free(struct tb_path *path)
 			if (hop->out_port)
 				tb_port_release_out_hopid(hop->out_port,
 							  hop->next_hop_index);
+			/*
+			 * Only drop the switch references after both HopIDs
+			 * have been released: the path may be freed after the
+			 * switch was already removed (e.g. asynchronous DP
+			 * tunnel teardown) and these references are what
+			 * keeps the ports and their HopID IDAs alive.
+			 */
+			if (hop->in_port)
+				tb_switch_put(hop->in_port->sw);
+			if (hop->out_port)
+				tb_switch_put(hop->out_port->sw);
 		}
 	}
 
diff --git a/drivers/thunderbolt/test.c b/drivers/thunderbolt/test.c
index 05652ee82fbf..034c56845380 100644
--- a/drivers/thunderbolt/test.c
+++ b/drivers/thunderbolt/test.c
@@ -33,6 +33,11 @@ static void kunit_ida_init(struct kunit *test, struct ida *ida)
 	kunit_alloc_resource(test, __ida_init, __ida_destroy, GFP_KERNEL, ida);
 }
 
+static void tb_test_switch_release(struct device *dev)
+{
+	/* The memory is owned by KUnit, nothing to do here */
+}
+
 static struct tb_switch *alloc_switch(struct kunit *test, u64 route,
 				      u8 upstream_port, u8 max_port_number)
 {
@@ -44,6 +49,13 @@ static struct tb_switch *alloc_switch(struct kunit *test, u64 route,
 	if (!sw)
 		return NULL;
 
+	/*
+	 * The paths take a reference to their switches and those devices
+	 * have to be initialized for that to work.
+	 */
+	sw->dev.release = tb_test_switch_release;
+	device_initialize(&sw->dev);
+
 	sw->config.upstream_port_number = upstream_port;
 	sw->config.depth = tb_route_length(route);
 	sw->config.route_hi = upper_32_bits(route);

-- 
2.55.0

