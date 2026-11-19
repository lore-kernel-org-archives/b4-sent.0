From: Patrick Vogelaar <patrick.vogelaar@belden.com>
Date: Thu, 19 Nov 2026 14:43:29 +0100
Subject: [meta-virtualization][scarthgap][PATCH] podman: fix CVE-2026-94603
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-fix-cve-2026-94603-v1-1-39caa8013648@belden.com>
X-B4-Tracking: v=1; b=H4sIAAD9/moC/yWNwQ6CMBBEf4Xs2U1oBZL6K00PS1lhjSJpS2Mg/
 LtFj28y82aHyEE4wq3aIXCWKO+5gLpU4CeaR0YZCoOudaeUMniXD/rMeAZomq6+YkvEmhvTekV
 Qhkvg0vpJrftzXPsH+3Sa7IsTYZaQVnrKRqk8Ohs9hTSNtDg4ji+wXKGSlgAAAA==
X-Change-ID: 20261119-fix-cve-2026-94603-5aae2e495c1a
To: meta-virtualization@lists.yoctoproject.org
Cc: patrick.vogelaar.dev@mailbox.org, 
 Patrick Vogelaar <patrick.vogelaar@belden.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795095819; l=10761;
 i=patrick.vogelaar@belden.com; s=20240201; h=from:subject:message-id;
 bh=xhK6K/avv+DSypD0DBOVBn3VgvL+r9pQjH8FhlL1ON4=;
 b=s2u9iWW9lYfJuXQIlb6Hr1le68c72MIXxc5j8abwDgp114KF/4k5kAT/MAhSbNqr4H2rXb/Xw
 AyoBbrjM2qQCvbfeo5miX3EA2+ENEq501taBzT5sP3DzflvUdB/QZn0
X-Developer-Key: i=patrick.vogelaar@belden.com; a=ed25519;
 pk=w0QU8RmOR3hQv1DxMcz6KmySeE8yqbvO0xC1ZSSUNqY=
X-Endpoint-Received: by B4 Relay for patrick.vogelaar@belden.com/20240201 with auth_id=125
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch applies the upstream v5.8 branch backport for CVE-2026-94603.
The backport commit [0] (CVE-2026-94603-01.patch) is mentioned here [1]
as well as [2] (CVE-2026-94603-02.patch) which adds a proper error message
but does not actually fix it.

[0] https://github.com/podman-container-tools/podman/commit/7728ba0a90094408ad9078e36c3622a651d49616
[1] https://nvd.nist.gov/vuln/detail/cve-2026-94603
[2] https://github.com/podman-container-tools/podman/commit/24706290d5c974f078d8ca284026802515f28e92

---
Signed-off-by: Patrick Vogelaar <patrick.vogelaar@belden.com>
---
 .../podman/podman/CVE-2026-94603-01.patch          | 132 +++++++++++++++++++++
 .../podman/podman/CVE-2026-94603-02.patch          |  67 +++++++++++
 recipes-containers/podman/podman_git.bb            |   2 +
 3 files changed, 201 insertions(+)

