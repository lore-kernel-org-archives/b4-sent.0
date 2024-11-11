From: Janne Grunau <j@jannau.net>
Date: Mon, 11 Nov 2024 07:56:33 +0100
Subject: [PATCH v3 3/4] lmb: Add basic io_lmb functionality
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241111-io_lmb_apple_dart_iommu-v3-3-32c05da51d72@jannau.net>
References: <20241111-io_lmb_apple_dart_iommu-v3-0-32c05da51d72@jannau.net>
In-Reply-To: <20241111-io_lmb_apple_dart_iommu-v3-0-32c05da51d72@jannau.net>
To: Tom Rini <trini@konsulko.com>, Mark Kettenis <kettenis@openbsd.org>, 
 Sughosh Ganu <sughosh.ganu@linaro.org>, Simon Glass <sjg@chromium.org>
Cc: u-boot@lists.denx.de, Janne Grunau <j@jannau.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=5309; i=j@jannau.net;
 s=yk2024; h=from:subject:message-id;
 bh=hTawnT4BWQhK8iCKBOSPiRuRcvxjauMLMrgdyCfBHjI=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhnTDVWtKe2bwyhZK7vl6Ykqad8i08Ot7Uh9pcPiwJX91X
 6m88/H+jlIWBjEuBlkxRZYk7ZcdDKtrFGNqH4TBzGFlAhnCwMUpABN5J8nIcCIndRJj2rUyubeH
 uifP2y6x8cpBtaTGkLVO9fffXk/fU8bIsMZPZsec957HRYo1KwXs53XncRde78varmnRW8seXKT
 KCwA=
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/yk2024 with auth_id=264
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These functions can be used with struct lmb pointers and will be used to
manage IOVA space in the apple_dart iommu driver. This restores part of
the pointer base struct lmb API from before commit ed17a33fed29 ("lmb:
make LMB memory map persistent and global").
io_lmb_add() and io_lmb_free() can trivially reuse exisiting lmb
functions. io_lmb_setup() is separate for unique error log messages.
io_lmb_alloc() is a simplified copy of _lmb_alloc_base() since the
later has unused features and internal use of the global LMB memory map.

Signed-off-by: Janne Grunau <j@jannau.net>
---
 include/lmb.h | 51 +++++++++++++++++++++++++++++++++++++
 lib/lmb.c     | 80 +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 2 files changed, 131 insertions(+)

diff --git a/include/lmb.h b/include/lmb.h
index 2201d6f2b67bb605dbff015fa2a6a008b780c57a..fa91bf17adea84d335ba43ee7749e2a12a1d44c0 100644
--- a/include/lmb.h
+++ b/include/lmb.h
@@ -156,6 +156,57 @@ static inline int lmb_read_check(phys_addr_t addr, phys_size_t len)
 	return lmb_alloc_addr(addr, len) == addr ? 0 : -1;
 }
 
+/**
+ * io_lmb_setup() - Initialize LMB struct
+ * @lmb: IO LMB to initialize
+ *
+ * Returns: 0 on success, negative error code on failure
+ */
+int io_lmb_setup(struct lmb *io_lmb);
+
+/**
+ * io_lmb_teardown() - Tear LMB struct down
+ * @lmb: IO LMB to teardown
+ */
+void io_lmb_teardown(struct lmb *io_lmb);
+
+/**
+ * io_lmb_add() - Add an IOVA range for allocations
+ * @io_lmb: LMB to add the space to
+ * @base: Base Address of region to add
+ * @size: Size of the region to add
+ *
+ * Add the IOVA space [base, base + size] to be managed by io_lmb.
+ *
+ * Returns: 0 if the region addition was successful, -1 on failure
+ */
+long io_lmb_add(struct lmb *io_lmb, phys_addr_t base, phys_size_t size);
+
+/**
+ * io_lmb_alloc() - Allocate specified IO memory address with specified alignment
+ * @io_lmb: LMB to alloc from
+ * @size: Size of the region requested
+ * @align: Required address and size alignment
+ *
+ * Allocate a region of IO memory. The base parameter is used to specify the
+ * base address of the requested region.
+ *
+ * Return: base IO address on success, 0 on error
+ */
+phys_addr_t io_lmb_alloc(struct lmb *io_lmb, phys_size_t size, ulong align);
+
+/**
+ * io_lmb_free() - Free up a region of IOVA space
+ * @io_lmb: LMB to return the IO address space to
+ * @base: Base Address of region to be freed
+ * @size: Size of the region to be freed
+ *
+ * Free up a region of IOVA space.
+ *
+ * Return: 0 if successful, -1 on failure
+ */
+long io_lmb_free(struct lmb *io_lmb, phys_addr_t base, phys_size_t size);
+
 #endif /* __KERNEL__ */
 
 #endif /* _LINUX_LMB_H */
