From: Eslam Almorshdy <ealmorshdy@d-matrix.ai>
Date: Sun, 18 Oct 2026 02:50:09 +0000
Subject: [PATCH 3/3] Create the strtab map read-only for BPF programs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261018-bug010-strlen-strtab-v1-3-ac5f5bc6f8a0@d-matrix.ai>
References: <20261018-bug010-strlen-strtab-v1-0-ac5f5bc6f8a0@d-matrix.ai>
In-Reply-To: <20261018-bug010-strlen-strtab-v1-0-ac5f5bc6f8a0@d-matrix.ai>
To: dtrace@lists.linux.dev
Cc: Kris Van Hees <kris.van.hees@oracle.com>, dtrace-devel@oss.oracle.com, 
 Eugene Loh <eugene.loh@oracle.com>, 
 Eslam Almorshdy <ealmorshdy@d-matrix.ai>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792291829; l=3112;
 i=ealmorshdy@d-matrix.ai; s=20261015; h=from:subject:message-id;
 bh=qzK9aOOHqm3BNR/pK6tIQKYAIFTWHqpMpEBuvuUu+cA=;
 b=J8ozVmqF0PldxvQ78Zgov17Cxrwp38mTiw8rFJPa6kYKmG4/osWoOPM6n3Obk/i485rho+4rb
 DvWi2oDOXFVDDIdH0vBVgzJycyCVj03pjVE89EQ5aYbm8QMhOwgrViQ
X-Developer-Key: i=ealmorshdy@d-matrix.ai; a=ed25519;
 pk=E4tVAIvp2rvz2CB7Re6YVMP6FiUVSxuq0TUtjGQL5NM=
X-Endpoint-Received: by B4 Relay for ealmorshdy@d-matrix.ai/20261015 with auth_id=1187
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The strtab map holds the string table, the read-only data and the
block of zeros, and every BPF reader assumes they never change.  Now
that strlen() uses a temporary string, no BPF code writes to the map,
but nothing enforced that, which is how the strlen() overwrite went
unnoticed.

Create the map with BPF_F_RDONLY_PROG, so that the verifier rejects a
program that writes to it.  User space still fills the map, which the
flag does not restrict.  BPF_F_RDONLY_PROG has been supported since
Linux 5.2.

The miscompiled strjoin() in codegen/tst.reg_spilling7.d (XFAIL) is an
example: it is now rejected at its first write into strtab, instead of
only when a later write runs past the end of the map.

Assisted-by: Claude Code:claude-opus-5-5
Signed-off-by: Eslam Almorshdy <ealmorshdy@d-matrix.ai>
---
 libdtrace/dt_bpf.c | 19 +++++++++++++------
 1 file changed, 13 insertions(+), 6 deletions(-)

diff --git a/libdtrace/dt_bpf.c b/libdtrace/dt_bpf.c
index 146a66e3..349f864a 100644
--- a/libdtrace/dt_bpf.c
+++ b/libdtrace/dt_bpf.c
@@ -548,8 +548,8 @@ map_create_error(dtrace_hdl_t *dtp, const char *name, int err)
 }
 
 static int
-create_gmap(dtrace_hdl_t *dtp, const char *name, enum bpf_map_type type,
-	    size_t ksz, size_t vsz, size_t size)
+create_gmap_flags(dtrace_hdl_t *dtp, const char *name, enum bpf_map_type type,
+		  size_t ksz, size_t vsz, size_t size, uint32_t flags)
 {
 	int		fd, err;
 	dt_ident_t	*idp;
@@ -561,7 +561,7 @@ create_gmap(dtrace_hdl_t *dtp, const char *name, enum bpf_map_type type,
 		fd = -1;
 		err = E2BIG;
 	} else {
-		fd = dt_bpf_map_create(type, name, ksz, vsz, size, 0);
+		fd = dt_bpf_map_create(type, name, ksz, vsz, size, flags);
 		err = errno;
 	}
 
@@ -584,6 +584,13 @@ create_gmap(dtrace_hdl_t *dtp, const char *name, enum bpf_map_type type,
 	return fd;
 }
 
+static int
+create_gmap(dtrace_hdl_t *dtp, const char *name, enum bpf_map_type type,
+	    size_t ksz, size_t vsz, size_t size)
+{
+	return create_gmap_flags(dtp, name, type, ksz, vsz, size, 0);
+}
+
 static int
 create_gmap_of_maps(dtrace_hdl_t *dtp, const char *name,
 		    enum bpf_map_type otype, size_t oksz, size_t osize,
@@ -848,7 +855,7 @@ gmap_create_scratchmem(dtrace_hdl_t *dtp)
  * from the DTrace consumer handle (dt_strlen).
  *
  * The read-only data is appended to the string table, as is a memory block of
- * zeros for initializing memory regions.
+ * zeros for initializing memory regions.  BPF programs may only read this map.
  *
  * In order to ensure the BPF verifier can validate all access requests for
  * dynamic references to string constants, the size of the read-only data plus
@@ -914,8 +921,8 @@ gmap_create_strtab(dtrace_hdl_t *dtp)
 	dt_rodata_write(dtp->dt_rodata, (dt_rodata_copy_f *)dt_rodata_copy,
 			strtab + dtp->dt_rooffset);
 
-	fd = create_gmap(dtp, "strtab", BPF_MAP_TYPE_ARRAY, sizeof(uint32_t),
-			 sz, 1);
+	fd = create_gmap_flags(dtp, "strtab", BPF_MAP_TYPE_ARRAY,
+			       sizeof(uint32_t), sz, 1, BPF_F_RDONLY_PROG);
 	if (fd == -1)
 		return -1;
 

-- 
2.55.0

