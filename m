From: Janne Grunau <j@jannau.net>
Date: Mon, 11 Nov 2024 07:56:32 +0100
Subject: [PATCH v3 2/4] lmb: cosmetic: reorder functions and global LMB
 variable
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241111-io_lmb_apple_dart_iommu-v3-2-32c05da51d72@jannau.net>
References: <20241111-io_lmb_apple_dart_iommu-v3-0-32c05da51d72@jannau.net>
In-Reply-To: <20241111-io_lmb_apple_dart_iommu-v3-0-32c05da51d72@jannau.net>
To: Tom Rini <trini@konsulko.com>, Mark Kettenis <kettenis@openbsd.org>, 
 Sughosh Ganu <sughosh.ganu@linaro.org>, Simon Glass <sjg@chromium.org>
Cc: u-boot@lists.denx.de, Janne Grunau <j@jannau.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=14613; i=j@jannau.net;
 s=yk2024; h=from:subject:message-id;
 bh=tfaI0OnBgN/0I/jma8YjKtilN9QxpWvpmqZf/AmXJkU=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhnTDVWu01i88uCKR6R8vT5W/RhqjtaT62f1KDJbbP03+K
 7WwLvtFRykLgxgXg6yYIkuS9ssOhtU1ijG1D8Jg5rAygQxh4OIUgIlovGP4xRyZz93hldK9rORS
 Hq+/3AZDCacXM79V35+YIWZ2/b/MdYa/cgIiYo+eHn7AnnDswUOlpZ6V7zofxCaFbO7Ly5mQbL+
 EBQA=
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/yk2024 with auth_id=264
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Low lovel LMB functionality will be used to manage IOVA space in the
Apple dart iommu driver. This reordering ensures that those function
can not access the global LMB memory map variable.

Signed-off-by: Janne Grunau <j@jannau.net>
---
 lib/lmb.c | 490 ++++++++++++++++++++++++++++++++------------------------------
 1 file changed, 251 insertions(+), 239 deletions(-)

diff --git a/lib/lmb.c b/lib/lmb.c
index cc2554dfa947182806c37b31da292becc1c868a1..ccc8a8a139c8fe58e71a6bbad65d2c1d8e56e247 100644
--- a/lib/lmb.c
+++ b/lib/lmb.c
@@ -27,96 +27,11 @@ DECLARE_GLOBAL_DATA_PTR;
 #define MAP_OP_FREE		(u8)0x2
 #define MAP_OP_ADD		(u8)0x3
 
-static struct lmb lmb;
-
-static bool lmb_should_notify(enum lmb_flags flags)
-{
-	return !lmb.test && !(flags & LMB_NONOTIFY) &&
-		CONFIG_IS_ENABLED(EFI_LOADER);
-}
-
-static int lmb_map_update_notify(phys_addr_t addr, phys_size_t size, u8 op,
-				 enum lmb_flags flags)
-{
-	u64 efi_addr;
-	u64 pages;
-	efi_status_t status;
-
-	if (op != MAP_OP_RESERVE && op != MAP_OP_FREE && op != MAP_OP_ADD) {
-		log_err("Invalid map update op received (%d)\n", op);
-		return -1;
-	}
-
-	if (!lmb_should_notify(flags))
-		return 0;
-
-	efi_addr = (uintptr_t)map_sysmem(addr, 0);
-	pages = efi_size_in_pages(size + (efi_addr & EFI_PAGE_MASK));
-	efi_addr &= ~EFI_PAGE_MASK;
-
-	status = efi_add_memory_map_pg(efi_addr, pages,
-				       op == MAP_OP_RESERVE ?
-				       EFI_BOOT_SERVICES_DATA :
-				       EFI_CONVENTIONAL_MEMORY,
-				       false);
-	if (status != EFI_SUCCESS) {
-		log_err("%s: LMB Map notify failure %lu\n", __func__,
-			status & ~EFI_ERROR_MASK);
-		return -1;
-	}
-	unmap_sysmem((void *)(uintptr_t)efi_addr);
-
-	return 0;
-}
-
-static void lmb_print_region_flags(enum lmb_flags flags)
-{
-	u64 bitpos;
-	const char *flag_str[] = { "none", "no-map", "no-overwrite", "no-notify" };
-
-	do {
-		bitpos = flags ? fls(flags) - 1 : 0;
-		assert_noisy(bitpos < ARRAY_SIZE(flag_str));
-		printf("%s", flag_str[bitpos]);
-		flags &= ~(1ull << bitpos);
-		puts(flags ? ", " : "\n");
-	} while (flags);
-}
-
-static void lmb_dump_region(struct alist *lmb_rgn_lst, char *name)
-{
-	struct lmb_region *rgn = lmb_rgn_lst->data;
-	unsigned long long base, size, end;
-	enum lmb_flags flags;
-	int i;
-
-	printf(" %s.count = 0x%x\n", name, lmb_rgn_lst->count);
-
-	for (i = 0; i < lmb_rgn_lst->count; i++) {
-		base = rgn[i].base;
-		size = rgn[i].size;
-		end = base + size - 1;
-		flags = rgn[i].flags;
-
-		printf(" %s[%d]\t[0x%llx-0x%llx], 0x%08llx bytes flags: ",
-		       name, i, base, end, size);
-		lmb_print_region_flags(flags);
-	}
-}
-
-void lmb_dump_all_force(void)
-{
-	printf("lmb_dump_all:\n");
-	lmb_dump_region(&lmb.free_mem, "memory");
-	lmb_dump_region(&lmb.used_mem, "reserved");
-}
-
-void lmb_dump_all(void)
-{
-#ifdef DEBUG
-	lmb_dump_all_force();
-#endif
-}
+/*
+ * The following low level LMB functions must not access the global LMB memory
+ * map since they are also used to manage IOVA memory maps in iommu drivers like
+ * apple_dart.
+ */
 
 static long lmb_addrs_overlap(phys_addr_t base1, phys_size_t size1,
 			      phys_addr_t base2, phys_size_t size2)
