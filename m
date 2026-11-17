From: Sidharth Saha <ssaha2000@gmail.com>
Date: Mon, 16 Nov 2026 18:21:32 -0700
Subject: [PATCH 1/5] drm/vkms: Add KUnit test for RGB565 writeback
 conversion
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-rgb565-test-v1-1-27f49c1aa694@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794878495; l=4548;
 i=ssaha2000@gmail.com; s=20261116; h=from:subject:message-id;
 bh=O4oCx5AVv4hw3TWfDUOkN6pr1WzBeONVMnkcYKgeUH4=;
 b=MJ11pi2eRZ7b71iwFlTOwgt0+haFEbdRh4RXrvssD92e6jGdROeJFOqffEsjOT20mlsigyfxF
 9t28QHgWgDQCXjZurmMaxb+Spxo9euLS3gjmquIWDBR+bXIIzqjUXol
X-Developer-Key: i=ssaha2000@gmail.com; a=ed25519;
 pk=wMWW9xOklVZkO7Yh4yIXvhVVRs/3ROsqgjTt8XBGybI=
X-Endpoint-Received: by B4 Relay for ssaha2000@gmail.com/20261116 with auth_id=1541
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

argb_u16_to_RGB565() reduces each 16-bit channel to 5 or 6 bits. Its
rounding was fixed in commit ab87f558dcfb ("drm/vkms: Fix RGB565 pixel
conversion"), lost again in commit cc4fd2934d41 ("drm/vkms: Isolate
writeback pixel conversion functions"), and restored by "drm/vkms: make
argb_u16_to_RGB565 round resulting values". Add a KUnit test so it can't
silently regress again.

The test checks hand-computed values for zero, maximum, the 0x8000
midpoint, inputs on either side of the first rounding step, and distinct
per-channel values to catch channel placement errors.

Make argb_u16_to_RGB565() visible to KUnit so the test can call it.

Signed-off-by: Sidharth Saha <40047656+Sidharth-Saha@users.noreply.github.com>
---
 drivers/gpu/drm/vkms/tests/vkms_format_test.c | 38 ++++++++++++++++++++++++++-
 drivers/gpu/drm/vkms/vkms_formats.c           |  3 ++-
 drivers/gpu/drm/vkms/vkms_formats.h           |  1 +
 3 files changed, 40 insertions(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/vkms/tests/vkms_format_test.c b/drivers/gpu/drm/vkms/tests/vkms_format_test.c
index bbb1ad18c99f..a8ef93b9c806 100644
--- a/drivers/gpu/drm/vkms/tests/vkms_format_test.c
+++ b/drivers/gpu/drm/vkms/tests/vkms_format_test.c
@@ -265,9 +265,45 @@ KUNIT_ARRAY_PARAM(yuv_u16_to_argb_u16, yuv_u16_to_argb_u16_cases,
 		  vkms_format_test_yuv_u16_to_argb_u16_case_desc
 );
 
+struct rgb565_case {
+	const char *name;
+	struct pixel_argb_u16 in;
+	u16 r, g, b;		/* expected 5/6/5-bit outputs */
+};
+
+static struct rgb565_case rgb565_cases[] = {
+	{ "zero",       { .a = 0xffff, .r = 0,      .g = 0,      .b = 0      },  0,  0,  0 },
+	{ "max",        { .a = 0xffff, .r = 0xffff, .g = 0xffff, .b = 0xffff }, 31, 63, 31 },
+	{ "midpoint",   { .a = 0xffff, .r = 0x8000, .g = 0x8000, .b = 0x8000 }, 16, 32, 16 },
+	{ "below-step", { .a = 0xffff, .r = 1057,   .g = 0,      .b = 0      },  0,  0,  0 },
+	{ "above-step", { .a = 0xffff, .r = 1058,   .g = 0,      .b = 0      },  1,  0,  0 },
+	{ "distinct",   { .a = 0xffff, .r = 0xffff, .g = 0x8000, .b = 0      }, 31, 32,  0 },
+};
+
+static void vkms_format_test_rgb565_case_desc(struct rgb565_case *t, char *desc)
+{
+	snprintf(desc, KUNIT_PARAM_DESC_SIZE, "%s", t->name);
+}
+
+KUNIT_ARRAY_PARAM(rgb565, rgb565_cases, vkms_format_test_rgb565_case_desc);
+
+static void vkms_format_test_argb_u16_to_RGB565(struct kunit *test)
+{
+	const struct rgb565_case *c = test->param_value;
+	__le16 out;
+	u16 v;
+
+	argb_u16_to_RGB565((u8 *)&out, &c->in);
+	v = le16_to_cpu(out);
+
+	KUNIT_EXPECT_EQ(test, (v >> 11) & 0x1f, c->r);
+	KUNIT_EXPECT_EQ(test, (v >> 5) & 0x3f, c->g);
+	KUNIT_EXPECT_EQ(test, v & 0x1f, c->b);
+}
+
 static struct kunit_case vkms_format_test_cases[] = {
 	KUNIT_CASE_PARAM(vkms_format_test_yuv_u16_to_argb_u16, yuv_u16_to_argb_u16_gen_params),
-	{}
+	KUNIT_CASE_PARAM(vkms_format_test_argb_u16_to_RGB565, rgb565_gen_params),
 };
 
 static struct kunit_suite vkms_format_test_suite = {
diff --git a/drivers/gpu/drm/vkms/vkms_formats.c b/drivers/gpu/drm/vkms/vkms_formats.c
index b0078d6efb90..c5ee2d6a920f 100644
--- a/drivers/gpu/drm/vkms/vkms_formats.c
+++ b/drivers/gpu/drm/vkms/vkms_formats.c
@@ -685,7 +685,7 @@ static void argb_u16_to_channels(u16 *out_r, u16 *out_g, u16 *out_b, u16 *out_a,
 		*out_a = u16_to_channel(a_size, in_pixel->a);
 }
 
-static void argb_u16_to_RGB565(u8 *out_pixel, const struct pixel_argb_u16 *in_pixel)
+VISIBLE_IF_KUNIT void argb_u16_to_RGB565(u8 *out_pixel, const struct pixel_argb_u16 *in_pixel)
 {
 	__le16 *pixel = (__le16 *)out_pixel;
 	u16 r, g, b;
@@ -694,6 +694,7 @@ static void argb_u16_to_RGB565(u8 *out_pixel, const struct pixel_argb_u16 *in_pi
 
 	*pixel = cpu_to_le16(r << 11 | g << 5 | b);
 }
+EXPORT_SYMBOL_IF_KUNIT(argb_u16_to_RGB565);
 
 static void argb_u16_to_BGR565(u8 *out_pixel, const struct pixel_argb_u16 *in_pixel)
 {
diff --git a/drivers/gpu/drm/vkms/vkms_formats.h b/drivers/gpu/drm/vkms/vkms_formats.h
index d969cc669a5e..2b8a1c4a5d46 100644
--- a/drivers/gpu/drm/vkms/vkms_formats.h
+++ b/drivers/gpu/drm/vkms/vkms_formats.h
@@ -16,6 +16,7 @@ void get_conversion_matrix_to_argb_u16(u32 format, enum drm_color_encoding encod
 #if IS_ENABLED(CONFIG_KUNIT)
 struct pixel_argb_u16 argb_u16_from_yuv161616(const struct conversion_matrix *matrix,
 					      u16 y, u16 channel_1, u16 channel_2);
+void argb_u16_to_RGB565(u8 *out_pixel, const struct pixel_argb_u16 *in_pixel);
 #endif
 
 #endif /* _VKMS_FORMATS_H_ */

-- 
2.53.0