diff --git a/recipes-containers/podman/podman/CVE-2026-94603-01.patch b/recipes-containers/podman/podman/CVE-2026-94603-01.patch
new file mode 100644
index 00000000..8b2de205
--- /dev/null
+++ b/recipes-containers/podman/podman/CVE-2026-94603-01.patch
@@ -0,0 +1,132 @@
+From 6d9a520b15661001365098fcb78121153fb968dc Mon Sep 17 00:00:00 2001
+From: Matt Heon <matthew.heon@pm.me>
+Date: Mon, 28 Sep 2026 07:48:00 -0400
+Subject: [PATCH 1/2] Revert "Enable 'podman run' for checkpoint images"
+
+This reverts commit f4401567cdf6d7ccc1ef9f50345c865bc6262c22.
+
+This commit has been identified as a serious security issue.
+Running checkpoints via `podman run` introduces potentially
+confusing behavior where all security for a container, even
+options specified by the user at the command line, can be turned
+off by the checkpoint. Checkpoints have special security
+considerations and must be explicitly requested by the user to
+ensure they are used safely. We recommend ensuring the lifecycle
+of a checkpoint is fully monitored and integrity is ensured at
+each stage to guarantee safety.
+
+Signed-off-by: Matt Heon <matthew.heon@pm.me>
+(cherry picked from commit 7728ba0a90094408ad9078e36c3622a651d49616)
+
+Upstream-Status: Backport [https://github.com/podman-container-tools/podman/commit/7728ba0a90094408ad9078e36c3622a651d49616]
+CVE: CVE-2015-94603
+
+Signed-off-by: Patrick Vogelaar <patrick.vogelaar@belden.com>
+---
+ pkg/domain/infra/abi/containers.go    | 39 ---------------------------
+ pkg/domain/infra/tunnel/containers.go | 25 -----------------
+ 2 files changed, 64 deletions(-)
+
+diff --git a/pkg/domain/infra/abi/containers.go b/pkg/domain/infra/abi/containers.go
+index 9016398bb5..a46680a487 100644
+--- a/pkg/domain/infra/abi/containers.go
++++ b/pkg/domain/infra/abi/containers.go
+@@ -6,7 +6,6 @@ import (
+ 	"errors"
+ 	"fmt"
+ 	"os"
+-	"reflect"
+ 	"strconv"
+ 	"sync"
+ 	"time"
+@@ -1090,44 +1089,6 @@ func (ic *ContainerEngine) ContainerRun(ctx context.Context, opts entities.Conta
+ 		fmt.Fprintf(os.Stderr, "%s\n", w)
+ 	}
+ 
+-	if opts.Spec != nil && !reflect.ValueOf(opts.Spec).IsNil() {
+-		// If this is a checkpoint image, restore it.
+-		img, resolvedImageName := opts.Spec.GetImage()
+-		if img != nil && resolvedImageName != "" {
+-			imgData, err := img.Inspect(ctx, nil)
+-			if err != nil {
+-				return nil, err
+-			}
+-			if imgData != nil {
+-				_, isCheckpointImage := imgData.Annotations[define.CheckpointAnnotationRuntimeName]
+-				if isCheckpointImage {
+-					var restoreOptions entities.RestoreOptions
+-					restoreOptions.Name = opts.Spec.Name
+-					restoreOptions.Pod = opts.Spec.Pod
+-					responses, err := ic.ContainerRestore(ctx, []string{resolvedImageName}, restoreOptions)
+-					if err != nil {
+-						return nil, err
+-					}
+-
+-					report := entities.ContainerRunReport{}
+-					for _, r := range responses {
+-						report.Id = r.Id
+-						report.ExitCode = 0
+-						if r.Err != nil {
+-							logrus.Errorf("Failed to restore checkpoint image %s: %v", resolvedImageName, r.Err)
+-							report.ExitCode = 126
+-						}
+-						if r.RawInput != "" {
+-							logrus.Errorf("Failed to restore checkpoint image %s: %v", resolvedImageName, r.RawInput)
+-							report.ExitCode = 126
+-						}
+-					}
+-					return &report, nil
+-				}
+-			}
+-		}
+-	}
+-
+ 	rtSpec, spec, optsN, err := generate.MakeContainer(ctx, ic.Libpod, opts.Spec, false, nil)
+ 	if err != nil {
+ 		return nil, err
+diff --git a/pkg/domain/infra/tunnel/containers.go b/pkg/domain/infra/tunnel/containers.go
+index 9c81fb2197..f7c2ea9af7 100644
+--- a/pkg/domain/infra/tunnel/containers.go
++++ b/pkg/domain/infra/tunnel/containers.go
+@@ -7,7 +7,6 @@ import (
+ 	"fmt"
+ 	"io"
+ 	"os"
+-	"reflect"
+ 	"strconv"
+ 	"strings"
+ 	"sync"
+@@ -830,30 +829,6 @@ func (ic *ContainerEngine) ContainerListExternal(ctx context.Context) ([]entitie
+ }
+ 
+ func (ic *ContainerEngine) ContainerRun(ctx context.Context, opts entities.ContainerRunOptions) (*entities.ContainerRunReport, error) {
+-	if opts.Spec != nil && !reflect.ValueOf(opts.Spec).IsNil() && opts.Spec.RawImageName != "" {
+-		// If this is a checkpoint image, restore it.
+-		getImageOptions := new(images.GetOptions).WithSize(false)
+-		inspectReport, err := images.GetImage(ic.ClientCtx, opts.Spec.RawImageName, getImageOptions)
+-		if err != nil {
+-			return nil, fmt.Errorf("no such container or image: %s", opts.Spec.RawImageName)
+-		}
+-		if inspectReport != nil {
+-			_, isCheckpointImage := inspectReport.Annotations[define.CheckpointAnnotationRuntimeName]
+-			if isCheckpointImage {
+-				restoreOptions := new(containers.RestoreOptions)
+-				restoreOptions.WithName(opts.Spec.Name)
+-				restoreOptions.WithPod(opts.Spec.Pod)
+-
+-				restoreReport, err := containers.Restore(ic.ClientCtx, inspectReport.ID, restoreOptions)
+-				if err != nil {
+-					return nil, err
+-				}
+-				runReport := entities.ContainerRunReport{Id: restoreReport.Id}
+-				return &runReport, nil
+-			}
+-		}
+-	}
+-
+ 	con, err := containers.CreateWithSpec(ic.ClientCtx, opts.Spec, nil)
+ 	if err != nil {
+ 		return nil, err
+-- 
+2.43.0
+
diff --git a/recipes-containers/podman/podman/CVE-2026-94603-02.patch b/recipes-containers/podman/podman/CVE-2026-94603-02.patch
new file mode 100644
index 00000000..f8672b5c
--- /dev/null
+++ b/recipes-containers/podman/podman/CVE-2026-94603-02.patch
@@ -0,0 +1,67 @@
+From 9e596b09edf7421861218a74d273257d808dd05c Mon Sep 17 00:00:00 2001
+From: Matt Heon <matthew.heon@pm.me>
+Date: Mon, 28 Sep 2026 09:26:35 -0400
+Subject: [PATCH 2/2] Error when a checkpoint image is run
+
+Support for these was removed in 3721ff82ffb as the feature is
+inherently insecure. Checkpoints imply an extremely privileged
+operation that is incompatible with the constraints of a
+`podman run` command. However, we should still tell folks that
+it no longer works with a clear error message. This is done
+during Specgen processing, server side, which should be safer
+than the previous client-side processing for these.
+
+<MH: Fixed cherry-pick conflicts>
+
+Signed-off-by: Matt Heon <matthew.heon@pm.me>
+(cherry picked from commit 24706290d5c974f078d8ca284026802515f28e92)
+
+Upstream-Status: Backport [https://github.com/podman-container-tools/podman/commit/24706290d5c974f078d8ca284026802515f28e92]
+
+Signed-off-by: Patrick Vogelaar <patrick.vogelaar@belden.com>
+---
+ docs/source/markdown/podman-container-restore.1.md |  6 ++++++
+ pkg/specgen/generate/container_create.go           | 10 ++++++++++
+ 2 files changed, 16 insertions(+)
+
+diff --git a/docs/source/markdown/podman-container-restore.1.md b/docs/source/markdown/podman-container-restore.1.md
+index 2cbb4c46f7..2432f5ca4c 100644
+--- a/docs/source/markdown/podman-container-restore.1.md
++++ b/docs/source/markdown/podman-container-restore.1.md
+@@ -10,6 +10,12 @@ podman\-container\-restore - Restore one or more containers from a checkpoint
+ **podman container restore** restores a container from a container checkpoint or
+ checkpoint image. The *container IDs*, *image IDs* or *names* are used as input.
+ 
++Please note that restoring a checkpoint will use the complete security context specified in the checkpoint.
++If a checkpoint specifies that it should be run with full capabilities added and all security features like Seccomp, SELinux, and Apparmor disabled, this will be done.
++Security configuration from **containers.conf** is not used, as the checkpoint must be restored with the originally-specified security configuration.
++As such, restoring a checkpoint is a security sensitive operation and should only be done on checkpoints that are fully trusted.
++It is recommended that checkpoint integrity be ensured at each lifecycle step - creation, storage, retrieval, and restoration.
++
+ ## OPTIONS
+ #### **--all**, **-a**
+ 
+diff --git a/pkg/specgen/generate/container_create.go b/pkg/specgen/generate/container_create.go
+index db4f8cdb60..0b6fa0b374 100644
+--- a/pkg/specgen/generate/container_create.go
++++ b/pkg/specgen/generate/container_create.go
+@@ -164,6 +164,16 @@ func MakeContainer(ctx context.Context, rt *libpod.Runtime, s *specgen.SpecGener
+ 		return nil, nil, nil, err
+ 	}
+ 
++	// Check for checkpoint annotation.
++	// This was removed in 3721ff82ffb44a4ceeaecc5abd3808e924a6b669 as a result of CVE-2026-94603.
++	// If we get it, throw an error stating that `podman container restore` must be used instead.
++	if imageData != nil {
++		_, isCheckpointImage := imageData.Annotations[define.CheckpointAnnotationRuntimeName]
++		if isCheckpointImage {
++			return nil, nil, nil, fmt.Errorf("%s is a checkpoint and must be started using `podman container restore` instead", s.Image)
++		}
++	}
++
+ 	if imageData != nil {
+ 		ociRuntimeVariant := rtc.Engine.ImagePlatformToRuntime(imageData.Os, imageData.Architecture)
+ 		// Don't unnecessarily set and invoke additional libpod
+-- 
+2.43.0
+
diff --git a/recipes-containers/podman/podman_git.bb b/recipes-containers/podman/podman_git.bb
index 77ac4280..0f7e5634 100644
--- a/recipes-containers/podman/podman_git.bb
+++ b/recipes-containers/podman/podman_git.bb
@@ -27,6 +27,8 @@ SRC_URI = " \
     file://CVE-2026-55686-dependent.patch;patchdir=src/import \
     file://CVE-2026-55686.patch;patchdir=src/import \
     file://CVE-2026-57231.patch;patchdir=src/import \
+    file://CVE-2026-94603-01.patch;patchdir=src/import \
+    file://CVE-2026-94603-02.patch;patchdir=src/import \
 "
 
 LICENSE = "Apache-2.0"

---
base-commit: e0b994c8457be2b32acf7b904fcc5408156de57a
change-id: 20261119-fix-cve-2026-94603-5aae2e495c1a

Best regards,
--  
Patrick Vogelaar <patrick.vogelaar@belden.com>

