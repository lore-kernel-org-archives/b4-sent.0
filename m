From: Sidharth Saha <ssaha2000@gmail.com>
Date: Mon, 16 Nov 2026 18:21:34 -0700
Subject: [PATCH 3/5] drm/vkms: Add KUnit tests for RGB332 and BGR233 read
 conversion
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-rgb565-test-v1-3-27f49c1aa694@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794878495; l=5355;
 i=ssaha2000@gmail.com; s=20261116; h=from:subject:message-id;
 bh=BzzSS01lRRAORcGhyQ44tyFvKj+4xyy3eKNDBMTs5Y0=;
 b=XOEwGPLUrfmGnzNQ8xD2l/PV0UVQlhyTzzJRcpGH+1ZJ+KUA8j7I+UgBboMzpNB/Ncgep7WYt
 HFBT6nIUhxrAPwxqFaYQYTWRuA0f51WKskP+IqjN+bGQNa+zqYSCtCL
X-Developer-Key: i=ssaha2000@gmail.com; a=ed25519;
 pk=wMWW9xOklVZkO7Yh4yIXvhVVRs/3ROsqgjTt8XBGybI=
X-Endpoint-Received: by B4 Relay for ssaha2000@gmail.com/20261116 with auth_id=1541
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Test argb_u16_from_RGB332() and argb_u16_from_BGR233(), which expand
3/3/2-bit channels to 16 bits. Each case holds the same color packed
both ways, with expected values computed by hand, including channel
values 4-6, where the result must be rounded up.

Make both functions visible to KUnit so the tests can call them.

Signed-off-by: Sidharth Saha <40047656+Sidharth-Saha@users.noreply.github.com>
---
 drivers/gpu/drm/vkms/tests/vkms_format_test.c | 49 +++++++++++++++++++++++++++
 drivers/gpu/drm/vkms/vkms_formats.c           |  6 ++--
 drivers/gpu/drm/vkms/vkms_formats.h           |  4 +++
 3 files changed, 57 insertions(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/vkms/tests/vkms_format_test.c b/drivers/gpu/drm/vkms/tests/vkms_format_test.c
index e7836664c788..ab95d6c3d2d5 100644
--- a/drivers/gpu/drm/vkms/tests/vkms_format_test.c
+++ b/drivers/gpu/drm/vkms/tests/vkms_format_test.c
@@ -315,10 +315,59 @@ static void vkms_format_test_argb_u16_to_BGR565(struct kunit *test)
 	KUNIT_EXPECT_EQ(test, (v >> 11) & 0x1f, c->b);	/* blue: high bits */
 }
 
