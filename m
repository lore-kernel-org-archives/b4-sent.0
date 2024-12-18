From: Joel Granados <joel.granados@kernel.org>
Date: Wed, 18 Dec 2024 11:29:59 +0100
Subject: [PATCH 05/12] ansible: Add build-deps tag
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241218-jag-bringup_fixes-v1-5-0bf2e07c640c@kernel.org>
References: <20241218-jag-bringup_fixes-v1-0-0bf2e07c640c@kernel.org>
In-Reply-To: <20241218-jag-bringup_fixes-v1-0-0bf2e07c640c@kernel.org>
To: kdevops@lists.linux.dev
Cc: Joel Granados <joel.granados@kernel.org>, da.gomez@samsung.com
X-Mailer: b4 0.15-dev-00a43
X-Developer-Signature: v=1; a=openpgp-sha256; l=4391;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=Kj8tG89mwj8PU4V97afgamZ3sTf5UN0mvrsoVFXiIVg=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGdipC0vTFCqIVpjdbbPEJRIefkKcGeOQGTqs
 61CixbFj4kqXIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJnYqQtAAoJELqXzVK3
 lkFPwH4L/0FJwTP7TFAJz8mSk4qBqmp1g7Mmay+nn3Ara86b/yUJrDr2Gz5bvMHV6IIi9ZqdFfF
 EUtLKFOIk4Exk8Bn9gEQnPftUy/txE7jeknm0/0BgvQ3HZ2ALO33MMnCGSNMBH04GpRCU8UMRAD
 rLOuFKvbEMRHTiqlmC6TrP9It+pfQy1v1skPDunDTYTIVSgUCzVi2YH2wdkKXKyH0Zct3ZGdvge
 o7OU78seX+J+mBoQWmxs4bsM5Xgmelcdv7st/F/sU5F1qZwoAmx5VRRO4qMPRemUjKCeWhCOHim
 99mcCCefghqQeLTzBpx3t8Z4r9pAa3bjc4upi81ZHwXZ8izOUYRcZtlc/QiCRVDSecPy0hcXhc2
 pcSCGHWnIkIKbQx+RUa9nqLH/D9NOX5l6z+PdTL0kGWG8JCVRNcQA9fOVmu6rAu5oK0qd2+RONx
 VpyxzmS6u4GUp19PnE+7PsSYG47NFxZOBERymXr44ALgUVq50yRS0fWUD1xs6xovzg7+xXa0037
 xw=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add build-deps tag to enable-user and install-deps tasks in libvirt_user
role so they can be used from other roles. With no tags, these tasks are
skipped.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 playbooks/roles/libvirt_user/tasks/enable-user/debian/main.yml | 6 +++++-
 playbooks/roles/libvirt_user/tasks/enable-user/main.yml        | 4 ++++
 playbooks/roles/libvirt_user/tasks/install-deps/main.yml       | 7 +++++++
 scripts/guestfs.Makefile                                       | 2 +-
 4 files changed, 17 insertions(+), 2 deletions(-)

diff --git a/playbooks/roles/libvirt_user/tasks/enable-user/debian/main.yml b/playbooks/roles/libvirt_user/tasks/enable-user/debian/main.yml
index 1ad7f17..5797bd6 100644
--- a/playbooks/roles/libvirt_user/tasks/enable-user/debian/main.yml
+++ b/playbooks/roles/libvirt_user/tasks/enable-user/debian/main.yml
@@ -9,12 +9,14 @@
   when:
     - not libvirt_session
     - not only_verify_user|bool
+  tags: [ 'build-deps' ]
 
 - name: Check if apparmor_status exists
   stat:
     path: /usr/sbin/apparmor_status
   register: apparmor_file_stat_result
   when: 'only_verify_user|bool'
+  tags: [ 'build-deps' ]
 
 - name: Verify if AppArmor is disabled when applicable
   become: yes
