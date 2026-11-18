From: =?utf-8?q?Eren_=C3=96zen?= <erenozen@protonmail.com>
Date: Wed, 18 Nov 2026 15:10:54 +0300
Subject: [PATCH v2 3/3] drm/amd/display: Test connector init with FRL
 status polling pending
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261118-frl-polling-wq-teardown-v2-3-957e61c0b698@protonmail.com>
References: <20261118-frl-polling-wq-teardown-v2-0-957e61c0b698@protonmail.com>
In-Reply-To: <20261118-frl-polling-wq-teardown-v2-0-957e61c0b698@protonmail.com>
To: Harry Wentland <harry.wentland@amd.com>, Leo Li <sunpeng.li@amd.com>, 
 Rodrigo Siqueira <siqueira@igalia.com>, 
 Alex Deucher <alexander.deucher@amd.com>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Fangzhi Zuo <Jerry.Zuo@amd.com>, Chenyu Chen <chen-yu.chen@amd.com>, 
 Bhawanpreet Lakha <bhawanpreet.lakha@amd.com>, 
 Alex Hung <alex.hung@amd.com>
Cc: Wayne Lin <Wayne.Lin@amd.com>, 
 =?utf-8?q?Timur_Krist=C3=B3f?= <timur.kristof@gmail.com>, 
 amd-gfx@lists.freedesktop.org, dri-devel@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?Eren_=C3=96zen?= <erenozen@protonmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795003852; l=3475;
 i=erenozen@protonmail.com; s=20261110; h=from:subject:message-id;
 bh=kRz6sTM7utoa2NOF2uowuuqvgRr6QvFl4fMYSUZAY+Q=;
 b=TeJT27I2ea5k85PobNZ37mhldRdA5V1rvCsBKLnEAgFInpHi3UPjfMWbmWnkAApYSEOFngEVy
 Sy8cr0kwv9MA7wM5GeQCqnAZ5+REtkxAdPKVwaL/XRU3tP11a/Pac75
X-Developer-Key: i=erenozen@protonmail.com; a=ed25519;
 pk=tPAwfVmIbYF3QziJ3LcoTIZDU12BsjVK+EkAB9nN1gA=
X-Endpoint-Received: by B4 Relay for erenozen@protonmail.com/20261110 with auth_id=1479
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a KUnit test for the problem fixed by "drm/amd/display: Initialize
FRL status polling work once at DM init". When an MST branch device is
plugged in, amdgpu_dm_connector_init_helper() runs for each new
connector while the display manager's FRL status polling work may be
pending, and it must not re-initialize that work.

The test queues the work with a long delay, runs the helper for a
DisplayPort connector below an MST root, and checks that the work and
its timer are still pending and that the polling delay is unchanged.

Without that fix the test fails: the helper re-initializes the work,
which drops its pending bit and its timer while the timer is still
queued, and with CONFIG_DEBUG_OBJECTS_TIMERS the kernel reports
"ODEBUG: init active ... object type: timer_list".

Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Eren Özen <erenozen@protonmail.com>
---
 .../amdgpu_dm/tests/amdgpu_dm_connector_test.c     | 34 ++++++++++++++++++++++
 1 file changed, 34 insertions(+)

diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_connector_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_connector_test.c
index 33082a674d9e..bac147717e41 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_connector_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_connector_test.c
@@ -9624,6 +9624,39 @@ static void dm_test_init_helper_hpd_debounce_disabled(struct kunit *test)
 	KUNIT_EXPECT_EQ(test, ctx->aconnector->hdmi_hpd_debounce_delay_ms, 0);
 }
 
+/**
+ * dm_test_init_helper_keeps_pending_frl_poll - Test a new connector leaves FRL polling alone
+ * @test: The KUnit test context
+ *
+ * The FRL status polling work belongs to the display manager and may be
+ * pending when an MST branch device is plugged in and a new connector is set
+ * up at runtime. Setting up that connector must not re-initialize the pending
+ * work or change its polling delay.
+ */
+static void dm_test_init_helper_keeps_pending_frl_poll(struct kunit *test)
+{
+	struct dm_test_init_helper_ctx *ctx =
+		dm_test_init_helper_ctx_alloc(test, DRM_MODE_CONNECTOR_DisplayPort);
+	struct delayed_work *dwork = &ctx->dm->hdmi_frl_status_polling_work;
+
+	INIT_DELAYED_WORK(dwork, hdmi_frl_status_polling_work);
+	ctx->dm->hdmi_frl_status_polling_delay_ms = 100000;
+	ctx->aconnector->mst_root = ctx->aconnector;
+
+	/* Long delay: the work must stay pending and never run in this test. */
+	KUNIT_ASSERT_TRUE(test, queue_delayed_work(system_wq, dwork,
+						   msecs_to_jiffies(100000)));
+
+	amdgpu_dm_connector_init_helper(ctx->dm, ctx->aconnector,
+					DRM_MODE_CONNECTOR_DisplayPort, ctx->link, 0);
+
+	KUNIT_EXPECT_TRUE(test, delayed_work_pending(dwork));
+	KUNIT_EXPECT_TRUE(test, timer_pending(&dwork->timer));
+	KUNIT_EXPECT_EQ(test, ctx->dm->hdmi_frl_status_polling_delay_ms, 100000);
+
+	KUNIT_EXPECT_TRUE(test, cancel_delayed_work_sync(dwork));
+}
+
 /* Tests for amdgpu_dm_initialize_hdmi_connector() */
 
 /**
@@ -10803,6 +10836,7 @@ static struct kunit_case amdgpu_dm_connector_tests[] = {
 	KUNIT_CASE(dm_test_init_helper_edp),
 	KUNIT_CASE(dm_test_init_helper_hdcp_property),
 	KUNIT_CASE(dm_test_init_helper_hpd_debounce_disabled),
+	KUNIT_CASE(dm_test_init_helper_keeps_pending_frl_poll),
 	/* amdgpu_dm_initialize_hdmi_connector */
 	KUNIT_CASE(dm_test_initialize_hdmi_cec_registers),
 	/* amdgpu_dm_update_freesync_caps */

-- 
2.56.0

