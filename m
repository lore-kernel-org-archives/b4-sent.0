From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 12 Nov 2026 10:44:59 +0000
Subject: [PATCH] drm/debugfs: Accept "reset" with a trailing newline in
 edid_override
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-drm-debugfs-edid-reset-v1-1-4cd19d83cd22@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQrCQAxG4auUrA1kBq3gVcRFO/lbI1glaUUov
 bujLr/FeysF3BB0alZyvCzsMVWkXUPl2k0j2LSasuQ2pSSsfmdFv4xDMNSUHYGZ5SD7Lktpj5q
 oxk/HYO/f+Hz5O5b+hjJ/b7RtHyvh3QV6AAAA
X-Change-ID: 20261110-drm-debugfs-edid-reset-0504a20c67d1
To: Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Jani Nikula <jani.nikula@linux.intel.com>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794480299; l=2159;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=q9OBm8AG1wALzNkA2iDL4Ckkgs47X7jT9hCbulBfsn4=;
 b=keagsGyaqUeHySKh+LwDiP92tHC1f78fQ47av3Plpx/nKzMNDn0IEVDiy9T1pC99dh+CH2lM5
 eHHLirfi9NSBqjuKaVQy9r9IyGuD68thYQjHso7mtgqDOqh70X64/yr
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Writing "reset" to a connector's edid_override debugfs file removes the
override, but only when exactly those five bytes are written. The
obvious

  echo reset > /sys/kernel/debug/dri/0/HDMI-A-1/edid_override

writes "reset\n", which is handed to drm_edid_override_set() as an EDID
and rejected with -EINVAL, leaving the override in place. A test
harness that cleared its override this way kept running on the
overridden EDID until the next reboot.

Accept a single trailing newline as well. An EDID is at least 128
bytes, so a six-byte "reset\n" can't be a valid override.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Found and tested on an Orange Pi 5 (RK3588S), with this change on a 7.3
based kernel: with the HDMI connector's own EDID written to
edid_override, "echo reset > edid_override" succeeds and edid_override
reads back empty, and "printf reset" (no newline) still succeeds. On
drm-misc-next the patch is build-tested only (arm64 and x86_64, W=1).

This patch was developed with Claude (Anthropic) as a coding assistant:
it wrote the code and the commit message, and I reviewed and tested it
as described above.
---
 drivers/gpu/drm/drm_debugfs.c | 7 ++++++-
 1 file changed, 6 insertions(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/drm_debugfs.c b/drivers/gpu/drm/drm_debugfs.c
index a72f9723d3a9..3c6290457fa3 100644
--- a/drivers/gpu/drm/drm_debugfs.c
+++ b/drivers/gpu/drm/drm_debugfs.c
@@ -569,7 +569,12 @@ static ssize_t edid_write(struct file *file, const char __user *ubuf,
 	if (IS_ERR(buf))
 		return PTR_ERR(buf);
 
-	if (len == 5 && !strncmp(buf, "reset", 5))
+	/*
+	 * An EDID is at least 128 bytes, so "reset" with the trailing newline
+	 * that "echo reset" adds can't be mistaken for one.
+	 */
+	if ((len == 5 || (len == 6 && buf[5] == '\n')) &&
+	    !strncmp(buf, "reset", 5))
 		ret = drm_edid_override_reset(connector);
 	else
 		ret = drm_edid_override_set(connector, buf, len);

---
base-commit: cb0a63f0c96e8ecb90199eeb99cc2a7fcfa703d4
change-id: 20261110-drm-debugfs-edid-reset-0504a20c67d1

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

