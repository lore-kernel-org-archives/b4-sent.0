From: Binoy Ravindran <binoy@vt.edu>
Date: Tue, 24 Nov 2026 10:34:29 -0500
Subject: [PATCH v2 3/3] livepatch: Select TASKS_RCU
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-klp-series-v3-v2-3-50d20829a337@vt.edu>
References: <20261124-klp-series-v3-v2-0-50d20829a337@vt.edu>
In-Reply-To: <20261124-klp-series-v3-v2-0-50d20829a337@vt.edu>
To: "Paul E. McKenney" <paulmck@kernel.org>, 
 Frederic Weisbecker <frederic@kernel.org>, 
 Neeraj Upadhyay <neeraj.upadhyay@kernel.org>, 
 Joel Fernandes <joelagnelf@nvidia.com>, 
 Josh Triplett <josh@joshtriplett.org>, Boqun Feng <boqun@kernel.org>, 
 Uladzislau Rezki <urezki@gmail.com>, Steven Rostedt <rostedt@goodmis.org>, 
 Mathieu Desnoyers <mathieu.desnoyers@efficios.com>, 
 Lai Jiangshan <jiangshanlai@gmail.com>, Zqiang <qiang.zhang@linux.dev>, 
 Josh Poimboeuf <jpoimboe@kernel.org>, Miroslav Benes <mbenes@suse.cz>, 
 Petr Mladek <pmladek@suse.com>, Joe Lawrence <joe.lawrence@redhat.com>, 
 Song Liu <song@kernel.org>, Ingo Molnar <mingo@kernel.org>, 
 Jiri Kosina <jikos@kernel.org>
Cc: rcu@vger.kernel.org, linux-kernel@vger.kernel.org, 
 live-patching@vger.kernel.org, Yafang Shao <laoar.shao@gmail.com>, 
 Jaidev Shastri <jaidevshastri@vt.edu>, Binoy Ravindran <binoy@vt.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795534504; l=1360;
 i=binoy@vt.edu; s=20261123; h=from:subject:message-id;
 bh=O07DZ6njJy/t9NEqF60nH7AFPGu6AH+JcyxcLxcqN68=;
 b=h5AxmIhSZ2ihSKCOhyw8ZKfE0osyf1IyI5LH0warbJcV4BvaZphK+A8E8Xa7fLf26ebMA8k5n
 /J/sNgc0OpoBgiYIEf8WfhfFtlB6o/+Sh3L6oxMgGT6f+ysM45yitZm
X-Developer-Key: i=binoy@vt.edu; a=ed25519;
 pk=4cNdKPHP0InmhK/9bb7Tm2ZMUXUvLGfw1pmVt5b98fA=
X-Endpoint-Received: by B4 Relay for binoy@vt.edu/20261123 with auth_id=1622
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The transition finds exiting tasks through the RCU-tasks exit lists,
which exist only with CONFIG_TASKS_RCU. Every kernel that can enable
LIVEPATCH already builds TASKS_RCU. TASKS_RCU defaults to
NEED_TASKS_RCU && PREEMPTION. LIVEPATCH depends on dynamic ftrace, so
FUNCTION_TRACER is set, and it selects NEED_TASKS_RCU. Every
architecture that selects HAVE_LIVEPATCH also selects
ARCH_HAS_PREEMPT_LAZY, which rules out PREEMPT_VOLUNTARY, and none
selects ARCH_NO_PREEMPT, which PREEMPT_NONE requires, so PREEMPTION is
always set.

Select TASKS_RCU explicitly, so that the dependency is documented and
holds even if those defaults change. This changes no configuration
today.

Suggested-by: Yafang Shao <laoar.shao@gmail.com>
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Binoy Ravindran <binoy@vt.edu>
---
 kernel/livepatch/Kconfig | 1 +
 1 file changed, 1 insertion(+)

diff --git a/kernel/livepatch/Kconfig b/kernel/livepatch/Kconfig
index 4c0a9c18d0b2..683d6993e207 100644
--- a/kernel/livepatch/Kconfig
+++ b/kernel/livepatch/Kconfig
@@ -12,6 +12,7 @@ config LIVEPATCH
 	depends on KALLSYMS_ALL
 	depends on HAVE_LIVEPATCH
 	depends on !TRIM_UNUSED_KSYMS
+	select TASKS_RCU
 	help
 	  Say Y here if you want to support kernel live patching.
 	  This option has no runtime impact until a kernel "patch"

-- 
2.39.5

