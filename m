From: Daniel Gomez <da.gomez@samsung.com>
Date: Tue, 27 Aug 2024 21:36:56 +0200
Subject: [PATCH RFC WIP 01/13] Makefile: add ansible_python_interpreter to
 ANSIBLE_EXTRA_ARGS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240827-ansible-cleanups-v1-1-2828a816de5e@samsung.com>
References: <20240827-ansible-cleanups-v1-0-2828a816de5e@samsung.com>
In-Reply-To: <20240827-ansible-cleanups-v1-0-2828a816de5e@samsung.com>
To: kdevops@lists.linux.dev, Luis Chamberlain <mcgrof@kernel.org>
Cc: "Daniel Gomez (Samsung)" <d+samsung@kruces.com>, gost.dev@samsung.com, 
 Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1724787418; l=6574;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=Xux5xt5TZSzOIwNWZurhlbhnrYYKhuGw6i9Qnmv9GLY=;
 b=8TIVuQT98O7Ytx0IMN9BIGPv0p8Y7oDFfiziZW17YzEcx+qZ8AobSKbuQXNI55bbHe+09dUN4
 mtYehNjeMJGCVI/RCcGDPLB2jZ051w3CIE9VEh0vbWt+q9q3E1iH3il
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add ansible_python_interpreter to the extra_vars.yaml
via ANSIBLE_EXTRA_ARGS and based on kdevops config
CONFIG_KDEVOPS_PYTHON_INTEPRETER to allow simplify the ansible-playbook
command by removing the extra argument to specify the python
interprester variable for those commands that already make use of the
argument '--extra-vars=@./extra_vars.yaml'

No functional changes.

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
 Makefile                    | 4 ++--
 Makefile.build_qemu         | 4 ----
 Makefile.hypervisor-tunings | 1 -
 Makefile.linux-mirror       | 1 -
 Makefile.postfix            | 1 -
 scripts/guestfs.Makefile    | 3 +--
 scripts/terraform.Makefile  | 1 -
 workflows/fstests/Makefile  | 1 -
 8 files changed, 3 insertions(+), 13 deletions(-)

diff --git a/Makefile b/Makefile
index b961e44f..8e2e805c 100644
--- a/Makefile
+++ b/Makefile
@@ -60,6 +60,8 @@ ANSIBLE_EXTRA_ARGS_SEPARATED :=
 ANSIBLE_EXTRA_ARGS_DIRECT :=
 include Makefile.extra_vars
 
+ANSIBLE_EXTRA_ARGS += ansible_python_interpreter='$(CONFIG_KDEVOPS_PYTHON_INTERPRETER)'
+
 LIMIT_HOSTS :=
 ifneq (,$(HOSTS))
 LIMIT_HOSTS := '-l $(subst ${space},$(comma),$(HOSTS))'
@@ -220,7 +222,6 @@ $(KDEVOPS_HOSTS): .config $(KDEVOPS_HOSTS_TEMPLATE)
 	$(Q)ansible-playbook $(ANSIBLE_VERBOSE) --connection=local \
 		--inventory localhost, \
 		$(KDEVOPS_PLAYBOOKS_DIR)/gen_hosts.yml \
-		-e 'ansible_python_interpreter=/usr/bin/python3' \
 		--extra-vars=@./extra_vars.yaml
 
 DEFAULT_DEPS += $(KDEVOPS_NODES)
@@ -228,7 +229,6 @@ $(KDEVOPS_NODES) $(KDEVOPS_VAGRANT): .config $(KDEVOPS_NODES_TEMPLATE)
 	$(Q)ansible-playbook $(ANSIBLE_VERBOSE) --connection=local \
 		--inventory localhost, \
 		$(KDEVOPS_PLAYBOOKS_DIR)/gen_nodes.yml \
-		-e 'ansible_python_interpreter=/usr/bin/python3' \
 		--extra-vars=@./extra_vars.yaml
 
 DEFAULT_DEPS += $(LOCALHOST_SETUP_WORK)
diff --git a/Makefile.build_qemu b/Makefile.build_qemu
index 7addd2f0..05cfb2f3 100644
--- a/Makefile.build_qemu
+++ b/Makefile.build_qemu
@@ -23,7 +23,6 @@ qemu: $(KDEVOPS_EXTRA_VARS)
 	@$(Q)ansible-playbook $(ANSIBLE_VERBOSE) --connection=local \
 		--inventory localhost, \
 		$(KDEVOPS_PLAYBOOKS_DIR)/build_qemu.yml \
-		-e 'ansible_python_interpreter=/usr/bin/python3' \
 		--extra-vars=@./extra_vars.yaml
 PHONY += qemu
 
@@ -31,7 +30,6 @@ qemu-install: $(KDEVOPS_EXTRA_VARS)
 	@$(Q)ansible-playbook $(ANSIBLE_VERBOSE) --connection=local \
 		--inventory localhost, \
 		$(KDEVOPS_PLAYBOOKS_DIR)/build_qemu.yml \
-		-e 'ansible_python_interpreter=/usr/bin/python3' \
 		--extra-vars=@./extra_vars.yaml --tags vars,install
 PHONY += qemu-install
 
@@ -39,7 +37,6 @@ qemu-configure: $(KDEVOPS_EXTRA_VARS)
 	@$(Q)ansible-playbook $(ANSIBLE_VERBOSE) --connection=local \
 		--inventory localhost, \
 		$(KDEVOPS_PLAYBOOKS_DIR)/build_qemu.yml \
