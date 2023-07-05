From: Jon Mason <jon.mason@arm.com>
Date: Wed, 05 Jul 2023 14:10:08 -0400
Subject: [PATCH] ci: xen guest and host testing
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230705-jdm-xen-v1-1-a654df463845@arm.com>
X-B4-Tracking: v=1; b=H4sIAP+xpWQC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI2MDcwNT3ayUXN2K1DzdZHML4+RU01SjxOQUJaDqgqLUtMwKsEnRsbW1AKE
 NGHpZAAAA
To: meta-arm@lists.yoctoproject.org
Cc: Jon Mason <jon.mason@arm.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=3974; i=jon.mason@arm.com;
 h=from:subject:message-id; bh=UNMsS9JiAC6YbVVjaf4Gfwul7/gr7ZWwZO1hNLE3lDc=;
 b=owEBbQKS/ZANAwAKAW5mS6x6i9IjAcsmYgBkpbIMU4rO7Pa/UudBx9ca3Fhe53XBAjhi3BJab
 kxMwWTRl7mJAjMEAAEKAB0WIQSgT1v1zdTYnFf3yapuZkuseovSIwUCZKWyDAAKCRBuZkuseovS
 I15oD/9VLiEqd6HXjDOmo/cIETTvuUNad6rYYobPnxKuqwk+OfAJVHBBRhcMSuOI3Po4/4Tpq5v
 Zu8KBmg8DvF29IKI7BRnpfJJ2XPGtRsTwMY6eJ1/+zrkpz4lXmXEuFj0GKUYHP2/srhuzSBtMNl
 s33jBbAvWygFtrqdRjd1/f45uVhX+FuekaFjddyi3lyl4kyT0Z0JT+OtvIoqcJlDHF0diVHPBl6
 IUatmTM8kv0Mssa85khwldkIvbAP6CXR5SXZyksSR6nzbP03Jd0FmSmGask2WKdUGYWti1O9Xw9
 zhWJCvnV2iNI9aycUDYCGLUIL/MWs0d0/GaV+/GI8Fs0uyikwLxbWH0jbFTU56ExYcIlwA6f34h
 GjHGmgDYSXemJPOU492b+cQ6DkKtYmXdM/N5xHE+frei+T0Yw6z0hYO+gwprl62lJl47jwjOa8h
 omc0YcN+Ye/7OUYjl0E+Qm3N+/FKXneOqQxY1xGYiCHDCJ5wUtj/2vK0skNSAwbL3mmDcszUAQ0
 lPegoMGw5gHNoAodbsGy0VrcvQq+cNOG+W+w/s8/gN16rsFwGAb/7n7gSOdRx6s63HqonbiwqRM
 GVtkJsWVlul0keWQwO2SOGdvRPWQS5zEfGweb0DVEXqGrXAjq2nnl3PEuOCdsx52ii3p3SRbPYC
 WCwrECSaH0kHoTQ==
X-Developer-Key: i=jon.mason@arm.com; a=openpgp;
 fpr=A04F5BF5CDD4D89C57F7C9AA6E664BAC7A8BD223
X-Endpoint-Received: by B4 Relay for jon.mason@arm.com/default with auth_id=58
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the ability to run testimage on xen guest images (not xen testing),
and add xen host testimage for qemuarm.
NOTE: xen yml files must come after testing yml file due to the order of
the sshd entry (and xen requires openssh).

Signed-off-by: Jon Mason <jon.mason@arm.com>
---
b4 test email
---
 .gitlab-ci.yml                                      | 9 +++++----
 ci/xen-guest.yml                                    | 7 +++++++
 ci/xen.yml                                          | 2 ++
 meta-arm/recipes-kernel/linux/files/xen-nopci.cfg   | 7 +++++++
 meta-arm/recipes-kernel/linux/linux-yocto%.bbappend | 2 ++
 5 files changed, 23 insertions(+), 4 deletions(-)

diff --git a/.gitlab-ci.yml b/.gitlab-ci.yml
index 1433d2ac43c3..8f5312c35998 100644
--- a/.gitlab-ci.yml
+++ b/.gitlab-ci.yml
@@ -82,15 +82,15 @@ update-repos:
 #
 # Build stage, the actual build jobs
 #
