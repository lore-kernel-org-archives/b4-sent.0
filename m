From: Hugo Sales <hugo@hsal.es>
Date: Sat, 14 Nov 2026 23:09:13 +0000
Subject: [PATCH 2/8] drm/amd/display: Don't match FreeSync video modes
 against the last probe
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-amdgpu-modes-four-v1-2-f11e2a6cd407@hsal.es>
References: <20261114-amdgpu-modes-four-v1-0-f11e2a6cd407@hsal.es>
In-Reply-To: <20261114-amdgpu-modes-four-v1-0-f11e2a6cd407@hsal.es>
To: Harry Wentland <harry.wentland@amd.com>, Leo Li <sunpeng.li@amd.com>, 
 Rodrigo Siqueira <siqueira@igalia.com>, 
 Alex Deucher <alexander.deucher@amd.com>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Ray Wu <ray.wu@amd.com>, Fangzhi Zuo <jerry.zuo@amd.com>, 
 Roman Li <roman.li@amd.com>, Alex Hung <alex.hung@amd.com>
Cc: amd-gfx@lists.freedesktop.org, dri-devel@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?Ville_Syrj=C3=A4l=C3=A4?= <ville.syrjala@linux.intel.com>, 
 Aurabindo Pillai <aurabindo.pillai@amd.com>, Hugo Sales <hugo@hsal.es>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=5805; i=hugo@hsal.es;
 h=from:subject:message-id; bh=yWWy7i9YetkE5GAq3UFyqpx2cMMLNJIdP9f/Q6iE3xM=;
 b=owJ4nJvAy8zAJVbLU7f+5A3TBYyn1ZIYsn68kmh5vitWNXVa0wYXy+sLipbJLD3wY1/Ka+GtB
 hoa4TMuldzqKGVhEONikBVTZNG94cnAMnHyzJyi50tg5rAygQxh4OIUgImsmcDI8GfD9LYvPRcq
 jF1PM73ber72xwUPlpLF3cpRIX+/liU1MzD8L5K4ImfN0HD0/LmPK89MsTRSElZ1W5ClxhHWWsx
 0b/E5DgChSkyL
X-Developer-Key: i=hugo@hsal.es; a=openpgp;
 fpr=193D095149CF7E8737B39064D912B0DB205A91C1
X-Endpoint-Received: by B4 Relay for hugo@hsal.es/default with auth_id=1417
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

add_fs_modes() runs in ->get_modes() and skips a FreeSync video mode
that is_duplicate_mode() finds. Since commit 828cfa384e23
("drm/amd/display: Fix unadvertised mode detection"),
is_duplicate_mode() also searches connector->modes, which during a
re-probe still lists the previous probe's modes. add_fs_modes() then
takes every FreeSync video mode for a duplicate and adds none, and the
probe helper prunes the old ones as stale. With amdgpu.freesync_video=1,
the FreeSync video modes disappear on every second probe

The connector->modes search was for the unadvertised mode check, which
is gone, so search only probed_modes again

Fixes: 828cfa384e23 ("drm/amd/display: Fix unadvertised mode detection")
Signed-off-by: Hugo Sales <hugo@hsal.es>
---
 .../amd/display/amdgpu_dm/amdgpu_dm_connector.c    |  5 -----
 .../amdgpu_dm/tests/amdgpu_dm_connector_test.c     | 26 +++++++++++-----------
 2 files changed, 13 insertions(+), 18 deletions(-)

diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.c b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.c
index 89f8427433af0..da2ee6179cb67 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm_connector.c
@@ -1409,11 +1409,6 @@ STATIC_IFN_KUNIT bool is_duplicate_mode(struct amdgpu_dm_connector *aconnector,
 			return true;
 	}
 
-	list_for_each_entry(m, &aconnector->base.modes, head) {
-		if (drm_mode_equal(m, mode))
-			return true;
-	}
-
 	return false;
 }
 
diff --git a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_connector_test.c b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_connector_test.c
index addc407841a2a..5af111698e355 100644
--- a/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_connector_test.c
+++ b/drivers/gpu/drm/amd/display/amdgpu_dm/tests/amdgpu_dm_connector_test.c
@@ -1136,7 +1136,6 @@ static void dm_test_is_duplicate_mode_empty_list(struct kunit *test)
 	aconnector = kunit_kzalloc(test, sizeof(*aconnector), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, aconnector);
 
-	INIT_LIST_HEAD(&aconnector->base.modes);
 	INIT_LIST_HEAD(&aconnector->base.probed_modes);
 	mode.hdisplay = 1920;
 	mode.vdisplay = 1080;
