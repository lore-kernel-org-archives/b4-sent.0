From: Sidharth Saha <ssaha2000@gmail.com>
Date: Mon, 16 Nov 2026 18:21:36 -0700
Subject: [PATCH 5/5] drm/vkms: Add KUnit tests for RGB565 and BGR565 read
 conversion
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-rgb565-test-v1-5-27f49c1aa694@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794878495; l=5464;
 i=ssaha2000@gmail.com; s=20261116; h=from:subject:message-id;
 bh=nLg0GXM40ZvS+lymhOWLgN3H/hzyxZ7QxDXgGA4ujHc=;
 b=/4S5BZwIsgS2oSg3ck2MdmiOR19T3JEAqT6p98NwjsAoq/vW/48NOWTQ93chkoGl4w55apn7U
 5/ZsOnFykvABnbTvFN3iALHhV3e8Zf0KbFJbTcFHrDjhAoxy0bPQyPg
X-Developer-Key: i=ssaha2000@gmail.com; a=ed25519;
 pk=wMWW9xOklVZkO7Yh4yIXvhVVRs/3ROsqgjTt8XBGybI=
X-Endpoint-Received: by B4 Relay for ssaha2000@gmail.com/20261116 with auth_id=1541
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

argb_u16_from_RGB565() and argb_u16_from_BGR565() were converted to the
new channels_to_argb_u16() helper. Test them against hand-computed
values; the tests pass both before and after that conversion, showing
it didn't change behavior.

Make both functions visible to KUnit so the tests can call them.

Signed-off-by: Sidharth Saha <40047656+Sidharth-Saha@users.noreply.github.com>
---
 drivers/gpu/drm/vkms/tests/vkms_format_test.c | 51 +++++++++++++++++++++++++++
 drivers/gpu/drm/vkms/vkms_formats.c           |  6 ++--
 drivers/gpu/drm/vkms/vkms_formats.h           |  2 ++
 3 files changed, 57 insertions(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/vkms/tests/vkms_format_test.c b/drivers/gpu/drm/vkms/tests/vkms_format_test.c
index 0683a74fc623..841f2c840ed8 100644
--- a/drivers/gpu/drm/vkms/tests/vkms_format_test.c
+++ b/drivers/gpu/drm/vkms/tests/vkms_format_test.c
@@ -411,6 +411,54 @@ static void vkms_format_test_argb_u16_to_BGR233(struct kunit *test)
 	KUNIT_EXPECT_EQ(test, out, c->bgr233);
 }
 
