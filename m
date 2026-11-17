From: Eslam Almorshdy <ealmorshdy@d-matrix.ai>
Date: Tue, 17 Nov 2026 22:36:39 +0000
Subject: [PATCH RFC 1/7] libproc: fix the fallback load bias for non-zero
 link addresses
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-b4-bug003-load-bias-v1-1-dcd0f6cde412@d-matrix.ai>
References: <20261117-b4-bug003-load-bias-v1-0-dcd0f6cde412@d-matrix.ai>
In-Reply-To: <20261117-b4-bug003-load-bias-v1-0-dcd0f6cde412@d-matrix.ai>
To: dtrace@lists.linux.dev
Cc: Nick Alcock <nix@esperi.org.uk>, 
 Kris Van Hees <kris.van.hees@oracle.com>, 
 Eslam Almorshdy <ealmorshdy@d-matrix.ai>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794955038; l=1852;
 i=ealmorshdy@d-matrix.ai; s=20261015; h=from:subject:message-id;
 bh=YuYQVScNcUEIHJgrghfDwbLlI0S38/abW8No5qYGv+4=;
 b=VkDVysqBQjPQLk66cRBqdfFvkRJELYIK7EcGoP4tgZ6zpLAha32RwOgOcsR/1ToNaVWN9fhAc
 6Z5bb9REVIrA+pmDAoEYRsN081+DVp3pKD3GRYIlAei0/z14L5ugo9U
X-Developer-Key: i=ealmorshdy@d-matrix.ai; a=ed25519;
 pk=E4tVAIvp2rvz2CB7Re6YVMP6FiUVSxuq0TUtjGQL5NM=
X-Endpoint-Received: by B4 Relay for ealmorshdy@d-matrix.ai/20261015 with auth_id=1187
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When ld.so's link map is not available, Pbuild_file_symtab() computes an
ET_DYN object's load bias as

    first_segment->pr_vaddr - (p_vaddr & (p_align - 1))

subtracting only the part of the first PT_LOAD's p_vaddr below its
alignment.  The bias is the first mapping's start minus the page-aligned
p_vaddr (the gABI base address).  The two agree only for objects linked
at 0; for an object linked elsewhere (GNU ld -Ttext-segment, lld
--image-base) the bias is too high by the link address and every symbol
lookup in the object fails.

Subtract the page-aligned p_vaddr.

Signed-off-by: Eslam Almorshdy <ealmorshdy@d-matrix.ai>
---
 libproc/Psymtab.c | 12 +++++++++---
 1 file changed, 9 insertions(+), 3 deletions(-)

diff --git a/libproc/Psymtab.c b/libproc/Psymtab.c
index 7876e9a8..b713e439 100644
--- a/libproc/Psymtab.c
+++ b/libproc/Psymtab.c
@@ -1593,14 +1593,20 @@ Pbuild_file_symtab(struct ps_prochandle *P, file_info_t *fptr)
 		goto elf_bad_noaddr;
 	}
 
+	/*
+	 * The first mapping starts at the load bias plus the first
+	 * PT_LOAD's page-aligned p_vaddr.  Subtract all of that, not just
+	 * the part of p_vaddr below p_align, or objects linked at a
+	 * non-zero address (GNU ld -Ttext-segment, lld --image-base) get a
+	 * bias that is too high by that address.
+	 */
 	fptr->file_dyn_base = prf->first_segment->pr_vaddr -
-	    (phdr->p_vaddr & (phdr->p_align - 1));
+	    (phdr->p_vaddr & ~((GElf_Addr)sysconf(_SC_PAGESIZE) - 1));
 
 	_dprintf("setting file_dyn_base for %s to %lx, "
 	    "from load address of %lx and phdr vaddr of %lx\n",
 	    fptr->file_pname, (long)fptr->file_dyn_base,
-	    prf->first_segment->pr_vaddr,
-	    (phdr->p_vaddr & (phdr->p_align - 1)));
+	    prf->first_segment->pr_vaddr, (long)phdr->p_vaddr);
 
 ret:
 	*jmp_pad = old_exec_jmp;

-- 
2.55.0

