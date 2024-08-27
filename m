From: Daniel Gomez <da.gomez@samsung.com>
Date: Tue, 27 Aug 2024 21:36:59 +0200
Subject: [PATCH RFC WIP 04/13] linux: Makefile: use helper for
 bootlinux-local
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240827-ansible-cleanups-v1-4-2828a816de5e@samsung.com>
References: <20240827-ansible-cleanups-v1-0-2828a816de5e@samsung.com>
In-Reply-To: <20240827-ansible-cleanups-v1-0-2828a816de5e@samsung.com>
To: kdevops@lists.linux.dev, Luis Chamberlain <mcgrof@kernel.org>
Cc: "Daniel Gomez (Samsung)" <d+samsung@kruces.com>, gost.dev@samsung.com, 
 Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1724787418; l=947;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=cR+EYjmznbFXt0VL6+4bdWFXqtZ31//oipY520Tp1aE=;
 b=WSulgrSG4VVTyfgqdJDkFp0GlM20LmYOAWGH2+j3xVbTtOtoodC/g47N3+zBHjyOfM8rfpEFB
 868Y3RlfxdqBeGgLRUGkqB5kJtNJW9zKaIZA+KjF4yVDz5pOCAJlgpx
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This uses '127.0.0.1' instead of localhost. Using the ansible helper
will make use of --connection=local and localhost for the inventory.

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
 workflows/linux/Makefile | 4 +---
 1 file changed, 1 insertion(+), 3 deletions(-)

diff --git a/workflows/linux/Makefile b/workflows/linux/Makefile
index db20ba99..d4a87b62 100644
--- a/workflows/linux/Makefile
+++ b/workflows/linux/Makefile
@@ -90,9 +90,7 @@ LINUX_HELP_EXTRA :=
 
 PHONY += linux
 linux: $(KDEVOPS_NODES)
-	$(Q)ansible-playbook $(ANSIBLE_VERBOSE) -i \
-		'127.0.0.1,' $(KDEVOPS_PLAYBOOKS_DIR)/bootlinux-local.yml \
-		--extra-vars="$(BOOTLINUX_ARGS)"
+	$(call run_ansible_playbook_local, $(KDEVOPS_PLAYBOOKS_DIR)/bootlinux-local.yml)
 	$(Q)ansible-playbook $(ANSIBLE_VERBOSE) -i \
 		$(KDEVOPS_HOSTFILE) $(KDEVOPS_PLAYBOOKS_DIR)/bootlinux.yml \
 		--extra-vars="$(BOOTLINUX_ARGS)" $(LIMIT_HOSTS)

-- 
2.39.2

