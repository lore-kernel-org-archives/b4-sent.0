From: Sidharth Saha <ssaha2000@gmail.com>
Date: Mon, 16 Nov 2026 18:21:33 -0700
Subject: [PATCH 2/5] drm/vkms: Add KUnit test for BGR565 writeback
 conversion
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-rgb565-test-v1-2-27f49c1aa694@gmail.com>
References: <20261116-rgb565-test-v1-0-27f49c1aa694@gmail.com>
In-Reply-To: <20261116-rgb565-test-v1-0-27f49c1aa694@gmail.com>
To: Louis Chauvet <louis.chauvet@bootlin.com>, 
 Haneen Mohammed <hamohammed.sa@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Melissa Wen <melissa.srw@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Sidharth Saha <40047656+Sidharth-Saha@users.noreply.github.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794878495; l=3359;
 i=ssaha2000@gmail.com; s=20261116; h=from:subject:message-id;
 bh=ApQ0qFyySZKS61HvfyzyTc22Ok4qXCkPkweSnnzwWLQ=;
 b=rFZn7J1E2fICdkDrUX/l0Yga74w+TpX6b2Vdxbt2OAZKrgpeMNbj3+s0DzXIwf3tXzxxRIGH5
 7j35k1Klxp0CA5/NS69KmsWLTXGYJ7x26IupXwwzv/W10mifPb59hQQ
X-Developer-Key: i=ssaha2000@gmail.com; a=ed25519;
 pk=wMWW9xOklVZkO7Yh4yIXvhVVRs/3ROsqgjTt8XBGybI=
X-Endpoint-Received: by B4 Relay for ssaha2000@gmail.com/20261116 with auth_id=1541
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Reuse the RGB565 writeback cases to test argb_u16_to_BGR565(), which
packs the same 5/6/5-bit channels with red and blue swapped. The
distinct-channel case checks that red and blue land in the right bits.

Make argb_u16_to_BGR565() visible to KUnit so the test can call it.

Signed-off-by: Sidharth Saha <40047656+Sidharth-Saha@users.noreply.github.com>
---
 drivers/gpu/drm/vkms/tests/vkms_format_test.c | 15 +++++++++++++++
 drivers/gpu/drm/vkms/vkms_formats.c           |  3 ++-
 drivers/gpu/drm/vkms/vkms_formats.h           |  1 +
 3 files changed, 18 insertions(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/vkms/tests/vkms_format_test.c b/drivers/gpu/drm/vkms/tests/vkms_format_test.c
index a8ef93b9c806..e7836664c788 100644
--- a/drivers/gpu/drm/vkms/tests/vkms_format_test.c
+++ b/drivers/gpu/drm/vkms/tests/vkms_format_test.c
@@ -301,9 +301,24 @@ static void vkms_format_test_argb_u16_to_RGB565(struct kunit *test)
 	KUNIT_EXPECT_EQ(test, v & 0x1f, c->b);
 }
 
+static void vkms_format_test_argb_u16_to_BGR565(struct kunit *test)
+{
+	const struct rgb565_case *c = test->param_value;
+	__le16 out;
+	u16 v;
+
+	argb_u16_to_BGR565((u8 *)&out, &c->in);
+	v = le16_to_cpu(out);
+
+	KUNIT_EXPECT_EQ(test, v & 0x1f, c->r);		/* red: low bits */
+	KUNIT_EXPECT_EQ(test, (v >> 5) & 0x3f, c->g);
+	KUNIT_EXPECT_EQ(test, (v >> 11) & 0x1f, c->b);	/* blue: high bits */
+}
+
 static struct kunit_case vkms_format_test_cases[] = {
 	KUNIT_CASE_PARAM(vkms_format_test_yuv_u16_to_argb_u16, yuv_u16_to_argb_u16_gen_params),
 	KUNIT_CASE_PARAM(vkms_format_test_argb_u16_to_RGB565, rgb565_gen_params),
+	KUNIT_CASE_PARAM(vkms_format_test_argb_u16_to_BGR565, rgb565_gen_params),
 };
 
 static struct kunit_suite vkms_format_test_suite = {
diff --git a/drivers/gpu/drm/vkms/vkms_formats.c b/drivers/gpu/drm/vkms/vkms_formats.c
index c5ee2d6a920f..7950751c4890 100644
--- a/drivers/gpu/drm/vkms/vkms_formats.c
+++ b/drivers/gpu/drm/vkms/vkms_formats.c
@@ -696,7 +696,7 @@ VISIBLE_IF_KUNIT void argb_u16_to_RGB565(u8 *out_pixel, const struct pixel_argb_
 }
 EXPORT_SYMBOL_IF_KUNIT(argb_u16_to_RGB565);
 
-static void argb_u16_to_BGR565(u8 *out_pixel, const struct pixel_argb_u16 *in_pixel)
+VISIBLE_IF_KUNIT void argb_u16_to_BGR565(u8 *out_pixel, const struct pixel_argb_u16 *in_pixel)
 {
 	__le16 *pixel = (__le16 *)out_pixel;
 	u16 r, g, b;
@@ -705,6 +705,7 @@ static void argb_u16_to_BGR565(u8 *out_pixel, const struct pixel_argb_u16 *in_pi
 
 	*pixel = cpu_to_le16(b << 11 | g << 5 | r);
 }
+EXPORT_SYMBOL_IF_KUNIT(argb_u16_to_BGR565);
 
 static void argb_u16_to_RGB332(u8 *out_pixel, const struct pixel_argb_u16 *in_pixel)
 {
diff --git a/drivers/gpu/drm/vkms/vkms_formats.h b/drivers/gpu/drm/vkms/vkms_formats.h
index 2b8a1c4a5d46..135bb60a554b 100644
--- a/drivers/gpu/drm/vkms/vkms_formats.h
+++ b/drivers/gpu/drm/vkms/vkms_formats.h
@@ -17,6 +17,7 @@ void get_conversion_matrix_to_argb_u16(u32 format, enum drm_color_encoding encod
 struct pixel_argb_u16 argb_u16_from_yuv161616(const struct conversion_matrix *matrix,
 					      u16 y, u16 channel_1, u16 channel_2);
 void argb_u16_to_RGB565(u8 *out_pixel, const struct pixel_argb_u16 *in_pixel);
+void argb_u16_to_BGR565(u8 *out_pixel, const struct pixel_argb_u16 *in_pixel);
 #endif
 
 #endif /* _VKMS_FORMATS_H_ */

-- 
2.53.0

