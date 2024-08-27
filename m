From: Daniel Gomez <da.gomez@samsung.com>
Date: Tue, 27 Aug 2024 21:37:07 +0200
Subject: [PATCH RFC WIP 12/13] ansible.cfg: add output when a task is
 started
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240827-ansible-cleanups-v1-12-2828a816de5e@samsung.com>
References: <20240827-ansible-cleanups-v1-0-2828a816de5e@samsung.com>
In-Reply-To: <20240827-ansible-cleanups-v1-0-2828a816de5e@samsung.com>
To: kdevops@lists.linux.dev, Luis Chamberlain <mcgrof@kernel.org>
Cc: "Daniel Gomez (Samsung)" <d+samsung@kruces.com>, gost.dev@samsung.com, 
 Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1724787418; l=611;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=5hWBP+OZDDQvLK9MwwMuvJ/NDK8YAntwke6yb64Pj98=;
 b=eF5yuFQzQAa69RawsMwUREAf8cMHb5AtJdyPbUrPI+KmSlzFQdoRveV44ZE6hKUHlJ1XB2Lhj
 5OKlrFyqYc/B06MnIaiAt6S3UXXpP7sKWo/aAnoa5oJ7/twb1UJoH4u
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From documentation [1]: "This adds output that shows when a task is
started to execute for each host".

https://docs.ansible.com/ansible/latest/collections/community/general/
dense_callback.html#parameter-show_per_host_start

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
 ansible.cfg | 1 +
 1 file changed, 1 insertion(+)

diff --git a/ansible.cfg b/ansible.cfg
index 08350e0c..2e90d2fc 100644
--- a/ansible.cfg
+++ b/ansible.cfg
@@ -3,3 +3,4 @@ display_skipped_hosts = no
 retries = 2000
 deprecation_warnings=False
 stdout_callback=debug
+show_per_host_start=True

-- 
2.39.2

