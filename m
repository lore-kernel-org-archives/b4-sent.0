From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH 0/6] iio: buffer-dma: Minor cleanups and improvements
Date: Wed, 03 Dec 2025 15:11:35 +0000
Message-Id: <20251203-iio-dmabuf-improvs-v1-0-0e4907ce7322@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIACdTMGkC/x3MQQ5AMBBA0avIrE3SVgmuIhalg1lQmYZIGnfXW
 L7F/wkiCVOEvkggdHPkcGTosoB5c8dKyD4bjDK11soic0C/u+lakPdTwh1RVb6zxrR2ahvI4Sm
 08PNPh/F9PyfoX3hkAAAA
X-Change-ID: 20251104-iio-dmabuf-improvs-03d942284b86
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764774697; l=1154;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=YdCCeSF1SQIBqUetVexQTJcy6L84v6sNqM9xPlse8XE=;
 b=GdFk7UYClyxXmOdoZgiDH12p8FGN4MfMRO680emZKNnDVrgZo32xVT1GxdTIzL8bNTkJWq9Cj
 yncNf30XJHaDtGjO7y1peCnfz6wnESgnCz3/3XuLzBe5IK/lVFcqlWW
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
Nuno Sá (6):
      iio: buffer-dma: use lockdep instead of WARN()
      iio: buffer-dma: Use the cleanup.h API
      iio: buffer-dma: Turn iio_dma_buffer_init() void
      iio: buffer-dma: Fix coding style complains
      iio: buffer-dmaengine: Use the cleanup.h API
      iio: buffer-dmaengine: Fix coding style complains

 drivers/iio/buffer/industrialio-buffer-dma.c       | 186 +++++++++------------
 drivers/iio/buffer/industrialio-buffer-dmaengine.c |  22 +--
 include/linux/iio/buffer-dma.h                     |  20 ++-
 3 files changed, 96 insertions(+), 132 deletions(-)
---
base-commit: c5411c8b9ed1caf53604bb1a5be3f487988efc98
change-id: 20251104-iio-dmabuf-improvs-03d942284b86
--

Thanks!
- Nuno Sá

