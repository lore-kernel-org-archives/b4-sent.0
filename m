From: Miao Wang <shankerwangmiao@gmail.com>
To: loongarch@lists.linux.dev, linux-efi@vger.kernel.org,
Cc: Jiaxun Yang <jiaxun.yang@flygoat.com>, 
 Huacai Chen <chenhuacai@kernel.org>, WANG Xuerui <kernel@xen0n.name>, 
 Ard Biesheuvel <ardb@kernel.org>,
Message-Id: b267d460-547f-11ef-a3fb-8fbda124b4d2@innull.com
Date: Fri, 26 Jul 2024 17:17:53 +0800
Subject: [PATCH] loongarch/efi: enable general efi poweroff
X-Developer-Signature: v=1; a=openpgp-sha256; l=801;
 i=shankerwangmiao@gmail.com; h=from:subject:message-id;
 bh=xdT7amiL25/NY3W3LV47NbtJ6xdKD7qZEQCH7VFyDQA=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBmswncjBJ44qRkRgyLM6btDBL6YBI6qAKvUv4Gt
 nPtTJFmuDqJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCZrMJ3AAKCRCwMePKe/7Z
 bvDpEACwNcrFx/+gbL3uoIISQ3jsTKx42C4ah4H2rHgUW9xjd6/aJWglVATtDqbnxBWTWrDKVBs
 mC8jqLIH+HBG3LmneJE4QppBYheE03vRCD3osF5EPxiXAtcmxjr1262EAAp9S8FmiWvz2I8klqk
 1sKPZNwwE2MH9KwskIYzDjs7pnND4YYkRLmywsA07nl5Hl55gDCaRsja5joln5isJabmJj7uy/r
 OQ0IFKdQ7eYv3UtwMr0i34WTiPbzT41/PGvUNDzk5Yg4l/zjikxJXpciLh4AAlT3+DjIQU61EzR
 MOstaZ+0KCZ+kAPQq94im6Psw7NJqbYoqlyKUSaZdl4nbJze/NHQGhm9LbF2arpx2hGnnv3OOC6
 FVStG47IpWTD3whTbRTh0OyNljyFoMAMjGb9HvlgWRCpqw5bzkPoQFgYZhhdEQMDV4IcTC3Kgos
 5gjpUUfhpOSpOXr6v7/Z4YGGzPBqB5nv7qA9iTqfrDh9+BF6miWNxHqvTx0eYeOdMo6ZkU5UI7a
 ea5KJ8rInANkMENmnj6gIYgbv/7sN8bOHlh/m2xxUIDjKI3hRvOnAf8pbXcr6ZpvNgVeKtqifvq
 r/S95mQoxRIZVxC5iJ4EPtj/AmhuBFWUzgEDOxmyuPwppjCWHp4nqsmKbCI1YoFkXdreMajJtmK
 Mt5VV37PWt2UEpg==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/default with auth_id=189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit

efi_shutdown_init can register a general sys_off handler,
efi_power_off. Enable this by providing efi_poweroff_required,
like arm and x86, since this is also supported on loongarch.

Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
 arch/loongarch/kernel/efi.c | 5 +++++
 1 file changed, 5 insertions(+)

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
-- 
2.43.0

