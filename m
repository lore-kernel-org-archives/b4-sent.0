From: Daniel Gomez <da.gomez@samsung.com>
Date: Tue, 27 Aug 2024 21:37:00 +0200
Subject: [PATCH RFC WIP 05/13] Makefile: add run_ansible_playbook_hosts
 helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240827-ansible-cleanups-v1-5-2828a816de5e@samsung.com>
References: <20240827-ansible-cleanups-v1-0-2828a816de5e@samsung.com>
In-Reply-To: <20240827-ansible-cleanups-v1-0-2828a816de5e@samsung.com>
To: kdevops@lists.linux.dev, Luis Chamberlain <mcgrof@kernel.org>
Cc: "Daniel Gomez (Samsung)" <d+samsung@kruces.com>, gost.dev@samsung.com, 
 Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1724787418; l=2055;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=iPRBijkXcihMQxCwO6djWDCnitpat1zvOfMErMeTAIw=;
 b=Pat+P4HQjYYfNgJI0fayIiT557ZEeR/RAqHyZw7M409kVzTdqcg7Or/H+XmkbY9WocozEsTEC
 X6k9odYDXCbBVFAJJtaVAqk8F3XPJB9vwDWyax7bkUXkg+NUsRD58gB
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use it where KDEVOPS_HOSTS var is used.

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
 scripts/ansible.Makefile   | 14 ++++++++++++++
 scripts/provision.Makefile |  3 +--
 scripts/vagrant.Makefile   |  3 +--
 3 files changed, 16 insertions(+), 4 deletions(-)

diff --git a/scripts/ansible.Makefile b/scripts/ansible.Makefile
index 46a318d6..5420a604 100644
--- a/scripts/ansible.Makefile
+++ b/scripts/ansible.Makefile
@@ -16,3 +16,17 @@ run_ansible_playbook_local_noq = \
 		--connection=local \
 		$(1) \
 		$(if $(2),$(2))
+
+run_ansible_playbook_hosts = \
+	$(Q)ansible-playbook \
+		$(ANSIBLE_VERBOSE) \
+		--inventory $(KDEVOPS_HOSTFILE) \
+		$(1) \
+		$(if $(2),$(2))
+
+run_ansible_playbook_hosts_noq = \
+	ansible-playbook \
+		$(ANSIBLE_VERBOSE) \
+		--inventory $(KDEVOPS_HOSTFILE) \
+		$(1) \
+		$(if $(2),$(2))
diff --git a/scripts/provision.Makefile b/scripts/provision.Makefile
index 26657c09..48d8bab2 100644
--- a/scripts/provision.Makefile
+++ b/scripts/provision.Makefile
@@ -65,8 +65,7 @@ KDEVOPS_MRPROPER += $(KDEVOPS_PROVISIONED_DEVCONFIG)
 
 $(KDEVOPS_PROVISIONED_DEVCONFIG):
 	$(Q)if [[ "$(CONFIG_KDEVOPS_ANSIBLE_PROVISION_PLAYBOOK)" != "" ]]; then \
-		ansible-playbook $(ANSIBLE_VERBOSE) -i \
-			$(KDEVOPS_HOSTFILE) $(KDEVOPS_PLAYBOOKS_DIR)/$(KDEVOPS_ANSIBLE_PROVISION_PLAYBOOK) ;\
+		$(call run_ansible_playbook_hosts_noq, $(KDEVOPS_PLAYBOOKS_DIR)/$(KDEVOPS_ANSIBLE_PROVISION_PLAYBOOK)) ;\
 	fi
 	$(Q)touch $(KDEVOPS_PROVISIONED_DEVCONFIG)
 
diff --git a/scripts/vagrant.Makefile b/scripts/vagrant.Makefile
index 880cb370..bec7ba81 100644
--- a/scripts/vagrant.Makefile
+++ b/scripts/vagrant.Makefile
@@ -87,8 +87,7 @@ extend-extra-args-vagrant:
 	fi
 
 vagrant_private_box_install:
-	$(Q)ansible-playbook $(ANSIBLE_VERBOSE) -i \
-		$(KDEVOPS_HOSTFILE) $(KDEVOPS_PLAYBOOKS_DIR)/install_vagrant_boxes.yml
+	$(call run_ansible_playbook_hosts, $(KDEVOPS_PLAYBOOKS_DIR)/install_vagrant_boxes.yml)
 
 vagrant_9p_linux_clone:
 	$(Q)make linux-clone

-- 
2.39.2

