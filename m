From: Shashank Balaji <shashank.mahadasyam@sony.com>
Date: Wed, 05 Mar 2025 13:12:43 +0900
Subject: [PATCH 1/2] cgroup, docs: Be explicit about independence of
 RT_GROUP_SCHED and non-cpu controllers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250305-rt-and-cpu-controller-doc-v1-1-7b6a6f5ff43d@sony.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2689;
 i=shashank.mahadasyam@sony.com; h=from:subject:message-id;
 bh=/4pX+lji8gdMF5fk81/FrjcxVt66tCgC2wZaTKjforA=;
 b=owGbwMvMwCV2mPH4Ij++H1mMp9WSGNKPnw++Yi2xcdGkB1eEW7keJWp+K955fdK19u37b2ZkF
 zdGHKpz7ihlYRDjYpAVU2R5J7PuwkEry6avxxm+wcxhZQIZwsDFKQATiVJgZOgJ6J4Re2LRn01V
 Uv+SpCwslALOXahLLOroElESzPJ6vZCR4VZ7kMi96EjTksmp9gr/uDSb1z0RNHhZKngo+3xT0/f
 rbAA=
X-Developer-Key: i=shashank.mahadasyam@sony.com; a=openpgp;
 fpr=EE1CAED0C13A3982F5C700F6C301C7A24E0EF86A
X-Endpoint-Received: by B4 Relay for shashank.mahadasyam@sony.com/default with auth_id=354
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The cgroup v2 cpu controller has a limitation that if
CONFIG_RT_GROUP_SCHED is enabled, the cpu controller can be enabled only
if all the realtime processes are in the root cgroup. The other
controllers have no such restriction. They can be used for the resource
control of realtime processes irrespective of whether
CONFIG_RT_GROUP_SCHED is enabled or not.

Signed-off-by: Shashank Balaji <shashank.mahadasyam@sony.com>
---
 Documentation/admin-guide/cgroup-v2.rst | 23 ++++++++++++++---------
 1 file changed, 14 insertions(+), 9 deletions(-)

diff --git a/Documentation/admin-guide/cgroup-v2.rst b/Documentation/admin-guide/cgroup-v2.rst
index cb1b4e759b7e267c24d7f4f69564c16fb29c4d89..f293a13b42ed69e7c6bf5e974cb86e228411af4e 100644
--- a/Documentation/admin-guide/cgroup-v2.rst
+++ b/Documentation/admin-guide/cgroup-v2.rst
@@ -1076,15 +1076,20 @@ cpufreq governor about the minimum desired frequency which should always be
 provided by a CPU, as well as the maximum desired frequency, which should not
 be exceeded by a CPU.
 
-WARNING: cgroup2 doesn't yet support control of realtime processes. For
-a kernel built with the CONFIG_RT_GROUP_SCHED option enabled for group
-scheduling of realtime processes, the cpu controller can only be enabled
-when all RT processes are in the root cgroup.  This limitation does
-not apply if CONFIG_RT_GROUP_SCHED is disabled.  Be aware that system
-management software may already have placed RT processes into nonroot
-cgroups during the system boot process, and these processes may need
-to be moved to the root cgroup before the cpu controller can be enabled
-with a CONFIG_RT_GROUP_SCHED enabled kernel.
+WARNING: cgroup2 cpu controller doesn't yet fully support the control of
+realtime processes. For a kernel built with the CONFIG_RT_GROUP_SCHED option
+enabled for group scheduling of realtime processes, the cpu controller can only
+be enabled when all RT processes are in the root cgroup. Be aware that system
+management software may already have placed RT processes into non-root cgroups
+during the system boot process, and these processes may need to be moved to the
+root cgroup before the cpu controller can be enabled with a
+CONFIG_RT_GROUP_SCHED enabled kernel.
+
+With CONFIG_RT_GROUP_SCHED disabled, this limitation does not apply and some of
+the interface files either affect realtime processes or account for them. See
+the following section for details. Only the cpu controller is affected by
+CONFIG_RT_GROUP_SCHED. Other controllers can be used for the resource control of
+realtime processes irrespective of CONFIG_RT_GROUP_SCHED.
 
 
 CPU Interface Files

-- 
2.43.0

