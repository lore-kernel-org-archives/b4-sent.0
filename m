From: Joel Granados <joel.granados@kernel.org>
Date: Wed, 18 Dec 2024 11:30:01 +0100
Subject: [PATCH 07/12] ansible: Run sudo by using the '-K' ansible arg
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241218-jag-bringup_fixes-v1-7-0bf2e07c640c@kernel.org>
References: <20241218-jag-bringup_fixes-v1-0-0bf2e07c640c@kernel.org>
In-Reply-To: <20241218-jag-bringup_fixes-v1-0-0bf2e07c640c@kernel.org>
To: kdevops@lists.linux.dev
Cc: Joel Granados <joel.granados@kernel.org>, da.gomez@samsung.com
X-Mailer: b4 0.15-dev-00a43
X-Developer-Signature: v=1; a=openpgp-sha256; l=3240;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=FVJUFjxaM/R8fpk2NV9PoLz5rdhcjKBPNJtHwh5TkzY=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGdipC4gdQq2TzX3Y5Nmmx4B7pV5lZiBpo79t
 2Yh4kKPscSUGokBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJnYqQuAAoJELqXzVK3
 lkFPU6UL/iM0QCsX5b1n1abec0yzUENXsBRsTPmQHqS6WIsthhTYv/24FSVl+ujpUxMgut7SIO/
 0E9+yvVy1Ni1YyND1LmA0w+W98SYJ7IwiTzBWCC8tVGehibJJqOBFIFL90YM26MFRV/eNLG9SVz
 iKKrTDBzxazLNwVVLV9ca+G9gVdQDjjgUfawklqN8AZ3Rm6mZnPNazdnz9tDhczj9jOilzmrsX4
 jndAqlsfG1OzNJEc427/kiBqR9XOKBB1WuWx1iB2vKw1sqi8k9ZEZWHL5/oUUxuzIW8NMng0+s1
 kYrHMTVRtiaFS8kEsfO3i4dn8z9YpUZMMGCD9i37UXLCf0rt3D5/8bYqcuLjgenzRnksIdsQHMf
 XgI/WMzkYedmFOHFx5TEWq0NqZjDGWxz2cAY3XnockDeWakgCtxACLAb/0iz0CRDB23StJ1L5A5
 rfyq2eIhF4SMDFdeIb6YLkChHrauO2UNyfvQoR0yyh3+91G44V6MaggYfvD8KNPrF8mwzoajoc6
 Wk=
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

