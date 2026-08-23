From: Sven Peter <sven@kernel.org>
Date: Sun, 23 Aug 2026 18:09:20 +0200
Subject: [PATCH v2 7/7] thunderbolt: Drop the DP tunnel activation callback
 data
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260823-b4-tbt-fixes-v2-7-26a18a426c9f@kernel.org>
References: <20260823-b4-tbt-fixes-v2-0-26a18a426c9f@kernel.org>
In-Reply-To: <20260823-b4-tbt-fixes-v2-0-26a18a426c9f@kernel.org>
To: Andreas Noever <andreas.noever@gmail.com>, 
 Mika Westerberg <westeri@kernel.org>, 
 Yehezkel Bernat <YehezkelShB@gmail.com>
Cc: Mika Westerberg <mika.westerberg@linux.intel.com>, 
 Konrad Dybcio <konradybcio@kernel.org>, asahi@lists.linux.dev, 
 linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sven Peter <sven@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=11508; i=sven@kernel.org;
 h=from:subject:message-id; bh=4/gZflZqyfX3VI0ASxHBldunkbN3iGh6yKI7giShHRE=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ1a3dMrbozeLWpMy+gI43ogs7LNWXTVv1ysr7TM6pst+L
 G3d6p3TUcrCIMbFICumyLJ9v73pk4dvBJduuvQeZg4rE8gQBi5OAZjI0jMMv5imV7nse7OVt3Su
 5uY7HBNPhrv03spZUV0z/+ZVd+bn57wY/he8czLNmnBgh1xxy4HGUsv3gZtvZmhXnxZ5cXXHy2+
 3nnEAAA==
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The callback data is always the domain the tunnel belongs to which the
callback can just take from the tunnel itself.

Signed-off-by: Sven Peter <sven@kernel.org>
---
 drivers/thunderbolt/tb.c     | 10 +++++-----
 drivers/thunderbolt/test.c   | 24 ++++++++++++------------
 drivers/thunderbolt/tunnel.c | 12 +++---------
 drivers/thunderbolt/tunnel.h | 10 +++-------
 4 files changed, 23 insertions(+), 33 deletions(-)

diff --git a/drivers/thunderbolt/tb.c b/drivers/thunderbolt/tb.c
index 921adba3544f..40a5a3ebb31d 100644
--- a/drivers/thunderbolt/tb.c
+++ b/drivers/thunderbolt/tb.c
@@ -89,7 +89,7 @@ static void tb_dp_resource_unavailable(struct tb *tb, struct tb_port *port,
 				       const char *reason);
 static void tb_queue_dp_bandwidth_request(struct tb *tb, u64 route, u8 port,
 					  int retry, unsigned long delay);
-static void tb_dp_tunnel_active(struct tb_tunnel *tunnel, void *data);
+static void tb_dp_tunnel_active(struct tb_tunnel *tunnel);
 
 static void tb_queue_hotplug(struct tb *tb, u64 route, u8 port, bool unplug)
 {
@@ -387,7 +387,7 @@ static void tb_switch_discover_tunnels(struct tb_switch *sw,
 		switch (port->config.type) {
 		case TB_TYPE_DP_HDMI_IN:
 			tunnel = tb_tunnel_discover_dp(tb, port, alloc_hopids,
-						       tb_dp_tunnel_active, tb);
+						       tb_dp_tunnel_active);
 			tb_increase_tmu_accuracy(tunnel);
 			break;
 
@@ -1905,11 +1905,11 @@ static struct tb_port *tb_find_dp_out(struct tb *tb, struct tb_port *in)
 	return NULL;
 }
 
-static void tb_dp_tunnel_active(struct tb_tunnel *tunnel, void *data)
+static void tb_dp_tunnel_active(struct tb_tunnel *tunnel)
 {
 	struct tb_port *in = tunnel->src_port;
 	struct tb_port *out = tunnel->dst_port;
-	struct tb *tb = data;
+	struct tb *tb = tunnel->tb;
 
 	mutex_lock(&tb->lock);
 
@@ -2038,7 +2038,7 @@ static void tb_tunnel_one_dp(struct tb *tb, struct tb_port *in,
 	       available_up, available_down);
 
 	tunnel = tb_tunnel_alloc_dp(tb, in, out, link_nr, available_up,
-				    available_down, tb_dp_tunnel_active, tb);
+				    available_down, tb_dp_tunnel_active);
 	if (!tunnel) {
 		tb_port_dbg(out, "could not allocate DP tunnel\n");
 		goto err_reclaim_usb;
diff --git a/drivers/thunderbolt/test.c b/drivers/thunderbolt/test.c
index fc3f647bf664..9e128c26f003 100644
--- a/drivers/thunderbolt/test.c
+++ b/drivers/thunderbolt/test.c
@@ -1398,7 +1398,7 @@ static void tb_test_tunnel_pcie(struct kunit *test)
 	tb_tunnel_put(tunnel1);
 }
 
-static void tb_test_dp_tunnel_active(struct tb_tunnel *tunnel, void *data)
+static void tb_test_dp_tunnel_active(struct tb_tunnel *tunnel)
 {
 }
 
@@ -1423,7 +1423,7 @@ static void tb_test_tunnel_dp(struct kunit *test)
 	out = &dev->ports[13];
 
 	tunnel = tb_tunnel_alloc_dp(NULL, in, out, 1, 0, 0,
-				    tb_test_dp_tunnel_active, NULL);
+				    tb_test_dp_tunnel_active);
 	KUNIT_ASSERT_NOT_NULL(test, tunnel);
 	KUNIT_EXPECT_EQ(test, tunnel->type, TB_TUNNEL_DP);
 	KUNIT_EXPECT_PTR_EQ(test, tunnel->src_port, in);
