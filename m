From: Joel Granados <joel.granados@kernel.org>
Date: Wed, 18 Dec 2024 11:30:00 +0100
Subject: [PATCH 06/12] ansible: Use full paths when importing tasks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241218-jag-bringup_fixes-v1-6-0bf2e07c640c@kernel.org>
References: <20241218-jag-bringup_fixes-v1-0-0bf2e07c640c@kernel.org>
In-Reply-To: <20241218-jag-bringup_fixes-v1-0-0bf2e07c640c@kernel.org>
To: kdevops@lists.linux.dev
Cc: Joel Granados <joel.granados@kernel.org>, da.gomez@samsung.com
X-Mailer: b4 0.15-dev-00a43
X-Developer-Signature: v=1; a=openpgp-sha256; l=2953;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=kK8WYlj3lCiI+bWD9/rTi5l4rFK8spbgf35AT9VzodE=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGdipC6D2kfNXdSiYIv5376WGvEHBSzx9icVb
 hvGBCN2Oq6hqIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJnYqQuAAoJELqXzVK3
 lkFPR/oL/jDdSWI032qQh8cY/srGHs4q851KoAsBXAMVq2bux1tIxgnc8dUhk1B0XH89fITOiWH
 8rKIp+ee/gF0+2gISxDqxjRpYSlL8dgn134g530h/q4pdDLqvardnLPrCQJQFotU4DZNJn6Qnck
 qeUitnKedTW4+CVn1H3FgXdSlWrMjdaF6jCe3tPH/jHMwOUTem8DiAkC/UumfWrgo7BoFHNRecQ
 YP71vNbmQm4TQz+b7hZVA+FEfu1oApHKObszaizDUihQUgu5zgYTnfNEK+mjqtCKtXSz2zNzSNj
 76t4lycehSsadFvTXr8pmzcByB6bAYeKSc8d7ba3Tzy58GUltqScRNhTSTyd12w6g8F4Xge+xXD
 HoEU84JOnsbMgAg5tjTR16p5G/gs2mpUmv4VD2shUnK5CgJ76WmlqZyKrJn0Q4DlqVlUTluKTqh
 jt0U3S9qVyQGZRv96beOgGH+mdoTCwwUYK3GfuCl8RnaP9PB4vc8qGYHd+GTvJ4/RBWFAYNXij5
 BU=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This allows importing libvirt_user tasks without the hassle of
changing relative paths.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 playbooks/roles/libvirt_user/tasks/enable-user/main.yml  | 8 ++++----
 playbooks/roles/libvirt_user/tasks/install-deps/main.yml | 8 ++++----
 2 files changed, 8 insertions(+), 8 deletions(-)

diff --git a/playbooks/roles/libvirt_user/tasks/enable-user/main.yml b/playbooks/roles/libvirt_user/tasks/enable-user/main.yml
index 364d625..2c632f2 100644
--- a/playbooks/roles/libvirt_user/tasks/enable-user/main.yml
+++ b/playbooks/roles/libvirt_user/tasks/enable-user/main.yml
@@ -1,23 +1,23 @@
 ---
 - name: Debian-specific set up
-  ansible.builtin.include_tasks: install-deps/debian/main.yml
+  ansible.builtin.include_tasks: "{{ role_path }}/tasks/enable-user/debian/main.yml"
   when: ansible_os_family == 'Debian'
   tags: [ 'build-deps' ]
 
 - name: SuSE-specific set up
-  ansible.builtin.include_tasks: install-deps/suse/main.yml
+  ansible.builtin.include_tasks: "{{ role_path }}/tasks/enable-user/suse/main.yml"
   when: ansible_os_family == 'Suse'
   tags: [ 'build-deps' ]
 
 - name: Red Hat-specific set up
-  ansible.builtin.include_tasks: install-deps/redhat/main.yml
+  ansible.builtin.include_tasks: "{{ role_path }}/tasks/enable-user/redhat/main.yml"
   when:
     - ansible_os_family == 'RedHat'
     - ansible_facts['distribution'] != "Fedora"
   tags: [ 'build-deps' ]
 
 - name: Fedora-specific set up
-  ansible.builtin.include_tasks: install-deps/fedora/main.yml
+  ansible.builtin.include_tasks: "{{ role_path }}/tasks/enable-user/fedora/main.yml"
   when:
     - ansible_os_family == 'RedHat'
     - ansible_facts['distribution'] == "Fedora"
diff --git a/playbooks/roles/libvirt_user/tasks/install-deps/main.yml b/playbooks/roles/libvirt_user/tasks/install-deps/main.yml
index c2f58c8..cd12e05 100644
--- a/playbooks/roles/libvirt_user/tasks/install-deps/main.yml
+++ b/playbooks/roles/libvirt_user/tasks/install-deps/main.yml
@@ -9,20 +9,20 @@
   tags: vars
 
 - name: Distribution specific setup
-  import_tasks: debian/main.yml
+  import_tasks: "{{ role_path }}/tasks/install-deps/debian/main.yml"
   when: ansible_facts['os_family']|lower == 'debian'
   tags: [ 'build-deps' ]
 
-- import_tasks: suse/main.yml
+- import_tasks: "{{ role_path }}/tasks/install-deps/suse/main.yml"
   when: ansible_facts['os_family']|lower == 'suse'
   tags: [ 'build-deps' ]
 
-- import_tasks: redhat/main.yml
+- import_tasks: "{{ role_path }}/tasks/install-deps/redhat/main.yml"
   when:
     - ansible_facts['os_family']|lower == 'redhat'
     - ansible_facts['distribution']|lower != "fedora"
   tags: [ 'build-deps' ]
 
-- import_tasks: fedora/main.yml
+- import_tasks: "{{ role_path }}/tasks/install-deps/fedora/main.yml"
   when: ansible_facts['distribution']|lower == "fedora"
   tags: [ 'build-deps' ]

-- 
2.44.2

