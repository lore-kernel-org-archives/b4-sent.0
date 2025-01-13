From: Joel Granados <joel.granados@kernel.org>
Date: Mon, 13 Jan 2025 12:53:05 +0100
Subject: [PATCH RESEND 07/12] ansible: Run sudo by using the '-K' ansible
 arg
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250113-jag-bringup_fixes-v1-7-fb28030b1f26@kernel.org>
References: <20250113-jag-bringup_fixes-v1-0-fb28030b1f26@kernel.org>
In-Reply-To: <20250113-jag-bringup_fixes-v1-0-fb28030b1f26@kernel.org>
To: kdevops@lists.linux.dev
Cc: Joel Granados <joel.granados@kernel.org>, mcgrof@kernel.org, 
 da.gomez@samsung.com
X-Mailer: b4 0.15-dev-00a43
X-Developer-Signature: v=1; a=openpgp-sha256; l=3240;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=FVJUFjxaM/R8fpk2NV9PoLz5rdhcjKBPNJtHwh5TkzY=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGeE/qbtjh6tlRNzC3rhNV22vS6dEpRScKjU+
 QLoECBcRn7vAokBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJnhP6mAAoJELqXzVK3
 lkFPoxkL/1wgbop1AiHixSqjBrHy/rURT+ip2Ub2wAJb/nmy5GApYHg8u/t4iTTgBMmDfI6AY1K
 B60nnMBffhw90zMoqSjMrH4jASh6+oR/bgWq55Ua8QNWwuoehAgjxWh7HAk6ytIVzq+GI3JAA5L
 rSEHD1UGTVS1sKdiFlis30YMYeIG3mKUAO0Vsic26RQsmIiY84Z+PF0EHLXRb4b9g1BFKpcjb+S
 3/b56xwwR7VppNxypTV/N/SO+Z6M7nz14uUlEzpgfPMZmIY4bzHkOyOdq/sgDUUyMu3XJAxqLqK
 7QHdD9Fzi46OlrhhRsqDDhwg8h6sWiL5MwdQ8INJ+TTvfs1gJ0KVJIyNgevl9skAcsdrPrME41t
 E1YmysPZpzpZ3+xe3zit1Dwi0tCKb9FM2wzR7bpp1/SpWhIPvwLsG45FuaBL2ukaT+uCjv55kP0
 3IO5b/ql7XJHZcYYwCc/CWvHNwzMMiR6oNdCMcTFnZNoOM6j3PhUvq5T25ksGl1FAomsW94i1Q9
 BU=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch does two things:
* Remove the become_flags from sudo tasks in bringup_guestfs and
  libvirt_user roles
* Call the playbook with the -K argument so the user enters the
  sudo password just once after the playbook call

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 playbooks/roles/bringup_guestfs/tasks/main.yml                 | 6 ------
 playbooks/roles/libvirt_user/tasks/enable-user/debian/main.yml | 1 -
 scripts/guestfs.Makefile                                       | 2 +-
 3 files changed, 1 insertion(+), 8 deletions(-)

diff --git a/playbooks/roles/bringup_guestfs/tasks/main.yml b/playbooks/roles/bringup_guestfs/tasks/main.yml
index 07e0fc4..95631aa 100644
--- a/playbooks/roles/bringup_guestfs/tasks/main.yml
+++ b/playbooks/roles/bringup_guestfs/tasks/main.yml
@@ -59,7 +59,6 @@
 
 - name: Check dnsmasq service status
   become: yes
-  become_flags: 'su - -c'
   become_method: sudo
   command: systemctl is-enabled dnsmasq
   register: dnsmasq_enabled
@@ -72,7 +71,6 @@
 
 - name: Check if dnsmasq service is active
   become: yes
-  become_flags: 'su - -c'
   become_method: sudo
   command: systemctl is-active dnsmasq
   register: dnsmasq_active
@@ -94,7 +92,6 @@
 
 - name: Check if libvirt default network is running
   become: yes
-  become_flags: 'su - -c'
   become_method: sudo
   shell: virsh net-list | grep -q default
   register: libvirt_default_net
@@ -106,7 +103,6 @@
 - name: Start the libvirt default network if not running
   command: virsh net-start default
   become: yes
-  become_flags: 'su - -c'
   become_method: sudo
   when:
     - 'libvirt_uri_system|bool'
@@ -123,7 +119,6 @@
 
 - name: Look for console.log files in guestfs subdirectories to check for CI enablement
   become: yes
-  become_flags: 'su - -c'
   become_method: sudo
   find:
     paths: "{{ topdir_path }}/guestfs"
@@ -137,7 +132,6 @@
 
 - name: Ensure console.log files are owned by the main user for CI monitoring
   become: yes
-  become_flags: 'su - -c'
   become_method: sudo
   file:
     path: "{{ item.path }}"
diff --git a/playbooks/roles/libvirt_user/tasks/enable-user/debian/main.yml b/playbooks/roles/libvirt_user/tasks/enable-user/debian/main.yml
index 5797bd6..2fa31ce 100644
--- a/playbooks/roles/libvirt_user/tasks/enable-user/debian/main.yml
+++ b/playbooks/roles/libvirt_user/tasks/enable-user/debian/main.yml
@@ -49,7 +49,6 @@
 - name: Ensure our user is part of the libvirt/kvm groups
   tags: [ 'journal', 'build-deps' ]
   become: yes
-  become_flags: 'su - -c'
   become_method: sudo
   ansible.builtin.user:
     name:  "{{ ansible_user_id }}"
diff --git a/scripts/guestfs.Makefile b/scripts/guestfs.Makefile
index dbfb372..480bc4f 100644
--- a/scripts/guestfs.Makefile
+++ b/scripts/guestfs.Makefile
@@ -73,7 +73,7 @@ $(KDEVOPS_PROVISIONED_SSH):
 	$(Q)touch $(KDEVOPS_PROVISIONED_SSH)
 
 bringup_guestfs: $(GUESTFS_BRINGUP_DEPS)
-	$(Q)ansible-playbook $(ANSIBLE_VERBOSE) --connection=local \
+	$(Q)ansible-playbook -K $(ANSIBLE_VERBOSE) --connection=local \
 		--inventory localhost, \
 		playbooks/bringup_guestfs.yml \
 		-e 'ansible_python_interpreter=/usr/bin/python3' \

-- 
2.44.2

