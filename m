From: Han Gao <gaohan@iscas.ac.cn>
Date: Fri, 23 Oct 2026 15:33:16 +0800
Subject: [PATCH 3/5] kexec_file: Honor the segment alignment for CMA
 allocations
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261023-riscv-kexec-cma-fixes-v1-3-825b90ea23c4@iscas.ac.cn>
References: <20261023-riscv-kexec-cma-fixes-v1-0-825b90ea23c4@iscas.ac.cn>
In-Reply-To: <20261023-riscv-kexec-cma-fixes-v1-0-825b90ea23c4@iscas.ac.cn>
To: Paul Walmsley <pjw@kernel.org>, Palmer Dabbelt <palmer@dabbelt.com>, 
 Albert Ou <aou@eecs.berkeley.edu>, Alexandre Ghiti <alex@ghiti.fr>, 
 Nathan Chancellor <nathan@kernel.org>, 
 Nick Desaulniers <ndesaulniers@google.com>, 
 Bill Wendling <morbo@google.com>, Justin Stitt <justinstitt@google.com>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Baoquan He <baoquan.he@linux.dev>, Mike Rapoport <rppt@kernel.org>, 
 Pasha Tatashin <pasha.tatashin@soleen.com>, 
 Pratyush Yadav <pratyush@kernel.org>, Yao Zi <me@ziyao.cc>
Cc: Han Gao <rabenda.cn@gmail.com>, Han Gao <gaohan@iscas.ac.cn>, 
 linux-riscv@lists.infradead.org, linux-kernel@vger.kernel.org, 
 llvm@lists.linux.dev, kexec@lists.infradead.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792740795; l=1480;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=qJEDPA0ppewD/2akK6SOlKkXPbYM3Y6vYk6RoryMxR0=;
 b=k2WWS6RTJ6LmCg0h1zKhwYN75d0Cz5RFyTNujkDVbhWiDu1L84xl9pr9j0UyBeqXCXktEAl1S
 b8+pMaOPh4vB3By4HbvwIG+rIw9MQ2jqBYyRbEonik0/PRAt8W4WIsi
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

dma_alloc_from_contiguous() limits the requested alignment to
CONFIG_CMA_ALIGNMENT without reporting it. kexec_alloc_contig() can
therefore place a segment at a less aligned address than buf_align. On
RISC-V with 4 KiB pages, the default 1 MiB limit is below the 2 MiB
kernel alignment, and the new kernel stops at the setup_vm() BUG_ON for
a misaligned physical address.

Release such a block and fall back to the regular memory hole search,
which honors the alignment.

Fixes: 07d24902977e ("kexec: enable CMA based contiguous allocation")
Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
 kernel/kexec_file.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/kernel/kexec_file.c b/kernel/kexec_file.c
index 59fb9d71e9d8..6ce10e01414e 100644
--- a/kernel/kexec_file.c
+++ b/kernel/kexec_file.c
@@ -690,6 +690,13 @@ static int kexec_alloc_contig(struct kexec_buf *kbuf)
 
 	mem = page_to_boot_pfn(p) << PAGE_SHIFT;
 
+	/* dma_alloc_from_contiguous() caps the alignment at CONFIG_CMA_ALIGNMENT. */
+	if (!IS_ALIGNED(mem, kbuf->buf_align)) {
+		pr_debug("CMA block 0x%lx is not aligned to 0x%lx\n", mem, kbuf->buf_align);
+		dma_release_from_contiguous(NULL, p, nr_pages);
+		return -EINVAL;
+	}
+
 	if (kimage_is_destination_range(kbuf->image, mem, mem + kbuf->memsz)) {
 		/* Our region is already in use by a statically defined one. Bail out. */
 		pr_debug("CMA overlaps existing mem: 0x%lx+0x%lx\n", mem, kbuf->memsz);

-- 
2.55.0

