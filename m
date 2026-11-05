From: Chen Linxuan <me@black-desk.cn>
Date: Thu, 05 Nov 2026 21:25:41 +0800
Subject: [PATCH] datatype: resolve the root cgroupv2 path when listing
 elements
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-cgroupv2-root-path-v1-1-5ce9f3b71f76@black-desk.cn>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqFMAxF0a1IxgZs8Qu6FXFQ26hxYEtaRRD3b
 v0OD7x3L4gkTBG64gKhgyP7LUOVBdjFbDMhu2zQlW6Uqn5oZ/F7ODSK9wmDSQtOpnW1047yBvI
 xCE18/qP98Dnu40o2vSW47wdM/4qfdgAAAA==
X-Change-ID: 20261105-cgroupv2-root-path-fa9d4d2de026
To: netfilter-devel@vger.kernel.org
Cc: Chen Linxuan <me@black-desk.cn>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3766; i=me@black-desk.cn;
 s=20260831; h=from:subject:message-id;
 bh=ynhawRs9TC8bzVrl9IuqXluCi4I2gyuIGekmvjQf5U0=;
 b=owEBbQKS/ZANAwAKAXYe5hQ5ma6LAcsmYgBq7IPXLtKJyJlX/g6c1QGXZ8Bjsm3xggNe/aUSw
 CCiNR/ErwWJAjMEAAEKAB0WIQTO1VElAk6xdvy0ZVp2HuYUOZmuiwUCauyD1wAKCRB2HuYUOZmu
 i2MOD/9BR05L2KbM4QiPJU+U83vqnUM63a9xqEydaBaMsrL2CahoEWao+2gP/E/VMITdmJQTmU9
 x4Kqe59/KebMPxLBhI/yXmAeFQmXc0P9ZviFXTxsxbs9itT54IEmMvuf+9RnaJOe4QeAhDdSfth
 pKYuNia1V2LUZswBw6L8KvykMIYQDFAQ00VoQtdw73eep8Sd/m1PS+/J1HW+2F/SyaW/GHbvg49
 JoBLOBBeCu44DuEWGnVS+ZDrxTx1jMypl+XY8x3bFUlVr/a7DniL/N8FQvYB334bq7+YWzdNTiT
 c02iGLv+yEsGGstVPfg+jdnQyz0mw8GW+oDEwWR19pAhLa0Y2aoDMdRtjS/qlbv2R8c/lQu8+28
 RXYlFHx5ZsfTXHDyYq6E6HpHcig0QjOeFQRcHVKMOXOB6mJq89YlpCKaPdbHfHKfKcA22C5iBJ3
 5S3XHOnRt0lU4yeaUZGvjX1JUzSUHRJW+AMYirM9qVmwHNk41vz/LybI5SaLeM+UzQIEIJze2J5
 FMs3/aIlpkKL997eY5KzDjiNpITN52Agj7VxjkhhQsyNkdvbkE11o9GduhA3CPavAnHAb9OoZdj
 QZmd0XafwEKA2pzy74EI8zHkMnka46v8i2rKxbp/h6ZObvpglBR1b49Xx8ZNDeNrsn1hs1p0gSh
 fQGioVxSZmsxBrw==
X-Developer-Key: i=me@black-desk.cn; a=openpgp;
 fpr=D818ACDD385CAE92D4BAC01A6269794D24791D21
X-Endpoint-Received: by B4 Relay for me@black-desk.cn/20260831 with auth_id=991
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The cgroupsv2 datatype accepts "/" as input, but cgroupv2_get_path()
only searches the descendants of /sys/fs/cgroup. Consequently a set
containing the root cgroup is listed with its numeric ID instead of
"/".

Check the opened directory's inode before traversing its children.
Handle the root path explicitly when printing the result, since the
usual offset past the mount path and its slash would point beyond the
terminating NUL for the root itself.

Add a shell regression test for both list set and get element, and a
ruleset dump to check the displayed root path and reload validation.

Validated in an Arch Linux Docker container.

