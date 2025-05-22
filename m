From: Aaron Kling <webgeek1234@gmail.com>
Date: Thu, 22 May 2025 11:11:24 -0500
Subject: [PATCH] ARM: tegra: Use io memcpy to write to iram
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250522-mach-tegra-kasan-v1-1-419041b8addb@gmail.com>
X-B4-Tracking: v=1; b=H4sIAKtML2gC/x2MQQqAMAzAviI9W9CKIn5FPNTZbUWcsokI4t8dH
 kNIHkgSVRIMxQNRLk26hwx1WYDxHJygLpmBKmqrlgg3Nh5PcZFx5cQBLc9Llo2lroecHVGs3v9
 ynN73A1jjFBdiAAAA
X-Change-ID: 20250522-mach-tegra-kasan-fabd0253f268
To: Russell King <linux@armlinux.org.uk>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-arm-kernel@lists.infradead.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747930286; l=1106;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=hU2Yl0x61OcdReq0QPOKVTLdxOPyeKujmiktaOo9ip0=;
 b=+CjK5VVg+heemutBNUgW5ZgTFi1GM58YOUfxw5ahL0xfg7exDr03GfcypGLgflQH1UbQahdYf
 mcrxHC7m+mzAOsRFSKYDE1V/wZ1CtL+lOYdb9zBf6HZy+SnO69xWWEV
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Kasan crashes the kernel trying to check boundaries when using the
normal memcpy.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Change-Id: I27714f45aa6aea6a7bee048f706b14b8c7535164
---
 arch/arm/mach-tegra/reset.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm/mach-tegra/reset.c b/arch/arm/mach-tegra/reset.c
index d5c805adf7a82b938bebd8941eae974cf6bcdbe3..ea706fac63587a393a17fe0f1c2ad69d6e5c14f2 100644
--- a/arch/arm/mach-tegra/reset.c
+++ b/arch/arm/mach-tegra/reset.c
@@ -63,7 +63,7 @@ static void __init tegra_cpu_reset_handler_enable(void)
 	BUG_ON(is_enabled);
 	BUG_ON(tegra_cpu_reset_handler_size > TEGRA_IRAM_RESET_HANDLER_SIZE);
 
-	memcpy(iram_base, (void *)__tegra_cpu_reset_handler_start,
+	memcpy_toio(iram_base, (void *)__tegra_cpu_reset_handler_start,
 			tegra_cpu_reset_handler_size);
 
 	err = call_firmware_op(set_cpu_boot_addr, 0, reset_address);

---
base-commit: d608703fcdd9e9538f6c7a0fcf98bf79b1375b60
change-id: 20250522-mach-tegra-kasan-fabd0253f268

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

