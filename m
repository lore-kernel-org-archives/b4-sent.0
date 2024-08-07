From: Daniel Gomez <da.gomez@samsung.com>
Date: Wed, 07 Aug 2024 12:40:42 +0200
Subject: [PATCH 1/3] Makefile: fix kdevops-deps missing target
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240807-fix-startup-kdevops-v1-1-87af646e1237@samsung.com>
References: <20240807-fix-startup-kdevops-v1-0-87af646e1237@samsung.com>
In-Reply-To: <20240807-fix-startup-kdevops-v1-0-87af646e1237@samsung.com>
To: kdevops@lists.linux.dev, Luis Chamberlain <mcgrof@kernel.org>
Cc: "Daniel Gomez (Samsung)" <d+samsung@kruces.com>, gost.dev@samsung.com, 
 Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1723027254; l=661;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=UCvdxvWdAerkw+iHAH7CWICL7p9DszqPdoBDIAnv2ZQ=;
 b=PHIl5a0I0UDnKPPugRYJBxnU5Sx4h+1SVZYJAqKSnDKqGVRy9Q09oy1gXSaZdPs89k/tL64oa
 HFSDWRPKtt2CCg/HTNimnIlcuCb5XmAhI5ZBgO29on/2qdFQsIgkmCD
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fixes:

make kdevops-deps
make: *** No rule to make target 'kdevops-deps'.  Stop

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
 Makefile | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/Makefile b/Makefile
index b961e44..0fb7ab3 100644
--- a/Makefile
+++ b/Makefile
@@ -78,6 +78,9 @@ ANSIBLE_EXTRA_ARGS += kdevops_version='$(PROJECTRELEASE)'
 export KDEVOPS_HOSTS_TEMPLATE := $(KDEVOPS_HOSTFILE).j2
 export KDEVOPS_HOSTS := $(KDEVOPS_HOSTFILE)
 
+include Makefile.kdevops
+DEFAULT_DEPS += kdevops-deps
+
 LOCAL_DEVELOPMENT_ARGS	:=
 ifeq (y,$(CONFIG_NEEDS_LOCAL_DEVELOPMENT_PATH))
 include Makefile.local

-- 
Git-146)