+struct u8_read_case {
+	const char *name;
+	u8 rgb332, bgr233;	/* the same color packed both ways */
+	u16 r, g, b;		/* expected 16-bit outputs */
+};
+
+static struct u8_read_case u8_read_cases[] = {
+	/*  name          RGB332 BGR233   r       g       b     */
+	{ "zero",         0x00,  0x00,    0,      0,      0     },
+	{ "max",          0xff,  0xff,    65535,  65535,  65535 },
+	{ "red-only",     0xe0,  0x07,    65535,  0,      0     },
+	{ "green-only",   0x1c,  0x38,    0,      65535,  0     },
+	{ "blue-only",    0x03,  0xc0,    0,      0,      65535 },
+	{ "low-steps",    0x29,  0x51,    9362,   18724,  21845 },  /* r=1 g=2 b=1 */
+	{ "round-up",     0x96,  0xac,    37449,  46811,  43690 },  /* r=4 g=5 b=2 */
+	{ "mixed",        0xcc,  0x1e,    56173,  28086,  0     },  /* r=6 g=3 b=0 */
+};
+
+static void vkms_format_test_u8_read_case_desc(struct u8_read_case *t, char *desc)
+{
+	snprintf(desc, KUNIT_PARAM_DESC_SIZE, "%s", t->name);
+}
+
+KUNIT_ARRAY_PARAM(u8_read, u8_read_cases, vkms_format_test_u8_read_case_desc);
+
+static void vkms_format_test_argb_u16_from_RGB332(struct kunit *test)
+{
+	const struct u8_read_case *c = test->param_value;
+	struct pixel_argb_u16 out = argb_u16_from_RGB332(c->rgb332);
+
+	KUNIT_EXPECT_EQ(test, out.r, c->r);
+	KUNIT_EXPECT_EQ(test, out.g, c->g);
+	KUNIT_EXPECT_EQ(test, out.b, c->b);
+	KUNIT_EXPECT_EQ(test, out.a, 0xffff);	/* no alpha channel: always opaque */
+}
+
+static void vkms_format_test_argb_u16_from_BGR233(struct kunit *test)
+{
+	const struct u8_read_case *c = test->param_value;
+	struct pixel_argb_u16 out = argb_u16_from_BGR233(c->bgr233);
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
 	KUNIT_CASE_PARAM(vkms_format_test_argb_u16_to_BGR565, rgb565_gen_params),
+	KUNIT_CASE_PARAM(vkms_format_test_argb_u16_from_RGB332, u8_read_gen_params),
+	KUNIT_CASE_PARAM(vkms_format_test_argb_u16_from_BGR233, u8_read_gen_params),
 };
 
 static struct kunit_suite vkms_format_test_suite = {
diff --git a/drivers/gpu/drm/vkms/vkms_formats.c b/drivers/gpu/drm/vkms/vkms_formats.c
index 7950751c4890..eccca25f51d4 100644
--- a/drivers/gpu/drm/vkms/vkms_formats.c
+++ b/drivers/gpu/drm/vkms/vkms_formats.c
@@ -267,17 +267,19 @@ static struct pixel_argb_u16 argb_u16_from_BGR565(const __le16 *pixel)
 				    (bgr_565 >> 11) & 0x1f, 0xffff, 5, 6, 5, 0);
 }
 
-static struct pixel_argb_u16 argb_u16_from_RGB332(u8 pixel)
+VISIBLE_IF_KUNIT struct pixel_argb_u16 argb_u16_from_RGB332(u8 pixel)
 {
 	return channels_to_argb_u16((pixel >> 5) & 0x7, (pixel >> 2) & 0x7,
 				    pixel & 0x3, 0xffff, 3, 3, 2, 0);
 }
+EXPORT_SYMBOL_IF_KUNIT(argb_u16_from_RGB332);
 
-static struct pixel_argb_u16 argb_u16_from_BGR233(u8 pixel)
+VISIBLE_IF_KUNIT struct pixel_argb_u16 argb_u16_from_BGR233(u8 pixel)
 {
 	return channels_to_argb_u16(pixel & 0x7, (pixel >> 3) & 0x7,
 				    (pixel >> 6) & 0x3, 0xffff, 3, 3, 2, 0);
 }
+EXPORT_SYMBOL_IF_KUNIT(argb_u16_from_BGR233);
 
 static struct pixel_argb_u16 argb_u16_from_gray8(u8 gray)
 {
diff --git a/drivers/gpu/drm/vkms/vkms_formats.h b/drivers/gpu/drm/vkms/vkms_formats.h
index 135bb60a554b..90006325a87e 100644
--- a/drivers/gpu/drm/vkms/vkms_formats.h
+++ b/drivers/gpu/drm/vkms/vkms_formats.h
@@ -18,6 +18,10 @@ struct pixel_argb_u16 argb_u16_from_yuv161616(const struct conversion_matrix *ma
 					      u16 y, u16 channel_1, u16 channel_2);
 void argb_u16_to_RGB565(u8 *out_pixel, const struct pixel_argb_u16 *in_pixel);
 void argb_u16_to_BGR565(u8 *out_pixel, const struct pixel_argb_u16 *in_pixel);
+void argb_u16_to_RGB565(u8 *out_pixel, const struct pixel_argb_u16 *in_pixel);
+void argb_u16_to_BGR565(u8 *out_pixel, const struct pixel_argb_u16 *in_pixel);
+struct pixel_argb_u16 argb_u16_from_RGB332(u8 pixel);
+struct pixel_argb_u16 argb_u16_from_BGR233(u8 pixel);
 #endif
 
 #endif /* _VKMS_FORMATS_H_ */

-- 
2.53.0

