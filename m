From: Junrui Luo <moonafterrain@outlook.com>
Date: Sat, 15 Aug 2026 22:56:37 +0800
Subject: [PATCH 3/4] media: vicodec: clamp visible dimensions on S_FMT to
 coded bounds
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260815-vicodec-fixes-v1-3-12101572eba7@outlook.com>
References: <20260815-vicodec-fixes-v1-0-12101572eba7@outlook.com>
In-Reply-To: <20260815-vicodec-fixes-v1-0-12101572eba7@outlook.com>
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Hans Verkuil <hverkuil@kernel.org>, 
 Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 Dafna Hirschfeld <dafna3@gmail.com>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Mauro Carvalho Chehab <mchehab+samsung@kernel.org>, 
 Junrui Luo <moonafterrain@outlook.com>, Yuhao Jiang <danisjiang@gmail.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2305;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=xw+SM0NXC9kyoKDEQVYsDRhjEC52Kz8+luL+uJhz9SQ=;
 b=owJ4nJvAy8zAJVb4wiKgu++DA+NptSSGrIY6tc5t0XfZ2C7auOxbVPr91OOvv2fP+X1y5uyfL
 jy3pHLM17R1lLIwiHExyIopshwvuPTNwneL7hafLckwc1iZQIYwcHEKwETa1jL8T1zPKLn76u4U
 l2tvfv5apnHY/splvr+OzNr+t5p2u3WEpzAy7EjtnTrvrK6c7Fxe6fiyBq9e/fsG3Hp/z1vZLV5
 x+OIZZgAcyk2d
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Setting a smaller CAPTURE format on the stateful decoder lets the visible
dimensions exceed the coded ones, and decode_plane() then writes past the
end of the capture buffer -- a kernel heap out-of-bounds write
controllable from unprivileged userspace.

vidioc_s_fmt() writes coded_width, coded_height and sizeimage but never
touches visible_width or visible_height, which vicodec_open() initialised
to 1280x720, so shrinking the coded pair leaves the visible pair larger.
job_ready() compares the bitstream header against the stale visible
dimensions, so no source-change event fires and decode_plane() iterates
over the visible height at a stride derived from coded_width.

On a KASAN-enabled kernel, a 1280x720 I-frame decoded into a 640x368
CAPTURE buffer triggers:

  BUG: KASAN: vmalloc-out-of-bounds in decode_plane+0x1bb8/0x34b0
  Write of size 1 at addr ffffc900004b8080 by task trigger_bin/69

  Call Trace:
   decode_plane+0x1bb8/0x34b0
   fwht_decode_frame+0x173/0x620
   v4l2_fwht_decode+0x595/0xea0

Clamp visible_width and visible_height to the new coded bounds after
every S_FMT, maintaining the invariant visible <= coded that
update_capture_data_from_header() relies on.

Fixes: 3b15f68e19c2 ("media: vicodec: Add support for resolution change event.")
Reported-by: Yuhao Jiang <danisjiang@gmail.com>
Assisted-by: Claude:claude-opus-5
Cc: stable@vger.kernel.org
Signed-off-by: Junrui Luo <moonafterrain@outlook.com>
---
 drivers/media/test-drivers/vicodec/vicodec-core.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/drivers/media/test-drivers/vicodec/vicodec-core.c b/drivers/media/test-drivers/vicodec/vicodec-core.c
index 318e8330f16a..36b92f68ac42 100644
--- a/drivers/media/test-drivers/vicodec/vicodec-core.c
+++ b/drivers/media/test-drivers/vicodec/vicodec-core.c
@@ -1029,6 +1029,11 @@ static int vidioc_s_fmt(struct vicodec_ctx *ctx, struct v4l2_format *f)
 		return -EINVAL;
 	}
 
+	q_data->visible_width = min(q_data->visible_width,
+				    q_data->coded_width);
+	q_data->visible_height = min(q_data->visible_height,
+				     q_data->coded_height);
+
 	dprintk(ctx->dev,
 		"Setting format for type %d, coded wxh: %dx%d, fourcc: 0x%08x\n",
 		f->type, q_data->coded_width, q_data->coded_height,

-- 
2.51.2