-# Available options for building are
+# Available options for building are (VIRT _must_ be last for ssh override)
 #  DISTRO: [poky, poky-tiny]
 #  KERNEL: [linux-yocto, linux-yocto-dev, linux-yocto-rt]
 #  TOOLCHAINS: [gcc, clang, external-gccarm]
 #  TCLIBC: [glibc, musl]
 #  FIRMWARE: [u-boot, edk2]
 #  TS: [none, trusted-services]
-#  VIRT: [none, xen]
 #  TESTING: testimage
+#  VIRT: [none, xen, xen-guest]
 
 corstone500:
   extends: .build
@@ -180,7 +180,7 @@ qemuarm64:
         TESTING: testimage
       - DISTRO: poky-tiny
         TESTING: testimage
-      - VIRT: xen
+        VIRT: [none, xen, xen-guest]
 
 qemuarm-secureboot:
   extends: .build
@@ -204,7 +204,7 @@ qemuarm:
         TESTING: testimage
       - DISTRO: poky-tiny
         TESTING: testimage
-      - VIRT: xen
+        VIRT: [none, xen, xen-guest]
 
 qemuarmv5:
   extends: .build
@@ -213,6 +213,7 @@ qemuarmv5:
       - DISTRO: poky
         KERNEL: [linux-yocto, linux-yocto-dev, linux-yocto-rt]
         TESTING: testimage
+        VIRT: [none, xen, xen-guest]
       - DISTRO: poky-tiny
         TESTING: testimage
 
diff --git a/ci/xen-guest.yml b/ci/xen-guest.yml
new file mode 100644
index 000000000000..d53eb4d09d52
--- /dev/null
+++ b/ci/xen-guest.yml
@@ -0,0 +1,7 @@
+header:
+  version: 11
+  includes:
+    - ci/xen.yml
+
+target:
+  - xen-guest-image-minimal
diff --git a/ci/xen.yml b/ci/xen.yml
index f4a8f9a453ad..a68eebfe5589 100644
--- a/ci/xen.yml
+++ b/ci/xen.yml
@@ -6,6 +6,8 @@ header:
 local_conf_header:
   meta-virt: |
     DISTRO_FEATURES:append = " virtualization xen"
+  sshd: |
+    IMAGE_FEATURES:append = " ssh-server-openssh"
 
 target:
   - xen-image-minimal
diff --git a/meta-arm/recipes-kernel/linux/files/xen-nopci.cfg b/meta-arm/recipes-kernel/linux/files/xen-nopci.cfg
new file mode 100644
index 000000000000..043c74295022
--- /dev/null
+++ b/meta-arm/recipes-kernel/linux/files/xen-nopci.cfg
@@ -0,0 +1,7 @@
+CONFIG_PCI=n
+CONFIG_PCI_HOST_GENERIC=n
+CONFIG_HOTPLUG_PCI=n
+CONFIG_PCIEPORTBUS=n
+CONFIG_PCI_MSI=n
+
+CONFIG_PERF_EVENTS=n
diff --git a/meta-arm/recipes-kernel/linux/linux-yocto%.bbappend b/meta-arm/recipes-kernel/linux/linux-yocto%.bbappend
index 3f2c83fd624f..7234c196255b 100644
--- a/meta-arm/recipes-kernel/linux/linux-yocto%.bbappend
+++ b/meta-arm/recipes-kernel/linux/linux-yocto%.bbappend
@@ -36,6 +36,8 @@ SRC_URI:append:qemuarm = " \
     file://efi.cfg \
     file://qemuarm-phys-virt.cfg \
     "
+SRC_URI:append:qemuarm = " ${@bb.utils.contains('DISTRO_FEATURES', 'xen', 'file://xen-nopci.cfg', '' , d)}"
+KERNEL_FEATURES:remove:qemuarm = "${@bb.utils.contains('DISTRO_FEATURES', 'xen', 'features/drm-bochs/drm-bochs.scc', '' , d)}"
 
 FFA_TRANSPORT_INCLUDE = "${@bb.utils.contains('MACHINE_FEATURES', 'arm-ffa', 'arm-ffa-transport.inc', '' , d)}"
 require ${FFA_TRANSPORT_INCLUDE}

---
base-commit: c2d0905b51ff267839d1482640d913ccfa3bae63
change-id: 20230705-jdm-xen-c783ce5e2acd

Best regards,
-- 
Jon Mason <jon.mason@arm.com>

