From: Miao Wang <shankerwangmiao@gmail.com>
Date: Fri, 26 Jul 2024 17:17:53 +0800
To: loongarch@lists.linux.dev, linux-efi@vger.kernel.org
Cc: Jiaxun Yang <jiaxun.yang@flygoat.com>, Huacai Chen <chenhuacai@kernel.org>, WANG Xuerui <kernel@xen0n.name>, Ard Biesheuvel <ardb@kernel.org>
Subject: [PATCH] loongarch/reset: use general efi poweroff
Message-Id: 4113cec4-4b4a-11ef-9897-937fbcdc8b5d@innull.com
X-Developer-Signature: v=1; a=openpgp-sha256; l=1434;
 i=shankerwangmiao@gmail.com; h=from:subject:message-id;
 bh=XDs3wdvu3+QYu/+for1RcDYAw7kto4GBLMR2VGI+QJ4=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBmo5aEhzIJM0G8rZsR1UIC3sNm/MGdt3NT1aeFf
 c8TsarVlhSJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCZqOWhAAKCRCwMePKe/7Z
 bqQoD/4qq6ob78WkErORRW3NXLffROp2/L38MynBBt+tXRVSwoLrzQNfaP/NEBhE3qAxlyupAT7
 X3kZ01peKpwnEibEPYhg6XTKkdREqanXvQKY1CaoLz0LOJ92g5l3d8mPKggCaN/RyjrN3pTDnIV
 o4cvMdZcaVuJ4y9LqXY2kSv9diTacx/NeaGnr09BhVZTYrD+kvfSO+jFU8e9/5Ug5kh2qiHOb7z
 k/7jyI3izMaUDeq9M6x/2M8NWTPrmvYFFxnEjttnPn9ohHXRr22cfjzKI0kaE/rwfWt/Mg3Hcqx
 fBoFOGOnuBYf+Sf9sHV/D6Ktmy2dS/dHBOfeiqz7vhEGBjWKpRzKZJiN2PVAsk1EXQTBLZBsvp5
 8kvymfQLU6F4RzADaDL/VZlfrLtC3p0UNh2i13cP/EIN1Zc7vcFcAOFVTO/2UXc/DSKtM2Yw5PD
 5D63Pdkc9qu0Dx6/jIPK3g07Zj72USdJDiR4+M74EfQNe2B+lNh97lq81PHnMgiBqYdN1cijayV
 2Nfl/0fjquz7qYgHnpFQouLm8wNSnsx5xJkcY3HNg6DkKW8RTjRhfJ3U1VTFUsC/fUrpx+xCgWO
 sZOa4hoclrv7w7QpwEJpCd6FMA82xsKmRIHP/AYzj/4wMJ8bfkRlZnfUayjNgKuwgET23AMu6yr
 nVhd9SpgflHFKuw==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/default with auth_id=189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit

Currently efi_shutdown_init can register a general sys_off handler,
efi_power_off, which will be called during do_kernel_power_off and shut
the machine off via efi runtime services. So enable this by providing
efi_poweroff_required, like arm and x86, and prevent directly calling
efi.reset_system in machine_power_off.

Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
 arch/loongarch/kernel/efi.c   | 5 +++++
 arch/loongarch/kernel/reset.c | 3 ---
 2 files changed, 5 insertions(+), 3 deletions(-)

diff --git a/arch/loongarch/kernel/efi.c b/arch/loongarch/kernel/efi.c
index 000825406c1f..df57c2674758 100644
--- a/arch/loongarch/kernel/efi.c
+++ b/arch/loongarch/kernel/efi.c
@@ -73,6 +73,11 @@ struct screen_info screen_info __section(".data");
 EXPORT_SYMBOL_GPL(screen_info);
 #endif
 
+bool efi_poweroff_required(void)
+{
+	return efi_enabled(EFI_RUNTIME_SERVICES);
+}
+
 static void __init init_screen_info(void)
 {
 	struct screen_info *si;
diff --git a/arch/loongarch/kernel/reset.c b/arch/loongarch/kernel/reset.c
index 1ef8c6383535..9c8156798e8d 100644
--- a/arch/loongarch/kernel/reset.c
+++ b/arch/loongarch/kernel/reset.c
@@ -48,9 +48,6 @@ void machine_power_off(void)
 		enable_pci_wakeup();
 #endif
 	do_kernel_power_off();
-#ifdef CONFIG_EFI
-	efi.reset_system(EFI_RESET_SHUTDOWN, EFI_SUCCESS, 0, NULL);
-#endif
 
 	while (true) {
 		__arch_cpu_idle();
-- 
2.39.2