@@ -26,6 +28,7 @@
   when:
     - 'only_verify_user|bool'
     - 'apparmor_file_stat_result.stat.exists'
+  tags: [ 'build-deps' ]
 
 - name: Verifies user's effective group allows to run libvirt/kvm without being root
   shell: groups | grep {{ item }}
@@ -41,9 +44,10 @@
   when:
     - not libvirt_session
     - not only_verify_user|bool
+  tags: [ 'build-deps' ]
 
 - name: Ensure our user is part of the libvirt/kvm groups
-  tags: [ 'journal' ]
+  tags: [ 'journal', 'build-deps' ]
   become: yes
   become_flags: 'su - -c'
   become_method: sudo
diff --git a/playbooks/roles/libvirt_user/tasks/enable-user/main.yml b/playbooks/roles/libvirt_user/tasks/enable-user/main.yml
index 04f8e31..364d625 100644
--- a/playbooks/roles/libvirt_user/tasks/enable-user/main.yml
+++ b/playbooks/roles/libvirt_user/tasks/enable-user/main.yml
@@ -2,19 +2,23 @@
 - name: Debian-specific set up
   ansible.builtin.include_tasks: install-deps/debian/main.yml
   when: ansible_os_family == 'Debian'
+  tags: [ 'build-deps' ]
 
 - name: SuSE-specific set up
   ansible.builtin.include_tasks: install-deps/suse/main.yml
   when: ansible_os_family == 'Suse'
+  tags: [ 'build-deps' ]
 
 - name: Red Hat-specific set up
   ansible.builtin.include_tasks: install-deps/redhat/main.yml
   when:
     - ansible_os_family == 'RedHat'
     - ansible_facts['distribution'] != "Fedora"
+  tags: [ 'build-deps' ]
 
 - name: Fedora-specific set up
   ansible.builtin.include_tasks: install-deps/fedora/main.yml
   when:
     - ansible_os_family == 'RedHat'
     - ansible_facts['distribution'] == "Fedora"
+  tags: [ 'build-deps' ]
diff --git a/playbooks/roles/libvirt_user/tasks/install-deps/main.yml b/playbooks/roles/libvirt_user/tasks/install-deps/main.yml
index c652ab2..c2f58c8 100644
--- a/playbooks/roles/libvirt_user/tasks/install-deps/main.yml
+++ b/playbooks/roles/libvirt_user/tasks/install-deps/main.yml
@@ -11,11 +11,18 @@
 - name: Distribution specific setup
   import_tasks: debian/main.yml
   when: ansible_facts['os_family']|lower == 'debian'
+  tags: [ 'build-deps' ]
+
 - import_tasks: suse/main.yml
   when: ansible_facts['os_family']|lower == 'suse'
+  tags: [ 'build-deps' ]
+
 - import_tasks: redhat/main.yml
   when:
     - ansible_facts['os_family']|lower == 'redhat'
     - ansible_facts['distribution']|lower != "fedora"
+  tags: [ 'build-deps' ]
+
 - import_tasks: fedora/main.yml
   when: ansible_facts['distribution']|lower == "fedora"
+  tags: [ 'build-deps' ]
diff --git a/scripts/guestfs.Makefile b/scripts/guestfs.Makefile
index 52397d5..dbfb372 100644
--- a/scripts/guestfs.Makefile
+++ b/scripts/guestfs.Makefile
@@ -78,7 +78,7 @@ bringup_guestfs: $(GUESTFS_BRINGUP_DEPS)
 		playbooks/bringup_guestfs.yml \
 		-e 'ansible_python_interpreter=/usr/bin/python3' \
 		--extra-vars=@./extra_vars.yaml \
-		--tags config-check,network
+		--tags config-check,network,build-deps
 	$(Q)$(TOPDIR)/scripts/bringup_guestfs.sh
 	$(Q)ansible-playbook $(ANSIBLE_VERBOSE) --connection=local \
 		--inventory localhost, \

-- 
2.44.2

