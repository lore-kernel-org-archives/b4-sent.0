From: Daniel Gomez <da.gomez@samsung.com>
Date: Tue, 27 Aug 2024 21:37:04 +0200
Subject: [PATCH RFC WIP 09/13] scripts: refs: remove Q overwrite
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240827-ansible-cleanups-v1-9-2828a816de5e@samsung.com>
References: <20240827-ansible-cleanups-v1-0-2828a816de5e@samsung.com>
In-Reply-To: <20240827-ansible-cleanups-v1-0-2828a816de5e@samsung.com>
To: kdevops@lists.linux.dev, Luis Chamberlain <mcgrof@kernel.org>
Cc: "Daniel Gomez (Samsung)" <d+samsung@kruces.com>, gost.dev@samsung.com, 
 Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1724787418; l=602;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=7TLFwa2QyCMJ/4kQeOLwrDfcrz3Mx2tk5Gx2vwF6oPQ=;
 b=5CsjNyl/zU913LHVPOHYlstj8FoPocvPaWPS863lcHaCKZbAOFV4eafUPUabdCtjbC0tm8jMX
 XTFRalR5Z6OAcKwFNoh6Re9bDsp1MrmGxDdNzRJya3i/ImQSnJAgguh
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This fixes make V=1 not being propagated proerly after main Makefile
includes this file.

Fixes 47f2275ba ("linux: generate refs automatically")

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
 scripts/refs.Makefile | 2 --
 1 file changed, 2 deletions(-)

diff --git a/scripts/refs.Makefile b/scripts/refs.Makefile
index 6d488031..96f2dd84 100644
--- a/scripts/refs.Makefile
+++ b/scripts/refs.Makefile
@@ -1,10 +1,8 @@
 # SPDX-License-Identifier: copyleft-next-0.3.1
 
 ifeq ($(V),1)
-export Q=@
 export E=echo
 else
-export Q=@
 export E=true
 endif
 

-- 
2.39.2

