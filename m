From: Joel Granados <joel.granados@kernel.org>
Date: Wed, 18 Dec 2024 11:30:03 +0100
Subject: [PATCH 09/12] ansible: Reduce long ansible messages for
 readability
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241218-jag-bringup_fixes-v1-9-0bf2e07c640c@kernel.org>
References: <20241218-jag-bringup_fixes-v1-0-0bf2e07c640c@kernel.org>
In-Reply-To: <20241218-jag-bringup_fixes-v1-0-0bf2e07c640c@kernel.org>
To: kdevops@lists.linux.dev
Cc: Joel Granados <joel.granados@kernel.org>, da.gomez@samsung.com
X-Mailer: b4 0.15-dev-00a43
X-Developer-Signature: v=1; a=openpgp-sha256; l=2148;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=uLN69fmmg4NNyq1bXPCNbwQrJjnLrTzRZWnbyJaeuXI=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGdipDCeCuMToaZXCrHAMoZ3iDZ/n9RrydmVq
 YRo5MDHjS8oJ4kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJnYqQwAAoJELqXzVK3
 lkFPnDYMAIB4hVQFCkHQoCFUSdP8aajmUUSgf78c023y7z0//ISY2ehdY8lAYTAiNzxxRUx1t1a
 RTfEMK9A0egAgxFb8NnU9ZGNVzIaVrNnE0J0rt5R6g3c8BhF/808dzFeEJjdqRUj71dBdFZnZE6
 BQdGf5wQPCyTesRjuCMPxzJ+9mhhQ/ZH8ralHg4pAc2Py2enYnXAzpcoBgESTSNtfr6h8TZ1QrF
 Bod5NEg5nuIjdvBVO/FcyIDxP5X0BoeLkXglM/93y7qWtBzFj5sGAr3Bdirl+5m5Hib0HAu0PAM
 BQcWOgdcrCr4gNsI9WQM0wJzIalKShnjmnk3gup1MUGhQSzrIaFVw4JayT9I0RHNK9aOQK8ghtj
 hmAC2+dWmSkTeTy8+jaEHpELEfcimljM/uZZPh80+9FGhvuZFZ0SIgrzan/1AdRWYBvhNCAW9xx
 OJZKjaunOSPcMPQ1iuQVTbN0s3AJxFELloxVrynCeWjfCCOfsXy6NmPybq4Lpdf+MoZXXVpFT64
 0k=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 playbooks/roles/bringup_guestfs/tasks/main.yml | 14 +++++++++++---
 1 file changed, 11 insertions(+), 3 deletions(-)

diff --git a/playbooks/roles/bringup_guestfs/tasks/main.yml b/playbooks/roles/bringup_guestfs/tasks/main.yml
index c764ae4..fbbb378 100644
--- a/playbooks/roles/bringup_guestfs/tasks/main.yml
+++ b/playbooks/roles/bringup_guestfs/tasks/main.yml
@@ -6,7 +6,7 @@
 
 - name: Fail if {{ topdir_path }}/.config is not present
   fail:
-    msg: "You have not configured kdevops yet, configure kdevops first."
+    msg: "kdevops is not confgured. You must run 'make menuconfig'"
   when: not config_file.stat.exists or not config_file.stat.isreg
   tags: [ 'config-check' ]
 
@@ -63,7 +63,10 @@
 
 - name: Fail if dnsmasq configuration files exist
   fail:
-    msg: "dnsmasq configuration files or directories still exist. Please remove the following to fully uninstall dnsmasq:\n{{ dnsmasq_config_files | join('\n') }}"
+    msg: |
+      dnsmasq configuration files or directories still exist.
+      Please remove the following to fully uninstall
+      dnsmasq:\n{{ dnsmasq_config_files | join('\n') }}
   when:
     - distro_debian_based|bool
     - dnsmasq_config_files.results | selectattr('stat.exists') | list | length > 0
@@ -95,7 +98,12 @@
 
 - name: Fail if dnsmasq service is enabled or active
   fail:
-    msg: "dnsmasq service is {{ 'enabled' if dnsmasq_enabled.rc == 0 else 'active' if dnsmasq_active.rc == 0 else 'present' }}. Please ensure dnsmasq is fully uninstalled and disabled. Run 'sudo systemctl disable dnsmasq' and 'sudo systemctl stop dnsmasq' to disable and stop the service."
+    msg: |
+      dnsmasq service is
+      {{ 'enabled' if dnsmasq_enabled.rc == 0 else 'active' if dnsmasq_active.rc == 0 else 'present' }}.
+      Please ensure dnsmasq is fully uninstalled and disabled.
+      Run 'sudo systemctl disable dnsmasq' and 'sudo systemctl
+      stop dnsmasq' to disable and stop the service.
   when:
     - distro_debian_based|bool
     - dnsmasq_config_files | length > 0

-- 
2.44.2

