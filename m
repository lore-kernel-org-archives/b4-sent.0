From: Mateusz Litwin <mateusz.litwin@nokia.com>
Subject: [PATCH RFC 0/3] mtd: spi-nor: allow multiple erase sizes on
 uniform flashes
Date: Mon, 20 Jul 2026 17:12:37 +0200
Message-Id: <20260720-spi_nor_multisize_erase-v1-0-38d719bfe77b@nokia.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOU6XmoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDcyMD3eKCzPi8/KL43NKcEqDqqtT41KLE4lTdFDMTk+S0FJNE07QkJaD
 ugqLUtMwKsMnRSkFuzkqxtbUA0Bza/W4AAAA=
X-Change-ID: 20260720-spi_nor_multisize_erase-d644cfd4a5fb
To: Pratyush Yadav <pratyush@kernel.org>, Michael Walle <mwalle@kernel.org>, 
 Takahiro Kuwano <takahiro.kuwano@infineon.com>, 
 Miquel Raynal <miquel.raynal@bootlin.com>, 
 Richard Weinberger <richard@nod.at>, Vignesh Raghavendra <vigneshr@ti.com>
Cc: linux-mtd@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Mateusz Litwin <mateusz.litwin@nokia.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784560422; l=5636;
 i=mateusz.litwin@nokia.com; s=20251217; h=from:subject:message-id;
 bh=6wOusxj+XRYlBiC+sGkaeefQm/+5jioo6ge9/BEVVpY=;
 b=t/840G3ZyvXGj6ZT/PGBjHLiPZd7BPqBSGEqBfUFI9fhmGTJkruhaQskaGaYb9D2YWZmlOe4y
 TC1tDFoP1UuAh2J8Qhp6xV3fgkfCctgwr+pe74YJkNwhhQnhKRW0i7+
X-Developer-Key: i=mateusz.litwin@nokia.com; a=ed25519;
 pk=9NV76cwWrtwYUektOrK/ht9GTzmhtkqSvghr3Td4hM4=
X-Endpoint-Received: by B4 Relay for mateusz.litwin@nokia.com/20251217 with auth_id=579
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Most SPI NOR flashes advertise several erase sizes (e.g. 4 KiB, 32 KiB and
64 KiB) even when the erase map is uniform across the whole device.  The
spi-nor driver currently collapses such flashes to a single erase size and
uses only that size for every erase request.

This is a problem on platforms that need a small exposed erasesize for
partition alignment (for example u-boot-env, RouterBoot soft_config, or
boot header partitions) while still wanting fast bulk erases.  Today the
usual workaround is to enable MTD_SPI_NOR_USE_4K_SECTORS, which forces 4 KiB
erases for the entire device and hurts erase performance on large regions.

This series introduces MTD_SPI_NOR_MULTI_ERASE_SIZE.  When enabled, uniform
flashes keep multiple erase sizes in the driver erase map and pick the
largest suitable erase size for each step of an erase operation, similar to
what non-uniform flashes already do.  Userspace still sees a single
mtd->erasesize (4 KiB when MTD_SPI_NOR_USE_4K_SECTORS is also enabled), but
large aligned portions of an erase request can use 32 KiB or 64 KiB erase
commands internally.

The series also converts all erase-type opcodes to their 4-byte-address
variants on uniform flashes, so multi-size erases work correctly on devices
larger than 16 MiB.

This is an RFC series. Feedback is especially welcome on whether to merge
patch 1 alone, patches 1+2, or the full series including the patch 3 PoC.

The series is stacked so maintainers can choose how much to take:

  - Patch 1 adds the Kconfig option, keeps multiple erase types in the
    uniform region mask, and converts all erase-type opcodes for 4-byte
    addressing.  On its own it routes multi-size uniform erases through
    spi_nor_erase_multi_sectors().
  - Patch 2 replaces that routing with a dedicated uniform erase flow
    (spi_nor_erase_uniform()), reducing CPU and memory overhead.
  - Patch 3 is a proof-of-concept optimization on top of patch 2: it
    caches the largest uniform erase type per request to skip redundant
    spi_nor_find_best_erase_type() calls in bulk-aligned regions.

