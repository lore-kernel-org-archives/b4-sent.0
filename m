From: Daniel Gomez <da.gomez@samsung.com>
Date: Tue, 27 Aug 2024 21:37:05 +0200
Subject: [PATCH RFC WIP 10/13] scripts: add ansible helper with hosts and
 extravars
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240827-ansible-cleanups-v1-10-2828a816de5e@samsung.com>
References: <20240827-ansible-cleanups-v1-0-2828a816de5e@samsung.com>
In-Reply-To: <20240827-ansible-cleanups-v1-0-2828a816de5e@samsung.com>
To: kdevops@lists.linux.dev, Luis Chamberlain <mcgrof@kernel.org>
Cc: "Daniel Gomez (Samsung)" <d+samsung@kruces.com>, gost.dev@samsung.com, 
 Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1724787418; l=645;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=6swAOkDRiczPYVE3SemJmSM5rdN03t7V3n/fgQ03Lqk=;
 b=20PU9pO6K0JMY6D2x6ydnaN1qaKDptconpBh1R8p+M+vlNqkkegRAD/c9TFswloqf1C/EzStV
 nxXoQJCLMgUAVlwmekS/a+FCE8Cu/qaun0gMXevVJ1dYcE43TlO/7cW
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
 scripts/ansible.Makefile | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/scripts/ansible.Makefile b/scripts/ansible.Makefile
index 5420a604..0b049c48 100644
--- a/scripts/ansible.Makefile
+++ b/scripts/ansible.Makefile
@@ -30,3 +30,11 @@ run_ansible_playbook_hosts_noq = \
 		--inventory $(KDEVOPS_HOSTFILE) \
 		$(1) \
 		$(if $(2),$(2))
+
+run_ansible_playbook_hosts_extravars = \
+	$(Q)ansible-playbook \
+		$(ANSIBLE_VERBOSE) \
+		--inventory $(KDEVOPS_HOSTFILE) \
+		--extra-vars=@./$(KDEVOPS_EXTRA_VARS) \
+		$(1) \
+		$(if $(2),$(2))

-- 
2.39.2

