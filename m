From: Shashank Balaji <shashank.mahadasyam@sony.com>
Date: Tue, 20 May 2025 23:07:46 +0900
Subject: [PATCH v2 2/3] sched_ext, docs: add label
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250520-rt-and-cpu-controller-doc-v2-2-70a2b6a1b703@sony.com>
References: <20250520-rt-and-cpu-controller-doc-v2-0-70a2b6a1b703@sony.com>
In-Reply-To: <20250520-rt-and-cpu-controller-doc-v2-0-70a2b6a1b703@sony.com>
To: Tejun Heo <tj@kernel.org>, Johannes Weiner <hannes@cmpxchg.org>, 
 =?utf-8?q?Michal_Koutn=C3=BD?= <mkoutny@suse.com>, 
 Jonathan Corbet <corbet@lwn.net>
Cc: cgroups@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Shinya Takumi <shinya.takumi@sony.com>, 
 Shashank Balaji <shashank.mahadasyam@sony.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=569;
 i=shashank.mahadasyam@sony.com; h=from:subject:message-id;
 bh=kROQYcJm32GQjz2uQCl7dr3UvhZuMbRBEjFkLwGn5dM=;
 b=owGbwMvMwCV2mPH4Ij++H1mMp9WSGDJ0eh6cSQ15na2Z2aq2wPxdy4IszUQDS7UO660769+xt
 a9STZHqKGVhEONikBVTZHkns+7CQSvLpq/HGb7BzGFlAhnCwMUpABMRZ2JkmHmDVdTcTzTp18kZ
 aamflOzYdjknNk975CL9w2OBgmepIMP/MCGB/BvvCjY2tpypXf31yxetby8jF7169pnvmWOi7Oo
 cRgA=
X-Developer-Key: i=shashank.mahadasyam@sony.com; a=openpgp;
 fpr=EE1CAED0C13A3982F5C700F6C301C7A24E0EF86A
X-Endpoint-Received: by B4 Relay for shashank.mahadasyam@sony.com/default with auth_id=354
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Shashank Balaji <shashank.mahadasyam@sony.com>
---
 Documentation/scheduler/sched-ext.rst | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/scheduler/sched-ext.rst b/Documentation/scheduler/sched-ext.rst
index 0b2654e2164b8e6139db19fc8b68e6c5c289503d..03f9e63a7b2aa10567366ff3e1a0cfc05b43e05a 100644
--- a/Documentation/scheduler/sched-ext.rst
+++ b/Documentation/scheduler/sched-ext.rst
@@ -1,3 +1,5 @@
+.. _sched-ext:
+
 ==========================
 Extensible Scheduler Class
 ==========================

-- 
2.43.0

