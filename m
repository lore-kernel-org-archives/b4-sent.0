From: Janne Grunau <j@jannau.net>
Date: Wed, 12 Jul 2023 08:42:20 +0200
Subject: [PATCH] kbuild: rpm-pkg: Add dtbs support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230712-kbuild_rpm_dtbs-v1-1-99693e8faaaf@jannau.net>
X-B4-Tracking: v=1; b=H4sIAEtLrmQC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI2MDc0Mj3eyk0syclPiigtz4lJKkYt0UA1PTRGNzC4OkpFQloK6CotS0zAq
 widGxtbUAJFQ7cGEAAAA=
To: Masahiro Yamada <masahiroy@kernel.org>, 
 Nathan Chancellor <nathan@kernel.org>, 
 Nick Desaulniers <ndesaulniers@google.com>, 
 Nicolas Schier <nicolas@fjasle.eu>
Cc: linux-kbuild@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2064; i=j@jannau.net;
 h=from:subject:message-id; bh=pqGGqDq9keUrENGYOALz/M+BMKf1FbSWOisiewqrdWw=;
 b=owJ4nJvAy8zAJbZQ2uZ2r35qGuNptSSGlHXePilL8v9Nb7kXvHy/hEax8s0vUYeldk7jW13n1
 KO9OHr5Mo2OUhYGMS4GWTFFliTtlx0Mq2sUY2ofhMHMYWUCGcLAxSkAEzknx8jw4oDAK1Hh2vur
 3s03twqYv7793qWJ7fafPl+ut0lvVmo1YPgrx3zOoOFWRt/0e78kL5m05J+Yc/s9/yHTrvka6ks
 WqacxAwBrX0jq
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/default with auth_id=62
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Based on the dtbs support in builddeb. Both Fedora and openSUSE kernel
rpm install their dtbs in "/boot/dtb-${KERNELRELEASE}". There seems no
other popular rpm based distributions which would benefit from dtbs
support and are not derived from those two.

Signed-off-by: Janne Grunau <j@jannau.net>
---
 scripts/package/mkspec | 11 +++++++++++
 1 file changed, 11 insertions(+)

diff --git a/scripts/package/mkspec b/scripts/package/mkspec
index 8049f0e2c110..a170b0c0a93f 100755
--- a/scripts/package/mkspec
+++ b/scripts/package/mkspec
@@ -28,6 +28,14 @@ else
 	M=DEL
 fi
 
+# Only some architectures with OF support have the dtbs_install target
+if grep -q CONFIG_OF_EARLY_FLATTREE=y include/config/auto.conf && \
+   [ -d "${srctree}/arch/${SRCARCH}/boot/dts" ]; then
+	D=
+else
+	D=DEL
+fi
+
 __KERNELRELEASE=$(echo $KERNELRELEASE | sed -e "s/-/_/g")
 EXCLUDES="$RCS_TAR_IGNORE --exclude=*vmlinux* --exclude=*.mod \
 --exclude=*.o --exclude=*.ko --exclude=*.cmd --exclude=Documentation \
@@ -38,6 +46,8 @@ EXCLUDES="$RCS_TAR_IGNORE --exclude=*vmlinux* --exclude=*.mod \
 # Labels:
 #  $S: this line is enabled only when building source package
 #  $M: this line is enabled only when CONFIG_MODULES is enabled
+#  $D: this line is enabled only when CONFIG_OF_EARLY_FLATTREE is enabled and
+#      the arch has a dts directory
 sed -e '/^DEL/d' -e 's/^\t*//' <<EOF
 	Name: kernel
 	Summary: The Linux Kernel
@@ -103,6 +113,7 @@ $S
 	%endif
 $M	$MAKE %{?_smp_mflags} INSTALL_MOD_PATH=%{buildroot} modules_install
 	$MAKE %{?_smp_mflags} INSTALL_HDR_PATH=%{buildroot}/usr headers_install
+$D	$MAKE %{?_smp_mflags} INSTALL_DTBS_PATH=%{buildroot}/boot/dtb-${KERNELRELEASE} dtbs_install
 	cp System.map %{buildroot}/boot/System.map-$KERNELRELEASE
 	cp .config %{buildroot}/boot/config-$KERNELRELEASE
 $S$M	rm -f %{buildroot}/lib/modules/$KERNELRELEASE/build

---
base-commit: 06c2afb862f9da8dc5efa4b6076a0e48c3fbaaa5
change-id: 20230712-kbuild_rpm_dtbs-d055a3780bbe

Best regards,
-- 
Janne Grunau <j@jannau.net>

