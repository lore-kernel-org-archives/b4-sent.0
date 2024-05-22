From: Nuno Sa <nuno.sa@analog.com>
Subject: [PATCH v2 0/2] iio: adc: ad9467: use DMA safe buffer for spi
Date: Wed, 22 May 2024 14:54:04 +0200
Message-Id: <20240522-dev-ad9467-dma-v2-0-a37bec463632@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAOzqTWYC/3XMQQ7CIBCF4as0s3YMQ2mrrryH6QJhaEksGDBE0
 /TuYvcu/5e8b4XMyXOGS7NC4uKzj6GGPDRgZh0mRm9rgxRSiU70aLmgtmfVD2gXjS2RctbKwZC
 Denomdv69g7ex9uzzK6bP7hf6rX+pQkjInWnprnrFJ3fVQT/idDRxgXHbti/9de8IrQAAAA==
To: linux-iio@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1716382445; l=700;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=kHj/TPFy35RtWhBWLYKooLoEmYZNgnP3Fqp7BjpqzfA=;
 b=bLdWrJIze+rV2cn+D5fGS1FdipIVf5NjI+TG1XhUXLOwxUfC0GzYpqGf46Y2jJWPUQZqaX4rf
 mNfMyqgY4pxA2LRnDpfnvQz1iLzYayNh+qzgrGFJ1Sn+i8nyVHwTo/1
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Added a new patch to "fix" the annoying tabs alignment on struct
members. 

---
Changes in v2:
- Patch 1
  * Don't use safe buffers for reads (uses spi_write_then_read()).
- Patch 1
  * New patch.
- Link to v1: https://lore.kernel.org/r/20240506-dev-ad9467-dma-v1-1-e5c31b464e8f@analog.com

---
Nuno Sa (2):
      iio: adc: ad9467: use DMA safe buffer for spi
      iio: adc: ad9467: change struct members padding

 drivers/iio/adc/ad9467.c | 103 +++++++++++++++++++++++------------------------
 1 file changed, 50 insertions(+), 53 deletions(-)
---
base-commit: 5e3c5871138da700796587aa5f096d39135f9d36
change-id: 20240506-dev-ad9467-dma-3114fdd27c1f
--

Thanks!
- Nuno Sá