Fixes: 38228087252c ("src: add cgroupsv2 support")
Signed-off-by: Chen Linxuan <me@black-desk.cn>
---
 src/datatype.c                                     | 17 +++++++----
 tests/shell/testcases/parsing/cgroupv2_root        | 33 ++++++++++++++++++++++
 .../testcases/parsing/dumps/cgroupv2_root.nft      |  6 ++++
 3 files changed, 51 insertions(+), 5 deletions(-)

diff --git a/src/datatype.c b/src/datatype.c
index 5025b2762853..6039501f8303 100644
--- a/src/datatype.c
+++ b/src/datatype.c
@@ -1612,6 +1612,11 @@ static char *cgroupv2_get_path(const char *path, uint64_t id)
 	if (!d)
 		return NULL;
 
+	if (fstat(dirfd(d), &st) == 0 && st.st_ino == id) {
+		cgroup_path = xstrdup(path);
+		goto out;
+	}
+
 	while ((dent = readdir(d)) != NULL) {
 		if (!strcmp(dent->d_name, ".") ||
 		    !strcmp(dent->d_name, ".."))
@@ -1632,6 +1637,7 @@ static char *cgroupv2_get_path(const char *path, uint64_t id)
 				break;
 		}
 	}
+out:
 	closedir(d);
 
 	return cgroup_path;
@@ -1641,14 +1647,15 @@ static void cgroupv2_type_print(const struct expr *expr,
 				struct output_ctx *octx)
 {
 	uint64_t id = mpz_get_uint64(expr->value);
-	char *cgroup_path;
+	char *cgroup_path, *path;
 
 	cgroup_path = cgroupv2_get_path(SYSFS_CGROUPSV2_PATH, id);
-	if (cgroup_path)
-		nft_print(octx, "\"%s\"",
-			  &cgroup_path[strlen(SYSFS_CGROUPSV2_PATH) + 1]);
-	else
+	if (cgroup_path) {
+		path = cgroup_path + strlen(SYSFS_CGROUPSV2_PATH);
+		nft_print(octx, "\"%s\"", *path ? path + 1 : "/");
+	} else {
 		nft_print(octx, "%" PRIu64, id);
+	}
 
 	free(cgroup_path);
 }
diff --git a/tests/shell/testcases/parsing/cgroupv2_root b/tests/shell/testcases/parsing/cgroupv2_root
new file mode 100755
index 000000000000..9fb5ce837897
--- /dev/null
+++ b/tests/shell/testcases/parsing/cgroupv2_root
@@ -0,0 +1,33 @@
+#!/bin/bash
+
+# The root cgroup must be listed as a path, just like its descendants.
+
+set -e
+
+if [ "$(stat -f --printf=%T /sys/fs/cgroup)" != "cgroup2fs" ]; then
+	echo "not a cgroupv2 mount"
+	exit 77
+fi
+
+$NFT -f - <<'RULESET'
+table inet t {
+	set cgroups {
+		type cgroupsv2
+		elements = { "/" }
+	}
+}
+RULESET
+
+out=$($NFT list set inet t cgroups)
+if ! grep -Fq 'elements = { "/" }' <<< "$out"; then
+	echo "E: the root cgroup is not listed as /" >&2
+	echo "$out" >&2
+	exit 1
+fi
+
+out=$($NFT get element inet t cgroups '{ "/" }')
+if ! grep -Fq 'elements = { "/" }' <<< "$out"; then
+	echo "E: the root cgroup lookup is not listed as /" >&2
+	echo "$out" >&2
+	exit 1
+fi
diff --git a/tests/shell/testcases/parsing/dumps/cgroupv2_root.nft b/tests/shell/testcases/parsing/dumps/cgroupv2_root.nft
new file mode 100644
index 000000000000..f1ee29d7aa99
--- /dev/null
+++ b/tests/shell/testcases/parsing/dumps/cgroupv2_root.nft
@@ -0,0 +1,6 @@
+table inet t {
+	set cgroups {
+		type cgroupsv2
+		elements = { "/" }
+	}
+}

---
base-commit: 07be13393b00f0212605a3e0e5f489fe11cc6864
change-id: 20261105-cgroupv2-root-path-fa9d4d2de026

Best regards,
--  
Chen Linxuan <me@black-desk.cn>

