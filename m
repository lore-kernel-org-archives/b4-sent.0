From: Sven Peter <sven@kernel.org>
Date: Sat, 29 Aug 2026 10:08:33 +0200
Subject: [PATCH v3 1/7] thunderbolt: Hold a router reference for each
 allocated HopID
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260829-b4-tbt-fixes-v3-1-e1fab6ac54fe@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=4048; i=sven@kernel.org;
 h=from:subject:message-id; bh=MOWklr/9/zxO0RK1ptJ7O/V6sWasLOgUeySDBc1yB98=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ9akyd3veqeH3Ww13ZVas2f1JYF0IeVnP8WTD99SyNldm
 3B+mr5ERykLgxgXg6yYIsv2/famTx6+EVy66dJ7mDmsTCBDGLg4BWAixk8YGdqYBJiehU2ax+K+
 d7qakdb72ZI7/DgWTc6VbrAN5ZTeOZuRodPU8sEf//Ot3qWKKZUSAbekDz2Pfv7pQ/V8I79qfvH
 d7AA=
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
never finish right now and because the unplug powers down the entire
USB4 complex and removes the NHI device.

Take a router reference whenever an input or output HopID is allocated
and drop it again after the HopID is released. This keeps the ports and
their HopID IDAs alive for as long as they are used.

The KUnit tests allocate routers without ever registering their devices
so initialize the embedded struct device there as well and drop its
initial reference when the test is finished.

Fixes: d6d458d42e1e ("thunderbolt: Handle DisplayPort tunnel activation asynchronously")
Cc: stable@vger.kernel.org
Signed-off-by: Sven Peter <sven@kernel.org>
---
 drivers/thunderbolt/switch.c |  9 ++++++++-
 drivers/thunderbolt/test.c   | 21 +++++++++++++++++++++
 2 files changed, 29 insertions(+), 1 deletion(-)

diff --git a/drivers/thunderbolt/switch.c b/drivers/thunderbolt/switch.c
index a830c82bb905..217e18f8a7c7 100644
--- a/drivers/thunderbolt/switch.c
+++ b/drivers/thunderbolt/switch.c
@@ -765,6 +765,7 @@ static int tb_port_alloc_hopid(struct tb_port *port, bool in, int min_hopid,
 {
 	int port_max_hopid;
 	struct ida *ida;
+	int ret;
 
 	if (in) {
 		port_max_hopid = port->config.max_in_hop_id;
@@ -784,7 +785,11 @@ static int tb_port_alloc_hopid(struct tb_port *port, bool in, int min_hopid,
 	if (max_hopid < 0 || max_hopid > port_max_hopid)
 		max_hopid = port_max_hopid;
 
-	return ida_alloc_range(ida, min_hopid, max_hopid, GFP_KERNEL);
+	ret = ida_alloc_range(ida, min_hopid, max_hopid, GFP_KERNEL);
+	if (ret >= 0)
+		tb_switch_get(port->sw);
+
+	return ret;
 }
 
 /**
@@ -823,6 +828,7 @@ int tb_port_alloc_out_hopid(struct tb_port *port, int min_hopid, int max_hopid)
 void tb_port_release_in_hopid(struct tb_port *port, int hopid)
 {
 	ida_free(&port->in_hopids, hopid);
+	tb_switch_put(port->sw);
 }
 
 /**
@@ -833,6 +839,7 @@ void tb_port_release_in_hopid(struct tb_port *port, int hopid)
 void tb_port_release_out_hopid(struct tb_port *port, int hopid)
 {
 	ida_free(&port->out_hopids, hopid);
+	tb_switch_put(port->sw);
 }
 
 static inline bool tb_switch_is_reachable(const struct tb_switch *parent,
diff --git a/drivers/thunderbolt/test.c b/drivers/thunderbolt/test.c
index 05652ee82fbf..799ada97cbc9 100644
--- a/drivers/thunderbolt/test.c
+++ b/drivers/thunderbolt/test.c
@@ -33,6 +33,18 @@ static void kunit_ida_init(struct kunit *test, struct ida *ida)
 	kunit_alloc_resource(test, __ida_init, __ida_destroy, GFP_KERNEL, ida);
 }
 
+static void tb_test_switch_release(struct device *dev)
+{
+	/* The memory is owned by KUnit, nothing to do here */
+}
+
+static void tb_test_switch_put(void *data)
+{
+	struct tb_switch *sw = data;
+
+	put_device(&sw->dev);
+}
+
 static struct tb_switch *alloc_switch(struct kunit *test, u64 route,
 				      u8 upstream_port, u8 max_port_number)
 {
@@ -44,6 +56,15 @@ static struct tb_switch *alloc_switch(struct kunit *test, u64 route,
 	if (!sw)
 		return NULL;
 
+	/*
+	 * HopID allocations take a reference to their routers and those devices
+	 * have to be initialized for that to work.
+	 */
+	sw->dev.release = tb_test_switch_release;
+	device_initialize(&sw->dev);
+	if (kunit_add_action_or_reset(test, tb_test_switch_put, sw))
+		return NULL;
+
 	sw->config.upstream_port_number = upstream_port;
 	sw->config.depth = tb_route_length(route);
 	sw->config.route_hi = upper_32_bits(route);

-- 
2.55.0

