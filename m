From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 19 Nov 2026 04:39:18 +0000
Subject: [PATCH v3] drm/debugfs: Accept "reset" with a trailing newline in
 edid_override
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-drm-debugfs-edid-reset-v3-1-1cc341d0cf41@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNyw6CMBQFf4V0bU0fyMOV/2FctL0XqBEwLTQaw
 r/bYkzYuJzknJmFeHQWPTlnC3EYrLfjEEEeMmI6NbRILUQmgomCc84ouJ4C6rltPEWwQB16nCg
 7sVwJZooSOInnp8PGvjbx9fZlP+s7minZ0qKzfhrdeysHnna/iPgXCZxymhvgNVTSgBCXtlf2c
 TRjT1IkiL1G/tWIqGFlLWvUWKpK7zXrun4AFLYJyxUBAAA=
X-Change-ID: 20261110-drm-debugfs-edid-reset-0504a20c67d1
To: Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Jani Nikula <jani.nikula@linux.intel.com>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795063158; l=1693;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=jlIJ52+T1x1z/bjrNl0cApVxb+LOrNW+ryJUXQMv/oM=;
 b=4ti2yccUOKqN89evQXTvQl+hFL7Z6TC71awA6+sDSvoKGcdikTS3/JkJ2MCuikEERP8bEOMzm
 x21MmiwNOf6BpGOz01QBYD8jthQ7e4lyL/8AsvpLmXc588cHREp/PVe
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Writing "reset" to edid_override removes the override only for exactly
those five bytes, so "echo reset > edid_override" fails with -EINVAL.

Compare with sysfs_streq() on a NUL-terminated copy.

Suggested-by: Jani Nikula <jani.nikula@linux.intel.com>
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Tested on an Orange Pi 5 (7.3-based kernel with KASAN) on its DP
connector: setting and reading back the EDID, both reset forms, and
malformed and oversized writes (rejected, override unchanged).

Developed with Claude (Anthropic), which wrote the code and the commit
message. I reviewed every change.
---
Changes in v3:
- Drop the unrelated length check (Jani Nikula)
- Link to v2: https://patch.msgid.link/20261113-drm-debugfs-edid-reset-v2-1-07939ebe7a8b@gmail.com
---
 drivers/gpu/drm/drm_debugfs.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/drm_debugfs.c b/drivers/gpu/drm/drm_debugfs.c
index a72f9723d3a9..77b22730d091 100644
--- a/drivers/gpu/drm/drm_debugfs.c
+++ b/drivers/gpu/drm/drm_debugfs.c
@@ -565,11 +565,11 @@ static ssize_t edid_write(struct file *file, const char __user *ubuf,
 	char *buf;
 	int ret;
 
-	buf = memdup_user(ubuf, len);
+	buf = memdup_user_nul(ubuf, len);
 	if (IS_ERR(buf))
 		return PTR_ERR(buf);
 
-	if (len == 5 && !strncmp(buf, "reset", 5))
+	if (sysfs_streq(buf, "reset"))
 		ret = drm_edid_override_reset(connector);
 	else
 		ret = drm_edid_override_set(connector, buf, len);

---
base-commit: 467ac0b56aebc804360f276feffbc9032c265a6e
change-id: 20261110-drm-debugfs-edid-reset-0504a20c67d1

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

