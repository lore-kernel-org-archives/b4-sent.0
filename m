From: Ernst Persson <ernst.persson@non.se.com>
Date: Fri, 10 Apr 2026 12:53:03 +0200
Subject: [PATCH] busybox: fix for CVE-2026-26157, CVE-2026-26158
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260410-busybox-fix-cve-v1-1-42202093b870@non.se.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MywqAIBAAf0X23IKaPX8lOqRttRcLpSikf086D
 sNMgkiBKUIvEgS6OPLuM6hCgNsmvxLynBm01LU0SqI942P3Gxe+0V2E3VTq1qhmLqsWcnUEyuo
 /DuP7fuYlDwJhAAAA
X-Change-ID: 20260410-busybox-fix-cve-9a328417d358
To: openembedded-core@lists.openembedded.org
Cc: Hitendra Prajapati <hprajapati@mvista.com>, 
 Ernst Persson <ernst.persson@non.se.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=12146;
 i=ernst.persson@non.se.com; s=4B54C57358F748DFEB181A7AB352515D6EE690C1;
 h=from:subject:message-id; bh=FwqRnYSWoHFpjYsTKiVYnhWpMnJcNcWt3RC5e8uP1Ec=;
 b=owGbwMvMwCW2OSgwNu/ZhIOMp9WSGDJvXJuy9B3HngWfuYU8H02Knr5w5WPWtebLqmNeHdmoo
 XxA68WLcx2lLAxiXAyyYoos3iFHiyO+e9x/LSFVBTOHlQlkCAMXpwBMRFmd4Z+JjNBTwR6pdicb
 G6VpVxgmqYtLX5nS4v+3zUQscEFO4DtGhrYPxxc+/Ty7q7vj19W59bV6v3qesfFumreuh5Pv7ME
 3DPwA
X-Developer-Key: i=ernst.persson@non.se.com; a=openpgp;
 fpr=4B54C57358F748DFEB181A7AB352515D6EE690C1
X-Endpoint-Received: by B4 Relay for ernst.persson@non.se.com/4B54C57358F748DFEB181A7AB352515D6EE690C1 with auth_id=729
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Pick up patch from NVD report.

More details :
[1]: https://nvd.nist.gov/vuln/detail/CVE-2026-26157
[2]: https://nvd.nist.gov/vuln/detail/CVE-2026-26158

Note:
We use patch from busybox mirror that looks trustworthy https://gogs.librecmc.org/OWEALS/busybox.

Suggested-by: Hitendra Prajapati <hprajapati@mvista.com>
Signed-off-by: Ernst Persson <ernst.persson@non.se.com>
---
 ...nsafe-hardlink-components-GNU-tar-does-th.patch | 196 +++++++++++++++++++++
 ...rip-unsafe-components-from-hardlinks-not-.patch |  35 ++++
 meta/recipes-core/busybox/busybox_1.37.0.bb        |   4 +-
 3 files changed, 234 insertions(+), 1 deletion(-)