+struct u16_565_read_case {
+	const char *name;
+	u16 rgb565, bgr565;	/* the same color packed both ways */
+	u16 r, g, b;
+};
+
+static struct u16_565_read_case u16_565_read_cases[] = {
+	{ "zero",       0x0000, 0x0000,     0,     0,     0 },
+	{ "max",        0xffff, 0xffff, 65535, 65535, 65535 },
+	{ "red-only",   0xf800, 0x001f, 65535,     0,     0 },
+	{ "green-only", 0x07e0, 0x07e0,     0, 65535,     0 },
+	{ "blue-only",  0x001f, 0xf800,     0,     0, 65535 },
+	{ "low",        0x0821, 0x0821,  2114,  1040,  2114 },	/* 1,1,1 */
+	{ "mid",        0x8410, 0x8410, 33825, 33288, 33825 },	/* 16,32,16 */
+	{ "distinct",   0xfc00, 0x041f, 65535, 33288,     0 },	/* 31,32,0 */
+};
+
+static void vkms_format_test_u16_565_read_case_desc(struct u16_565_read_case *t, char *desc)
+{
+	snprintf(desc, KUNIT_PARAM_DESC_SIZE, "%s", t->name);
+}
+
+KUNIT_ARRAY_PARAM(u16_565_read, u16_565_read_cases, vkms_format_test_u16_565_read_case_desc);
+
+static void vkms_format_test_argb_u16_from_RGB565(struct kunit *test)
+{
+	const struct u16_565_read_case *c = test->param_value;
+	__le16 px = cpu_to_le16(c->rgb565);
+	struct pixel_argb_u16 out = argb_u16_from_RGB565(&px);
+
+	KUNIT_EXPECT_EQ(test, out.r, c->r);
+	KUNIT_EXPECT_EQ(test, out.g, c->g);
+	KUNIT_EXPECT_EQ(test, out.b, c->b);
+	KUNIT_EXPECT_EQ(test, out.a, 0xffff);
+}
+
+static void vkms_format_test_argb_u16_from_BGR565(struct kunit *test)
+{
+	const struct u16_565_read_case *c = test->param_value;
+	__le16 px = cpu_to_le16(c->bgr565);
+	struct pixel_argb_u16 out = argb_u16_from_BGR565(&px);
+
+	KUNIT_EXPECT_EQ(test, out.r, c->r);
+	KUNIT_EXPECT_EQ(test, out.g, c->g);
+	KUNIT_EXPECT_EQ(test, out.b, c->b);
+	KUNIT_EXPECT_EQ(test, out.a, 0xffff);
+}
+
 static struct kunit_case vkms_format_test_cases[] = {
 	KUNIT_CASE_PARAM(vkms_format_test_yuv_u16_to_argb_u16, yuv_u16_to_argb_u16_gen_params),
 	KUNIT_CASE_PARAM(vkms_format_test_argb_u16_to_RGB565, rgb565_gen_params),
@@ -419,6 +467,9 @@ static struct kunit_case vkms_format_test_cases[] = {
 	KUNIT_CASE_PARAM(vkms_format_test_argb_u16_from_BGR233, u8_read_gen_params),
 	KUNIT_CASE_PARAM(vkms_format_test_argb_u16_to_RGB332, u8_write_gen_params),
 	KUNIT_CASE_PARAM(vkms_format_test_argb_u16_to_BGR233, u8_write_gen_params),
+	KUNIT_CASE_PARAM(vkms_format_test_argb_u16_from_RGB565, u16_565_read_gen_params),
+	KUNIT_CASE_PARAM(vkms_format_test_argb_u16_from_BGR565, u16_565_read_gen_params),
+	{}
 };
 
 static struct kunit_suite vkms_format_test_suite = {
diff --git a/drivers/gpu/drm/vkms/vkms_formats.c b/drivers/gpu/drm/vkms/vkms_formats.c
index a5d04f922a94..95456ac9d003 100644
--- a/drivers/gpu/drm/vkms/vkms_formats.c
+++ b/drivers/gpu/drm/vkms/vkms_formats.c
@@ -251,21 +251,23 @@ static struct pixel_argb_u16 channels_to_argb_u16(u16 in_r, u16 in_g, u16 in_b,
 	return out_pixel;
 }
 
-static struct pixel_argb_u16 argb_u16_from_RGB565(const __le16 *pixel)
+VISIBLE_IF_KUNIT struct pixel_argb_u16 argb_u16_from_RGB565(const __le16 *pixel)
 {
 	u16 rgb_565 = le16_to_cpu(*pixel);
 
 	return channels_to_argb_u16((rgb_565 >> 11) & 0x1f, (rgb_565 >> 5) & 0x3f,
 				    rgb_565 & 0x1f, 0xffff, 5, 6, 5, 0);
 }
+EXPORT_SYMBOL_IF_KUNIT(argb_u16_from_RGB565);
 
-static struct pixel_argb_u16 argb_u16_from_BGR565(const __le16 *pixel)
+VISIBLE_IF_KUNIT struct pixel_argb_u16 argb_u16_from_BGR565(const __le16 *pixel)
 {
 	u16 bgr_565 = le16_to_cpu(*pixel);
 
 	return channels_to_argb_u16(bgr_565 & 0x1f, (bgr_565 >> 5) & 0x3f,
 				    (bgr_565 >> 11) & 0x1f, 0xffff, 5, 6, 5, 0);
 }
+EXPORT_SYMBOL_IF_KUNIT(argb_u16_from_BGR565);
 
 VISIBLE_IF_KUNIT struct pixel_argb_u16 argb_u16_from_RGB332(u8 pixel)
 {
diff --git a/drivers/gpu/drm/vkms/vkms_formats.h b/drivers/gpu/drm/vkms/vkms_formats.h
index 8565b2ca86c3..d7a42771fd4c 100644
--- a/drivers/gpu/drm/vkms/vkms_formats.h
+++ b/drivers/gpu/drm/vkms/vkms_formats.h
@@ -24,6 +24,8 @@ struct pixel_argb_u16 argb_u16_from_RGB332(u8 pixel);
 struct pixel_argb_u16 argb_u16_from_BGR233(u8 pixel);
 void argb_u16_to_RGB332(u8 *out_pixel, const struct pixel_argb_u16 *in_pixel);
 void argb_u16_to_BGR233(u8 *out_pixel, const struct pixel_argb_u16 *in_pixel);
+struct pixel_argb_u16 argb_u16_from_RGB565(const __le16 *pixel);
+struct pixel_argb_u16 argb_u16_from_BGR565(const __le16 *pixel);
 #endif
 
 #endif /* _VKMS_FORMATS_H_ */

-- 
2.53.0