Patch 1 follows an OpenWrt pending patch already used in production:

https://github.com/openwrt/openwrt/blob/main/target/linux/generic/pending-6.12/402-mtd-spi-nor-write-support-for-minor-aligned-partitions.patch

MTD_SPI_NOR_MULTI_ERASE_SIZE defaults to N, so existing configurations are
unaffected.

Tested: backported to a 6.6-based tree on Micron MT25QU02G with
MTD_SPI_NOR_MULTI_ERASE_SIZE enabled and MTD_SPI_NOR_USE_4K_SECTORS
disabled (mtd->erasesize reports 64 KiB).  librsu erases the flash with
the MEMERASE ioctl on the MTD character device, issuing erase requests
smaller than mtd->erasesize (e.g. a 32 KiB boot header region).
mtd_erase() does not enforce erasesize alignment, so these requests reach
the driver, where the previous uniform path rejected them; they now
succeed through spi_nor_is_uniform_erasable() and the multi-size erase
path.  Verified writes and erases on the 32 KiB region.

A few implementation details are worth discussing:

1. The previous uniform erase path only required the length to be a
   multiple of mtd->erasesize.  With MTD_SPI_NOR_MULTI_ERASE_SIZE enabled,
   spi_nor_is_uniform_erasable() instead checks the address and length
   against the smallest supported uniform erase size.  Requests aligned to
   mtd->erasesize still pass (it is a multiple of that size), while
   callers may now issue erases smaller than mtd->erasesize, as the tested
   librsu path does.  Misaligned requests are rejected rather than
   relying on undefined behavior; please report any regressions.

2. Patch 3 addresses per-step spi_nor_find_best_erase_type() overhead.
   As a PoC it may be dropped, revised, or split out depending on
   maintainer feedback.

3. Patch 3 calculates the largest erase size on every request.  This could
   be done once at init.  The same applies to the smallest erase size used
   for request validation.  Where to store that data is open for
   discussion if such a change is needed.

4. spansion_nor_late_init() overrides nor->erase_opcode (and mtd->erasesize)
   for flashes larger than 16 MiB.  With MTD_SPI_NOR_MULTI_ERASE_SIZE enabled,
   spi_nor_erase_uniform() sets nor->erase_opcode before each erase, so the
   late_init value is not used on the erase path.  If the SFDP table masks
   unsupported erase types in 4-byte-address mode, this is not an issue;
   otherwise late_init() or erase-type masking may need changes for
   Cypress/Spansion parts.

5. Some flashes do not support every erase type with 4-byte-address opcodes.
   Unsupported types are masked by clearing erase_type[].size, but the
   corresponding erase_mask bit is not cleared.  Erases work correctly, but
   debugfs can show a set bit in the sector-map erase mask for a type that is
   not listed under "erase commands".  Fixing that is probably best done in
   a separate patch.

Signed-off-by: Mateusz Litwin <mateusz.litwin@nokia.com>
---
Mateusz Litwin (3):
      mtd: spi-nor: allow multiple erase sizes on uniform flash
      mtd: spi-nor: add dedicated multi-size uniform erase path
      mtd: spi-nor: skip erase type search in uniform bulk erase

 drivers/mtd/spi-nor/Kconfig |  25 +++++
 drivers/mtd/spi-nor/core.c  | 247 +++++++++++++++++++++++++++++++++-----------
 2 files changed, 213 insertions(+), 59 deletions(-)
---
base-commit: df415c5e1de0f1aeefacb4e6252ff98d38c04437
change-id: 20260720-spi_nor_multisize_erase-d644cfd4a5fb

Best regards,
-- 
Mateusz Litwin <mateusz.litwin@nokia.com>

