From: Shashank Balaji <shashank.mahadasyam@sony.com>
Date: Wed, 05 Mar 2025 13:12:44 +0900
Subject: [PATCH 2/2] cgroup, docs: Document interaction of RT processes
 with cpu controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250305-rt-and-cpu-controller-doc-v1-2-7b6a6f5ff43d@sony.com>
References: <20250305-rt-and-cpu-controller-doc-v1-0-7b6a6f5ff43d@sony.com>
In-Reply-To: <20250305-rt-and-cpu-controller-doc-v1-0-7b6a6f5ff43d@sony.com>
To: Tejun Heo <tj@kernel.org>, Johannes Weiner <hannes@cmpxchg.org>, 
 =?utf-8?q?Michal_Koutn=C3=BD?= <mkoutny@suse.com>, 
 Jonathan Corbet <corbet@lwn.net>
Cc: Waiman Long <longman@redhat.com>, cgroups@vger.kernel.org, 
 linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Shinya Takumi <shinya.takumi@sony.com>, 
 Shashank Balaji <shashank.mahadasyam@sony.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3070;
 i=shashank.mahadasyam@sony.com; h=from:subject:message-id;
 bh=C7JgnbF46KXkV/sLIdJxl+OtmX2NjXxlaJ2fLtetvIs=;
 b=owGbwMvMwCV2mPH4Ij++H1mMp9WSGNKPnw9e//2RmAhj3o5Du+SOLT0Xfi9vQYeCx84HZxYwC
 vzvemXwu6OUhUGMi0FWTJHlncy6CwetLJu+Hmf4BjOHlQlkCAMXpwBMxG8VI0NzIlvCn5hrrx4x
 iPRL7MhbL7J4AZ+BcWTx1e7fikX8J2Yz/A9+WhAhdXtX9QvT+uPMHMKiUusO/G6y/eXmc2Ptv5X
 Xv7EDAA==
X-Developer-Key: i=shashank.mahadasyam@sony.com; a=openpgp;
 fpr=EE1CAED0C13A3982F5C700F6C301C7A24E0EF86A
X-Endpoint-Received: by B4 Relay for shashank.mahadasyam@sony.com/default with auth_id=354
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If the cpu controller is enabled in a CONFIG_RT_GROUP_SCHED
disabled setting, cpu.stat and cpu.pressure account for realtime
processes, and cpu.uclamp.{min, max} affect realtime processes as well.
None of the other interface files are affected by or affect realtime
processes.

Signed-off-by: Shashank Balaji <shashank.mahadasyam@sony.com>
---
 Documentation/admin-guide/cgroup-v2.rst | 18 +++++++++++++-----
 1 file changed, 13 insertions(+), 5 deletions(-)

diff --git a/Documentation/admin-guide/cgroup-v2.rst b/Documentation/admin-guide/cgroup-v2.rst
index f293a13b42ed69e7c6bf5e974cb86e228411af4e..2c267f42e5fef9c4e2c3530ce73330d680b9b2dc 100644
--- a/Documentation/admin-guide/cgroup-v2.rst
+++ b/Documentation/admin-guide/cgroup-v2.rst
@@ -1095,7 +1095,9 @@ realtime processes irrespective of CONFIG_RT_GROUP_SCHED.
 CPU Interface Files
 ~~~~~~~~~~~~~~~~~~~
 
-All time durations are in microseconds.
+All time durations are in microseconds. Only cpu.stat and cpu.pressure account
+for realtime processes, and only cpu.uclamp.min and cpu.uclamp.max
+affect realtime processes.
 
   cpu.stat
 	A read-only flat-keyed file.
@@ -1115,6 +1117,9 @@ All time durations are in microseconds.
 	- nr_bursts
 	- burst_usec
 
+    The runtime of realtime processes is accounted for only by the usage_usec,
+	user_usec, and system_usec fields.
+
   cpu.weight
 	A read-write single value file which exists on non-root
 	cgroups.  The default is "100".
@@ -1158,8 +1163,9 @@ All time durations are in microseconds.
   cpu.pressure
 	A read-write nested-keyed file.
 
-	Shows pressure stall information for CPU. See
-	:ref:`Documentation/accounting/psi.rst <psi>` for details.
+	Shows pressure stall information for CPU, including the contribution of
+	realtime processes. See :ref:`Documentation/accounting/psi.rst <psi>`
+	for details.
 
   cpu.uclamp.min
         A read-write single value file which exists on non-root cgroups.
@@ -1170,7 +1176,8 @@ All time durations are in microseconds.
 
         This interface allows reading and setting minimum utilization clamp
         values similar to the sched_setattr(2). This minimum utilization
-        value is used to clamp the task specific minimum utilization clamp.
+        value is used to clamp the task specific minimum utilization clamp,
+        including those of realtime processes.
 
         The requested minimum utilization (protection) is always capped by
         the current value for the maximum utilization (limit), i.e.
@@ -1185,7 +1192,8 @@ All time durations are in microseconds.
 
         This interface allows reading and setting maximum utilization clamp
         values similar to the sched_setattr(2). This maximum utilization
-        value is used to clamp the task specific maximum utilization clamp.
+        value is used to clamp the task specific maximum utilization clamp,
+        including those of realtime processes.
 
   cpu.idle
 	A read-write single value file which exists on non-root cgroups.

-- 
2.43.0