@@ -1157,12 +1156,11 @@ static void dm_test_is_duplicate_mode_match(struct kunit *test)
 	aconnector = kunit_kzalloc(test, sizeof(*aconnector), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, aconnector);
 
-	INIT_LIST_HEAD(&aconnector->base.modes);
 	INIT_LIST_HEAD(&aconnector->base.probed_modes);
 	existing.hdisplay = 1920;
 	existing.vdisplay = 1080;
 	existing.clock = 148500;
-	list_add_tail(&existing.head, &aconnector->base.modes);
+	list_add_tail(&existing.head, &aconnector->base.probed_modes);
 
 	candidate.hdisplay = 1920;
 	candidate.vdisplay = 1080;
@@ -1172,10 +1170,14 @@ static void dm_test_is_duplicate_mode_match(struct kunit *test)
 }
 
 /**
- * dm_test_is_duplicate_mode_probed_match - Test probed mode duplicate match
+ * dm_test_is_duplicate_mode_previous_probe - Test modes of the previous probe don't count
  * @test: The KUnit test context
+ *
+ * During a re-probe, base.modes still holds the previous probe's modes. A
+ * mode listed only there is not a duplicate, so add_fs_modes() builds the
+ * FreeSync video modes again on every probe
  */
-static void dm_test_is_duplicate_mode_probed_match(struct kunit *test)
+static void dm_test_is_duplicate_mode_previous_probe(struct kunit *test)
 {
 	struct amdgpu_dm_connector *aconnector;
 	struct drm_display_mode existing = {};
@@ -1189,13 +1191,13 @@ static void dm_test_is_duplicate_mode_probed_match(struct kunit *test)
 	existing.hdisplay = 1920;
 	existing.vdisplay = 1080;
 	existing.clock = 148500;
-	list_add_tail(&existing.head, &aconnector->base.probed_modes);
+	list_add_tail(&existing.head, &aconnector->base.modes);
 
 	candidate.hdisplay = 1920;
 	candidate.vdisplay = 1080;
 	candidate.clock = 148500;
 
-	KUNIT_EXPECT_TRUE(test, is_duplicate_mode(aconnector, &candidate));
+	KUNIT_EXPECT_FALSE(test, is_duplicate_mode(aconnector, &candidate));
 }
 
 /**
@@ -1212,11 +1214,10 @@ static void dm_test_is_duplicate_mode_no_match(struct kunit *test)
 	KUNIT_ASSERT_NOT_NULL(test, aconnector);
 
 	INIT_LIST_HEAD(&aconnector->base.probed_modes);
-	INIT_LIST_HEAD(&aconnector->base.modes);
 	existing.hdisplay = 1920;
 	existing.vdisplay = 1080;
 	existing.clock = 148500;
-	list_add_tail(&existing.head, &aconnector->base.modes);
+	list_add_tail(&existing.head, &aconnector->base.probed_modes);
 
 	candidate.hdisplay = 2560;
 	candidate.vdisplay = 1440;
@@ -1238,13 +1239,12 @@ static void dm_test_is_duplicate_mode_same_size_different_clock(struct kunit *te
 
 	aconnector = kunit_kzalloc(test, sizeof(*aconnector), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_NULL(test, aconnector);
-	INIT_LIST_HEAD(&aconnector->base.probed_modes);
 
-	INIT_LIST_HEAD(&aconnector->base.modes);
+	INIT_LIST_HEAD(&aconnector->base.probed_modes);
 	existing.hdisplay = 1920;
 	existing.vdisplay = 1080;
 	existing.clock = 148500;
-	list_add_tail(&existing.head, &aconnector->base.modes);
+	list_add_tail(&existing.head, &aconnector->base.probed_modes);
 
 	candidate.hdisplay = 1920;
 	candidate.vdisplay = 1080;
@@ -10402,7 +10402,7 @@ static struct kunit_case amdgpu_dm_connector_tests[] = {
 	/* is_duplicate_mode */
 	KUNIT_CASE(dm_test_is_duplicate_mode_empty_list),
 	KUNIT_CASE(dm_test_is_duplicate_mode_match),
-	KUNIT_CASE(dm_test_is_duplicate_mode_probed_match),
+	KUNIT_CASE(dm_test_is_duplicate_mode_previous_probe),
 	KUNIT_CASE(dm_test_is_duplicate_mode_no_match),
 	KUNIT_CASE(dm_test_is_duplicate_mode_same_size_different_clock),
 	/* amdgpu_dm_get_encoder_crtc_mask */

-- 
2.56.0

