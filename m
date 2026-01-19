From: Yang Xiwen <forbidden405@outlook.com>
Date: Tue, 20 Jan 2026 03:07:19 +0800
Subject: [PATCH v3 2/6] test: dm: core: add some assertions for
 device_reparent()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260120-clk-reparent-v3-2-0d43d4b362ac@outlook.com>
References: <20260120-clk-reparent-v3-0-0d43d4b362ac@outlook.com>
In-Reply-To: <20260120-clk-reparent-v3-0-0d43d4b362ac@outlook.com>
To: Simon Glass <sjg@chromium.org>, Tom Rini <trini@konsulko.com>, 
 Lukasz Majewski <lukma@denx.de>, Sean Anderson <seanga2@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768849639; l=2626;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=2QXGW9r8Q5sFBpTKm5IaUyJL35Ll9DB0wc/4vC8AZBI=;
 b=R20p0k0sHLRNpY223m62Rxdm5rctGrflPBLiuzJg79/1btGS/PL91PPmGqjK74q3awWOI11Rh
 52EMgZPgZk5BcvHBo7x4CV3OfkkcIDnzRRCEc6BvKYjBUu6B6znj5kD
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The original tests only assert the return value of device_reparent(),
but does not check the actual relation between the new parent and the
child. Add some assertions to check this behavior.

It also lacks the logic to test orphan/root devices. Add tests for that.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 test/dm/core.c | 34 ++++++++++++++++++++++++++++++++--
 1 file changed, 32 insertions(+), 2 deletions(-)

diff --git a/test/dm/core.c b/test/dm/core.c
index 53693f4f7ed7..ae9415c89563 100644
--- a/test/dm/core.c
+++ b/test/dm/core.c
@@ -696,9 +696,10 @@ DM_TEST(dm_test_children, 0);
 static int dm_test_device_reparent(struct unit_test_state *uts)
 {
 	struct udevice *top[NODE_COUNT];
-	struct udevice *child[NODE_COUNT];
+	struct udevice *child[NODE_COUNT], *temp_child = NULL;
 	struct udevice *grandchild[NODE_COUNT];
 	struct udevice *dev;
+	struct udevice *orphan;
 	int total;
 	int ret;
 	int i;
@@ -720,8 +721,11 @@ static int dm_test_device_reparent(struct unit_test_state *uts)
 		ut_assertok(create_children(uts, child[i], NODE_COUNT, 50 * i,
 					    i == 2 ? grandchild : NULL));
 
+	/* Create an orphan device */
+	ut_assertok(create_children(uts, NULL, 1, 49, &orphan));
+
 	/* Check total number of devices */
-	total = NODE_COUNT * (3 + NODE_COUNT);
+	total = NODE_COUNT * (3 + NODE_COUNT) + 1;
 	ut_asserteq(total, dm_testdrv_op_count[DM_TEST_OP_BIND]);
 
 	/* Probe everything */
@@ -738,6 +742,14 @@ static int dm_test_device_reparent(struct unit_test_state *uts)
 
 	ut_assertok(device_reparent(top[4], top[0]));
 
+	/* Ensure it's reparented */
+	ut_asserteq_ptr(top[4]->parent, top[0]);
+	device_foreach_child(temp_child, top[0]) {
+		if (temp_child == top[4])
+			break;
+	}
+	ut_asserteq_ptr(temp_child, top[4]);
+
 	/* try to get devices */
 	ret = uclass_find_first_device(UCLASS_TEST, &dev);
 	ut_assert(!ret);
@@ -773,6 +785,24 @@ static int dm_test_device_reparent(struct unit_test_state *uts)
 	ut_assert(!ret);
 	ut_assertnonnull(dev);
 
+	/* Re-parent orphant device */
+	ut_assertok(device_reparent(orphan, top[0]));
+
+	/* try to get the device */
+	ret = uclass_find_first_device(UCLASS_TEST, &dev);
+	ut_assert(!ret);
+	ut_assertnonnull(dev);
+
+	/* ensure it's reparented */
+	ut_asserteq_ptr(orphan->parent, top[0]);
+
+	temp_child = NULL;
+	device_foreach_child(temp_child, top[0]) {
+		if (temp_child == orphan)
+			break;
+	}
+	ut_asserteq_ptr(temp_child, orphan);
+
 	/* Remove re-pareneted devices. */
 	ut_assertok(device_remove(top[3], DM_REMOVE_NORMAL));
 

-- 
2.43.0

