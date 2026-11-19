From: Ahmed Abdelfattah <me@ahmedabdelfattah.dev>
Date: Thu, 19 Nov 2026 20:35:25 +0200
Subject: [PATCH] ACPI: APEI: Don't disable HEST for a disabled IA-32 CMC
 structure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-acpi-hest-cmc-disabled-v1-1-87644a1bf0ca@ahmedabdelfattah.dev>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBBA0avIrDtgIlXrVYqLZDLWKa1KRkUQ7
 95ol2/x/w7KUVihyXaIvIrKOCSYWwbUu+HFKCEZbG5LY8wDHU2CPeuM9CUMos5/OGAgV1Tlvau
 tryHFU+ROtmv8bP/Wxb+Z5vMGx/ED4XwbL3oAAAA=
X-Change-ID: 20261119-acpi-hest-cmc-disabled-dca3765f82b8
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Tony Luck <tony.luck@intel.com>, Borislav Petkov <bp@alien8.de>, 
 Hanjun Guo <guohanjun@huawei.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Shuai Xue <xueshuai@linux.alibaba.com>, Len Brown <lenb@kernel.org>, 
 Will Deacon <will@kernel.org>
Cc: linux-acpi@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Ahmed Abdelfattah <me@ahmedabdelfattah.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795113327; l=2913;
 i=me@ahmedabdelfattah.dev; s=20261106; h=from:subject:message-id;
 bh=tT5kjIxpoyje3RI718C4NeyvvkC2yB2rkjIZMzaQ/gs=;
 b=DU7PcSDgrwAM011pR5s8vkBX9zEaLMl9JFtCT393FbK3ZkuiuosNuZnn4fhM6SckqGcdVHoJd
 YqjzT/HskosDNPbD9y7pts1YxsN5tG16XFKJsVcqDBgkL3PFbUUEqYn
X-Developer-Key: i=me@ahmedabdelfattah.dev; a=ed25519;
 pk=DHEHKU4PddrkJ/iYMZpwyyXsFyIQ6ySjTttKLrt9YqI=
X-Endpoint-Received: by B4 Relay for me@ahmedabdelfattah.dev/20261106 with auth_id=1438
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On x86, a HEST whose IA-32 Architecture Corrected Machine Check
structure has Enabled = 0 makes acpi_hest_init() give up on the whole
table. hest_disable is set to HEST_DISABLED, no GHES device is
registered, and every other error source in the table is ignored. The
only trace of it is "GHES: HEST is not enabled!".

arch_apei_enable_cmcff() returns 0 for a disabled structure and 1
otherwise. hest_parse_cmc() returns the negation, so a disabled
structure stops apei_hest_parse() with 1, which acpi_hest_init() takes
as an error. Enabled = 0 is a valid value: ACPI 6.5, Table 18.5, says
that the error source is then not to be enabled. It does not make the
table invalid.

Before commit 9f9a35a7b654 ("ACPI / APEI / ARM64: APEI initial support
for ARM64"), the result of this walk was ignored. That commit inverted
the callback's return value and started checking the result.

There is nothing to report from hest_parse_cmc(), and the spec allows
only one structure of this type, so ignore the return value of
arch_apei_enable_cmcff() and let the walk go on.

Fixes: 9f9a35a7b654 ("ACPI / APEI / ARM64: APEI initial support for ARM64")
Cc: stable@vger.kernel.org
Signed-off-by: Ahmed Abdelfattah <me@ahmedabdelfattah.dev>
---
I hit this with a hand-built HEST in a QEMU guest: clearing Enabled in
its IA-32 Corrected Machine Check structure also took away the generic
error source next to it.

Tested on v7.4-rc3+ (4405c18c95d2) with a HEST loaded through
-acpitable that holds two error sources, an IA-32 CMC structure
(FIRMWARE_FIRST, bank 8) and a polled GHESv2:

  CMC structure   without the patch               with it
  Enabled = 1     HEST initialized, "Enabling     the same
                  Firmware First mode for
                  corrected errors", GHES.1 bound
  Enabled = 0     "GHES: HEST is not enabled!",   HEST initialized,
                  no GHES device                  GHES.1 bound
  Enabled = 0,    HEST initialized, GHES.1        the same
  acpi=nocmcff    bound

Every boot also prints "GHES: Failed to enable APEI firmware first
mode", because the guest's firmware has no APEI _OSC; that is the same
with and without the patch.
---
 drivers/acpi/apei/hest.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/acpi/apei/hest.c b/drivers/acpi/apei/hest.c
index 20d757687e3d..881dd0b25939 100644
--- a/drivers/acpi/apei/hest.c
+++ b/drivers/acpi/apei/hest.c
@@ -185,7 +185,7 @@ static int __init hest_parse_cmc(struct acpi_hest_header *hest_hdr, void *data)
 		return 0;
 
 	if (!acpi_disable_cmcff)
-		return !arch_apei_enable_cmcff(hest_hdr, data);
+		arch_apei_enable_cmcff(hest_hdr, data);
 
 	return 0;
 }

---
base-commit: 4405c18c95d2d0f99f6c581ef0ee8591a1aa6ccd
change-id: 20261119-acpi-hest-cmc-disabled-dca3765f82b8

Best regards,
--  
Ahmed Abdelfattah <me@ahmedabdelfattah.dev>

