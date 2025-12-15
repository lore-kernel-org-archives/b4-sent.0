From: Massimiliano Minella <massimiliano.minella@se.com>
Date: Mon, 15 Dec 2025 18:12:07 +0100
Subject: [PATCH] oras: add recipe for oras v1.3.0
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251215-add_oras_recipe-v1-1-1075af14e8aa@se.com>
X-B4-Tracking: v=1; b=H4sIAGZBQGkC/x3MQQqAIBBA0avIrBNUFKKrRMikU83GYoQIwrsnL
 d/i/xcqCVOFSb0gdHPls3TYQUE6sOykOXeDMy5YZ4PGnOMpWKNQ4ou0N7h6jyNm46BXl9DGz3+
 cl9Y+0dRqOGEAAAA=
To: meta-virtualization@lists.yoctoproject.org
Cc: Massimiliano Minella <massimiliano.minella@se.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1765818733; l=19410;
 i=massimiliano.minella@se.com; s=20250121; h=from:subject:message-id;
 bh=mmLTP6pmqLaHLdi4pX24H8do7TGvmjbOQ6CiUw7hmKs=;
 b=SbdY48H0q8qpZY9zDTXCcmdqRxEz5CZ+mp1iSwRwv0CHf9svQwjiegoPAu2Nk1+8Re7HTnI+G
 KS8ndqZgY0IAluksd7qlurcBi75s7INYLzZkQsaRdcrTGAyDXynAQTD
X-Developer-Key: i=massimiliano.minella@se.com; a=ed25519;
 pk=p6Og4stDBPm4cBEySH8oVWARLO52pxVayNFqHslSXU0=
X-Endpoint-Received: by B4 Relay for massimiliano.minella@se.com/20250121 with auth_id=325
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ORAS is an OCI registry client for managing artifacts in container
registries. It enables pushing and pulling arbitrary artifacts to and
from OCI-compliant registries.

The base files for modules.txt, src_uri.inc and relocation.inc were
auto-generated using:

./scripts/oe-go-mod-autogen.py --repo https://github.com/oras-project/oras.git --rev v1.3.0

modules.txt has been updated by running 'go mod vendor' in a devshell
environment and copying the resulting modules.txt.

Signed-off-by: Massimiliano Minella <massimiliano.minella@se.com>
---
 recipes-containers/oras/files/modules.txt | 113 ++++++++++++++++++++++++++++++
 recipes-containers/oras/oras_git.bb       |  63 +++++++++++++++++
 recipes-containers/oras/relocation.inc    |  56 +++++++++++++++
 recipes-containers/oras/src_uri.inc       |  96 +++++++++++++++++++++++++
 4 files changed, 328 insertions(+)

