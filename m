From: Alberto Ruiz <aruiz@redhat.com>
Date: Fri, 12 Jun 2026 18:17:16 +0100
Subject: [PATCH 1/4] drm/solomon: add ssd130x_run_cmd_seq() for batch
 command execution
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260612-ssd-batchcmd-v1-1-c61e5f7c24bc@redhat.com>
References: <20260612-ssd-batchcmd-v1-0-c61e5f7c24bc@redhat.com>
In-Reply-To: <20260612-ssd-batchcmd-v1-0-c61e5f7c24bc@redhat.com>
To: Javier Martinez Canillas <javierm@redhat.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Alberto Ruiz <aruiz@redhat.com>
X-Mailer: b4 0.15.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781284654; l=2024;
 i=aruiz@redhat.com; s=20260612; h=from:subject:message-id;
 bh=7aY1PLlc9EJ6kLHma9AUr2Hy4BkrCZ+OPY9RYqNraa8=;
 b=lu5PX75vL6lQbkOsRQQAYv7YUE1Tn1Fv/pH2+a55vb6vriNela8AXX4bkuWcnPNH6hDqA6LPX
 CJagk3r8LwEArDW0Hm5Ro+cruvB2clp02mOo6F3mEZNHvRxpdB38+bq
X-Developer-Key: i=aruiz@redhat.com; a=ed25519;
 pk=d1doFQwve1B/jU9nG5oPl1W5d+t+iFrjkkwk/hD97Ow=
X-Endpoint-Received: by B4 Relay for aruiz@redhat.com/20260612 with auth_id=818
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce ssd130x_run_cmd_seq() that interprets a flat byte array of
length-prefixed command entries terminated by a zero byte, removing the
need for per-command error checking at each call site.

Signed-off-by: Alberto Ruiz <aruiz@redhat.com>
---
 drivers/gpu/drm/solomon/ssd130x.c | 43 +++++++++++++++++++++++++++++++++++++++
 1 file changed, 43 insertions(+)

diff --git a/drivers/gpu/drm/solomon/ssd130x.c b/drivers/gpu/drm/solomon/ssd130x.c
index c77455b1834d..46e2c277a9bf 100644
--- a/drivers/gpu/drm/solomon/ssd130x.c
+++ b/drivers/gpu/drm/solomon/ssd130x.c
@@ -276,6 +276,49 @@ static int ssd130x_write_cmd(struct ssd130x_device *ssd130x, int count,
 	return ret;
 }
 
+/*
+ * Write a command byte sequence from a buffer.
+ *
+ * Like ssd130x_write_cmd() but takes a pre-built byte array instead of
+ * variadic arguments, handy when the command is already in an array or
+ * when the caller wants to use sizeof() for the length.
+ */
+static int ssd130x_write_cmds(struct ssd130x_device *ssd130x, const u8 *cmd,
+			      size_t len)
+{
+	unsigned int i;
+	int ret;
+
+	for (i = 0; i < len; i++) {
+		ret = regmap_write(ssd130x->regmap, SSD13XX_COMMAND, cmd[i]);
+		if (ret)
+			return ret;
+	}
+
+	return 0;
+}
+
+/*
+ * Run a packed command sequence.  The format is a flat byte array where each
+ * entry starts with a length byte followed by that many command bytes.  A
+ * zero length byte terminates the sequence.
+ *
+ * Example: { 2, 0x81, 0x80, 1, 0xAF, 0 }
+ *   sends command {0x81, 0x80}, then command {0xAF}, then stops.
+ */
+static int ssd130x_run_cmd_seq(struct ssd130x_device *ssd130x, const u8 *seq)
+{
+	while (*seq) {
+		u8 len = *seq++;
+		int ret = ssd130x_write_cmds(ssd130x, seq, len);
+
+		if (ret)
+			return ret;
+		seq += len;
+	}
+
+	return 0;
+}
 /* Set address range for horizontal/vertical addressing modes */
 static int ssd130x_set_col_range(struct ssd130x_device *ssd130x,
 				 u8 col_start, u8 cols)

-- 
2.53.0

