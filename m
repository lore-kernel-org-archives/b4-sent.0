From: Shashank Balaji <shashank.mahadasyam@sony.com>
Subject: [PATCH v2 0/3] cgroup, docs: cpu controller interaction with
 various scheduling policies
Date: Tue, 20 May 2025 23:07:44 +0900
Message-Id: <20250520-rt-and-cpu-controller-doc-v2-0-70a2b6a1b703@sony.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALGMLGgC/32NQQ6CMBBFr0Jm7ZhSLBBX3MOwqO1UmmBLpkgkh
 Ltbce/yveS/v0Ei9pTgWmzAtPjkY8ggTwWYQYcHobeZQQqphJQ18ow6WDTTC00MM8dxJEYbDba
 61dqoRrqKIO8nJuffR/vWZx58miOvx9VSfu2vWgn1p7qUKLC517p2yrlLZbsUw3o28Qn9vu8f9
 QYiscEAAAA=
X-Change-ID: 20250226-rt-and-cpu-controller-doc-8a8aac572f3e
To: Tejun Heo <tj@kernel.org>, Johannes Weiner <hannes@cmpxchg.org>, 
 =?utf-8?q?Michal_Koutn=C3=BD?= <mkoutny@suse.com>, 
 Jonathan Corbet <corbet@lwn.net>
Cc: cgroups@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Shinya Takumi <shinya.takumi@sony.com>, 
 Shashank Balaji <shashank.mahadasyam@sony.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1257;
 i=shashank.mahadasyam@sony.com; h=from:subject:message-id;
 bh=ttAbpSM1hXQuNR/OMOYp8x1yy4Ma9fGMFXn0HWuoelg=;
 b=owGbwMvMwCV2mPH4Ij++H1mMp9WSGDJ0eu6rPGPd+v97b+NxtpuqO+YKrd8TpLhUpG5b7ux9q
 7z751WrdpSyMIhxMciKKbK8k1l34aCVZdPX4wzfYOawMoEMYeDiFICJ5HExMqyZ1Pbk+N95RTsT
 DEIN9jPeWCzKvvKf1I+16bM9ZnFF1T5m+O8+48/RVZemsCus8Jw/v38in/T1NUtZU65t/LR1SWH
 KlvncAA==
X-Developer-Key: i=shashank.mahadasyam@sony.com; a=openpgp;
 fpr=EE1CAED0C13A3982F5C700F6C301C7A24E0EF86A
X-Endpoint-Received: by B4 Relay for shashank.mahadasyam@sony.com/default with auth_id=354
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The cgroup v2 cpu controller interface files interact with processes
differently based on their scheduling policy and the underlying
scheduler used (fair-class vs. BPF scheduler). This patchset
documents these differences.

This is related to the previous patchset titled "cgroup, docs: Clarify
interaction of RT processes with cgroup v2 cpu controller"
(https://lore.kernel.org/all/20250305-rt-and-cpu-controller-doc-v1-0-7b6a6f5ff43d@sony.com/),
which focused solely on RT processes. The current patchset incorporates
the previous feedback and expands on the scope of scheduling policies.

Signed-off-by: Shashank Balaji <shashank.mahadasyam@sony.com>
---
Shashank Balaji (3):
      cgroup, docs: be specific about bandwidth control of rt processes
      sched_ext, docs: add label
      cgroup, docs: cpu controller interaction with various scheduling policies

 Documentation/admin-guide/cgroup-v2.rst | 100 ++++++++++++++++++++++++--------
 Documentation/scheduler/sched-ext.rst   |   2 +
 2 files changed, 78 insertions(+), 24 deletions(-)
---
base-commit: 036ee8a17bd046d7a350de0aae152307a061cc46
change-id: 20250226-rt-and-cpu-controller-doc-8a8aac572f3e

Best regards,
-- 
Shashank Balaji <shashank.mahadasyam@sony.com>