@@ -1470,7 +1470,7 @@ static void tb_test_tunnel_dp_chain(struct kunit *test)
 	out = &dev4->ports[14];
 
 	tunnel = tb_tunnel_alloc_dp(NULL, in, out, 1, 0, 0,
-				    tb_test_dp_tunnel_active, NULL);
+				    tb_test_dp_tunnel_active);
 	KUNIT_ASSERT_NOT_NULL(test, tunnel);
 	KUNIT_EXPECT_EQ(test, tunnel->type, TB_TUNNEL_DP);
 	KUNIT_EXPECT_PTR_EQ(test, tunnel->src_port, in);
@@ -1521,7 +1521,7 @@ static void tb_test_tunnel_dp_tree(struct kunit *test)
 	out = &dev5->ports[13];
 
 	tunnel = tb_tunnel_alloc_dp(NULL, in, out, 1, 0, 0,
-				    tb_test_dp_tunnel_active, NULL);
+				    tb_test_dp_tunnel_active);
 	KUNIT_ASSERT_NOT_NULL(test, tunnel);
 	KUNIT_EXPECT_EQ(test, tunnel->type, TB_TUNNEL_DP);
 	KUNIT_EXPECT_PTR_EQ(test, tunnel->src_port, in);
@@ -1587,7 +1587,7 @@ static void tb_test_tunnel_dp_max_length(struct kunit *test)
 	out = &dev12->ports[13];
 
 	tunnel = tb_tunnel_alloc_dp(NULL, in, out, 1, 0, 0,
-				    tb_test_dp_tunnel_active, NULL);
+				    tb_test_dp_tunnel_active);
 	KUNIT_ASSERT_NOT_NULL(test, tunnel);
 	KUNIT_EXPECT_EQ(test, tunnel->type, TB_TUNNEL_DP);
 	KUNIT_EXPECT_PTR_EQ(test, tunnel->src_port, in);
@@ -1658,7 +1658,7 @@ static void tb_test_tunnel_3dp(struct kunit *test)
 	out3 = &dev4->ports[14];
 
 	tunnel1 = tb_tunnel_alloc_dp(NULL, in1, out1, 1, 0, 0,
-				     tb_test_dp_tunnel_active, NULL);
+				     tb_test_dp_tunnel_active);
 	KUNIT_ASSERT_TRUE(test, tunnel1 != NULL);
 	KUNIT_EXPECT_EQ(test, tunnel1->type, TB_TUNNEL_DP);
 	KUNIT_EXPECT_PTR_EQ(test, tunnel1->src_port, in1);
@@ -1667,7 +1667,7 @@ static void tb_test_tunnel_3dp(struct kunit *test)
 	KUNIT_ASSERT_EQ(test, tunnel1->paths[0]->path_length, 3);
 
 	tunnel2 = tb_tunnel_alloc_dp(NULL, in2, out2, 1, 0, 0,
-				     tb_test_dp_tunnel_active, NULL);
+				     tb_test_dp_tunnel_active);
 	KUNIT_ASSERT_TRUE(test, tunnel2 != NULL);
 	KUNIT_EXPECT_EQ(test, tunnel2->type, TB_TUNNEL_DP);
 	KUNIT_EXPECT_PTR_EQ(test, tunnel2->src_port, in2);
