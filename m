From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 12 Nov 2026 11:17:52 +0000
Subject: [PATCH] media: verisilicon: Only accept formats of the queue's
 kind in TRY_FMT
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-hantro-fmt-role-v1-1-e596d6f4828f@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQ0MjXaBgSVG+blpuiW5Rfk6qrrmJcUqiUZKlRXJykhJQV0FRalpmBdj
 E6FgIv7g0KSs1uQRkjFJtLQAkwJ6acwAAAA==
X-Change-ID: 20261112-hantro-fmt-role-743da2b98ccb
To: Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Hans Verkuil <hverkuil@kernel.org>, 
 Ezequiel Garcia <ezequiel@vanguardiasur.com.ar>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794482272; l=4438;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=s3CPAFpQ1/qB9nw0SP8YBgc/jIrhI3ySnN7uPXYFxW4=;
 b=Y8ORNp5aA3bzodvaJDfM+grVFHRPKgG4txfK1ZC+0Y2b16sv5q50TTacSXLRObUFtAewOP/zd
 UZWgNf9SZr+ApgVTplkVfT1vH4lqo2pjGW2lxnGtJ3aqdpNY9aWFDL2
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The format tables of the Hantro variants hold both the coded formats and
the raw ones (codec_mode HANTRO_MODE_NONE). vidioc_enum_fmt() and
hantro_get_default_fmt() filter them by kind, but hantro_try_fmt() looks
the requested pixelformat up in the whole table. It therefore accepts a
raw format on the coded queue and a coded format on the raw queue, and
hantro_set_fmt_out() and hantro_set_fmt_cap() store it as
ctx->vpu_src_fmt or ctx->vpu_dst_fmt.

On an RK3588 running a 7.3 based kernel, a user who is only a member of
the video group can set a raw format on the coded queue of the VEPU121
JPEG encoder and of the VPU981 AV1 decoder with VIDIOC_S_FMT. When the
application leaves sizeimage at zero, the driver computes it from the
header size and the depth of the format. A raw format has neither, so
the sizeimage of the coded queue stays zero, and the next VIDIOC_REQBUFS
on that queue fails with -EINVAL after

  WARNING: drivers/media/common/videobuf2/videobuf2-core.c:951 at vb2_core_reqbufs+0x1ac/0x530 [videobuf2_common]

which is the WARN_ON(!plane_sizes[i]) check. With panic_on_warn set,
this is enough for such a user to panic the machine.

From reading the code, the wrong format can do more harm than that:
hantro_start_streaming() takes the codec mode from the format of the
coded queue and uses it as the index into the codec_ops array of the
variant, and HANTRO_MODE_NONE is -1. This was not observed. In the test
above, which left sizeimage at zero, no buffer could be allocated on the
coded queue and VIDIOC_STREAMON failed with -EINVAL too, so the index
was never used. It has not been established whether another sequence
gets that far.

Treat a format of the wrong kind like an unknown one and fall back to
the default format of the queue. With this change VIDIOC_S_FMT returns
the default coded format on the nodes above.

Fixes: 775fec69008d ("media: add Rockchip VPU JPEG encoder driver")
Reported-by: Sashiko <sashiko-bot@kernel.org>
Closes: https://sashiko.dev/#/patchset/20261110-hantro-jpeg-enc-fixes-v1-0-fc4dc7e985d2@gmail.com?part=1
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Sashiko listed this as a pre-existing problem in the findings of its
review of "[PATCH 1/6] media: verisilicon: Enforce a minimum CAPTURE
sizeimage for the encoder" (in the review data on sashiko.dev, not in
the review mail it sent to the list); it is not caused by that series
and this patch does not depend on it.

Tested on an Orange Pi 5 (RK3588S) with a 7.3 based kernel that carries
out-of-tree patches, with a small test program run as an unprivileged
user in the video group. Without the change the raw format is accepted
on the coded queue of the VEPU121 JPEG encoder, of the VPU981 AV1
decoder and of an H.264 encoder node that is not in mainline, and each
of them logs the warning quoted in the commit message. With the change
all three return their default coded format and the kernel log stays
clean. The coded format on the raw queue case is fixed by the same
check but was not exercised. On media-committers next the patch is
build-tested only (arm64, W=1). The test program is available on
request.

This patch was developed with Claude (Anthropic) as a coding assistant:
it wrote the code and the commit message, and I reviewed and tested it
as described above.
---
 drivers/media/platform/verisilicon/hantro_v4l2.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/media/platform/verisilicon/hantro_v4l2.c b/drivers/media/platform/verisilicon/hantro_v4l2.c
index 83af9fa1ce94..64e32aef8b04 100644
--- a/drivers/media/platform/verisilicon/hantro_v4l2.c
+++ b/drivers/media/platform/verisilicon/hantro_v4l2.c
@@ -337,6 +337,9 @@ static int hantro_try_fmt(const struct hantro_ctx *ctx,
 	vpu_debug(4, "trying format %p4cc\n", &pix_mp->pixelformat);
 
 	fmt = hantro_find_format(ctx, pix_mp->pixelformat);
+	/* The format list mixes coded and raw formats, only take the right kind */
+	if (fmt && coded != (fmt->codec_mode != HANTRO_MODE_NONE))
+		fmt = NULL;
 	if (!fmt) {
 		fmt = hantro_get_default_fmt(ctx, coded, HANTRO_DEFAULT_BIT_DEPTH, HANTRO_AUTO_POSTPROC);
 		pix_mp->pixelformat = fmt->fourcc;

---
base-commit: 55271157078b9a6fd3519ee21b567a684f7277ca
change-id: 20261112-hantro-fmt-role-743da2b98ccb

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

