From: Eslam Almorshdy <ealmorshdy@d-matrix.ai>
Date: Tue, 17 Nov 2026 22:36:44 +0000
Subject: [PATCH RFC 6/7] dtprobed: fix the USDT load bias for non-zero link
 addresses
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-b4-bug003-load-bias-v1-6-dcd0f6cde412@d-matrix.ai>
References: <20261117-b4-bug003-load-bias-v1-0-dcd0f6cde412@d-matrix.ai>
In-Reply-To: <20261117-b4-bug003-load-bias-v1-0-dcd0f6cde412@d-matrix.ai>
To: dtrace@lists.linux.dev
Cc: Nick Alcock <nix@esperi.org.uk>, 
 Kris Van Hees <kris.van.hees@oracle.com>, 
 Eslam Almorshdy <ealmorshdy@d-matrix.ai>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794955038; l=2391;
 i=ealmorshdy@d-matrix.ai; s=20261015; h=from:subject:message-id;
 bh=ViXW6Fjdic9ZZgQ9WlQHCjn5bwm83dfPgvTDBQ7Wzw0=;
 b=Mpahp5D02ndiel9lqQOPsLXHkadW5EYu1aPEDn+YpHXmJb/nXvMlNw4FQxcDNB3p5jo23Ieaj
 BtOujPybilGCEeS8nRHYwUUcUrx06mZyGzSNHCftHAFfONsSO+I7fIG
X-Developer-Key: i=ealmorshdy@d-matrix.ai; a=ed25519;
 pk=E4tVAIvp2rvz2CB7Re6YVMP6FiUVSxuq0TUtjGQL5NM=
X-Endpoint-Received: by B4 Relay for ealmorshdy@d-matrix.ai/20261015 with auth_id=1187
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For USDT probes in ELF notes, dtprobed passes the load address of the
object's first mapping as dofhp_addr, and the note parser adds it to
each probe's link-time address.  That is the load bias only for objects
linked at 0.  In a shared library linked elsewhere (GNU ld
-Ttext-segment, lld --image-base) every probe address is too high by the
link address, libdtrace finds no mapping for it, and no probe is
created.

Subtract the first PT_LOAD's page-aligned p_vaddr, as libproc now does
for its computed load bias.

Also log the DOF helper after the adjustment, so the debug output shows
the address actually used.

Signed-off-by: Eslam Almorshdy <ealmorshdy@d-matrix.ai>
---
 dtprobed/dtprobed.c | 27 ++++++++++++++++++++++++---
 1 file changed, 24 insertions(+), 3 deletions(-)

diff --git a/dtprobed/dtprobed.c b/dtprobed/dtprobed.c
index 37d615bb..a84424b8 100644
--- a/dtprobed/dtprobed.c
+++ b/dtprobed/dtprobed.c
@@ -503,9 +503,6 @@ handle_usdt_notes(pid_t pid, uintptr_t addr)
 	dh.dofhp_addr = mapp->pr_vaddr;
 	dh.dofhp_dof = 0;
 
-	fuse_log(FUSE_LOG_DEBUG, "%i: DOF helper { '%s', %lx, %lx }\n",
-		 pid, dh.dofhp_mod, dh.dofhp_addr, dh.dofhp_dof);
-
 	exec_mapp = Plmid_to_map(P, LM_ID_BASE, PR_OBJ_EXEC);
 	if (exec_mapp == NULL || (prf = exec_mapp->pr_file) == NULL) {
 		fuse_log(FUSE_LOG_ERR, "%i: dtprobed: cannot look up mapping (process dead?)\n",
@@ -538,6 +535,30 @@ handle_usdt_notes(pid_t pid, uintptr_t addr)
 		goto elf_err;
 	if (ehdr.e_type == ET_EXEC)
 		dh.dofhp_addr = 0;
+	else {
+		size_t nphdrs, i;
+		GElf_Phdr phdr;
+
+		/*
+		 * dofhp_addr is the load address of the first segment.  The
+		 * load bias is that minus the page-aligned p_vaddr of the
+		 * first PT_LOAD segment, which is not 0 for objects linked at a
+		 * non-zero address (GNU ld -Ttext-segment, lld --image-base).
+		 */
+		if (elf_getphdrnum(elf, &nphdrs) == 0) {
+			for (i = 0; i < nphdrs; i++) {
+				if (gelf_getphdr(elf, i, &phdr) == NULL ||
+				    phdr.p_type != PT_LOAD)
+					continue;
+				dh.dofhp_addr -= phdr.p_vaddr &
+				    ~((GElf_Addr)sysconf(_SC_PAGESIZE) - 1);
+				break;
+			}
+		}
+	}
+
+	fuse_log(FUSE_LOG_DEBUG, "%i: DOF helper { '%s', %lx, %lx }\n",
+		 pid, dh.dofhp_mod, dh.dofhp_addr, dh.dofhp_dof);
 
 	while ((scn = elf_nextscn(elf, scn)) != NULL) {
 		const char *name;

-- 
2.55.0

