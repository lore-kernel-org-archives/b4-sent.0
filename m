From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH RFC 0/3] dmaengine: Support address bus widths of 32 bytes
 and above
Date: Tue, 16 Jun 2026 16:40:51 +0100
Message-Id: <20260616-dmaengine-support-wider-dma-masks-v1-0-da23a8dcb756@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWNywrCMBAAf6Xs2YUm2Ba9Cn6AV/GwJmtdpWnI9
 iGU/rupHmcOMwsoJ2GFY7FA4klU+pDB7ApwTwoto/jMYEtbl7Wp0HfEoZXAqGOMfRpwFs9p89i
 RvhUrImfs/tCwbSB3YuKHfH6PK1zOJ7j9pY73F7thq8O6fgGmfC+IigAAAA==
X-Change-ID: 20260615-dmaengine-support-wider-dma-masks-5aac12497e27
To: dmaengine@vger.kernel.org, linux-iio@vger.kernel.org
Cc: Vinod Koul <vkoul@kernel.org>, Frank Li <Frank.Li@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781624455; l=3227;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=+QIasRBIyKP+WO6TXZ4SAPt7bwYYwVLv6m09mqd7suk=;
 b=tmf6UE3hfFI9WDOrUkRnTII+gZl3A+Vv7vcWdbRAns06aGK8bkU1u75Fgv3aTUwKERpKBz1vT
 6OwhDyHlp6tAkBYJavrwXTdFMq+JocGbj3yAVY8J96Qm/9RwqSIdw9p
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The DMA engine slave capabilities advertise the supported source and
destination bus widths in src_addr_widths / dst_addr_widths. These are
plain u32 bitmasks where a set bit's position equals the corresponding
enum dma_slave_buswidth value, e.g. DMA_SLAVE_BUSWIDTH_4_BYTES sets
bit 4.

The consequence is that widths of 32 bytes and above cannot be
represented at all: DMA_SLAVE_BUSWIDTH_32/64/128_BYTES would need bits
32, 64 and 128, which simply do not fit in a u32. Hardware with wider
data paths is becoming common, so we need a representation that can
express these widths while still using enum dma_slave_buswidth.

This series switches the masks to bitmaps that span the full enum
range. Because there are many producers (DMA controllers) and a number
of consumers spread across the tree, converting everything in one go is
not realistic. To allow an incremental migration, the legacy u32 fields
are kept alongside the new bitmaps:

- producers set the bitmap via the new dma_set_{src,dst}_addr_mask()
helpers, which also mirror the low 32 bits back into the legacy u32;
- legacy producers that still assign the u32 directly keep working, and
dma_get_slave_caps() folds such a u32 into the bitmap it returns, so
new consumers always see a complete bitmap;
- consumers can read either the legacy u32 or the new bitmap during the
transition.

The axi-dmac controller and the IIO dmaengine buffer are converted as
examples of a producer and a consumer. And this actually fixes a very
open coded path to undefined behavior in the axi-dmac driver and
possibly others.

The end goal is to convert every producer and consumer, then drop the
legacy u32 src/dst_addr_widths fields and rename the *_mask members.
I cannot commit to a timeline for that conversion (it touches a lot of
drivers across several subsystems), but I do intend to see it through.

Sending as RFC mainly to agree on the approach!

I'm also not sure if the dma_slave_caps_get_{src,dst}_width_min() accessors
are worth having? Their purpose is purely to keep consumers from touching
the representation directly, so that the eventual u32 removal + mask
rename is a no-op for consumers. The alternative is to let consumers use
the bitmap directly (find_first_bit()/test_bit()/etc.) and just delete the
u32 members at the end. I mean, now we do have a bitmask so the _mask
suffix can of makes sense.

This issue was discussed before here:

https://lore.kernel.org/dmaengine/abkoXXbaxaiqbBuX@vaman/

---
Nuno Sá (3):
      dmaengine: Support address bus widths of 32 bytes and above
      dmaengine: dma-axi-dmac: Switch to bitmap-based address width masks
      iio: buffer-dmaengine: Use dma_slave_caps width accessors

 drivers/dma/dma-axi-dmac.c                         |  12 ++-
 drivers/dma/dmaengine.c                            |  18 ++++
 drivers/iio/buffer/industrialio-buffer-dmaengine.c |  15 ++--
 include/linux/dmaengine.h                          | 100 ++++++++++++++++++++-
 4 files changed, 129 insertions(+), 16 deletions(-)
---
base-commit: 7524fe142b5a772f8421aeee2132cf7e21a00103
change-id: 20260615-dmaengine-support-wider-dma-masks-5aac12497e27
--

Thanks!
- Nuno Sá

