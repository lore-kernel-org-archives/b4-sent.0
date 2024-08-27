From: Daniel Gomez <da.gomez@samsung.com>
Date: Tue, 27 Aug 2024 21:37:03 +0200
Subject: [PATCH RFC WIP 08/13] Makefile.kdevops: allow to use verbose make
 options
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240827-ansible-cleanups-v1-8-2828a816de5e@samsung.com>
References: <20240827-ansible-cleanups-v1-0-2828a816de5e@samsung.com>
In-Reply-To: <20240827-ansible-cleanups-v1-0-2828a816de5e@samsung.com>
To: kdevops@lists.linux.dev, Luis Chamberlain <mcgrof@kernel.org>
Cc: "Daniel Gomez (Samsung)" <d+samsung@kruces.com>, gost.dev@samsung.com, 
 Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1724787418; l=786;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=HVIHeWNyqb8TqzYSiJi7Gycx8sI+aIvZaB0P/1+0NbA=;
 b=18ip5enO8yStRdgMm69XIrIYyNMFT3KaKj2dsudw7sUxAWFHj8GV+q8c9P6QYv2VPkcC072Cg
 vuxtJlJYnryBkIQIMKdotShaBBCvvCfs+jJbwWXm6iSJXBdU1iBaR3Y
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Allow the use of V= in Makefile.kdevops.

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
 Makefile.kdevops | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/Makefile.kdevops b/Makefile.kdevops
index 509ac1df..1c09e8da 100644
--- a/Makefile.kdevops
+++ b/Makefile.kdevops
@@ -5,6 +5,14 @@ KDEVOPS_PLAYBOOKS_DIR ?=	playbooks
 KDEVOPS_HOSTFILE ?=		hosts
 KDEVOPS_LOCAL_WORK :=
 
+ifeq ($(V),1) # If V=1 then, Q is empty -> $(Q)<command> prints command
+export Q= # Empty Q allows to print the command
+export NQ=true
+else
+export Q=@ # Do not print command
+export NQ=echo
+endif
+
 # scripts/bringup.Makefile calls this Makefile with kdevops_stage_2 callback
 # include Ansible Makefile helper
 include scripts/ansible.Makefile

-- 
2.39.2

