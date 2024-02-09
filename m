From: Mathys-Gasnier <mathys35.gasnier@gmail.com>
Date: Fri, 09 Feb 2024 17:22:24 +0100
Subject: [PATCH] rust: locks: Add `get_mut` method to `Lock`
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240209-rust-locks-get-mut-v1-1-ce351fc3de47@gmail.com>
X-B4-Tracking: v=1; b=H4sIAD9RxmUC/x3MSwqAMAwA0atI1gaaUlC8iriQGmvwS1NFEO9uc
 fkWMw8oR2GFpngg8iUq+5ZBZQF+6rfAKEM2WGOdIaoxnppw2f2sGDjheib0zprKkqGh6iGHR+R
 R7n/adu/7AZBaGoxkAAAA
To: Miguel Ojeda <ojeda@kernel.org>, Alex Gaynor <alex.gaynor@gmail.com>, 
 Wedson Almeida Filho <wedsonaf@gmail.com>, 
 Boqun Feng <boqun.feng@gmail.com>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <benno.lossin@proton.me>, 
 Andreas Hindborg <a.hindborg@samsung.com>, 
 Alice Ryhl <aliceryhl@google.com>
Cc: rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Mathys-Gasnier <mathys35.gasnier@gmail.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707495746; l=1162;
 i=mathys35.gasnier@gmail.com; s=20240118; h=from:subject:message-id;
 bh=BG0YFKP39LR9WWLZKQnZyk4pbHn9EQrD/0InazZ8oWY=;
 b=kYEX+M8gpUsUd4Tgnh+4FKAf2LwOpTAjIowMb+niPGNSrVk5nRPtPSng1HrJ1ib+p0Jdh5Gal
 q372/7CHy8aCPVbGpulcJ8Ud4Bdt2SJwWcgQKheYUB03W0kj/oaG8Mo
X-Developer-Key: i=mathys35.gasnier@gmail.com; a=ed25519;
 pk=C5tqKAA3Ua7li5s3a+q2aDelT2j98/yjGg2nEVGArXE=
X-Endpoint-Received: by B4 Relay for mathys35.gasnier@gmail.com/20240118 with auth_id=129
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Having a mutable reference guarantees that no other threads have
access to the lock, so we can take advantage of that to grant callers
access to the protected data without the the cost of acquiring and
releasing the locks. Since the lifetime of the data is tied to the
mutable reference, the borrow checker guarantees that the usage is safe.

Signed-off-by: Mathys-Gasnier <mathys35.gasnier@gmail.com>
---
 rust/kernel/sync/lock.rs | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/rust/kernel/sync/lock.rs b/rust/kernel/sync/lock.rs
index f12a684bc957..7711c6313e14 100644
--- a/rust/kernel/sync/lock.rs
+++ b/rust/kernel/sync/lock.rs
@@ -121,6 +121,11 @@ pub fn lock(&self) -> Guard<'_, T, B> {
         // SAFETY: The lock was just acquired.
         unsafe { Guard::new(self, state) }
     }
+
+    /// Gets the data contained in the lock
+    pub fn get_mut(&mut self) -> &mut T {
+        self.data.get_mut()
+    }
 }
 
 /// A lock guard.

---
base-commit: 711cbfc717650532624ca9f56fbaf191bed56e67
change-id: 20240118-rust-locks-get-mut-c42072101d7a

Best regards,
-- 
Mathys-Gasnier <mathys35.gasnier@gmail.com>

