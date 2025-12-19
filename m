From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH v2 0/6] iio: buffer-dma: Minor cleanups and improvements
Date: Fri, 19 Dec 2025 15:28:11 +0000
Message-Id: <20251219-iio-dmabuf-improvs-v2-0-caa76de6e873@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAtvRWkC/22NQQ6CMBBFr0Jm7ZjpUAVceQ/DokCBSYSSVhsN4
 e5W3Lp8L/nvrxCsFxvgkq3gbZQgbk7Ahwza0cyDRekSAxOflCKNIg67yTTPHmVavIsBKe8qzVz
 qpjxDGi7e9vLao7c68Sjh4fx7/4jqa385pvxfLiokJKsrKlpb5MxXM5u7G46tm6Detu0DoKqoV
 7UAAAA=
X-Change-ID: 20251104-iio-dmabuf-improvs-03d942284b86
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1766158092; l=1574;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=kDT4GASbwzi4yQXRWZBEF6knm2Xzp3O0z7UDIsKWgPg=;
 b=Dgkk/W415qIeM6iV3WycUKrnzASz1vjIQ31Fm5DCxgOUU5e7T7Fyx7wAgn1GfJDGj2AlgMZub
 kY9rS+7F5wjDLVkJ97zZZlQzbLVmXwg/kByzt/Vm9qkljFa1cy5XnI9
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Small series with some minor improvements for IIO DMA buffers:
 * Use lockdep instead of WARN() + mutex API;
 * Use cleanup.h;
 * Turn iio_dma_buffer_init() void;
 * And I could not resist in cleaning up coding style.

Also note that in some of the coding style cleanups I deliberately went
above the 80 col limit as I think it otherwise hurts readability. If not
the case for everyone, I can change it.

---
Changes in v2:
- Patch 1
  * Updated the commit subject and message (given that lockdep also WARNs()) 
- Patch 2
  * Slight change on the 80 column limit when allocating the block
    (Jonathan expressed preference on that form).
- Patch 4
  * Updated mutex/spinlock comments according Andy feedback.
- Link to v1: https://lore.kernel.org/r/20251203-iio-dmabuf-improvs-v1-0-0e4907ce7322@analog.com

---
Nuno Sá (6):
      iio: buffer-dma: Use lockdep for locking annotations
      iio: buffer-dma: Use the cleanup.h API
      iio: buffer-dma: Turn iio_dma_buffer_init() void
      iio: buffer-dma: Fix coding style complains
      iio: buffer-dmaengine: Use the cleanup.h API
      iio: buffer-dmaengine: Fix coding style complains

 drivers/iio/buffer/industrialio-buffer-dma.c       | 187 +++++++++------------
 drivers/iio/buffer/industrialio-buffer-dmaengine.c |  22 +--
 include/linux/iio/buffer-dma.h                     |  20 ++-
 3 files changed, 97 insertions(+), 132 deletions(-)
---
base-commit: c5411c8b9ed1caf53604bb1a5be3f487988efc98
change-id: 20251104-iio-dmabuf-improvs-03d942284b86
--

Thanks!
- Nuno Sá