@@ -1676,7 +1676,7 @@ static void tb_test_tunnel_3dp(struct kunit *test)
 	KUNIT_ASSERT_EQ(test, tunnel2->paths[0]->path_length, 4);
 
 	tunnel3 = tb_tunnel_alloc_dp(NULL, in3, out3, 1, 0, 0,
-				     tb_test_dp_tunnel_active, NULL);
+				     tb_test_dp_tunnel_active);
 	KUNIT_ASSERT_TRUE(test, tunnel3 != NULL);
 	KUNIT_EXPECT_EQ(test, tunnel3->type, TB_TUNNEL_DP);
 	KUNIT_EXPECT_PTR_EQ(test, tunnel3->src_port, in3);
@@ -1775,7 +1775,7 @@ static void tb_test_tunnel_port_on_path(struct kunit *test)
 	out = &dev5->ports[13];
 
 	dp_tunnel = tb_tunnel_alloc_dp(NULL, in, out, 1, 0, 0,
-				       tb_test_dp_tunnel_active, NULL);
+				       tb_test_dp_tunnel_active);
 	KUNIT_ASSERT_NOT_NULL(test, dp_tunnel);
 
 	KUNIT_EXPECT_TRUE(test, tb_tunnel_port_on_path(dp_tunnel, in));
@@ -2208,7 +2208,7 @@ static void tb_test_credit_alloc_dp(struct kunit *test)
 	out = &dev->ports[14];
 
 	tunnel = tb_tunnel_alloc_dp(NULL, in, out, 1, 0, 0,
-				    tb_test_dp_tunnel_active, NULL);
+				    tb_test_dp_tunnel_active);
 	KUNIT_ASSERT_NOT_NULL(test, tunnel);
 	KUNIT_ASSERT_EQ(test, tunnel->npaths, (size_t)3);
 
@@ -2445,7 +2445,7 @@ static struct tb_tunnel *TB_TEST_DP_TUNNEL1(struct kunit *test,
 	in = &host->ports[5];
 	out = &dev->ports[13];
 	dp_tunnel1 = tb_tunnel_alloc_dp(NULL, in, out, 1, 0, 0,
-					tb_test_dp_tunnel_active, NULL);
+					tb_test_dp_tunnel_active);
 	KUNIT_ASSERT_NOT_NULL(test, dp_tunnel1);
 	KUNIT_ASSERT_EQ(test, dp_tunnel1->npaths, (size_t)3);
 
@@ -2483,7 +2483,7 @@ static struct tb_tunnel *TB_TEST_DP_TUNNEL2(struct kunit *test,
 	in = &host->ports[6];
 	out = &dev->ports[14];
 	dp_tunnel2 = tb_tunnel_alloc_dp(NULL, in, out, 1, 0, 0,
-					tb_test_dp_tunnel_active, NULL);
+					tb_test_dp_tunnel_active);
 	KUNIT_ASSERT_NOT_NULL(test, dp_tunnel2);
 	KUNIT_ASSERT_EQ(test, dp_tunnel2->npaths, (size_t)3);
 
diff --git a/drivers/thunderbolt/tunnel.c b/drivers/thunderbolt/tunnel.c
index 3785e29cf92b..cbffb1e612b6 100644
--- a/drivers/thunderbolt/tunnel.c
+++ b/drivers/thunderbolt/tunnel.c
@@ -1113,7 +1113,7 @@ static void tb_dp_dprx_work(struct work_struct *work)
 	}
 	mutex_unlock(&tb->lock);
 
-	tunnel->callback(tunnel, tunnel->callback_data);
+	tunnel->callback(tunnel);
 	tb_tunnel_put(tunnel);
 	tb_domain_put(tb);
 }
@@ -1589,7 +1589,6 @@ static void tb_dp_dump(struct tb_tunnel *tunnel)
  * @alloc_hopid: Allocate HopIDs from visited ports
  * @callback: Callback that is called when the DP tunnel is fully
  *	      activated (or there is an error)
- * @callback_data: Data for @callback
  *
  * If @in adapter is active, follows the tunnel to the DP out adapter
  * and back. Returns the discovered tunnel or %NULL if there was no
