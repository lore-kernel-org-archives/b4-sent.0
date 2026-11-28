From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH v2 0/2] media: cedrus: allocation failure and capture
 payload fixes
Date: Sat, 28 Nov 2026 17:35:51 +0000
Message-Id: <20261128-b4-cedrus-generic-fixes-v2-0-af8472be660b@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNQQ6CMBBFr0Jm7RjagIIr72FYwHQKY4SaFoiGc
 HcLxqXLl/lv3gKBvXCAS7KA51mCuCGCPiRAXT20jGIig071SSmVYZMhsfFTwJaH6BJaeXHAgvi
 sSJvamhyi/fS8H6J8q74cpubONG7vtkUnYXT+vadnte1+lfJvZVaYoi1tnhZKU5E317av5XEk1
 0O1rusHDlibTtAAAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795887352; l=1257;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=dJGnmVJGpSJaB86690jlc2NnembJd/VR2+GSpaAGP1c=;
 b=F6GLmg1EGyXRb9oUOc0xusNvvZCBujsLbLSA5KQe/uDZGRfNSoVrU5kZIhF25a4Xfag2E3IBk
 Kw5yGqSEUQRDtGMbDWNykmFcCaUccclorEgBgMwj3YpAQonIJTqD0tt
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
Changes in v2:
- 1/2: commit message: only the IOMMU path is affected (Jernej).
- 2/2: add Jernej's Reviewed-by.
- Rebase on media-committers next.
- Link to v1: https://patch.msgid.link/20261119-b4-cedrus-generic-fixes-v1-0-f9f50812c85b@gmail.com

---
Arun Iyengar (2):
      media: cedrus: fail buffer allocations that do not fit with -ENOMEM
      media: cedrus: report only the picture as capture payload

 drivers/staging/media/sunxi/cedrus/cedrus_video.c | 13 +++++++++++--
 1 file changed, 11 insertions(+), 2 deletions(-)
---
base-commit: fb8b2c10a588f1384b98280b1c32307da9db4747
change-id: 20261114-b4-cedrus-generic-fixes-8ce71c2dafd5

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

