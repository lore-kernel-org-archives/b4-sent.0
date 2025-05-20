From: Shashank Balaji <shashank.mahadasyam@sony.com>
Date: Tue, 20 May 2025 23:07:45 +0900
Subject: [PATCH v2 1/3] cgroup, docs: be specific about bandwidth control
 of rt processes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250520-rt-and-cpu-controller-doc-v2-1-70a2b6a1b703@sony.com>
References: <20250520-rt-and-cpu-controller-doc-v2-0-70a2b6a1b703@sony.com>
In-Reply-To: <20250520-rt-and-cpu-controller-doc-v2-0-70a2b6a1b703@sony.com>
To: Tejun Heo <tj@kernel.org>, Johannes Weiner <hannes@cmpxchg.org>, 
 =?utf-8?q?Michal_Koutn=C3=BD?= <mkoutny@suse.com>, 
 Jonathan Corbet <corbet@lwn.net>
Cc: cgroups@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Shinya Takumi <shinya.takumi@sony.com>, 
 Shashank Balaji <shashank.mahadasyam@sony.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1072;
 i=shashank.mahadasyam@sony.com; h=from:subject:message-id;
 bh=0fu39uClw6bO5Fx9qm8IAuu7HAJELLYW1+XN2jpeVRc=;
 b=owGbwMvMwCV2mPH4Ij++H1mMp9WSGDJ0eu4ryTSGmj/9K5m283rhgp2TvHbPr+kp3S/tf6D7j
 nncxO08HaUsDGJcDLJiiizvZNZdOGhl2fT1OMM3mDmsTCBDGLg4BWAinN6MDBOnHXDfpefzryzv
 5t+ZQYxia9t3/2g32+9gO6vhuX3oyURGhl8vA09LbbSKufD17pmXV5czV30MUbOen2am4vw6rUl
 rJSMA
X-Developer-Key: i=shashank.mahadasyam@sony.com; a=openpgp;
 fpr=EE1CAED0C13A3982F5C700F6C301C7A24E0EF86A
X-Endpoint-Received: by B4 Relay for shashank.mahadasyam@sony.com/default with auth_id=354
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Shashank Balaji <shashank.mahadasyam@sony.com>
---
 Documentation/admin-guide/cgroup-v2.rst | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/Documentation/admin-guide/cgroup-v2.rst b/Documentation/admin-guide/cgroup-v2.rst
index 1a16ce68a4d7f6f8c9070be89c4975dbfa79077e..3b3685736fe9b12e96a273248dfb4a8c62a4b698 100644
--- a/Documentation/admin-guide/cgroup-v2.rst
+++ b/Documentation/admin-guide/cgroup-v2.rst
@@ -1076,7 +1076,7 @@ cpufreq governor about the minimum desired frequency which should always be
 provided by a CPU, as well as the maximum desired frequency, which should not
 be exceeded by a CPU.
 
-WARNING: cgroup2 cpu controller doesn't yet fully support the control of
+WARNING: cgroup2 cpu controller doesn't yet support the (bandwidth) control of
 realtime processes. For a kernel built with the CONFIG_RT_GROUP_SCHED option
 enabled for group scheduling of realtime processes, the cpu controller can only
 be enabled when all RT processes are in the root cgroup. Be aware that system

-- 
2.43.0

