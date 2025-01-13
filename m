From: Joel Granados <joel.granados@kernel.org>
Date: Mon, 13 Jan 2025 12:53:07 +0100
Subject: [PATCH RESEND 09/12] ansible: Reduce long ansible messages for
 readability
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250113-jag-bringup_fixes-v1-9-fb28030b1f26@kernel.org>
References: <20250113-jag-bringup_fixes-v1-0-fb28030b1f26@kernel.org>
In-Reply-To: <20250113-jag-bringup_fixes-v1-0-fb28030b1f26@kernel.org>
To: kdevops@lists.linux.dev
Cc: Joel Granados <joel.granados@kernel.org>, mcgrof@kernel.org, 
 da.gomez@samsung.com
X-Mailer: b4 0.15-dev-00a43
X-Developer-Signature: v=1; a=openpgp-sha256; l=2148;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=uLN69fmmg4NNyq1bXPCNbwQrJjnLrTzRZWnbyJaeuXI=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGeE/qcC26qMbqNmHdjgUFaitOlkid3r9EnSo
 Nd3iKjqxvQOyIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJnhP6nAAoJELqXzVK3
 lkFPvgwMAIb+HIwcTbuPHRP3/kWOLEVgDMr2j13XDTaVNZCr4sz5L5VmNXP2ibTWIH8uUlkyK4A
 O918ns3s+ST3uBdcNpVcP/NesqgKSfHKHV+Z6uSqRx7IwOAoyWmkayYj63ERMxEWPjAdTD+iHPa
 6auQAdyZp677dNieDkFROO5V/iLOJ90A31gy3iY13DZSMcaG2+z67ScADCrZbm0EEbzpgWb8CWS
 dAXb89Gz00Jumb2VkOVOkc1aIkUBqX2iy1pKX9mLo32hW7MO0v2DlVUNgAwd9xLGHEWP6uh21n6
 JLuLBWzwlRGBwe3EHZsffnbZArdK+zy0hW61vfjJB+EBH08HovsFVlgOs8ZhmRD+anW5160TROo
 uWl2MAe86Bm5mQSldtp1DE9X2JQFdrOVP6XQEhzq/8xJ/sKA2b2vmVbUVWERwqQY5vB9mW7pNNX
 3eeRG+fVDFof/+7S1C7wzAayi7+Jlw1MQ69oXP7lQKz+jhvV80zAP9kdgoj3665s5KApzhSkdm6
 Z4=
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