diff --git a/meta/recipes-core/busybox/busybox/0001-tar-strip-unsafe-hardlink-components-GNU-tar-does-th.patch b/meta/recipes-core/busybox/busybox/0001-tar-strip-unsafe-hardlink-components-GNU-tar-does-th.patch
new file mode 100644
index 0000000000..46e47c5993
--- /dev/null
+++ b/meta/recipes-core/busybox/busybox/0001-tar-strip-unsafe-hardlink-components-GNU-tar-does-th.patch
@@ -0,0 +1,196 @@
+From 3ab1d6c123a6916e7efb821a441164ae56c6cd01 Mon Sep 17 00:00:00 2001
+From: Denys Vlasenko <vda.linux@googlemail.com>
+Date: Thu, 29 Jan 2026 11:48:02 +0100
+Subject: [PATCH] tar: strip unsafe hardlink components - GNU tar does the same
+
+Defends against files like these (python reproducer):
+
+import tarfile
+ti = tarfile.TarInfo("leak_hosts")
+ti.type = tarfile.LNKTYPE
+ti.linkname = "/etc/hosts"  # or "../etc/hosts" or ".."
+ti.size = 0
+with tarfile.open("/tmp/hardlink.tar", "w") as t:
+	t.addfile(ti)
+
+function                                             old     new   delta
+skip_unsafe_prefix                                     -     127    +127
+get_header_tar                                      1752    1754      +2
+.rodata                                           106861  106856      -5
+unzip_main                                          2715    2706      -9
+strip_unsafe_prefix                                  102      18     -84
+------------------------------------------------------------------------------
+(add/remove: 1/0 grow/shrink: 1/3 up/down: 129/-98)            Total: 31 bytes
+
+Signed-off-by: Denys Vlasenko <vda.linux@googlemail.com>
+
+CVE: CVE-2026-26157
+CVE: CVE-2026-26158
+Upstream-Status: Backport [https://git.busybox.net/busybox/commit/?id=3fb6b31c716669e12f75a2accd31bb7685b1a1cb]
+(Alternative mirrored URL: https://gogs.librecmc.org/OWEALS/busybox/commit/3fb6b31c716669e12f75a2accd31bb7685b1a1cb)
+Signed-off-by: Ernst Persson <ernst.persson@non.se.com>
+---
+ archival/libarchive/data_extract_all.c      |  7 +++--
+ archival/libarchive/get_header_tar.c        | 11 ++++++--
+ archival/libarchive/unsafe_prefix.c         | 30 +++++++++++++++++----
+ archival/libarchive/unsafe_symlink_target.c |  1 +
+ archival/tar.c                              |  2 +-
+ archival/unzip.c                            |  2 +-
+ include/bb_archive.h                        |  3 ++-
+ 7 files changed, 42 insertions(+), 14 deletions(-)
+
+diff --git a/archival/libarchive/data_extract_all.c b/archival/libarchive/data_extract_all.c
+index 8a69711..b84b960 100644
+--- a/archival/libarchive/data_extract_all.c
++++ b/archival/libarchive/data_extract_all.c
+@@ -66,8 +66,8 @@ void FAST_FUNC data_extract_all(archive_handle_t *archive_handle)
+ 	}
+ #endif
+ #if ENABLE_FEATURE_PATH_TRAVERSAL_PROTECTION
+-	/* Strip leading "/" and up to last "/../" path component */
+-	dst_name = (char *)strip_unsafe_prefix(dst_name);
++	/* Skip leading "/" and past last ".." path component */
++	dst_name = (char *)skip_unsafe_prefix(dst_name);
+ #endif
+ // ^^^ This may be a problem if some applets do need to extract absolute names.
+ // (Probably will need to invent ARCHIVE_ALLOW_UNSAFE_NAME flag).
+@@ -185,8 +185,7 @@ void FAST_FUNC data_extract_all(archive_handle_t *archive_handle)
+ 
+ 		/* To avoid a directory traversal attack via symlinks,
+ 		 * do not restore symlinks with ".." components
+-		 * or symlinks starting with "/", unless a magic
+-		 * envvar is set.
++		 * or symlinks starting with "/"
+ 		 *
+ 		 * For example, consider a .tar created via:
+ 		 *  $ tar cvf bug.tar anything.txt
+diff --git a/archival/libarchive/get_header_tar.c b/archival/libarchive/get_header_tar.c
+index cc6f3f0..1c40ece 100644
+--- a/archival/libarchive/get_header_tar.c
++++ b/archival/libarchive/get_header_tar.c
+@@ -454,8 +454,15 @@ char FAST_FUNC get_header_tar(archive_handle_t *archive_handle)
+ #endif
+ 
+ 	/* Everything up to and including last ".." component is stripped */
+-	overlapping_strcpy(file_header->name, strip_unsafe_prefix(file_header->name));
+-//TODO: do the same for file_header->link_target?
++	strip_unsafe_prefix(file_header->name);
++	if (file_header->link_target) {
++		/* GNU tar 1.34 examples:
++		 * tar: Removing leading '/' from hard link targets
++		 * tar: Removing leading '../' from hard link targets
++		 * tar: Removing leading 'etc/../' from hard link targets
++		 */
++		strip_unsafe_prefix(file_header->link_target);
++	}
+ 
+ 	/* Strip trailing '/' in directories */
+ 	/* Must be done after mode is set as '/' is used to check if it's a directory */
+diff --git a/archival/libarchive/unsafe_prefix.c b/archival/libarchive/unsafe_prefix.c
+index 6670811..89a371a 100644
+--- a/archival/libarchive/unsafe_prefix.c
++++ b/archival/libarchive/unsafe_prefix.c
+@@ -5,11 +5,11 @@
+ #include "libbb.h"
+ #include "bb_archive.h"
+ 
+-const char* FAST_FUNC strip_unsafe_prefix(const char *str)
++const char* FAST_FUNC skip_unsafe_prefix(const char *str)
+ {
+ 	const char *cp = str;
+ 	while (1) {
+-		char *cp2;
++		const char *cp2;
+ 		if (*cp == '/') {
+ 			cp++;
+ 			continue;
+@@ -22,10 +22,25 @@ const char* FAST_FUNC strip_unsafe_prefix(const char *str)
+ 			cp += 3;
+ 			continue;
+ 		}
+-		cp2 = strstr(cp, "/../");
++		cp2 = cp;
++ find_dotdot:
++		cp2 = strstr(cp2, "/..");
+ 		if (!cp2)
+-			break;
+-		cp = cp2 + 4;
++			break; /* No (more) malicious components */
++
++		/* We found "/..something" */
++		cp2 += 3;
++		if (*cp2 != '/') {
++			if (*cp2 == '\0') {
++				/* Trailing "/..": malicious, return "" */
++				/* (causes harmless errors trying to create or hardlink a file named "") */
++				return cp2;
++			}
++			/* "/..name" is not malicious, look for next "/.." */
++			goto find_dotdot;
++		}
++		/* Found "/../": malicious, advance past it */
++		cp = cp2 + 1;
+ 	}
+ 	if (cp != str) {
+ 		static smallint warned = 0;
+@@ -37,3 +52,8 @@ const char* FAST_FUNC strip_unsafe_prefix(const char *str)
+ 	}
+ 	return cp;
+ }
++
++void FAST_FUNC strip_unsafe_prefix(char *str)
++{
++	overlapping_strcpy(str, skip_unsafe_prefix(str));
++}
+diff --git a/archival/libarchive/unsafe_symlink_target.c b/archival/libarchive/unsafe_symlink_target.c
+index f8dc803..d764c89 100644
+--- a/archival/libarchive/unsafe_symlink_target.c
++++ b/archival/libarchive/unsafe_symlink_target.c
+@@ -36,6 +36,7 @@ void FAST_FUNC create_links_from_list(llist_t *list)
+ 				*list->data ? "hard" : "sym",
+ 				list->data + 1, target
+ 			);
++			/* Note: GNU tar 1.34 errors out only _after_ all links are (attempted to be) created */
+ 		}
+ 		list = list->link;
+ 	}
+diff --git a/archival/tar.c b/archival/tar.c
+index d6ca6c1..d42dcfc 100644
+--- a/archival/tar.c
++++ b/archival/tar.c
+@@ -475,7 +475,7 @@ static int FAST_FUNC writeFileToTarball(struct recursive_state *state,
+ 	DBG("writeFileToTarball('%s')", fileName);
+ 
+ 	/* Strip leading '/' and such (must be before memorizing hardlink's name) */
+-	header_name = strip_unsafe_prefix(fileName);
++	header_name = skip_unsafe_prefix(fileName);
+ 
+ 	if (header_name[0] == '\0')
+ 		return TRUE;
+diff --git a/archival/unzip.c b/archival/unzip.c
+index 71a3029..8a9a90f 100644
+--- a/archival/unzip.c
++++ b/archival/unzip.c
+@@ -860,7 +860,7 @@ int unzip_main(int argc, char **argv)
+ 
+ 		/* Guard against "/abspath", "/../" and similar attacks */
+ // NB: UnZip 6.00 has option -: to disable this
+-		overlapping_strcpy(dst_fn, strip_unsafe_prefix(dst_fn));
++		strip_unsafe_prefix(dst_fn);
+ 
+ 		/* Filter zip entries */
+ 		if (find_list_entry(zreject, dst_fn)
+diff --git a/include/bb_archive.h b/include/bb_archive.h
+index e0ef8fc..1dc77f3 100644
+--- a/include/bb_archive.h
++++ b/include/bb_archive.h
+@@ -202,7 +202,8 @@ char get_header_tar_xz(archive_handle_t *archive_handle) FAST_FUNC;
+ void seek_by_jump(int fd, off_t amount) FAST_FUNC;
+ void seek_by_read(int fd, off_t amount) FAST_FUNC;
+ 
+-const char *strip_unsafe_prefix(const char *str) FAST_FUNC;
++const char *skip_unsafe_prefix(const char *str) FAST_FUNC;
++void strip_unsafe_prefix(char *str) FAST_FUNC;
+ void create_or_remember_link(llist_t **link_placeholders,
+ 		const char *target,
+ 		const char *linkname,
diff --git a/meta/recipes-core/busybox/busybox/0002-tar-only-strip-unsafe-components-from-hardlinks-not-.patch b/meta/recipes-core/busybox/busybox/0002-tar-only-strip-unsafe-components-from-hardlinks-not-.patch
new file mode 100644
index 0000000000..830082a7d6
--- /dev/null
+++ b/meta/recipes-core/busybox/busybox/0002-tar-only-strip-unsafe-components-from-hardlinks-not-.patch
@@ -0,0 +1,35 @@
+From 981479997e29953c1a12c9c7376c9d259d035311 Mon Sep 17 00:00:00 2001
+From: Radoslav Kolev <radoslav.kolev@suse.com>
+Date: Mon, 16 Feb 2026 11:50:04 +0200
+Subject: [PATCH] tar: only strip unsafe components from hardlinks, not
+ symlinks
+
+commit 3fb6b31c7 introduced a check for unsafe components in
+tar archive hardlinks, but it was being applied to symlinks too
+which broke "Symlinks and hardlinks coexist" tar test.
+
+Signed-off-by: Radoslav Kolev <radoslav.kolev@suse.com>
+Signed-off-by: Denys Vlasenko <vda.linux@googlemail.com>
+
+CVE: CVE-2026-26157
+CVE: CVE-2026-26158
+Upstream-Status: Backport [https://git.busybox.net/busybox/commit/?id=599f5dd8fac390c18b79cba4c14c334957605dae]
+(Alternative mirrored URL: https://gogs.librecmc.org/OWEALS/busybox/commit/599f5dd8fac390c18b79cba4c14c334957605dae)
+Signed-off-by: Ernst Persson <ernst.persson@non.se.com>
+---
+ archival/libarchive/get_header_tar.c | 2 +-
+ 1 file changed, 1 insertion(+), 1 deletion(-)
+
+diff --git a/archival/libarchive/get_header_tar.c b/archival/libarchive/get_header_tar.c
+index 1c40ece..606d806 100644
+--- a/archival/libarchive/get_header_tar.c
++++ b/archival/libarchive/get_header_tar.c
+@@ -455,7 +455,7 @@ char FAST_FUNC get_header_tar(archive_handle_t *archive_handle)
+ 
+ 	/* Everything up to and including last ".." component is stripped */
+ 	strip_unsafe_prefix(file_header->name);
+-	if (file_header->link_target) {
++	if (file_header->link_target && !S_ISLNK(file_header->mode)) {
+ 		/* GNU tar 1.34 examples:
+ 		 * tar: Removing leading '/' from hard link targets
+ 		 * tar: Removing leading '../' from hard link targets
diff --git a/meta/recipes-core/busybox/busybox_1.37.0.bb b/meta/recipes-core/busybox/busybox_1.37.0.bb
index fbb0edb0fb..61ff602be6 100644
--- a/meta/recipes-core/busybox/busybox_1.37.0.bb
+++ b/meta/recipes-core/busybox/busybox_1.37.0.bb
@@ -60,7 +60,9 @@ SRC_URI = "https://busybox.net/downloads/busybox-${PV}.tar.bz2;name=tarball \
            file://CVE-2025-46394-01.patch \
            file://CVE-2025-46394-02.patch \
            file://CVE-2025-60876.patch \
-           file://0001-busybox-fix-printf-ptest-failure-with-glibc-2.43.patch \ 
+           file://0001-busybox-fix-printf-ptest-failure-with-glibc-2.43.patch \
+           file://0001-tar-strip-unsafe-hardlink-components-GNU-tar-does-th.patch \
+           file://0002-tar-only-strip-unsafe-components-from-hardlinks-not-.patch \
            "
 SRC_URI:append:libc-musl = " file://musl.cfg"
 SRC_URI:append:x86-64 = " file://sha_accel.cfg"

---
base-commit: 853baa702e3275fc8b4dc492a93d9a00c8cf5c0f
change-id: 20260410-busybox-fix-cve-9a328417d358

Best regards,
-- 
Ernst Persson <ernst.persson@non.se.com>