-		-e 'ansible_python_interpreter=/usr/bin/python3' \
 		--extra-vars=@./extra_vars.yaml --tags vars,configure
 PHONY += qemu-configure
 
@@ -47,7 +44,6 @@ qemu-build: $(KDEVOPS_EXTRA_VARS)
 	@$(Q)ansible-playbook $(ANSIBLE_VERBOSE) --connection=local \
 		--inventory localhost, \
 		$(KDEVOPS_PLAYBOOKS_DIR)/build_qemu.yml \
-		-e 'ansible_python_interpreter=/usr/bin/python3' \
 		--extra-vars=@./extra_vars.yaml --tags vars,build
 PHONY += qemu-build
 
diff --git a/Makefile.hypervisor-tunings b/Makefile.hypervisor-tunings
index 46b3b00e..3f2f45a0 100644
--- a/Makefile.hypervisor-tunings
+++ b/Makefile.hypervisor-tunings
@@ -17,7 +17,6 @@ kdevops_hypervisor_tunning: $(KDEVOPS_EXTRA_VARS)
 	@$(Q)ansible-playbook $(ANSIBLE_VERBOSE) --connection=local \
 		--inventory localhost, \
 		$(KDEVOPS_PLAYBOOKS_DIR)/hypervisor-tuning.yml \
-		-e 'ansible_python_interpreter=/usr/bin/python3' \
 		--extra-vars=@./extra_vars.yaml
 PHONY += kdevops_hypervisor_tunning
 
diff --git a/Makefile.linux-mirror b/Makefile.linux-mirror
index f38a6198..8e8794d2 100644
--- a/Makefile.linux-mirror
+++ b/Makefile.linux-mirror
@@ -14,7 +14,6 @@ kdevops_linux_mirror: $(KDEVOPS_EXTRA_VARS)
 	$(Q)ansible-playbook --connection=local \
 		--inventory localhost, \
 		$(KDEVOPS_PLAYBOOKS_DIR)/linux-mirror.yml \
-		-e 'ansible_python_interpreter=/usr/bin/python3' \
 		--extra-vars=@./extra_vars.yaml
 PHONY += kdevops_linux_mirror
 
diff --git a/Makefile.postfix b/Makefile.postfix
index 7d945d97..e5d1776d 100644
--- a/Makefile.postfix
+++ b/Makefile.postfix
@@ -10,7 +10,6 @@ kdevops_postfix_setup_relay: $(KDEVOPS_EXTRA_VARS)
 	@$(Q)ansible-playbook $(ANSIBLE_VERBOSE) --connection=local \
 		--inventory localhost, \
 		$(KDEVOPS_PLAYBOOKS_DIR)/postfix_relay_host.yml \
-		-e 'ansible_python_interpreter=/usr/bin/python3' \
 		--extra-vars=@./extra_vars.yaml
 PHONY += kdevos_postfix_setup_relay
 ANSIBLE_EXTRA_ARGS += $(POSTFIX_SETUP_ARGS)
diff --git a/scripts/guestfs.Makefile b/scripts/guestfs.Makefile
index e4591ab4..08785644 100644
--- a/scripts/guestfs.Makefile
+++ b/scripts/guestfs.Makefile
@@ -70,8 +70,7 @@ $(KDEVOPS_PROVISIONED_SSH):
 		ansible-playbook $(ANSIBLE_VERBOSE) --connection=local \
 			--inventory localhost, \
 			playbooks/update_ssh_config_guestfs.yml \
-			--extra-vars=@./extra_vars.yaml \
-			-e 'ansible_python_interpreter=/usr/bin/python3' ;\
+			--extra-vars=@./extra_vars.yaml ;\
 		LIBVIRT_DEFAULT_URI=$(CONFIG_LIBVIRT_URI) $(TOPDIR)/scripts/update_ssh_config_guestfs.py; \
 	fi
 	$(Q)ansible $(ANSIBLE_VERBOSE) -i hosts all -e 'ansible_python_interpreter=/usr/bin/python3' -m wait_for_connection
diff --git a/scripts/terraform.Makefile b/scripts/terraform.Makefile
index 842dd28a..aeeac595 100644
--- a/scripts/terraform.Makefile
+++ b/scripts/terraform.Makefile
@@ -173,5 +173,4 @@ $(KDEVOPS_TFVARS): $(KDEVOPS_TFVARS_TEMPLATE) .config
 	$(Q)ansible-playbook $(ANSIBLE_VERBOSE) --connection=local \
 		--inventory localhost, \
 		$(KDEVOPS_PLAYBOOKS_DIR)/gen_tfvars.yml \
-		-e 'ansible_python_interpreter=/usr/bin/python3' \
 		--extra-vars=@./extra_vars.yaml
diff --git a/workflows/fstests/Makefile b/workflows/fstests/Makefile
index bc57b319..31db5257 100644
--- a/workflows/fstests/Makefile
+++ b/workflows/fstests/Makefile
@@ -215,7 +215,6 @@ fstests-config-debug: $(KDEVOPS_EXTRA_VARS)
 	$(Q)ansible-playbook $(ANSIBLE_VERBOSE) --connection=local \
 		--inventory localhost, \
 		playbooks/fstests.yml \
-		-e 'ansible_python_interpreter=/usr/bin/python3' \
 		-e 'fstests_debug_localhost=True' \
 		--tags vars,generate-fstests-config \
 		--extra-vars=@./extra_vars.yaml

-- 
2.39.2

