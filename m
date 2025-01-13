From: Joel Granados <joel.granados@kernel.org>
Date: Mon, 13 Jan 2025 12:53:06 +0100
Subject: [PATCH RESEND 08/12] ansible: Install libvirt deps and enable user
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250113-jag-bringup_fixes-v1-8-fb28030b1f26@kernel.org>
References: <20250113-jag-bringup_fixes-v1-0-fb28030b1f26@kernel.org>
In-Reply-To: <20250113-jag-bringup_fixes-v1-0-fb28030b1f26@kernel.org>
To: kdevops@lists.linux.dev
Cc: Joel Granados <joel.granados@kernel.org>, mcgrof@kernel.org, 
 da.gomez@samsung.com
X-Mailer: b4 0.15-dev-00a43
X-Developer-Signature: v=1; a=openpgp-sha256; l=1171;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=DvGfd4CLkmhlBD3vAsOZb4k3P/lxx9nbk6oF98SgWGs=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGeE/qY6S/o7dsMnXjGnA7CirAZQtD1pk/iMA
 /fPJIgXvhplx4kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJnhP6mAAoJELqXzVK3
 lkFPvDUL/0/p19s3IJXY1YHnPfoLtjzvRJH7RY/w9dd24E5K+nHZ4WDiSQKsMxliYJWqkpld16O
 WkffVA6hUXrLI7Fn/IxjFoPzm229jKJE6LThrEYB9JfEZbgxVtYOumAFLMxmQsvRKmePPlaWyEk
 nCPsq3Ij6QAXfc6KdAixgccD2bmFfSMdQiFhHfkVIIjQ8G0rOw4IxuCSLvYL6M56/s80JSWJlTE
 hTtsJgzV6vOwuzUAnx9HPErrYTTB6fiIgLhQf0Jx1BlF28+2PERnyZzYlJCEzyaIvgzPb5gZwCX
 2IS8y95G7O+3GiiKIFzScO4UZYleQJsYSb6ZxabIkEkvKdOJKAehF/WFPyStn5jshTPFL4mvDlF
 4Ba+QBEfFZ8N5sLk7tqysKaKyXSHLJkeG6iK40Z7YD7Z6YHViuJk4BquxgCOwPQ8uD/4GkAV4gZ
 BHkT80gMwc4AE2IBvmXA+EC444w/7DX+qK77K40gimeFUnAjXlvZypLnxpsE8D+gGq6mLY5YmZ5
 0g=
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

