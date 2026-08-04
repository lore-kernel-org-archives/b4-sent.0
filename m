From: Junrui Luo <moonafterrain@outlook.com>
Date: Tue, 04 Aug 2026 18:55:04 +0800
Subject: [PATCH 4/5] NFSv4/flexfiles: bound the filehandle version count
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260804-nfs-fixes-v1-4-1544df970e7c@outlook.com>
References: <20260804-nfs-fixes-v1-0-1544df970e7c@outlook.com>
In-Reply-To: <20260804-nfs-fixes-v1-0-1544df970e7c@outlook.com>
To: Trond Myklebust <trondmy@kernel.org>, Anna Schumaker <anna@kernel.org>
Cc: linux-nfs@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jonathan Curley <jcurley@purestorage.com>, 
 Michael Bommarito <michael.bommarito@gmail.com>, 
 Junrui Luo <moonafterrain@outlook.com>, Yuhao Jiang <danisjiang@gmail.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2341;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=HE7wEMko3m9Jwve0mVBI8y2cKV7TCTLF5kvH7eM8vzw=;
 b=owJ4nJvAy8zAJVb4wiKgu++DA+NptSSGrMKjMvsSGH+qKbNxX43ZtLXX5UhjmVqNyvttU35Fa
 B39u/rkmeiOUhYGMS4GWTFFluMFl75Z+G7R3eKzJRlmDisTyBAGLk4BmMi6Lwz/qzh4D77LeWte
 4Pj6daWfS19iZs7s3sklr4WLumyO8TIoMPxPeeF5w+afVU9VnuP9TpEe7pevLl5mzj7VuM5i07q
 zGuGcABtXTSg=
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ff_layout_alloc_lseg() decodes fh_count from the flexfiles LAYOUTGET
body and passes it directly to kzalloc_objs() to size the
dss_info->fh_versions array. Commit 2c6bb3c40bc2 ("NFSv4/flexfiles:
reject zero filehandle version count") rejected a zero count, but
unlike the neighbouring mirror_array_cnt and dss_count the value
remains unbounded from above.

sizeof(struct nfs_fh) is 130, so an fh_count of 32264 or more pushes
get_order() past MAX_PAGE_ORDER and trips the page allocator's
WARN_ON_ONCE_GFP().

Reject implausible counts up front, as this function already does for
mirror_array_cnt and dss_count, and as filelayout_decode_layout() does
for the equivalent num_fh field.

Fixes: d67ae825a59d ("pnfs/flexfiles: Add the FlexFile Layout Driver")
Reported-by: Yuhao Jiang <danisjiang@gmail.com>
Assisted-by: Claude:claude-opus-5
Cc: stable@vger.kernel.org
Signed-off-by: Junrui Luo <moonafterrain@outlook.com>
---
 fs/nfs/flexfilelayout/flexfilelayout.c | 3 ++-
 fs/nfs/flexfilelayout/flexfilelayout.h | 5 +++++
 2 files changed, 7 insertions(+), 1 deletion(-)

diff --git a/fs/nfs/flexfilelayout/flexfilelayout.c b/fs/nfs/flexfilelayout/flexfilelayout.c
index c4aa995026f6..bdc4b960eeb7 100644
--- a/fs/nfs/flexfilelayout/flexfilelayout.c
+++ b/fs/nfs/flexfilelayout/flexfilelayout.c
@@ -551,7 +551,8 @@ ff_layout_alloc_lseg(struct pnfs_layout_hdr *lh,
 			if (!p)
 				goto out_err_free;
 			fh_count = be32_to_cpup(p);
-			if (fh_count == 0) {
+			if (fh_count == 0 ||
+			    fh_count > NFS4_FLEXFILE_LAYOUT_MAX_FH_CNT) {
 				rc = -EINVAL;
 				goto out_err_free;
 			}
diff --git a/fs/nfs/flexfilelayout/flexfilelayout.h b/fs/nfs/flexfilelayout/flexfilelayout.h
index d024b8db4ce0..a4c7f9040084 100644
--- a/fs/nfs/flexfilelayout/flexfilelayout.h
+++ b/fs/nfs/flexfilelayout/flexfilelayout.h
@@ -27,6 +27,11 @@
  * otherwise let a server spin the GETDEVICEINFO decode loop. */
 #define NFS4_FLEXFILE_LAYOUT_MAX_MULTIPATH_CNT 4096
 
+/* Filter out insanely large filehandle version counts, which would
+ * otherwise let a server size a kernel allocation from the LAYOUTGET
+ * body. */
+#define NFS4_FLEXFILE_LAYOUT_MAX_FH_CNT 4096
+
 /* LAYOUTSTATS report interval in ms */
 #define FF_LAYOUTSTATS_REPORT_INTERVAL (60000L)
 #define FF_LAYOUTSTATS_MAXDEV 4

-- 
2.51.2