@@ -205,115 +120,6 @@ static void lmb_fix_over_lap_regions(struct alist *lmb_rgn_lst,
 	lmb_remove_region(lmb_rgn_lst, r2);
 }
 
-static void lmb_reserve_uboot_region(void)
-{
-	int bank;
-	ulong end, bank_end;
-	phys_addr_t rsv_start;
-
-	rsv_start = gd->start_addr_sp - CONFIG_STACK_SIZE;
-	end = gd->ram_top;
-
-	/*
-	 * Reserve memory from aligned address below the bottom of U-Boot stack
-	 * until end of RAM area to prevent LMB from overwriting that memory.
-	 */
-	debug("## Current stack ends at 0x%08lx ", (ulong)rsv_start);
-
-	for (bank = 0; bank < CONFIG_NR_DRAM_BANKS; bank++) {
-		if (!gd->bd->bi_dram[bank].size ||
-		    rsv_start < gd->bd->bi_dram[bank].start)
-			continue;
-		/* Watch out for RAM at end of address space! */
-		bank_end = gd->bd->bi_dram[bank].start +
-			gd->bd->bi_dram[bank].size - 1;
-		if (rsv_start > bank_end)
-			continue;
-		if (bank_end > end)
-			bank_end = end - 1;
-
-		lmb_reserve_flags(rsv_start, bank_end - rsv_start + 1,
-				  LMB_NOOVERWRITE);
-
-		if (gd->flags & GD_FLG_SKIP_RELOC)
-			lmb_reserve_flags((phys_addr_t)(uintptr_t)_start,
-					  gd->mon_len, LMB_NOOVERWRITE);
-
-		break;
-	}
-}
-
-static void lmb_reserve_common(void *fdt_blob)
-{
-	lmb_reserve_uboot_region();
-
-	if (CONFIG_IS_ENABLED(OF_LIBFDT) && fdt_blob)
-		boot_fdt_add_mem_rsv_regions(fdt_blob);
-}
-
-static __maybe_unused void lmb_reserve_common_spl(void)
-{
-	phys_addr_t rsv_start;
-	phys_size_t rsv_size;
-
-	/*
-	 * Assume a SPL stack of 16KB. This must be
-	 * more than enough for the SPL stage.
-	 */
-	if (IS_ENABLED(CONFIG_SPL_STACK_R_ADDR)) {
-		rsv_start = gd->start_addr_sp - 16384;
-		rsv_size = 16384;
-		lmb_reserve_flags(rsv_start, rsv_size, LMB_NOOVERWRITE);
-	}
-
-	if (IS_ENABLED(CONFIG_SPL_SEPARATE_BSS)) {
-		/* Reserve the bss region */
-		rsv_start = (phys_addr_t)(uintptr_t)__bss_start;
-		rsv_size = (phys_addr_t)(uintptr_t)__bss_end -
-			(phys_addr_t)(uintptr_t)__bss_start;
-		lmb_reserve_flags(rsv_start, rsv_size, LMB_NOOVERWRITE);
-	}
-}
-
-/**
- * lmb_add_memory() - Add memory range for LMB allocations
- *
- * Add the entire available memory range to the pool of memory that
- * can be used by the LMB module for allocations.
- *
- * Return: None
- */
-void lmb_add_memory(void)
-{
-	int i;
-	phys_size_t size;
-	u64 ram_top = gd->ram_top;
-	struct bd_info *bd = gd->bd;
-
-	if (CONFIG_IS_ENABLED(LMB_ARCH_MEM_MAP))
-		return lmb_arch_add_memory();
-
-	/* Assume a 4GB ram_top if not defined */
-	if (!ram_top)
-		ram_top = 0x100000000ULL;
-
-	for (i = 0; i < CONFIG_NR_DRAM_BANKS; i++) {
-		size = bd->bi_dram[i].size;
-		if (size) {
-			lmb_add(bd->bi_dram[i].start, size);
-
-			/*
-			 * Reserve memory above ram_top as
-			 * no-overwrite so that it cannot be
-			 * allocated
-			 */
-			if (bd->bi_dram[i].start >= ram_top)
-				lmb_reserve_flags(bd->bi_dram[i].start, size,
-						  LMB_NOOVERWRITE);
-		}
-	}
-}
-
 static long lmb_resize_regions(struct alist *lmb_rgn_lst,
 			       unsigned long idx_start,
 			       phys_addr_t base, phys_size_t size)
