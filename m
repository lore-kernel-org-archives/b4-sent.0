From: Han Gao <gaohan@iscas.ac.cn>
Date: Fri, 23 Oct 2026 15:33:17 +0800
Subject: [PATCH 4/5] kexec_core: Clear the unused part of CMA segments
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261023-riscv-kexec-cma-fixes-v1-4-825b90ea23c4@iscas.ac.cn>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792740795; l=1247;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=WsDVC64bHfydftrHjB9ROmcnpvLdDMLm7LAG2iAtKWU=;
 b=DHa8l1upqFe8GF0mr/wI7BJo0OZLh4M+VDC9vtw7ebm3LQOk9dhQ/R3IcFgCVQ3BmqCnUxdFj
 9V4k04q5zHwBlic6h3xu2XScMsBcX0ln1yqzAgLHbr//OOGGibK8100
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

kimage_load_cma_segment() copies the source data into pages that are not
cleared, but zeroes nothing after it: the final memset() runs once the
loop has consumed all of memsz. The tail of the last source page and
every page beyond bufsz keep stale data, while the purgatory digest
covers them as zeroes.

A kexec_file reboot then stops in purgatory on a digest mismatch, for
instance when the DTB lands in a reused CMA page.

Zero the remainder of each page instead.

Fixes: 07d24902977e ("kexec: enable CMA based contiguous allocation")
Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
 kernel/kexec_core.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/kernel/kexec_core.c b/kernel/kexec_core.c
index dc770b9a6d05..0d6e10bea4e4 100644
--- a/kernel/kexec_core.c
+++ b/kernel/kexec_core.c
@@ -780,15 +780,15 @@ static int kimage_load_cma_segment(struct kimage *image, int idx)
 			goto out;
 		}
 
+		/* CMA pages are not cleared: zero the part without source data */
+		memset(ptr + uchunk, 0, mchunk - uchunk);
+
 		ptr    += mchunk;
 		mbytes -= mchunk;
 
 		cond_resched();
 	}
 
-	/* Clear any remainder */
-	memset(ptr, 0, mbytes);
-
 out:
 	return result;
 }

-- 
2.55.0

