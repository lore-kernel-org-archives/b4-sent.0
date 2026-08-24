From: Cheng Lingfei <chenglingfei@foxmail.com>
Date: Mon, 24 Aug 2026 20:45:46 +0800
Subject: [PATCH v2] docs: cgroup-v2: fix misc.events key format description
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260824-master-v2-1-00331c3cfb6e@foxmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/2WNwQ7CIBAFf6XZs5hCFKon/8P0ALjYNbYYQFLT8
 O/SevQ4ybx5C0QMhBHOzQIBM0XyUwWxa8AOerojo1tlEK2QbScObNQxYWCtQXt06oTSdlDlV0B
 H8xa69j+Ob/NAm9b1agwUkw+f7Snz1fuLZs44k52URinkToqL8/Oo6bm3foS+lPIF725UxLAAA
 AA=
X-Change-ID: 20260824-master-0bec5f79e6c8
To: Tejun Heo <tj@kernel.org>, Johannes Weiner <hannes@cmpxchg.org>, 
 =?utf-8?q?Michal_Koutn=C3=BD?= <mkoutny@suse.com>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>
Cc: cgroups@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Cheng Lingfei <chenglingfei@foxmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787575549; l=1345;
 i=chenglingfei@foxmail.com; s=20260824; h=from:subject:message-id;
 bh=9EdW2zRd1zyz6uqGRm1e2H1GPoLMd2RzHiRdXSbyxsM=;
 b=pb+yUPVe3/hm6yx1unRjXXbNHgcVIXaQfUPZniMPlcNHkNWRQMhxqeuWl1QqvVNGTQk4FIV1V
 JWPZOwPGd7wB40i1DJDGuRg9zk2jD2MxUmSmE/UGs3bZ/4bYLLSiCCg
X-Developer-Key: i=chenglingfei@foxmail.com; a=ed25519;
 pk=jJFtzwUiUOhTRJNlFx9WjsWHIYGk49Br17a7AD8MH2I=
X-Endpoint-Received: by B4 Relay for chenglingfei@foxmail.com/20260824 with auth_id=972
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In misc cgroup, misc.events does not output a simple "max" key. Instead,
each registered misc resource outputs a separate key suffixed with ".max"
(i.e., "<res>.max").
Update the documentation to clarify that the entry key is "<res>.max".

Suggested-by: Michal Koutný <mkoutny@suse.com>
Signed-off-by: Cheng Lingfei <chenglingfei@foxmail.com>
---
Changes in v2:
- Use "<res>.max" entry name instead of expanding with explicit examples (Michal Koutný).
- Link to v1: https://patch.msgid.link/20260824-master-v1-1-6866b77e1f62@foxmail.com
---
 Documentation/admin-guide/cgroup-v2.rst | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/Documentation/admin-guide/cgroup-v2.rst b/Documentation/admin-guide/cgroup-v2.rst
index 7c2a8ed80..6a6fd2017 100644
--- a/Documentation/admin-guide/cgroup-v2.rst
+++ b/Documentation/admin-guide/cgroup-v2.rst
@@ -3064,7 +3064,7 @@ resources (res_a and res_b) are registered then:
 	change in this file generates a file modified event. All fields in
 	this file are hierarchical.
 
-	  max
+	  <res>.max
 		The number of times the cgroup's resource usage was
 		about to go over the max boundary.
 

---
base-commit: 0a0d1d55dad570724bf8c7ea83409639cfb4be9b
change-id: 20260824-master-0bec5f79e6c8

Best regards,
--  
Cheng Lingfei <chenglingfei@foxmail.com>

