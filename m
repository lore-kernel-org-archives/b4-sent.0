From: Shashank Balaji <shashank.mahadasyam@sony.com>
Subject: [PATCH 0/2] cgroup, docs: Clarify interaction of RT processes with
 cgroup v2 cpu controller
Date: Wed, 05 Mar 2025 13:12:42 +0900
Message-Id: <20250305-rt-and-cpu-controller-doc-v1-0-7b6a6f5ff43d@sony.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADrPx2cC/x3MQQqDQAxA0atI1gZsilZ6leIiZKINyIxkrBRk7
 u7g8i3+PyGrm2Z4Nye4HpYtxYpH24B8OS6KFqqBOuo7ogF9R44BZfuhpLh7Wld1DElw5JFZ+hf
 NT4Xab66z/e/3ZyrlAtNmlBlrAAAA
X-Change-ID: 20250226-rt-and-cpu-controller-doc-8a8aac572f3e
To: Tejun Heo <tj@kernel.org>, Johannes Weiner <hannes@cmpxchg.org>, 
 =?utf-8?q?Michal_Koutn=C3=BD?= <mkoutny@suse.com>, 
 Jonathan Corbet <corbet@lwn.net>
Cc: Waiman Long <longman@redhat.com>, cgroups@vger.kernel.org, 
 linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Shinya Takumi <shinya.takumi@sony.com>, 
 Shashank Balaji <shashank.mahadasyam@sony.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1499;
 i=shashank.mahadasyam@sony.com; h=from:subject:message-id;
 bh=5UXRL54BFARNyIExd957ZiQGbmJZmiFrgr7K+zCJvRQ=;
 b=owGbwMvMwCV2mPH4Ij++H1mMp9WSGNKPnw+6+bcjp3D9rkCn1feVrZ4o9OzxMqu4f6zss+Mfs
 19xBz23dJSyMIhxMciKKbK8k1l34aCVZdPX4wzfYOawMoEMYeDiFICJzPnJ8IeT757aNhEu/W8p
 zaGFfgpXFft4k6PfWN7cXqTxv/3Qt2eMDDcUKxsPXbumLzLHV/aM8Jqgpm2y28y37Tm3LGLq95W
 6nfwA
X-Developer-Key: i=shashank.mahadasyam@sony.com; a=openpgp;
 fpr=EE1CAED0C13A3982F5C700F6C301C7A24E0EF86A
X-Endpoint-Received: by B4 Relay for shashank.mahadasyam@sony.com/default with auth_id=354
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, CONFIG_RT_GROUP_SCHED is practically unusable. If enabled,
the cpu controller can be enabled only when all the realtime processes are in
the root cgroup. This has been clarified by Waiman Long in commit
20d4628 (cgroup, docs: Clarify limitation of RT processes with cgroup v2
cpu controller): https://lore.kernel.org/lkml/20240320142302.1790171-1-longman@redhat.com/

But this limitation does not affect any of the other controllers:
irrespective of CONFIG_RT_GROUP_SCHED, the other controllers can be used
for the resource control of realtime processes. This is made more
explicit in the first patch.

Even when CONFIG_RT_GROUP_SCHED is disabled, the runtime of realtime
processes is accounted for by cpu.pressure, and the usage_usec, user_usec,
and system_usec fields of cpu.stat, and cpu.uclamp.{min, max} affect
realtime processes as well. This is documented in the second patch.

Signed-off-by: Shashank Balaji <shashank.mahadasyam@sony.com>
---
Shashank Balaji (2):
      cgroup, docs: Be explicit about independence of RT_GROUP_SCHED and non-cpu controllers
      cgroup, docs: Document interaction of RT processes with cpu controller

 Documentation/admin-guide/cgroup-v2.rst | 41 ++++++++++++++++++++++-----------
 1 file changed, 27 insertions(+), 14 deletions(-)
---
base-commit: 9b381a28f44a49b92b03bb3982728f9cb67ee225
change-id: 20250226-rt-and-cpu-controller-doc-8a8aac572f3e

Best regards,
-- 
Shashank Balaji <shashank.mahadasyam@sony.com>