diff --git a/lib/lmb.c b/lib/lmb.c
index ccc8a8a139c8fe58e71a6bbad65d2c1d8e56e247..74ffa9f9272fcc1a184828470695aa44879f5ed0 100644
--- a/lib/lmb.c
+++ b/lib/lmb.c
@@ -351,6 +351,86 @@ static phys_addr_t lmb_align_down(phys_addr_t addr, phys_size_t size)
 	return addr & ~(size - 1);
 }
 
+/*
+ * IOVA LMB memory maps using lmb pointers instead of the global LMB memory map.
+ */
+
+int io_lmb_setup(struct lmb *io_lmb)
+{
+	int ret;
+
+	ret = alist_init(&io_lmb->free_mem, sizeof(struct lmb_region),
+			 (uint)LMB_ALIST_INITIAL_SIZE);
+	if (!ret) {
+		log_debug("Unable to initialise the list for LMB free IOVA\n");
+		return -ENOMEM;
+	}
+
+	ret = alist_init(&io_lmb->used_mem, sizeof(struct lmb_region),
+			 (uint)LMB_ALIST_INITIAL_SIZE);
+	if (!ret) {
+		log_debug("Unable to initialise the list for LMB used IOVA\n");
+		return -ENOMEM;
+	}
+
+	io_lmb->test = false;
+
+	return 0;
+}
+
+void io_lmb_teardown(struct lmb *io_lmb)
+{
+	alist_uninit(&io_lmb->free_mem);
+	alist_uninit(&io_lmb->used_mem);
+}
+
+long io_lmb_add(struct lmb *io_lmb, phys_addr_t base, phys_size_t size)
+{
+	return lmb_add_region_flags(&io_lmb->free_mem, base, size, LMB_NONE);
+}
+
+/* derived and simplified from _lmb_alloc_base() */
+phys_addr_t io_lmb_alloc(struct lmb *io_lmb, phys_size_t size, ulong align)
+{
+	long i, rgn;
+	phys_addr_t base = 0;
+	phys_addr_t res_base;
+	struct lmb_region *lmb_used = io_lmb->used_mem.data;
+	struct lmb_region *lmb_memory = io_lmb->free_mem.data;
+
+	for (i = io_lmb->free_mem.count - 1; i >= 0; i--) {
+		phys_addr_t lmbbase = lmb_memory[i].base;
+		phys_size_t lmbsize = lmb_memory[i].size;
+
+		if (lmbsize < size)
+			continue;
+		base = lmb_align_down(lmbbase + lmbsize - size, align);
+
+		while (base && lmbbase <= base) {
+			rgn = lmb_overlaps_region(&io_lmb->used_mem, base, size);
+			if (rgn < 0) {
+				/* This area isn't reserved, take it */
+				if (lmb_add_region_flags(&io_lmb->used_mem, base,
+							 size, LMB_NONE) < 0)
+					return 0;
+
+				return base;
+			}
+
+			res_base = lmb_used[rgn].base;
+			if (res_base < size)
+				break;
+			base = lmb_align_down(res_base - size, align);
+		}
+	}
+	return 0;
+}
+
+long io_lmb_free(struct lmb *io_lmb, phys_addr_t base, phys_size_t size)
+{
+	return _lmb_free(&io_lmb->used_mem, base, size);
+}
+
 /*
  * Low level LMB functions are used to manage IOVA memory maps for the Apple
  * dart iommu. They must not access the global LMB memory map.

-- 
2.47.0

