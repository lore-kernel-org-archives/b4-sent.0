From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH v2 0/3] iio: buffer: Fix DMABUF mapping in some systems
Date: Mon, 06 Oct 2025 17:06:31 +0100
Message-Id: <20251006-fix-iio-dmabuf-get-dma-device-v2-0-d960bc9084da@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAfp42gC/4WNQQ6CMBBFr2Jm7ZhpCzF15T0Mi9IOMIlQ0yLRE
 O5u4QLu/vvJf3+FzEk4w+20QuJFssSpgD6fwA9u6hklFAZNuiZrCDv5oEjEMLr23WHP8x4xlK1
 nNMY6f6W6MqGF4nglLoPD/2gKD5LnmL7H3aL29jArIv3HvCgk9MpbW9WkbaC7m9wz9hcfR2i2b
 fsBRStkD8sAAAA=
X-Change-ID: 20250930-fix-iio-dmabuf-get-dma-device-339ac70543db
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1759766793; l=2563;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=2HriaveKNvlAzz3g9JtDTugyDiYrNXDtfRXTc0G9D3Q=;
 b=N2ZYoKriYdqN0yWcMcoNXHfWYxYeXBT5vn5REZAoZzOctVbo3a8+ikEEI/CA78oWX0ljOgLoX
 YZvKMQ6gHPDAIjZhUJSRYRMASaYP+tRGcFJXw0xwyYRXvD1zbfIKSSG
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series fixes an issue with DMABUF support in the IIO subsystem where
the wrong DMA device could be used for buffer mapping operations. This
becomes critical on systems like Xilinx/AMD ZynqMP Ultrascale where memory
can be mapped above the 32-bit address range.

Problem:
--------
The current IIO DMABUF implementation assumes it can use the parent device
of the IIO device for DMA operations. However, this device may not have
the appropriate DMA mask configuration for accessing high memory addresses.
On systems where memory is mapped above 32-bits, this leads to the use of
bounce buffers through swiotlb, significantly impacting performance.

Solution:
---------
This series introduces a new .get_dma_dev() callback in the buffer access
functions that allows buffer implementations to specify the correct DMA
device that should be used for DMABUF operations. The DMA buffer
infrastructure implements this callback to return the device that actually
owns the DMA channel, ensuring proper memory mapping without bounce buffers.

Changes:
--------
1. Add .get_dma_dev() callback to iio_buffer_access_funcs and update core
   DMABUF code to use it when available
2. Implement the callback in the DMA buffer infrastructure
3. Wire up the callback in the dmaengine buffer implementation

This ensures that DMABUF operations use the device with the correct DMA
configuration, eliminating unnecessary bounce buffer usage and improving
performance on high-memory systems.

(AI generated cover. I would not be this formal but I guess is not
that bad :))

---
Changes in v2:
- Dropped Fixes tags on the first two patches and Cc stable them instead
  (as prerequisites for the third patch). 
- Link to v1: https://lore.kernel.org/r/20251002-fix-iio-dmabuf-get-dma-device-v1-0-c1c9945029d0@analog.com

---
Nuno Sá (3):
      iio: buffer: support getting dma channel from the buffer
      iio: buffer-dma: support getting the DMA channel
      iio: buffer-dmaengine: enable .get_dma_dev()

 drivers/iio/buffer/industrialio-buffer-dma.c       |  6 +++++
 drivers/iio/buffer/industrialio-buffer-dmaengine.c |  2 ++
 drivers/iio/industrialio-buffer.c                  | 28 +++++++++++++++++-----
 include/linux/iio/buffer-dma.h                     |  1 +
 include/linux/iio/buffer_impl.h                    |  2 ++
 5 files changed, 33 insertions(+), 6 deletions(-)
---
base-commit: b9700f87939f0f477e5c00db817f54ab8a97702b
change-id: 20250930-fix-iio-dmabuf-get-dma-device-339ac70543db
--

Thanks!
- Nuno Sá

