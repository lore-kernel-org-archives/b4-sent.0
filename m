From: Joel Granados <joel.granados@kernel.org>
Date: Wed, 18 Dec 2024 11:30:02 +0100
Subject: [PATCH 08/12] ansible: Install libvirt deps and enable user
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241218-jag-bringup_fixes-v1-8-0bf2e07c640c@kernel.org>
References: <20241218-jag-bringup_fixes-v1-0-0bf2e07c640c@kernel.org>
In-Reply-To: <20241218-jag-bringup_fixes-v1-0-0bf2e07c640c@kernel.org>
To: kdevops@lists.linux.dev
Cc: Joel Granados <joel.granados@kernel.org>, da.gomez@samsung.com
X-Mailer: b4 0.15-dev-00a43
X-Developer-Signature: v=1; a=openpgp-sha256; l=1171;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=DvGfd4CLkmhlBD3vAsOZb4k3P/lxx9nbk6oF98SgWGs=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGdipC+/TB4qp0GWlRWlwn5A/+4LBYTHGLv+j
 XDeZ/mZSGrr8IkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJnYqQvAAoJELqXzVK3
 lkFPfLsL/0e+fVA/cbaMh0OyeYAz0gnO8felFvf45m+NBVC4zcG4jiXUgZT1b41d4AcvROplyqO
 fK2VrSatvGW8IDp9C74A6vKjhxdmrD98CI+Xa8CVbSiNkCM2mXEjFXStNDC+8Vry4hyOGFAnRtP
 WYBbl07rZFcPCg8HeTalwGaJDn1NSkgRkrxWkRM7GUFFvkK07GklnEdVuImwk8S0MqQP9x4VslT
 SeNHE4JH6lR6H5CLHHK7Q7f2GudwD9rbpfLxdyDeD9J4pi+x/1kGb1uxNaL5w3JYFyBa/8rc9f6
 ULXL+9OcKbTik2HFs8evyiNUXnpUWrL1x4bL/GNJvNzn7FwoAAfrGrgKnhn0E3WpBKTetDawkC5
 4EPlAth7NR9mBAq5cvViq3+DTu9tsc5Nn2gXNK/eQLqpOqEOoWo09c8bu7sj0b/7+pwkn4rGdeq
 Cap7HNo6osF/1rBcNGnwdtZV/HDlSilFxahtJfxSLi+IiBJlV74M+HJ4pl6J4NFHUQQbBV6mch8
 po=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There is a need to setup libvirt when running `make bringup` in a system
that does not have libvirt installed. Call the dpendency install and
user enablement roles from the bringup task.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 playbooks/roles/bringup_guestfs/tasks/main.yml | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/playbooks/roles/bringup_guestfs/tasks/main.yml b/playbooks/roles/bringup_guestfs/tasks/main.yml
index 95631aa..c764ae4 100644
--- a/playbooks/roles/bringup_guestfs/tasks/main.yml
+++ b/playbooks/roles/bringup_guestfs/tasks/main.yml
@@ -38,6 +38,18 @@
   when: guestfs_subdirectories.matched == 0
   tags: [ 'config-check' ]
 
+- name: Use install-dep tasks from libvirt_user role to install libvirt deps
+  include_role:
+    name: libvirt_user
+    tasks_from: install-deps/main.yml
+  tags: [ 'network' ]
+
+- name: Use enable-user tasks from libvirt_user role to enable user
+  include_role:
+    name: libvirt_user
+    tasks_from: enable-user/main.yml
+  tags: [ 'network' ]
+
 - name: Check for dnsmasq configuration files
   stat:
     path: "{{ item }}"

-- 
2.44.2

