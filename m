From: Joel Granados <joel.granados@kernel.org>
Date: Tue, 08 Apr 2025 10:02:42 +0200
Subject: [PATCH 2/3] scripts: Add root dir to arguments
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250408-jag-sysctl-v1-2-f5c4aba3e7ff@kernel.org>
References: <20250408-jag-sysctl-v1-0-f5c4aba3e7ff@kernel.org>
In-Reply-To: <20250408-jag-sysctl-v1-0-f5c4aba3e7ff@kernel.org>
To: =?utf-8?q?Alex_Benn=C3=A9e?= <alex.bennee@linaro.org>, 
 =?utf-8?q?Philippe_Mathieu-Daud=C3=A9?= <philmd@linaro.org>, 
 Thomas Huth <thuth@redhat.com>, 
 Wainer dos Santos Moschetta <wainersm@redhat.com>
Cc: Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3596;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=nhhtsinaOBQHNfYgiTQPRXdYH8S92/y0v4vPFKB9/BA=;
 b=kA0DAAoBupfNUreWQU8ByyZiAGf02Fegk/6fY9TzIzsBM6eY2UpbApo1DeGchN3FsIUl8wDkz
 4kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJn9NhXAAoJELqXzVK3lkFPIFEL/2XL
 ZguPb+wU+O77Sh5/bcCQ8gEitlZdTpvm0Xfx/BhzZ4czXeuUn7snn3HIlu0EVhHy2kY4mzIXqps
 FDoEmP0z16270FaVwEvPeeyEk0477Jl0jG0hMr5GL7uqDHwUYu4xwZioaMj1FuxppmPbrMQ2Y7B
 41A02zoI253dcPa3nIYQeFWv2w/o9QeAPDZgcE6JfQTGuAXUga31xddiZcpAsc5dPe6wV0FmJD+
 QL+DThsa5W1Ve0SKG+sH0qb9sHf+vpyEUwqjs267WQVgsgLr7r8WQuB0E8HuDMyg6IqBjMIKpZW
 33kmawlaxkTnEdYxVT7EOd6fSeXuHmYoUYe/mFKFnf3e+iyV3/fRoVfvdiiRZga/Uoyz8GH/G2D
 y4yHApNslyIpR2zSUcvKYzOUqWQAChKadzh+6VXfu7dTuWW0vx8g2joNqZoL3Eyy7qwE86hDPYc
 Sw+8FeRS/SUsQOl4BZZJHNmM9J980P+BOYacReRygNTGJtrbgPFg1QcM4e4Q==
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The archive-source script appended everything directly on the tar root
making it unusable for creating nix overlays; nix expects all files to
be under a directory in the tarbal.

Add a "-d|--dir" argument that places all files under a custom root.
Behaviour is unchanged when the argument is not given.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 scripts/archive-source.sh | 78 ++++++++++++++++++++++++++++++++++++++---------
 1 file changed, 63 insertions(+), 15 deletions(-)

diff --git a/scripts/archive-source.sh b/scripts/archive-source.sh
index a469a5e2dec4b05e51474f0a1af190c1ccf23c7e..7143aaefc1133fe991b329df3c78e6ed7726322f 100755
--- a/scripts/archive-source.sh
+++ b/scripts/archive-source.sh
@@ -9,19 +9,6 @@
 # This code is licensed under the GPL version 2 or later.  See
 # the COPYING file in the top-level directory.
 
-error() {
-    printf %s\\n "$*" >&2
-    exit 1
-}
-
-if test $# -lt 1; then
-    error "Usage: $0 <output tarball>"
-fi
-
-tar_file=$(realpath "$1")
-sub_tdir=$(mktemp -d "${tar_file%.tar}.sub.XXXXXXXX")
-sub_file="${sub_tdir}/submodule.tar"
-
 # We want a predictable list of submodules for builds, that is
 # independent of what the developer currently has initialized
 # in their checkout, because the build environment is completely
@@ -32,6 +19,61 @@ subprojects="keycodemapdb libvfio-user berkeley-softfloat-3
   proc-macro-error-1-rs proc-macro-error-attr-1-rs quote-1-rs
   syn-2-rs unicode-ident-1-rs"
 sub_deinit=""
+git_archive_prefix=""
+tar_transform=""
+
+BASENAME="$(basename "${BASH_SOURCE[0]}")"
+USAGE="Usage: ${BASENAME} [OPTIONS] <tarball>
+  <tarball>             Resulting tarball name
+
+  OPTIONS:
+    -d, --dir <DIR>     Files will be placed into DIR inside the tarball
+"
+
+error() {
+    printf %s\\n "$*" >&2
+    exit 1
+}
+
+get_opts() {
+    local short="d:"
+    local long="dir:"
+
+    if ! tmp=$(getopt -o "$short" --long "$long" -n "$BASENAME" -- "$@"); then
+        exit 1
+    fi
+    eval set -- "$tmp"
+    unset tmp
+
+    while true; do
+      case "$1" in
+        '-d' | '--dir' )
+            local tar_dir_name=$"$2/"; shift 2
+            git_archive_prefix="--prefix ${tar_dir_name}"
+            tar_transform="--transform=s|^|${tar_dir_name}|"
+            ;;
+
+        '--' )
+            shift 1
+            ;;
+
+        * )
+            tar_file_name="$1"; shift
+            break
+            ;;
+
+      esac
+    done
+
+    if [ $# -gt 0 ]; then
+        echo "Superfluous args: $@"
+        error "${USAGE}"
+    fi
+
+    tar_file=$(realpath "$tar_file_name")
+    sub_tdir=$(mktemp -d "${tar_file%.tar}.sub.XXXXXXXX")
+    sub_file="${sub_tdir}/submodule.tar"
+}
 
 function cleanup() {
     local status=$?
@@ -73,13 +115,19 @@ function subproject_dir() {
     echo "${dir:-$1}"
 }
 
-git archive --format tar "$(tree_ish)" > "$tar_file"
+get_opts "$@"
+
+git archive --format tar ${git_archive_prefix} "$(tree_ish)" > "$tar_file"
 test $? -ne 0 && error "failed to archive qemu"
 
 for sp in $subprojects; do
     meson subprojects download $sp
     test $? -ne 0 && error "failed to download subproject $sp"
-    tar --append --file "$tar_file" --exclude=.git subprojects/"$(subproject_dir $sp)"
+    tar --append \
+        --file "$tar_file" \
+        --exclude=.git \
+        ${tar_transform} \
+        subprojects/"$(subproject_dir $sp)"
     test $? -ne 0 && error "failed to append subproject $sp to $tar_file"
 done
 exit 0

-- 
2.44.1

