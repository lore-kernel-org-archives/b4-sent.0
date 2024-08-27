From: Daniel Gomez <da.gomez@samsung.com>
Date: Tue, 27 Aug 2024 21:37:08 +0200
Subject: [PATCH RFC WIP 13/13] ansible.cfg: switch stdout_callback to dense
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240827-ansible-cleanups-v1-13-2828a816de5e@samsung.com>
References: <20240827-ansible-cleanups-v1-0-2828a816de5e@samsung.com>
In-Reply-To: <20240827-ansible-cleanups-v1-0-2828a816de5e@samsung.com>
To: kdevops@lists.linux.dev, Luis Chamberlain <mcgrof@kernel.org>
Cc: "Daniel Gomez (Samsung)" <d+samsung@kruces.com>, gost.dev@samsung.com, 
 Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1724787418; l=533;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=8euPbA6GCWeD5MZznBkzRi09M3mtrEnCc+vCmLKm+ZY=;
 b=fpdZoACk8OfPP07S1tJUGa1htFlevWMMhAAnkqe1g8ZOtKvdS+depw71T2o+FDOIqA/YeLvFv
 kb5T4YuX7GtAZlp8xpKvVx91+ZQtjmx4YFw026vJyeMhXT4KPwPw3qW
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A clean output without '***'. Reports error if running with -v level
(AV=1).

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
 ansible.cfg | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/ansible.cfg b/ansible.cfg
index 2e90d2fc..68c26fbd 100644
--- a/ansible.cfg
+++ b/ansible.cfg
@@ -2,5 +2,6 @@
 display_skipped_hosts = no
 retries = 2000
 deprecation_warnings=False
-stdout_callback=debug
+stdout_callback=dense
+display_failed_stderr=True
 show_per_host_start=True

-- 
2.39.2