@@ -473,25 +279,6 @@ static long lmb_add_region_flags(struct alist *lmb_rgn_lst, phys_addr_t base,
 	return 0;
 }
 
-static long lmb_add_region(struct alist *lmb_rgn_lst, phys_addr_t base,
-			   phys_size_t size)
-{
-	return lmb_add_region_flags(lmb_rgn_lst, base, size, LMB_NONE);
-}
-
-/* This routine may be called with relocation disabled. */
-long lmb_add(phys_addr_t base, phys_size_t size)
-{
-	long ret;
-	struct alist *lmb_rgn_lst = &lmb.free_mem;
-
-	ret = lmb_add_region(lmb_rgn_lst, base, size);
-	if (ret)
-		return ret;
-
-	return lmb_map_update_notify(base, size, MAP_OP_ADD, LMB_NONE);
-}
-
 static long _lmb_free(struct alist *lmb_rgn_lst, phys_addr_t base,
 		      phys_size_t size)
 {
@@ -543,6 +330,252 @@ static long _lmb_free(struct alist *lmb_rgn_lst, phys_addr_t base,
 				    rgn[i].flags);
 }
 
+static long lmb_overlaps_region(struct alist *lmb_rgn_lst, phys_addr_t base,
+				phys_size_t size)
+{
+	unsigned long i;
+	struct lmb_region *rgn = lmb_rgn_lst->data;
+
+	for (i = 0; i < lmb_rgn_lst->count; i++) {
+		phys_addr_t rgnbase = rgn[i].base;
+		phys_size_t rgnsize = rgn[i].size;
+		if (lmb_addrs_overlap(base, size, rgnbase, rgnsize))
+			break;
+	}
+
+	return (i < lmb_rgn_lst->count) ? i : -1;
+}
+
+static phys_addr_t lmb_align_down(phys_addr_t addr, phys_size_t size)
+{
+	return addr & ~(size - 1);
+}
+
+/*
+ * Low level LMB functions are used to manage IOVA memory maps for the Apple
+ * dart iommu. They must not access the global LMB memory map.
+ * So keep the global LMB variable declaration unreachable from them.
+ */
+
+static struct lmb lmb;
+
+static bool lmb_should_notify(enum lmb_flags flags)
+{
+	return !lmb.test && !(flags & LMB_NONOTIFY) &&
+		CONFIG_IS_ENABLED(EFI_LOADER);
+}
+
+static int lmb_map_update_notify(phys_addr_t addr, phys_size_t size, u8 op,
+				 enum lmb_flags flags)
+{
+	u64 efi_addr;
+	u64 pages;
+	efi_status_t status;
+
+	if (op != MAP_OP_RESERVE && op != MAP_OP_FREE && op != MAP_OP_ADD) {
+		log_err("Invalid map update op received (%d)\n", op);
+		return -1;
+	}
+
+	if (!lmb_should_notify(flags))
+		return 0;
+
+	efi_addr = (uintptr_t)map_sysmem(addr, 0);
+	pages = efi_size_in_pages(size + (efi_addr & EFI_PAGE_MASK));
+	efi_addr &= ~EFI_PAGE_MASK;
+
+	status = efi_add_memory_map_pg(efi_addr, pages,
+				       op == MAP_OP_RESERVE ?
+				       EFI_BOOT_SERVICES_DATA :
+				       EFI_CONVENTIONAL_MEMORY,
+				       false);
+	if (status != EFI_SUCCESS) {
+		log_err("%s: LMB Map notify failure %lu\n", __func__,
+			status & ~EFI_ERROR_MASK);
+		return -1;
+	}
+	unmap_sysmem((void *)(uintptr_t)efi_addr);
+
+	return 0;
+}
+
+static void lmb_print_region_flags(enum lmb_flags flags)
+{
+	u64 bitpos;
+	const char *flag_str[] = { "none", "no-map", "no-overwrite", "no-notify" };
+
+	do {
+		bitpos = flags ? fls(flags) - 1 : 0;
+		assert_noisy(bitpos < ARRAY_SIZE(flag_str));
+		printf("%s", flag_str[bitpos]);
+		flags &= ~(1ull << bitpos);
+		puts(flags ? ", " : "\n");
+	} while (flags);
+}
+
+static void lmb_dump_region(struct alist *lmb_rgn_lst, char *name)
+{
+	struct lmb_region *rgn = lmb_rgn_lst->data;
+	unsigned long long base, size, end;
+	enum lmb_flags flags;
+	int i;
+
+	printf(" %s.count = 0x%x\n", name, lmb_rgn_lst->count);
+
+	for (i = 0; i < lmb_rgn_lst->count; i++) {
+		base = rgn[i].base;
+		size = rgn[i].size;
+		end = base + size - 1;
+		flags = rgn[i].flags;
+
+		printf(" %s[%d]\t[0x%llx-0x%llx], 0x%08llx bytes flags: ",
+		       name, i, base, end, size);
+		lmb_print_region_flags(flags);
+	}
+}
+
+void lmb_dump_all_force(void)
+{
+	printf("lmb_dump_all:\n");
+	lmb_dump_region(&lmb.free_mem, "memory");
+	lmb_dump_region(&lmb.used_mem, "reserved");
+}
+
+void lmb_dump_all(void)
+{
+#ifdef DEBUG
+	lmb_dump_all_force();
+#endif
+}
+
+static void lmb_reserve_uboot_region(void)
+{
+	int bank;
+	ulong end, bank_end;
+	phys_addr_t rsv_start;
+
+	rsv_start = gd->start_addr_sp - CONFIG_STACK_SIZE;
+	end = gd->ram_top;
+
+	/*
+	 * Reserve memory from aligned address below the bottom of U-Boot stack
+	 * until end of RAM area to prevent LMB from overwriting that memory.
+	 */
+	debug("## Current stack ends at 0x%08lx ", (ulong)rsv_start);
+
+	for (bank = 0; bank < CONFIG_NR_DRAM_BANKS; bank++) {
+		if (!gd->bd->bi_dram[bank].size ||
+		    rsv_start < gd->bd->bi_dram[bank].start)
+			continue;
+		/* Watch out for RAM at end of address space! */
+		bank_end = gd->bd->bi_dram[bank].start +
+			gd->bd->bi_dram[bank].size - 1;
+		if (rsv_start > bank_end)
+			continue;
+		if (bank_end > end)
+			bank_end = end - 1;
+
+		lmb_reserve_flags(rsv_start, bank_end - rsv_start + 1,
+				  LMB_NOOVERWRITE);
+
+		if (gd->flags & GD_FLG_SKIP_RELOC)
+			lmb_reserve_flags((phys_addr_t)(uintptr_t)_start,
+					  gd->mon_len, LMB_NOOVERWRITE);
+
+		break;
+	}
+}
+
+static void lmb_reserve_common(void *fdt_blob)
+{
+	lmb_reserve_uboot_region();
+
+	if (CONFIG_IS_ENABLED(OF_LIBFDT) && fdt_blob)
+		boot_fdt_add_mem_rsv_regions(fdt_blob);
+}
+
+static __maybe_unused void lmb_reserve_common_spl(void)
+{
+	phys_addr_t rsv_start;
+	phys_size_t rsv_size;
+
+	/*
+	 * Assume a SPL stack of 16KB. This must be
+	 * more than enough for the SPL stage.
+	 */
+	if (IS_ENABLED(CONFIG_SPL_STACK_R_ADDR)) {
+		rsv_start = gd->start_addr_sp - 16384;
+		rsv_size = 16384;
+		lmb_reserve_flags(rsv_start, rsv_size, LMB_NOOVERWRITE);
+	}
+
+	if (IS_ENABLED(CONFIG_SPL_SEPARATE_BSS)) {
+		/* Reserve the bss region */
+		rsv_start = (phys_addr_t)(uintptr_t)__bss_start;
+		rsv_size = (phys_addr_t)(uintptr_t)__bss_end -
+			(phys_addr_t)(uintptr_t)__bss_start;
+		lmb_reserve_flags(rsv_start, rsv_size, LMB_NOOVERWRITE);
+	}
+}
+
+/**
+ * lmb_add_memory() - Add memory range for LMB allocations
+ *
+ * Add the entire available memory range to the pool of memory that
+ * can be used by the LMB module for allocations.
+ *
+ * Return: None
+ */
+void lmb_add_memory(void)
+{
+	int i;
+	phys_size_t size;
+	u64 ram_top = gd->ram_top;
+	struct bd_info *bd = gd->bd;
+
+	if (CONFIG_IS_ENABLED(LMB_ARCH_MEM_MAP))
+		return lmb_arch_add_memory();
+
+	/* Assume a 4GB ram_top if not defined */
+	if (!ram_top)
+		ram_top = 0x100000000ULL;
+
+	for (i = 0; i < CONFIG_NR_DRAM_BANKS; i++) {
+		size = bd->bi_dram[i].size;
+		if (size) {
+			lmb_add(bd->bi_dram[i].start, size);
+
+			/*
+			 * Reserve memory above ram_top as
+			 * no-overwrite so that it cannot be
+			 * allocated
+			 */
+			if (bd->bi_dram[i].start >= ram_top)
+				lmb_reserve_flags(bd->bi_dram[i].start, size,
+						  LMB_NOOVERWRITE);
+		}
+	}
+}
+
+static long lmb_add_region(struct alist *lmb_rgn_lst, phys_addr_t base,
+			   phys_size_t size)
+{
+	return lmb_add_region_flags(lmb_rgn_lst, base, size, LMB_NONE);
+}
+
+/* This routine may be called with relocation disabled. */
+long lmb_add(phys_addr_t base, phys_size_t size)
+{
+	long ret;
+	struct alist *lmb_rgn_lst = &lmb.free_mem;
+
+	ret = lmb_add_region(lmb_rgn_lst, base, size);
+	if (ret)
+		return ret;
+
+	return lmb_map_update_notify(base, size, MAP_OP_ADD, LMB_NONE);
+}
+
 /**
  * lmb_free_flags() - Free up a region of memory
  * @base: Base Address of region to be freed
@@ -587,27 +620,6 @@ long lmb_reserve(phys_addr_t base, phys_size_t size)
 	return lmb_reserve_flags(base, size, LMB_NONE);
 }
 
-static long lmb_overlaps_region(struct alist *lmb_rgn_lst, phys_addr_t base,
-				phys_size_t size)
-{
-	unsigned long i;
-	struct lmb_region *rgn = lmb_rgn_lst->data;
-
-	for (i = 0; i < lmb_rgn_lst->count; i++) {
-		phys_addr_t rgnbase = rgn[i].base;
-		phys_size_t rgnsize = rgn[i].size;
-		if (lmb_addrs_overlap(base, size, rgnbase, rgnsize))
-			break;
-	}
-
-	return (i < lmb_rgn_lst->count) ? i : -1;
-}
-
-static phys_addr_t lmb_align_down(phys_addr_t addr, phys_size_t size)
-{
-	return addr & ~(size - 1);
-}
-
 static phys_addr_t _lmb_alloc_base(phys_size_t size, ulong align,
 				    phys_addr_t max_addr, enum lmb_flags flags)
 {

-- 
2.47.0

