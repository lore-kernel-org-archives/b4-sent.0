From: Jihan LIN <linjh22s@gmail.com>
Subject: [PATCH RFC 0/3] zram: Allow zcomps to manage their own streams
Date: Wed, 04 Feb 2026 13:48:50 +0000
Message-Id: <20260204-b4_zcomp_stream-v1-0-35c06ce1d332@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEJOg2kC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDIKGbZBJflZyfWxBfXFKUmpira55qmWZuYWGSamhkoQTUVVCUmpZZATY
 xWinIzVkptrYWAHqm2bFmAAAA
X-Change-ID: 20260202-b4_zcomp_stream-7e9f7884e128
To: Minchan Kim <minchan@kernel.org>, 
 Sergey Senozhatsky <senozhatsky@chromium.org>, Jens Axboe <axboe@kernel.dk>
Cc: linux-kernel@vger.kernel.org, linux-block@vger.kernel.org, 
 Jihan LIN <linjh22s@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770212935; l=3744;
 i=linjh22s@gmail.com; s=linjh22s_machine; h=from:subject:message-id;
 bh=pc9zD6AGH0779UZk+DuKfn4l01qz37hu1Ou3/rMWP/o=;
 b=4SsG2RqijlRLSQ8Y2rIR4aTpFpmzdHPT9SqREaJPrkg9S+oH8KLUA3tOjM6z7p08YaCO/0haT
 foiz3YYYU4FAWr7+UkX43u+xl3ZpHSv+FRPi3qG6X+mPwyyqRJMA0xI
X-Developer-Key: i=linjh22s@gmail.com; a=ed25519;
 pk=MnRQAVFy1t4tiGb8ce7ohJwrN2YFXd+dA7XmzR6GmUc=
X-Endpoint-Received: by B4 Relay for linjh22s@gmail.com/linjh22s_machine with auth_id=592
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi all,

This RFC series introduces a new interface to allow zram compression
backends to manage their own streams, in addition to the existing
per-CPU stream model.

Current zram manages compression contexts via preemptive per-CPU
streams, which strictly limits concurrency to the number of online CPUs. 
In contrast, hardware accelerators specialized for page compression
generally process PAGE_SIZE payloads (e.g. 4K) using standard
algorithms. These devices expose the limitations of this model due to
the following features:
 - These devices utilize a hardware queue to batch requests. A typical
   queue depth (e.g., 256) far exceeds the number of available CPUs.
 - These devices are asymmetric. Submission is generally fast and
   asynchronous, but completion implies latency.
 - Some devices only support compression requests, leaving decompression
   to be handled by software.

This exposes the limitations of the current zcomp architecture, which
assumes a model where streams are inherently tied to CPU execution
contexts. This design is not flexible enough to integrate with such
backends, as it forces a one-size-fits-all model that limits the ability
to offload compression operations from CPU.

This series proposes a hybrid approach. While maintaining full backward
compatibility with existing backends, this series introduces a new set
of operations, op->{get, put}_streams(), for backends that wish to
manage their own streams. This allows the backend to handle contentions
internally and dynamically select an execution path for the acquired
streams. A new flag is also introduced to indicate this capability at
runtime. zram_write_page() now prefers streams managed by the backend if
 a bio is considered asynchronous.

Some design decisions as follows.
1. The proposed get_stream() does not take gfp_t flags to keep the
   interface minimal. By design, backends are fully responsible for
   allocation safety.
2. The default per-cpu streams now also imply synchronous path for the
   backends.
3. The recompression path currently relies on the default per-cpu
   streams. This is a trade-off, since recompression is primarily for
   memory saving, and hardware accelerators typically prioritize
   throughput over compression ratio.
4. zstrm->lock is restricted to the default per-cpu streams. Backends
   must implement internal locking if required. While currently exposed
   in struct zstrm, this mutex is an implementation detail of the
   default path. Future work may involve making the default stream
   locking mechanism opaque to the backends, ensuring they interact only
   with the necessary stream interfaces.

Although I do not have access to an Intel IAA accelerator and other
accelerators may not be generally available, this series seems to give
a good start for supporting batched asynchronous operations in zram.
The next step would be to introduce an interface that allows
non-blocking compression submission and validate its real-world
performance once such hardware accelerators become available.

Signed-off-by: Jihan LIN <linjh22s@gmail.com>
---
Jihan LIN (3):
      zram: Rename zcomp_strm_{init, free}()
      zram: Introduce zcomp-managed streams
      zram: Use zcomp-managed streams for async write requests

 drivers/block/zram/zcomp.c    | 37 ++++++++++++++++++++++++++++++-------
 drivers/block/zram/zcomp.h    | 23 +++++++++++++++++++++--
 drivers/block/zram/zram_drv.c | 28 ++++++++++++++++++++++------
 3 files changed, 73 insertions(+), 15 deletions(-)
---
base-commit: 24d479d26b25bce5faea3ddd9fa8f3a6c3129ea7
change-id: 20260202-b4_zcomp_stream-7e9f7884e128

Best regards,
-- 
Jihan LIN <linjh22s@gmail.com>

