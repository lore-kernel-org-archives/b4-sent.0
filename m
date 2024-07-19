From: Nikita Shubin <n.shubin@yadro.com>
Date: Fri, 19 Jul 2024 17:17:38 +0300
Subject: [PATCH] workqueue: doc: Fix function name
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240719-fix_doc-v1-1-9d176e38ba98@yadro.com>
X-B4-Tracking: v=1; b=H4sIAIF1mmYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDc0NL3bTMiviU/GRdk9TkFHOjpDRLS2MTJaDqgqJUoBTYpOjY2loAeap
 64VkAAAA=
To: Tejun Heo <tj@kernel.org>, Lai Jiangshan <jiangshanlai@gmail.com>, 
 Jonathan Corbet <corbet@lwn.net>
Cc: nikita.shubin@maquefel.me, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux@yadro.com, 
 Nikita Shubin <n.shubin@yadro.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721398668; l=1021;
 i=n.shubin@yadro.com; s=20230718; h=from:subject:message-id;
 bh=6/ib8dGatUxNJG05zdhXdZ6AZtRqyM3pThPJjlGkNx4=;
 b=cRAqQq5yIutUty/S5LFaNNALEemsa2GMaE7bcvIREB7a+QH+jWdV0HWSn1WcK8HJtofYCtPStjOf
 pwbD37WFDYGkuWv43RJQHnqG8SQJ3rvz4JK2+m0QFSCME1jQTWW1
X-Developer-Key: i=n.shubin@yadro.com; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for n.shubin@yadro.com/20230718 with auth_id=161
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

s/alloc_ordered_queue()/alloc_ordered_workqueue()/

Signed-off-by: Nikita Shubin <n.shubin@yadro.com>
---
 Documentation/core-api/workqueue.rst | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/Documentation/core-api/workqueue.rst b/Documentation/core-api/workqueue.rst
index bcc370c876be..f28d7a1ab4b1 100644
--- a/Documentation/core-api/workqueue.rst
+++ b/Documentation/core-api/workqueue.rst
@@ -260,7 +260,7 @@ Some users depend on strict execution ordering where only one work item
 is in flight at any given time and the work items are processed in
 queueing order. While the combination of ``@max_active`` of 1 and
 ``WQ_UNBOUND`` used to achieve this behavior, this is no longer the
-case. Use ``alloc_ordered_queue()`` instead.
+case. Use ``alloc_ordered_workqueue()`` instead.
 
 
 Example Execution Scenarios

---
base-commit: 080402007007ca1bed8bcb103625137a5c8446c6
change-id: 20240719-fix_doc-4ecd72bf9934

Best regards,
-- 
Nikita Shubin <n.shubin@yadro.com>

