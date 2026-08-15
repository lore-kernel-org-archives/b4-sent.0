From: Junrui Luo <moonafterrain@outlook.com>
Subject: [PATCH 0/4] media: fix four memory-safety bugs in vicodec and
 v4l2-mem2mem
Date: Sat, 15 Aug 2026 22:56:34 +0800
Message-Id: <20260815-vicodec-fixes-v1-0-12101572eba7@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACJ+gGoC/x3LQQqAIBBA0avErBMcTYmuEi1Ep5qNhoIE4t2Tl
 o/Pb1AoMxXYpgaZKhdOcQDnCfzt4kWCwzAoqaxc0YjKPgXy4uSXirBSOkSjtV4QxvNk+sNY9qP
 3D+WX4RZfAAAA
X-Change-ID: 20260815-vicodec-fixes-600a11533341
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Hans Verkuil <hverkuil@kernel.org>, 
 Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 Dafna Hirschfeld <dafna3@gmail.com>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Mauro Carvalho Chehab <mchehab+samsung@kernel.org>, 
 Junrui Luo <moonafterrain@outlook.com>, Yuhao Jiang <danisjiang@gmail.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1728;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=A/OHJ9zYmscv3Q/pEhjmGIVnvixUXEumJLOP0slecFA=;
 b=owJ4nJvAy8zAJVb4wiKgu++DA+NptSSGrIY61XThyTOXaLilxwZN+i+14OYJ/obLm/SWJFz7Y
 XeZ7YC+yPaOUhYGMS4GWTFFluMFl75Z+G7R3eKzJRlmDisTyBAGLk4BmMjVp4wMS0MUZ2qe3j35
 WNjs8wqCnYF+ZaoyP7y0hZt4/dZbR9nzMPzTftZaUn2yInOXkOuC8v7K1ssp5xqnLbzgzmD32aB
 R8AMTAPGcSDg=
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Four independent fixes found while auditing the vicodec codec paths.
Each is reachable from unprivileged userspace and was reproduced under
KASAN in QEMU.

  1  v4l2-mem2mem: VIDIOC_REMOVE_BUFS is not serialized against job
     execution and can free a buffer an in-flight decode is still
     reading -- use-after-free of a stateless decoder's reference frame.

  2  vicodec: vic_round_dim() rounds only the chroma plane, so a
     dimension one past a multiple of 16 yields a coded size one 8x8
     block short of what the codec walks.

  3  vicodec: S_FMT never clamps the visible dimensions, so shrinking the
     CAPTURE format leaves visible > coded and the decoder runs off the
     end of the capture buffer.

  4  vicodec: the encoder's CAPTURE width and height are settable
     independently of the OUTPUT format, letting the encoder write into a
     buffer far too small for the frame it produces.

Signed-off-by: Junrui Luo <moonafterrain@outlook.com>
---
Junrui Luo (4):
      media: v4l2-mem2mem: serialize REMOVE_BUFS with job execution
      media: vicodec: fix out-of-bounds write on under-rounded coded dimensions
      media: vicodec: clamp visible dimensions on S_FMT to coded bounds
      media: vicodec: make encoder CAPTURE dimensions read-only

 drivers/media/test-drivers/vicodec/codec-fwht.h   |  2 +-
 drivers/media/test-drivers/vicodec/vicodec-core.c | 15 ++++++
 drivers/media/v4l2-core/v4l2-mem2mem.c            | 60 +++++++++++++++++++++--
 3 files changed, 72 insertions(+), 5 deletions(-)
---
base-commit: f5bbbfec59b4e2fb7520a91de3df8a6174325d6a
change-id: 20260815-vicodec-fixes-600a11533341

Best regards,
-- 
Junrui Luo <moonafterrain@outlook.com>

