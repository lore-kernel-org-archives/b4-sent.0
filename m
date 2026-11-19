From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH 0/2] media: cedrus: allocation failure and capture payload
 fixes
Date: Thu, 19 Nov 2026 16:34:46 +0000
Message-Id: <20261119-b4-cedrus-generic-fixes-v1-0-f9f50812c85b@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQrCQAyE4VcpORswS6viq4iHNjut8bDKxopQ+
 u5Ge/wY/lnIUQ1O52ahire5PUpAdg3prS8T2HKY0j4dRKTloWVFrrPzhBKt8mgfOJ8UR9GU+zF
 3FPWz4j9EfLlu9nm4Q1+/O1rXL5JCp0J7AAAA
X-Change-ID: 20261114-b4-cedrus-generic-fixes-8ce71c2dafd5
To: Maxime Ripard <mripard@kernel.org>, 
 Paul Kocialkowski <paulk@sys-base.io>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Chen-Yu Tsai <wens@kernel.org>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, Hans Verkuil <hverkuil@kernel.org>
Cc: linux-media@vger.kernel.org, linux-staging@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, linux-sunxi@lists.linux.dev, 
 linux-kernel@vger.kernel.org, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795106086; l=997;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=wYVP1PucRg6lWg2/ngxnBUIQiUIQRKql/Gq/N+y2N6I=;
 b=6IqB4ZHRS2PcVo6o6j3tFxdrpHRv2ITJ4ztz3QgqrkrQejXbRdjRDvrBSs2dD3nlLNSTj1zuG
 9MOTavWvfvNCDfVAyLu/SUZ+Lv6dffylRiNbgtHHWBXuQYV0WTrDGqg
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Two cedrus fixes, found on an Orange Pi Zero2 (H616) and reproduced on
media-committers next. Patch 2 concerns the private plane of Jernej
Skrabec's 10-bit HEVC support.

Tested on H616 only: 17 x 64 MiB REQBUFS gives 12 buffers and no OOM
kill (next: five processes killed); 10-bit H.265 bytesused 12441600
(next: 15552000); v4l2-compliance 49/49; MPEG-2, H.264 and H.265
bit-exact.

Developed with Claude (Anthropic) as a coding assistant, which wrote
the code and the commit messages. I reviewed and tested them.

---
Arun Iyengar (2):
      media: cedrus: fail buffer allocations that do not fit with -ENOMEM
      media: cedrus: report only the picture as capture payload

 drivers/staging/media/sunxi/cedrus/cedrus_video.c | 13 +++++++++++--
 1 file changed, 11 insertions(+), 2 deletions(-)
---
base-commit: aa0f4c41d4870a18e65772a1817af16427200371
change-id: 20261114-b4-cedrus-generic-fixes-8ce71c2dafd5

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

