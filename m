From: Aakash Bollineni <aakash.bollineni@multicorewareinc.com>
Date: Wed, 08 Apr 2026 16:06:38 +0530
Subject: [PATCH v6 1/3] rust: helpers: add workqueue helpers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260408-workqueue-v5-sent-v6-1-0dc184c5343d@multicorewareinc.com>
References: <20260408-workqueue-v5-sent-v6-0-0dc184c5343d@multicorewareinc.com>
In-Reply-To: <20260408-workqueue-v5-sent-v6-0-0dc184c5343d@multicorewareinc.com>
To: Miguel Ojeda <ojeda@kernel.org>, Alex Gaynor <alex.gaynor@gmail.com>, 
 Wedson Almeida Filho <wedsonaf@gmail.com>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn.roy.baron@gmail.com>, 
 Alice Ryhl <aliceryhl@google.com>, Tejun Heo <tj@kernel.org>, 
 Lai Jiangshan <jiangshanlai@gmail.com>, Boqun Feng <boqun@kernel.org>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>
Cc: rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Aakash Bollineni <aakash.bollineni@multicorewareinc.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775644627; l=1654;
 i=aakash.bollineni@multicorewareinc.com; s=20260402;
 h=from:subject:message-id; bh=N914P+plvR5IEkLzAqjpGBi8jBApqGMRlOfflBmXQOs=;
 b=QvK2fubgv5E19WQ7IlP/eqlLSvbI0+sJ0P3wV1CuOEbzgzQjahmOjvjRnZbDNK+I2hE6jshgA
 WRnMve/9kbfCttf7a5GAcg+YcL51sk/KTXKMQF5xo+xak2GoGGPdAw/
X-Developer-Key: i=aakash.bollineni@multicorewareinc.com; a=ed25519;
 pk=r3Gonl+2k+8RozN9U/XwfICQdnRlAcLeeAfsExmurdE=
X-Endpoint-Received: by B4 Relay for aakash.bollineni@multicorewareinc.com/20260402 with auth_id=711
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add C helpers for work_pending, cancel_work_sync, and
cancel_delayed_work_sync to bridge the Rust workqueue abstraction
with the kernel's C workqueue macros.

Additionally, add a robust initialization helper for delayed_work
that ensures correct timer (delayed_work_timer_fn) and lockdep setup
in a single pass, avoiding redundant initialization.

Signed-off-by: Aakash Bollineni <aakash.bollineni@multicorewareinc.com>
---
 rust/helpers/workqueue.c | 27 +++++++++++++++++++++++++++
 1 file changed, 27 insertions(+)

diff --git a/rust/helpers/workqueue.c b/rust/helpers/workqueue.c
index ce1c3a5b2150..ef18d79f95be 100644
--- a/rust/helpers/workqueue.c
+++ b/rust/helpers/workqueue.c
@@ -14,3 +14,30 @@ __rust_helper void rust_helper_init_work_with_key(struct work_struct *work,
 	INIT_LIST_HEAD(&work->entry);
 	work->func = func;
 }
+
+__rust_helper bool rust_helper_work_pending(struct work_struct *work)
+{
+	return work_pending(work);
+}
+
+__rust_helper bool rust_helper_cancel_work_sync(struct work_struct *work)
+{
+	return cancel_work_sync(work);
+}
+
+__rust_helper bool rust_helper_cancel_delayed_work_sync(struct delayed_work *dwork)
+{
+	return cancel_delayed_work_sync(dwork);
+}
+
+__rust_helper void rust_helper_init_delayed_work(struct delayed_work *dwork,
+						 work_func_t func,
+						 const char *name,
+						 struct lock_class_key *key,
+						 const char *tname,
+						 struct lock_class_key *tkey)
+{
+	rust_helper_init_work_with_key(&dwork->work, func, false, name, key);
+	timer_init_key(&dwork->timer, delayed_work_timer_fn, TIMER_IRQSAFE, tname, tkey);
+}
+

-- 
2.43.0

