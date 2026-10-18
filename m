From: Eslam Almorshdy <ealmorshdy@d-matrix.ai>
Date: Sun, 18 Oct 2026 07:46:09 +0000
Subject: [PATCH 1/2] libproc: name objects by their mapped file when there
 is no link map
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261018-bug005-pid-noninvasive-names-v1-1-417b0f34f0b8@d-matrix.ai>
References: <20261018-bug005-pid-noninvasive-names-v1-0-417b0f34f0b8@d-matrix.ai>
In-Reply-To: <20261018-bug005-pid-noninvasive-names-v1-0-417b0f34f0b8@d-matrix.ai>
To: dtrace@lists.linux.dev
Cc: Alan Maguire <alan.maguire@oracle.com>, 
 Kris Van Hees <kris.van.hees@oracle.com>, dtrace-devel@oss.oracle.com, 
 Eugene Loh <eugene.loh@oracle.com>, Nick Alcock <nick.alcock@oracle.com>, 
 Eslam Almorshdy <ealmorshdy@d-matrix.ai>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792309584; l=4573;
 i=ealmorshdy@d-matrix.ai; s=20261015; h=from:subject:message-id;
 bh=jLsuKRfbKhhAPOyJ+pdcKtwqpJa+0ZQwndUx8MoPuyI=;
 b=myyenk1krHapSrZTciGklBmTHcwVWStUYqq/oYQt/CKeKP7hvARMb6xIZkhRxygzxLbhmu3mm
 RgE48H0DZ8YByWN8DBvMZAC+yMR8V59+1V1WptkP4JU1CkpDKx92ysd
X-Developer-Key: i=ealmorshdy@d-matrix.ai; a=ed25519;
 pk=E4tVAIvp2rvz2CB7Re6YVMP6FiUVSxuq0TUtjGQL5NM=
X-Endpoint-Received: by B4 Relay for ealmorshdy@d-matrix.ai/20261015 with auth_id=1187
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit 4aec5c99 ("dt_pid: pid grabs should be shortlived"),
dtrace creates pid probes on a running process through a short-lived
grab, which is noninvasive if the process is a system daemon, is
already being traced or may not be ptrace()d.  pid$pid probes then
fail.  For example, pid4242:a.out:main:entry fails with "failed to
lookup 'main' in module 'a.out'" when dtrace runs as root in a
container without systemd and process 4242 has no terminal.

A noninvasive grab has no rtld_db, so libproc never learns ld.so's
names for the objects in the process, and it looks objects up only by
those names:

 - Pobject_iter() passes "" as every object's name, so an empty or
   globbed module matches nothing;
 - object_to_map() matches base names only against ld.so's names, so
   neither a.out (which dt_pid_fix_mod() turns into the executable's
   base name) nor a library's base name is found;
 - Plmid() fails, so the module is named LMffffffffffffffff`main
   rather than main.

Name each object by the file it is mapped from, as map_iter() already
does for the executable and Pobjname() for any object without a
link-map name, and put every object on the base link map when there is
no rtld_db.  Invasive grabs are unaffected: the new branches are taken
only when the link-map name or rtld_db is missing.

Assisted-by: Claude Code:claude-opus-5-5
Signed-off-by: Eslam Almorshdy <ealmorshdy@d-matrix.ai>
---
 libproc/Psymtab.c | 43 +++++++++++++++++++++++++++++++++++++++----
 1 file changed, 39 insertions(+), 4 deletions(-)

diff --git a/libproc/Psymtab.c b/libproc/Psymtab.c
index e648c5aa..06bbcaef 100644
--- a/libproc/Psymtab.c
+++ b/libproc/Psymtab.c
@@ -1673,6 +1673,25 @@ Paddr2mptr(struct ps_prochandle *P, uintptr_t addr)
 	return &P->mappings[mpidx];
 }
 
+/*
+ * The base name of an object: ld.so's name for it if we have the link map,
+ * else the base name of the file it is mapped from (e.g. after a noninvasive
+ * grab, which has no rtld_db).
+ */
+static const char *
+file_basename(const file_info_t *fp)
+{
+	const char *p;
+
+	if (fp->file_lbase != NULL)
+		return fp->file_lbase;
+	if (fp->file_pname == NULL)
+		return NULL;
+	if ((p = strrchr(fp->file_pname, '/')) != NULL)
+		return p + 1;
+	return fp->file_pname;
+}
+
 /*
  * Given a shared object name, return the map_info_t for it.  If no matching
  * object is found, return NULL.  Normally, the link maps contain the full
@@ -1696,6 +1715,7 @@ object_to_map(struct ps_prochandle *P, Lmid_t lmid, const char *objname)
 {
 	map_info_t *mp;
 	file_info_t *fp;
+	const char *base;
 	size_t objlen;
 	uint_t i;
 
@@ -1725,7 +1745,7 @@ object_to_map(struct ps_prochandle *P, Lmid_t lmid, const char *objname)
 		 * one; if none (unlikely), just return the mapping we matched.
 		 */
 		if ((fp->file_pname && strcmp(fp->file_pname, objname) == 0) ||
-		    (fp->file_lbase && strcmp(fp->file_lbase, objname) == 0) ||
+		    ((base = file_basename(fp)) && strcmp(base, objname) == 0) ||
 		    (fp->file_lname && strcmp(fp->file_lname, objname) == 0))
 			return fp->file_map != -1 ? &P->mappings[fp->file_map] : mp;
 	}
@@ -1749,9 +1769,9 @@ object_to_map(struct ps_prochandle *P, Lmid_t lmid, const char *objname)
 		 * If we match, return the primary text mapping, if there is
 		 * one; if none (unlikely), just return the mapping we matched.
 		 */
-		if (fp->file_lbase &&
-		    (strncmp(fp->file_lbase, objname, objlen) == 0) &&
-		    (fp->file_lbase[objlen] == '.'))
+		if ((base = file_basename(fp)) != NULL &&
+		    (strncmp(base, objname, objlen) == 0) &&
+		    (base[objlen] == '.'))
 			return fp->file_map != -1 ? &P->mappings[fp->file_map] : mp;
 	}
 
@@ -2252,8 +2272,14 @@ Pobject_iter(struct ps_prochandle *P, proc_map_f *func, void *cd)
 	    cnt; cnt--, fptr = dt_list_next(fptr)) {
 		const char *lname;
 
+		/*
+		 * Without the link map (noninvasive grab), name the object by
+		 * the file it is mapped from.
+		 */
 		if (fptr->file_lname != NULL)
 			lname = fptr->file_lname;
+		else if (fptr->file_pname != NULL)
+			lname = fptr->file_pname;
 		else
 			lname = "";
 
@@ -2331,6 +2357,15 @@ Plmid(struct ps_prochandle *P, uintptr_t addr, Lmid_t *lmidp)
 		return 0;
 	}
 
+	/*
+	 * Without rtld_db (a noninvasive grab, or no dynamic linker) there is
+	 * no link map: every mapped object is on the base link map.
+	 */
+	if (mptr != NULL && P->rap == NULL) {
+		*lmidp = LM_ID_BASE;
+		return 0;
+	}
+
 	return -1;
 }
 

-- 
2.55.0

