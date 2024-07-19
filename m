From: Nikita Shubin <n.shubin@yadro.com>
Date: Fri, 19 Jul 2024 17:30:16 +0300
Subject: [PATCH v2] workqueue: doc: Fix function name, remove markers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240719-fix_doc-v2-1-a5cbeb46e0cc@yadro.com>
X-B4-Tracking: v=1; b=H4sIAHd4mmYC/2WMQQ7CIBBFr9LMWkyHEimuvIdpDIWpnYWlAUNsG
 u4uduvy/f/ydkgUmRJcmx0iZU4clgry1ICb7fIkwb4yyFaqVqMRE38ePjihyHktx8mYTkG110j
 1Okr3ofLM6R3idoQz/tb/RkaBwnjUF+r60Zr+tlkfw9mFFwyllC/7FNp3ngAAAA==
To: Tejun Heo <tj@kernel.org>, Lai Jiangshan <jiangshanlai@gmail.com>, 
 Jonathan Corbet <corbet@lwn.net>
Cc: nikita.shubin@maquefel.me, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux@yadro.com, 
 Nikita Shubin <n.shubin@yadro.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721399417; l=1221;
 i=n.shubin@yadro.com; s=20230718; h=from:subject:message-id;
 bh=J54vi+EARiXY1qbZRDNxODuY2S1a3C8+8h3B7EsXh9E=;
 b=3zYY9q2uPCLsBhaWI1jbMjaRHDeT4Bbh0astcXoZ+T7SGfSAWvSKMXhN3YShfyYZfo9YtoIHL3BH
 6oJnv1TLAyrLZyIJunvLThv2KCGVWoBUVx2ziTpD/VvytzlVx+S4
X-Developer-Key: i=n.shubin@yadro.com; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for n.shubin@yadro.com/20230718 with auth_id=161
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

- s/alloc_ordered_queue()/alloc_ordered_workqueue()/
- remove markers to convert it into a link.

Signed-off-by: Nikita Shubin <n.shubin@yadro.com>
---
Changes in v2:
Matthew Wilcox:
- No problem removed `` markers
- Link to v1: https://lore.kernel.org/r/20240719-fix_doc-v1-1-9d176e38ba98@yadro.com
---
 Documentation/core-api/workqueue.rst | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/Documentation/core-api/workqueue.rst b/Documentation/core-api/workqueue.rst
index bcc370c876be..16f861c9791e 100644
--- a/Documentation/core-api/workqueue.rst
+++ b/Documentation/core-api/workqueue.rst
@@ -260,7 +260,7 @@ Some users depend on strict execution ordering where only one work item
 is in flight at any given time and the work items are processed in
 queueing order. While the combination of ``@max_active`` of 1 and
 ``WQ_UNBOUND`` used to achieve this behavior, this is no longer the
-case. Use ``alloc_ordered_queue()`` instead.
+case. Use alloc_ordered_workqueue() instead.
 
 
 Example Execution Scenarios

---
base-commit: 080402007007ca1bed8bcb103625137a5c8446c6
change-id: 20240719-fix_doc-4ecd72bf9934

Best regards,
-- 
Nikita Shubin <n.shubin@yadro.com>