@@ -1599,8 +1598,7 @@ static void tb_dp_dump(struct tb_tunnel *tunnel)
  */
 struct tb_tunnel *tb_tunnel_discover_dp(struct tb *tb, struct tb_port *in,
 					bool alloc_hopid,
-					void (*callback)(struct tb_tunnel *, void *),
-					void *callback_data)
+					void (*callback)(struct tb_tunnel *))
 {
 	struct tb_tunnel *tunnel;
 	struct tb_port *port;
@@ -1625,7 +1623,6 @@ struct tb_tunnel *tb_tunnel_discover_dp(struct tb *tb, struct tb_port *in,
 	tunnel->consumed_bandwidth = tb_dp_consumed_bandwidth;
 	tunnel->src_port = in;
 	tunnel->callback = callback;
-	tunnel->callback_data = callback_data;
 	INIT_DELAYED_WORK(&tunnel->dprx_work, tb_dp_dprx_work);
 
 	path = tb_path_discover(in, TB_DP_VIDEO_HOPID, NULL, -1,
@@ -1696,7 +1693,6 @@ struct tb_tunnel *tb_tunnel_discover_dp(struct tb *tb, struct tb_port *in,
  *	      %0 if no available bandwidth.
  * @callback: Callback that is called when the DP tunnel is fully
  *	      activated (or there is an error)
- * @callback_data: Data for @callback
  *
  * Allocates a tunnel between @in and @out that is capable of tunneling
  * Display Port traffic. The @callback is called after tb_tunnel_activate()
@@ -1710,8 +1706,7 @@ struct tb_tunnel *tb_tunnel_discover_dp(struct tb *tb, struct tb_port *in,
 struct tb_tunnel *tb_tunnel_alloc_dp(struct tb *tb, struct tb_port *in,
 				     struct tb_port *out, int link_nr,
 				     int max_up, int max_down,
-				     void (*callback)(struct tb_tunnel *, void *),
-				     void *callback_data)
+				     void (*callback)(struct tb_tunnel *))
 {
 	struct tb_tunnel *tunnel;
 	struct tb_path **paths;
@@ -1737,7 +1732,6 @@ struct tb_tunnel *tb_tunnel_alloc_dp(struct tb *tb, struct tb_port *in,
 	tunnel->max_up = max_up;
 	tunnel->max_down = max_down;
 	tunnel->callback = callback;
-	tunnel->callback_data = callback_data;
 	INIT_DELAYED_WORK(&tunnel->dprx_work, tb_dp_dprx_work);
 
 	paths = tunnel->paths;
diff --git a/drivers/thunderbolt/tunnel.h b/drivers/thunderbolt/tunnel.h
index 7d1d255ab5a7..28f49f7e9f56 100644
--- a/drivers/thunderbolt/tunnel.h
+++ b/drivers/thunderbolt/tunnel.h
@@ -67,7 +67,6 @@ enum tb_tunnel_state {
  * @dprx_timeout: If set DPRX capabilities read poll work will timeout after this passes
  * @dprx_work: Worker that is scheduled to poll completion of DPRX capabilities read
  * @callback: Callback called when DP tunnel is fully activated
- * @callback_data: Data for @callback
  * @paths: All paths required by the tunnel
  */
 struct tb_tunnel {
@@ -104,8 +103,7 @@ struct tb_tunnel {
 	bool dprx_canceled;
 	ktime_t dprx_timeout;
 	struct delayed_work dprx_work;
-	void (*callback)(struct tb_tunnel *tunnel, void *data);
-	void *callback_data;
+	void (*callback)(struct tb_tunnel *tunnel);
 
 	struct tb_path *paths[] __counted_by(npaths);
 };
@@ -118,13 +116,11 @@ bool tb_tunnel_reserved_pci(struct tb_port *port, int *reserved_up,
 			    int *reserved_down);
 struct tb_tunnel *tb_tunnel_discover_dp(struct tb *tb, struct tb_port *in,
 					bool alloc_hopid,
-					void (*callback)(struct tb_tunnel *, void *),
-					void *callback_data);
+					void (*callback)(struct tb_tunnel *));
 struct tb_tunnel *tb_tunnel_alloc_dp(struct tb *tb, struct tb_port *in,
 				     struct tb_port *out, int link_nr,
 				     int max_up, int max_down,
-				     void (*callback)(struct tb_tunnel *, void *),
-				     void *callback_data);
+				     void (*callback)(struct tb_tunnel *));
 struct tb_tunnel *tb_tunnel_alloc_dma(struct tb *tb, struct tb_port *nhi,
 				      struct tb_port *dst, int transmit_path,
 				      int transmit_ring, int receive_path,

-- 
2.55.0