diff --git recipes-containers/oras/files/modules.txt recipes-containers/oras/files/modules.txt
new file mode 100644
index 00000000..521b33f0
--- /dev/null
+++ recipes-containers/oras/files/modules.txt
@@ -0,0 +1,113 @@
+# dario.cat/mergo v1.0.2
+## explicit; go 1.13
+dario.cat/mergo
+# github.com/Masterminds/goutils v1.1.1
+## explicit
+github.com/Masterminds/goutils
+# github.com/Masterminds/semver/v3 v3.4.0
+## explicit; go 1.21
+github.com/Masterminds/semver/v3
+# github.com/Masterminds/sprig/v3 v3.3.0
+## explicit; go 1.21
+github.com/Masterminds/sprig/v3
+# github.com/containerd/console v1.0.5
+## explicit; go 1.13
+github.com/containerd/console
+# github.com/google/uuid v1.6.0
+## explicit
+github.com/google/uuid
+# github.com/huandu/xstrings v1.5.0
+## explicit; go 1.12
+github.com/huandu/xstrings
+# github.com/inconshreveable/mousetrap v1.1.0
+## explicit; go 1.18
+github.com/inconshreveable/mousetrap
+# github.com/mitchellh/copystructure v1.2.0
+## explicit; go 1.15
+github.com/mitchellh/copystructure
+# github.com/mitchellh/reflectwalk v1.0.2
+## explicit
+github.com/mitchellh/reflectwalk
+# github.com/morikuni/aec v1.0.0
+## explicit
+github.com/morikuni/aec
+# github.com/opencontainers/go-digest v1.0.0
+## explicit; go 1.13
+github.com/opencontainers/go-digest
+# github.com/opencontainers/image-spec v1.1.1
+## explicit; go 1.18
+github.com/opencontainers/image-spec/specs-go
+github.com/opencontainers/image-spec/specs-go/v1
+# github.com/shopspring/decimal v1.4.0
+## explicit; go 1.10
+github.com/shopspring/decimal
+# github.com/sirupsen/logrus v1.9.3
+## explicit; go 1.13
+github.com/sirupsen/logrus
+# github.com/spf13/cast v1.9.2
+## explicit; go 1.21.0
+github.com/spf13/cast
+github.com/spf13/cast/internal
+# github.com/spf13/cobra v1.10.1
+## explicit; go 1.15
+github.com/spf13/cobra
+# github.com/spf13/pflag v1.0.9
+## explicit; go 1.12
+github.com/spf13/pflag
+# golang.org/x/crypto v0.40.0
+## explicit; go 1.23.0
+golang.org/x/crypto/bcrypt
+golang.org/x/crypto/blowfish
+golang.org/x/crypto/pbkdf2
+golang.org/x/crypto/scrypt
+# golang.org/x/sync v0.16.0
+## explicit; go 1.23.0
+golang.org/x/sync/errgroup
+golang.org/x/sync/semaphore
+# golang.org/x/sys v0.35.0
+## explicit; go 1.23.0
+golang.org/x/sys/plan9
+golang.org/x/sys/unix
+golang.org/x/sys/windows
+# golang.org/x/term v0.34.0
+## explicit; go 1.23.0
+golang.org/x/term
+# gopkg.in/yaml.v3 v3.0.1
+## explicit
+gopkg.in/yaml.v3
+# oras.land/oras-go/v2 v2.6.0
+## explicit; go 1.23.0
+oras.land/oras-go/v2
+oras.land/oras-go/v2/content
+oras.land/oras-go/v2/content/file
+oras.land/oras-go/v2/content/memory
+oras.land/oras-go/v2/content/oci
+oras.land/oras-go/v2/errdef
+oras.land/oras-go/v2/internal/cas
+oras.land/oras-go/v2/internal/container/set
+oras.land/oras-go/v2/internal/copyutil
+oras.land/oras-go/v2/internal/descriptor
+oras.land/oras-go/v2/internal/docker
+oras.land/oras-go/v2/internal/fs/tarfs
+oras.land/oras-go/v2/internal/graph
+oras.land/oras-go/v2/internal/httputil
+oras.land/oras-go/v2/internal/interfaces
+oras.land/oras-go/v2/internal/ioutil
+oras.land/oras-go/v2/internal/manifestutil
+oras.land/oras-go/v2/internal/platform
+oras.land/oras-go/v2/internal/registryutil
+oras.land/oras-go/v2/internal/resolver
+oras.land/oras-go/v2/internal/spec
+oras.land/oras-go/v2/internal/status
+oras.land/oras-go/v2/internal/syncutil
+oras.land/oras-go/v2/registry
+oras.land/oras-go/v2/registry/remote
+oras.land/oras-go/v2/registry/remote/auth
+oras.land/oras-go/v2/registry/remote/credentials
+oras.land/oras-go/v2/registry/remote/credentials/internal/config
+oras.land/oras-go/v2/registry/remote/credentials/internal/executer
+oras.land/oras-go/v2/registry/remote/credentials/internal/ioutil
+oras.land/oras-go/v2/registry/remote/credentials/trace
+oras.land/oras-go/v2/registry/remote/errcode
+oras.land/oras-go/v2/registry/remote/internal/errutil
+oras.land/oras-go/v2/registry/remote/retry
diff --git recipes-containers/oras/oras_git.bb recipes-containers/oras/oras_git.bb
new file mode 100644
index 00000000..94f8251d
--- /dev/null
+++ recipes-containers/oras/oras_git.bb
@@ -0,0 +1,63 @@
+HOMEPAGE = "https://oras.land/"
+SUMMARY = "OCI registry client for managing artifacts in container registries"
+
+DEPENDS = " \
+    rsync-native \
+"
+
+# Specify the first two important SRCREVs as the format
+SRCREV_FORMAT = "oras"
+SRCREV_oras = "40530fe4c68e5825b868cd874bd46fc0cdd0f432"
+
+SRC_URI = "git://github.com/oras-project/oras;name=oras;protocol=https;nobranch=1;destsuffix=${GO_SRCURI_DESTSUFFIX}"
+
+include src_uri.inc
+
+# patches and config
+SRC_URI += "file://modules.txt"
+
+LICENSE = "Apache-2.0"
+LIC_FILES_CHKSUM = "file://src/import/LICENSE;md5=019fcb726ce54798fc2e56a02520dae8"
+
+GO_IMPORT = "import"
+
+PV = "v1.3.0"
+
+ORAS_PKG = "oras.land/oras"
+
+inherit go goarch
+inherit pkgconfig
+
+do_configure[noexec] = "1"
+
+include relocation.inc
+
+GOBUILDFLAGS:append = " -mod=vendor"
+do_compile() {
+	cd ${S}/src/import
+
+	export GOPATH="$GOPATH:${S}/src/import/.gopath"
+
+	# Pass the needed cflags/ldflags so that cgo
+	# can find the needed headers files and libraries
+	export GOARCH=${TARGET_GOARCH}
+	export CGO_ENABLED="1"
+	export CGO_CFLAGS="${CFLAGS} --sysroot=${STAGING_DIR_TARGET}"
+	export CGO_LDFLAGS="${LDFLAGS} --sysroot=${STAGING_DIR_TARGET}"
+
+	# our copied .go files are to be used for the build
+	ln -sf vendor.copy vendor
+	# inform go that we know what we are doing
+	cp ${UNPACKDIR}/modules.txt vendor/
+
+	# set BuildMetadata to empty to remove default "unreleases" tag
+	GO_LDFLAGS="-w -X ${ORAS_PKG}/internal/version.BuildMetadata="
+	GO_BUILDTAGS=""
+	mkdir -p ./bin
+	${GO} build ${GOBUILDFLAGS} -tags "$GO_BUILDTAGS" -ldflags "$GO_LDFLAGS" -o ./bin/oras ./cmd/oras
+}
+
+do_install() {
+    install -d ${D}${bindir}
+    install -m 755 ${S}/src/import/bin/oras ${D}${bindir}
+}
diff --git recipes-containers/oras/relocation.inc recipes-containers/oras/relocation.inc
new file mode 100644
index 00000000..e5d3242a
--- /dev/null
+++ recipes-containers/oras/relocation.inc
@@ -0,0 +1,56 @@
+export sites = "dario.cat/mergo:dario.cat/mergo:force \
+           gopkg.in/yaml.v3:gopkg.in/yaml.v3:force \
+           golang.org/x/sys:golang.org/x/sys:force \
+           golang.org/x/sync:golang.org/x/sync:force \
+           golang.org/x/term:golang.org/x/term:force \
+           golang.org/x/crypto:golang.org/x/crypto:force \
+           oras.land/oras-go/v2:oras.land/oras-go/v2:force \
+           github.com/spf13/cast:github.com/spf13/cast:force \
+           github.com/spf13/cobra:github.com/spf13/cobra:force \
+           github.com/spf13/pflag:github.com/spf13/pflag:force \
+           github.com/google/uuid:github.com/google/uuid:force \
+           github.com/morikuni/aec:github.com/morikuni/aec:force \
+           github.com/sirupsen/logrus:github.com/sirupsen/logrus:force \
+           github.com/huandu/xstrings:github.com/huandu/xstrings:force \
+           github.com/containerd/console:github.com/containerd/console:force \
+           github.com/shopspring/decimal:github.com/shopspring/decimal:force \
+           github.com/Masterminds/goutils:github.com/Masterminds/goutils:force \
+           github.com/Masterminds/sprig/v3:github.com/Masterminds/sprig/v3:force \
+           github.com/Masterminds/semver/v3:github.com/Masterminds/semver/v3:force \
+           github.com/mitchellh/reflectwalk:github.com/mitchellh/reflectwalk:force \
+           github.com/mitchellh/copystructure:github.com/mitchellh/copystructure:force \
+           github.com/opencontainers/go-digest:github.com/opencontainers/go-digest:force \
+           github.com/opencontainers/image-spec:github.com/opencontainers/image-spec:force \
+           github.com/inconshreveable/mousetrap:github.com/inconshreveable/mousetrap:force"
+
+do_compile:prepend() {
+    cd ${S}/src/import
+    for s in $sites; do
+        site_dest=$(echo $s | cut -d: -f1)
+        site_source=$(echo $s | cut -d: -f2)
+        force_flag=$(echo $s | cut -d: -f3)
+
+        mkdir -p vendor.copy/$site_dest
+
+        # create a temporary exclude file
+        exclude_file=$(mktemp)
+
+        find vendor.fetch/$site_source -type d -print0 |         xargs -0 du -sBM 2>/dev/null |         awk '{if ($1+0 > 500) print substr($0, index($0,$2))}' |         sed 's|^vendor.fetch/||' > "$exclude_file"
+
+        if [ -n "$force_flag" ]; then
+            echo "[INFO] $site_dest: force copying .go files"
+            rm -rf vendor.copy/$site_dest
+            rsync -a                 --exclude='vendor/'                 --exclude='.git/'                 --exclude-from="$exclude_file"                 vendor.fetch/$site_source/ vendor.copy/$site_dest
+        else
+            if [ -n "$(ls -A vendor.copy/$site_dest/*.go 2> /dev/null)" ]; then
+                echo "[INFO] vendor.fetch/$site_source -> $site_dest: go copy skipped (files present)"
+                true
+            else
+                echo "[INFO] $site_dest: copying .go files"
+                rsync -a                     --exclude='vendor/'                     --exclude='.git/'                     --exclude-from="$exclude_file"                     vendor.fetch/$site_source/ vendor.copy/$site_dest
+            fi
+        fi
+
+        rm -f "$exclude_file"
+    done
+}
diff --git recipes-containers/oras/src_uri.inc recipes-containers/oras/src_uri.inc
new file mode 100644
index 00000000..5fbff72f
--- /dev/null
+++ recipes-containers/oras/src_uri.inc
@@ -0,0 +1,96 @@
+# [dario.cat/mergo v1.0.2] git ls-remote https://github.com/imdario/mergo 7b33b2b01026fbbbbfcfbb1ee2c9c0a5e0c9a9f7
+SRCREV_mergo = "7b33b2b01026fbbbbfcfbb1ee2c9c0a5e0c9a9f7"
+SRC_URI += "git://github.com/imdario/mergo;name=mergo;protocol=https;nobranch=1;destsuffix=${GO_SRCURI_DESTSUFFIX}/vendor.fetch/dario.cat/mergo"
+
+# [gopkg.in/yaml.v3 v3.0.1] git ls-remote https://github.com/go-yaml/yaml f6f7691b1fdeb513f56608cd2c32c51f8194bf51
+SRCREV_yaml.v3 = "f6f7691b1fdeb513f56608cd2c32c51f8194bf51"
+SRC_URI += "git://github.com/go-yaml/yaml;name=yaml.v3;protocol=https;nobranch=1;destsuffix=${GO_SRCURI_DESTSUFFIX}/vendor.fetch/gopkg.in/yaml.v3"
+
+# [golang.org/x/sys v0.35.0] git ls-remote https://go.googlesource.com/sys 5b936e1f126baa13682eff91c2e4d5d9e3a0b71d
+SRCREV_sys = "5b936e1f126baa13682eff91c2e4d5d9e3a0b71d"
+SRC_URI += "git://go.googlesource.com/sys;name=sys;protocol=https;nobranch=1;destsuffix=${GO_SRCURI_DESTSUFFIX}/vendor.fetch/golang.org/x/sys"
+
+# [golang.org/x/sync v0.16.0] git ls-remote https://go.googlesource.com/sync 7fad2c9213e0821bd78435a9c106806f2fc383f1
+SRCREV_sync = "7fad2c9213e0821bd78435a9c106806f2fc383f1"
+SRC_URI += "git://go.googlesource.com/sync;name=sync;protocol=https;nobranch=1;destsuffix=${GO_SRCURI_DESTSUFFIX}/vendor.fetch/golang.org/x/sync"
+
+# [golang.org/x/term v0.34.0] git ls-remote https://go.googlesource.com/term a35244d18d7756b12deca31a518c0fa1327d050a
+SRCREV_term = "a35244d18d7756b12deca31a518c0fa1327d050a"
+SRC_URI += "git://go.googlesource.com/term;name=term;protocol=https;nobranch=1;destsuffix=${GO_SRCURI_DESTSUFFIX}/vendor.fetch/golang.org/x/term"
+
+# [golang.org/x/crypto v0.40.0] git ls-remote https://go.googlesource.com/crypto 459a9db11b9c43bb1d61722bfd371751d6de05c9
+SRCREV_crypto = "459a9db11b9c43bb1d61722bfd371751d6de05c9"
+SRC_URI += "git://go.googlesource.com/crypto;name=crypto;protocol=https;nobranch=1;destsuffix=${GO_SRCURI_DESTSUFFIX}/vendor.fetch/golang.org/x/crypto"
+
+# [oras.land/oras-go/v2 v2.6.0] git ls-remote https://github.com/oras-project/oras-go 05a2b09cbf2eab1df691411884dc4df741ec56ab
+SRCREV_v2 = "05a2b09cbf2eab1df691411884dc4df741ec56ab"
+SRC_URI += "git://github.com/oras-project/oras-go;name=v2;protocol=https;nobranch=1;destsuffix=${GO_SRCURI_DESTSUFFIX}/vendor.fetch/oras.land/oras-go/v2"
+
+# [github.com/spf13/cast v1.9.2] git ls-remote https://github.com/spf13/cast 40e8e077c1091d832abbde369bbf6cb6455d3335
+SRCREV_cast = "40e8e077c1091d832abbde369bbf6cb6455d3335"
+SRC_URI += "git://github.com/spf13/cast;name=cast;protocol=https;nobranch=1;destsuffix=${GO_SRCURI_DESTSUFFIX}/vendor.fetch/github.com/spf13/cast"
+
+# [github.com/spf13/cobra v1.10.1] git ls-remote https://github.com/spf13/cobra 7da941c3547e93b8c9f70bbd3befca79c6335388
+SRCREV_cobra = "7da941c3547e93b8c9f70bbd3befca79c6335388"
+SRC_URI += "git://github.com/spf13/cobra;name=cobra;protocol=https;nobranch=1;destsuffix=${GO_SRCURI_DESTSUFFIX}/vendor.fetch/github.com/spf13/cobra"
+
+# [github.com/spf13/pflag v1.0.9] git ls-remote https://github.com/spf13/pflag 10438578954bba2527fe5cae3684d4532b064bbe
+SRCREV_pflag = "10438578954bba2527fe5cae3684d4532b064bbe"
+SRC_URI += "git://github.com/spf13/pflag;name=pflag;protocol=https;nobranch=1;destsuffix=${GO_SRCURI_DESTSUFFIX}/vendor.fetch/github.com/spf13/pflag"
+
+# [github.com/google/uuid v1.6.0] git ls-remote https://github.com/google/uuid 0f11ee6918f41a04c201eceeadf612a377bc7fbc
+SRCREV_uuid = "0f11ee6918f41a04c201eceeadf612a377bc7fbc"
+SRC_URI += "git://github.com/google/uuid;name=uuid;protocol=https;nobranch=1;destsuffix=${GO_SRCURI_DESTSUFFIX}/vendor.fetch/github.com/google/uuid"
+
+# [github.com/morikuni/aec v1.0.0] git ls-remote https://github.com/morikuni/aec 39771216ff4c63d11f5e604076f9c45e8be1067b
+SRCREV_aec = "39771216ff4c63d11f5e604076f9c45e8be1067b"
+SRC_URI += "git://github.com/morikuni/aec;name=aec;protocol=https;nobranch=1;destsuffix=${GO_SRCURI_DESTSUFFIX}/vendor.fetch/github.com/morikuni/aec"
+
+# [github.com/sirupsen/logrus v1.9.3] git ls-remote https://github.com/sirupsen/logrus d40e25cd45ed9c6b2b66e6b97573a0413e4c23bd
+SRCREV_logrus = "d40e25cd45ed9c6b2b66e6b97573a0413e4c23bd"
+SRC_URI += "git://github.com/sirupsen/logrus;name=logrus;protocol=https;nobranch=1;destsuffix=${GO_SRCURI_DESTSUFFIX}/vendor.fetch/github.com/sirupsen/logrus"
+
+# [github.com/huandu/xstrings v1.5.0] git ls-remote https://github.com/huandu/xstrings 1040c040a86302c5a4de066f5653bccdff2ecd2f
+SRCREV_xstrings = "1040c040a86302c5a4de066f5653bccdff2ecd2f"
+SRC_URI += "git://github.com/huandu/xstrings;name=xstrings;protocol=https;nobranch=1;destsuffix=${GO_SRCURI_DESTSUFFIX}/vendor.fetch/github.com/huandu/xstrings"
+
+# [github.com/containerd/console v1.0.5] git ls-remote https://github.com/containerd/console c8d962180f543ac07c008ecc79a413406ea10c0b
+SRCREV_console = "c8d962180f543ac07c008ecc79a413406ea10c0b"
+SRC_URI += "git://github.com/containerd/console;name=console;protocol=https;nobranch=1;destsuffix=${GO_SRCURI_DESTSUFFIX}/vendor.fetch/github.com/containerd/console"
+
+# [github.com/shopspring/decimal v1.4.0] git ls-remote https://github.com/shopspring/decimal a1bdfc355e9c71119322b748c95f7d6b82566e30
+SRCREV_decimal = "a1bdfc355e9c71119322b748c95f7d6b82566e30"
+SRC_URI += "git://github.com/shopspring/decimal;name=decimal;protocol=https;nobranch=1;destsuffix=${GO_SRCURI_DESTSUFFIX}/vendor.fetch/github.com/shopspring/decimal"
+
+# [github.com/Masterminds/goutils v1.1.1] git ls-remote https://github.com/Masterminds/goutils f1923532a168b8203bfe956d8cd3b17ebece5982
+SRCREV_goutils = "f1923532a168b8203bfe956d8cd3b17ebece5982"
+SRC_URI += "git://github.com/Masterminds/goutils;name=goutils;protocol=https;nobranch=1;destsuffix=${GO_SRCURI_DESTSUFFIX}/vendor.fetch/github.com/Masterminds/goutils"
+
+# [github.com/Masterminds/sprig/v3 v3.3.0] git ls-remote https://github.com/Masterminds/sprig e708470d529a10ac1a3f02ab6fdd339b65958372
+SRCREV_v3 = "e708470d529a10ac1a3f02ab6fdd339b65958372"
+SRC_URI += "git://github.com/Masterminds/sprig;name=v3;protocol=https;nobranch=1;destsuffix=${GO_SRCURI_DESTSUFFIX}/vendor.fetch/github.com/Masterminds/sprig/v3"
+
+# [github.com/Masterminds/semver/v3 v3.4.0] git ls-remote https://github.com/Masterminds/semver 61fc460d28283a91c53be65c2e0f20b494ac8ad9
+SRCREV_semver-v3 = "61fc460d28283a91c53be65c2e0f20b494ac8ad9"
+SRC_URI += "git://github.com/Masterminds/semver;name=semver-v3;protocol=https;nobranch=1;destsuffix=${GO_SRCURI_DESTSUFFIX}/vendor.fetch/github.com/Masterminds/semver/v3"
+
+# [github.com/mitchellh/reflectwalk v1.0.2] git ls-remote https://github.com/mitchellh/reflectwalk e0c24fdb021963cd2c4013097a0b993a7c4e344f
+SRCREV_reflectwalk = "e0c24fdb021963cd2c4013097a0b993a7c4e344f"
+SRC_URI += "git://github.com/mitchellh/reflectwalk;name=reflectwalk;protocol=https;nobranch=1;destsuffix=${GO_SRCURI_DESTSUFFIX}/vendor.fetch/github.com/mitchellh/reflectwalk"
+
+# [github.com/mitchellh/copystructure v1.2.0] git ls-remote https://github.com/mitchellh/copystructure d4ce1f938f7a7ea2a40bff4544b56be9c00b5e84
+SRCREV_copystructure = "d4ce1f938f7a7ea2a40bff4544b56be9c00b5e84"
+SRC_URI += "git://github.com/mitchellh/copystructure;name=copystructure;protocol=https;nobranch=1;destsuffix=${GO_SRCURI_DESTSUFFIX}/vendor.fetch/github.com/mitchellh/copystructure"
+
+# [github.com/opencontainers/go-digest v1.0.0] git ls-remote https://github.com/opencontainers/go-digest ea51bea511f75cfa3ef6098cc253c5c3609b037a
+SRCREV_go-digest = "ea51bea511f75cfa3ef6098cc253c5c3609b037a"
+SRC_URI += "git://github.com/opencontainers/go-digest;name=go-digest;protocol=https;nobranch=1;destsuffix=${GO_SRCURI_DESTSUFFIX}/vendor.fetch/github.com/opencontainers/go-digest"
+
+# [github.com/opencontainers/image-spec v1.1.1] git ls-remote https://github.com/opencontainers/image-spec 147f9c13cedb47a0c4d9a11a222961073d585877
+SRCREV_image-spec = "147f9c13cedb47a0c4d9a11a222961073d585877"
+SRC_URI += "git://github.com/opencontainers/image-spec;name=image-spec;protocol=https;nobranch=1;destsuffix=${GO_SRCURI_DESTSUFFIX}/vendor.fetch/github.com/opencontainers/image-spec"
+
+# [github.com/inconshreveable/mousetrap v1.1.0] git ls-remote https://github.com/inconshreveable/mousetrap 4e8053ee7ef85a6bd26368364a6d27f1641c1d21
+SRCREV_mousetrap = "4e8053ee7ef85a6bd26368364a6d27f1641c1d21"
+SRC_URI += "git://github.com/inconshreveable/mousetrap;name=mousetrap;protocol=https;nobranch=1;destsuffix=${GO_SRCURI_DESTSUFFIX}/vendor.fetch/github.com/inconshreveable/mousetrap"
+

---
base-commit: 26e2b40b91f2424b0b9318b50dbb700a67714b6f
change-id: 20251215-add_oras_recipe-40ab44a8ad02

Best regards,
-- 
Massimiliano Minella <massimiliano.minella@se.com>

