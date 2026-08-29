From: Tobias Jakobsen <tjakobsen84@protonmail.com>
Date: Sat, 29 Aug 2026 03:04:33 +0200
Subject: [PATCH 2/2] spi: spi-intel: report controller enforced write
 protection
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260829-spi-nor-platform-lock-v1-2-cd362d4914e2@protonmail.com>
References: <20260829-spi-nor-platform-lock-v1-0-cd362d4914e2@protonmail.com>
In-Reply-To: <20260829-spi-nor-platform-lock-v1-0-cd362d4914e2@protonmail.com>
To: Pratyush Yadav <pratyush@kernel.org>, Michael Walle <mwalle@kernel.org>, 
 Takahiro Kuwano <takahiro.kuwano@infineon.com>, 
 Miquel Raynal <miquel.raynal@bootlin.com>, 
 Richard Weinberger <richard@nod.at>, Vignesh Raghavendra <vigneshr@ti.com>, 
 Mark Brown <broonie@kernel.org>
Cc: Mika Westerberg <mika.westerberg@linux.intel.com>, 
 linux-mtd@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-spi@vger.kernel.org, Tobias Jakobsen <tjakobsen84@protonmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787965476; l=3457;
 i=tjakobsen84@protonmail.com; s=20260829; h=from:subject:message-id;
 bh=gtEEAKizpcnWW1tUrFGFb4Gr6XQwi2idSgfJOzM3heg=;
 b=NKpDKeAa95+S/284Or3ncZbzcN15LrGx+vzGVdClOGc8pkjWpxqzTfoSd/t2Xh3BYsdjWFifP
 ZKP2wx74Y9TDUGvCbybWdMm80iFd8N0wmmI0YnQGudh7Ex0EkMAjC9u
X-Developer-Key: i=tjakobsen84@protonmail.com; a=ed25519;
 pk=UREd6cisfwsFIDP455nUH6Ysx+ZDGnAVE9nGmKzm1Ks=
X-Endpoint-Received: by B4 Relay for tjakobsen84@protonmail.com/20260829 with auth_id=986
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On Intel PCH platforms write protection is enforced by the controller's
protected range registers, not by the flash chip's block protection
bits, which are typically left clear. The SPI MEM conversion left
spi-intel without visibility of the MTD device, so it cannot supply MTD
locking operations directly.

Pass a write protection query through struct flash_platform_data, which
spi-intel already uses to hand the partition layout to spi-nor.

Note this asks the opposite question to intel_spi_is_protected(): rather
than whether a flash region contains a protected range, it asks whether
the queried range is itself entirely covered by one, which is what the
MTD layer means by locked.

Tested on a Coffee Lake i5 with PR0 covering 0x860000-0xffffff and
FLOCKDN set, querying MEMISLOCKED over four ranges:

                               PR0 range  whole chip  in PR0  below PR0
  unpatched                       -95        -95       -95      -95
  chip lock flags only              0          0         0        0
  patched, no chip lock flags       1          0         1        0
  patched + chip lock flags         1          0         1        0

The whole chip and below-PR0 columns stay unlocked because only
0x860000-0xffffff is covered by a protected range.

Link: https://bugzilla.kernel.org/show_bug.cgi?id=221927
Signed-off-by: Tobias Jakobsen <tjakobsen84@protonmail.com>
---
 drivers/spi/spi-intel.c | 46 ++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 46 insertions(+)

diff --git a/drivers/spi/spi-intel.c b/drivers/spi/spi-intel.c
index 7494b921a..667291979 100644
--- a/drivers/spi/spi-intel.c
+++ b/drivers/spi/spi-intel.c
@@ -1223,6 +1223,46 @@ static bool intel_spi_is_protected(const struct intel_spi *ispi,
 	return false;
 }
 
+/*
+ * Unlike intel_spi_is_protected(), which asks whether a flash region contains
+ * any protected range, this asks the opposite: whether the given range is
+ * itself entirely covered by a write protected range. That is what the MTD
+ * layer means by "locked".
+ */
+static bool intel_spi_is_range_protected(const struct intel_spi *ispi,
+					 unsigned int base, unsigned int limit)
+{
+	int i;
+
+	for (i = 0; i < ispi->pr_num; i++) {
+		u32 pr_base, pr_limit, pr_value;
+
+		pr_value = readl(ispi->pregs + PR(i));
+		if (!(pr_value & PR_WPE))
+			continue;
+
+		pr_limit = (pr_value & PR_LIMIT_MASK) >> PR_LIMIT_SHIFT;
+		pr_base = pr_value & PR_BASE_MASK;
+
+		if (base >= pr_base && limit <= pr_limit)
+			return true;
+	}
+
+	return false;
+}
+
+static int intel_spi_is_locked(struct spi_device *spi, loff_t ofs, u64 len)
+{
+	struct intel_spi *ispi = spi_controller_get_devdata(spi->controller);
+
+	if (!len)
+		return 0;
+
+	/* Protected range registers work in 4k units */
+	return intel_spi_is_range_protected(ispi, ofs >> 12,
+					    (ofs + len - 1) >> 12);
+}
+
 /*
  * There will be a single partition holding all enabled flash regions. We
  * call this "BIOS".
@@ -1395,6 +1435,12 @@ static int intel_spi_populate_chip(struct intel_spi *ispi)
 
 	intel_spi_fill_partition(ispi, pdata->parts);
 
+	/*
+	 * The protected range registers address the first chip, so only it can
+	 * be queried this way.
+	 */
+	pdata->is_locked = intel_spi_is_locked;
+
 	memset(&chip, 0, sizeof(chip));
 	snprintf(chip.modalias, 8, "spi-nor");
 	chip.platform_data = pdata;

-- 
2.53.0

