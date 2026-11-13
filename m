From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Fri, 13 Nov 2026 21:27:54 +0000
Subject: [PATCH v2] drm/debugfs: Accept "reset" with a trailing newline in
 edid_override
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-drm-debugfs-edid-reset-v2-1-07939ebe7a8b@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNQQ6CQAxFr0Jmbc20Iior72FYwLRAjYCZAaIh3
 F3AuHT5kv/fm0wQrxJMGk3Gy6hBu3YB2kXG1XlbCSgvbMhSgogW2DfAUgxVGUBYGbwE6cEebZy
 TdcmJ0Sznp5dSX5v4ln05DMVdXL/a1kWtoe/8eyuPuO5+EfoXGREQYsd44fPBMdG1anJ97F3Xm
 Gye5w8kD9nrzgAAAA==
X-Change-ID: 20261110-drm-debugfs-edid-reset-0504a20c67d1
To: Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Jani Nikula <jani.nikula@linux.intel.com>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794605273; l=2090;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=NYL/q8RW4OVHSqWl5Xmdo7H2RuHmd47GPaMUXnBj3ww=;
 b=GBnVq8NpjUHncNStUoHXfUdva311z6rUwCSQZaIRbwplqMYBmr7bkrz/OHXO8V0ciQtVA1ORm
 R+wmP0AUgD3CMWYf1zSh/XSbO+eEhj211EZT7oZqLXal3aycABZMEW1
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Writing "reset" to edid_override only removes the override when exactly
those five bytes are written, so "echo reset > edid_override" fails with
-EINVAL and leaves the override in place.

Compare with sysfs_streq() on a NUL-terminated copy, and reject writes
larger than the largest possible EDID (256 blocks) before copying,
so that the size of the copy is bounded.

Suggested-by: Jani Nikula <jani.nikula@linux.intel.com>
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Tested on an Orange Pi 5 (RK3588S) with this patch on a 7.3 based
kernel: "echo reset" and "printf reset" both remove an override, an EDID
override round trip still works, and garbage or oversized writes fail
with -EINVAL.

Developed with Claude (Anthropic), which wrote the code and the commit
message. I reviewed and tested it.
---
Changes in v2:
- Use memdup_user_nul() and sysfs_streq() (Jani Nikula)
- Reject writes larger than 256 EDID blocks before copying
- Shorter commit message
- Link to v1: https://patch.msgid.link/20261112-drm-debugfs-edid-reset-v1-1-4cd19d83cd22@gmail.com
---
 drivers/gpu/drm/drm_debugfs.c | 8 ++++++--
 1 file changed, 6 insertions(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/drm_debugfs.c b/drivers/gpu/drm/drm_debugfs.c
index a72f9723d3a9..7c39c8ed3984 100644
--- a/drivers/gpu/drm/drm_debugfs.c
+++ b/drivers/gpu/drm/drm_debugfs.c
@@ -565,11 +565,15 @@ static ssize_t edid_write(struct file *file, const char __user *ubuf,
 	char *buf;
 	int ret;
 
-	buf = memdup_user(ubuf, len);
+	/* An EDID has at most 256 blocks */
+	if (len > 256 * EDID_LENGTH)
+		return -EINVAL;
+
+	buf = memdup_user_nul(ubuf, len);
 	if (IS_ERR(buf))
 		return PTR_ERR(buf);
 
-	if (len == 5 && !strncmp(buf, "reset", 5))
+	if (sysfs_streq(buf, "reset"))
 		ret = drm_edid_override_reset(connector);
 	else
 		ret = drm_edid_override_set(connector, buf, len);

---
base-commit: cb0a63f0c96e8ecb90199eeb99cc2a7fcfa703d4
change-id: 20261110-drm-debugfs-edid-reset-0504a20c67d1

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

