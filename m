From: Junrui Luo <moonafterrain@outlook.com>
Date: Sun, 02 Aug 2026 23:51:39 +0800
Subject: [PATCH 1/6] powerpc/spufs: fix spu_context leak in coredump
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260802-fixes-v1-1-7368423440f4@outlook.com>
References: <20260802-fixes-v1-0-7368423440f4@outlook.com>
In-Reply-To: <20260802-fixes-v1-0-7368423440f4@outlook.com>
To: Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 "Christophe Leroy (CS GROUP)" <chleroy@kernel.org>, 
 Paul Mackerras <paulus@ozlabs.org>, Arnd Bergmann <arnd@arndb.de>, 
 Al Viro <viro@zeniv.linux.org.uk>
Cc: linuxppc-dev@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 Junrui Luo <moonafterrain@outlook.com>, Yuhao Jiang <danisjiang@gmail.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1723;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=4NyNHOiKkA4MH4J7oCGRtB6kCVTq8tsAtxRO2bfYk0g=;
 b=owJ4nJvAy8zAJVb4wiKgu++DA+NptSSGrPz0aQ/f7o50yDxiLOf7RMF8+oaGq+FhITvXLakqa
 71w6LqkQXtHKQuDGBeDrJgiy/GCS98sfLfobvHZkgwzh5UJZAgDF6cATGTeEUaGj6cyeValXTCt
 FQgxjG+NvjRv1+qIe0sdvrpwhDsuOve0gZFh4tb5rZyLDGb4ub3v2xMi7n3OzdKlwUjA08iycoJ
 F23dOAPdZSaI=
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

coredump_next_context() returns a spu_context with a reference taken by
get_spu_context(), which the caller must drop.
spufs_coredump_extra_notes_size() does so on all of its exits, but
spufs_coredump_extra_notes_write() never calls put_spu_context(), so
every context dumped through elf_coredump_extra_notes_write() leaks a
reference, including on the success path.

Fix by dropping the reference on each of the three exits of the loop,
mirroring ..._size().

Fixes: 38b407be172d ("powerpc/spufs: Rework fcheck() usage")
Reported-by: Yuhao Jiang <danisjiang@gmail.com>
Cc: stable@vger.kernel.org
Signed-off-by: Junrui Luo <moonafterrain@outlook.com>
---
 arch/powerpc/platforms/cell/spufs/coredump.c | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)

diff --git a/arch/powerpc/platforms/cell/spufs/coredump.c b/arch/powerpc/platforms/cell/spufs/coredump.c
index 301ee7d8b7df..f5964c9ebb3e 100644
--- a/arch/powerpc/platforms/cell/spufs/coredump.c
+++ b/arch/powerpc/platforms/cell/spufs/coredump.c
@@ -162,13 +162,16 @@ int spufs_coredump_extra_notes_write(struct coredump_params *cprm)
 	fd = 0;
 	while ((ctx = coredump_next_context(&fd)) != NULL) {
 		rc = spu_acquire_saved(ctx);
-		if (rc)
+		if (rc) {
+			put_spu_context(ctx);
 			return rc;
+		}
 
 		for (j = 0; spufs_coredump_read[j].name != NULL; j++) {
 			rc = spufs_arch_write_note(ctx, j, cprm, fd);
 			if (rc) {
 				spu_release_saved(ctx);
+				put_spu_context(ctx);
 				return rc;
 			}
 		}
@@ -177,6 +180,7 @@ int spufs_coredump_extra_notes_write(struct coredump_params *cprm)
 
 		/* start searching the next fd next time */
 		fd++;
+		put_spu_context(ctx);
 	}
 
 	return 0;

-- 
2.51.2

