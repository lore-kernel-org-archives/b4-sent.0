From: Daniel Gomez <da.gomez@samsung.com>
Date: Tue, 27 Aug 2024 21:37:02 +0200
Subject: [PATCH RFC WIP 07/13] Makefile.kdevops: add run helper fix
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240827-ansible-cleanups-v1-7-2828a816de5e@samsung.com>
References: <20240827-ansible-cleanups-v1-0-2828a816de5e@samsung.com>
In-Reply-To: <20240827-ansible-cleanups-v1-0-2828a816de5e@samsung.com>
To: kdevops@lists.linux.dev, Luis Chamberlain <mcgrof@kernel.org>
Cc: "Daniel Gomez (Samsung)" <d+samsung@kruces.com>, gost.dev@samsung.com, 
 Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1724787418; l=663;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=JzN6aWjBLkZI/cd2okYMganv898szwktggDosAEouO0=;
 b=AAPB/1d4W8XIa1ErFvcbJvi2JTqEWZdU7t/OCgLe7rw/VpYBjABhlcpFvY4MwXZFS6lk/74C/
 q0zq8mTZh7WAi2ZIqGjD64D2bQSOLh/xn5l93OmbEiGXG1bc8Hy/nq1
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Make sure stage 2 include Ansible Makefile helper so it can make use
of it.

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
 Makefile.kdevops | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/Makefile.kdevops b/Makefile.kdevops
index 649cb729..509ac1df 100644
--- a/Makefile.kdevops
+++ b/Makefile.kdevops
@@ -5,6 +5,10 @@ KDEVOPS_PLAYBOOKS_DIR ?=	playbooks
 KDEVOPS_HOSTFILE ?=		hosts
 KDEVOPS_LOCAL_WORK :=
 
+# scripts/bringup.Makefile calls this Makefile with kdevops_stage_2 callback
+# include Ansible Makefile helper
+include scripts/ansible.Makefile
+
 kdevops_all: kdevops_deps
 PHONY := kdevops_all
 

-- 
2.39.2

