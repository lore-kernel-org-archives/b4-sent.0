From: Mathys-Gasnier <mathys35.gasnier@gmail.com>
Date: Mon, 12 Feb 2024 15:13:22 +0100
Subject: [PATCH v2] rust: locks: Add `get_mut` method to `Lock`
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240212-rust-locks-get-mut-v2-1-5ccd34c2b70b@gmail.com>
X-B4-Tracking: v=1; b=H4sIAIEnymUC/22NQQ6CMBBFr0Jm7ZhOqUFdeQ/DgpQBJgI1bWk0h
 LtbcevyveS/v0JgLxzgWqzgOUkQN2fQhwLs0Mw9o7SZQSttFNEZ/RIijs4+AvYccVoiWqNVpUl
 RWzWQh0/Pnbz26L3OPEiIzr/3j0Rf+8tpdfmXS4SElssTdbZs2VS3fmpkPFo3Qb1t2wc70JFNt
 AAAAA==
To: Miguel Ojeda <ojeda@kernel.org>, Alex Gaynor <alex.gaynor@gmail.com>, 
 Wedson Almeida Filho <wedsonaf@gmail.com>, 
 Boqun Feng <boqun.feng@gmail.com>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <benno.lossin@proton.me>, 
 Andreas Hindborg <a.hindborg@samsung.com>, 
 Alice Ryhl <aliceryhl@google.com>
Cc: rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Martin Rodriguez Reboredo <yakoyoku@gmail.com>, 
 Mathys-Gasnier <mathys35.gasnier@gmail.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707747202; l=1549;
 i=mathys35.gasnier@gmail.com; s=20240118; h=from:subject:message-id;
 bh=4WHIEGc6TIVbfvh7PeNOQmNjpDZmYDavVMoHaIlodHI=;
 b=q7QD3UdUQRQXztcJOdSgVPNrRpVwVF4EV+NxuHzQ0fNNhCQfFLrtc7vL1HeBf97d+i2Pm7BTo
 b6bOFj/3Ch8DHtpCfnUFM/cB2BPCMOXl2I+OUl/daVwpCYgt/NeZfrO
X-Developer-Key: i=mathys35.gasnier@gmail.com; a=ed25519;
 pk=C5tqKAA3Ua7li5s3a+q2aDelT2j98/yjGg2nEVGArXE=
X-Endpoint-Received: by B4 Relay for mathys35.gasnier@gmail.com/20240118 with auth_id=129
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Having a mutable reference guarantees that no other threads have
access to the lock, so we can take advantage of that to grant callers
access to the protected data without the the cost of acquiring and
releasing the locks. Since the lifetime of the data is tied to the
mutable reference, the borrow checker guarantees that the usage is safe.

Reviewed-by: Martin Rodriguez Reboredo <yakoyoku@gmail.com>
Signed-off-by: Mathys-Gasnier <mathys35.gasnier@gmail.com>
---
Changes in v2:
- Improved doc comment. 
- Link to v1: https://lore.kernel.org/r/20240209-rust-locks-get-mut-v1-1-ce351fc3de47@gmail.com
---
 rust/kernel/sync/lock.rs | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/rust/kernel/sync/lock.rs b/rust/kernel/sync/lock.rs
index f12a684bc957..d15af6625d01 100644
--- a/rust/kernel/sync/lock.rs
+++ b/rust/kernel/sync/lock.rs
@@ -121,6 +121,13 @@ pub fn lock(&self) -> Guard<'_, T, B> {
         // SAFETY: The lock was just acquired.
         unsafe { Guard::new(self, state) }
     }
+
+    /// Gets the data contained in the lock
+    /// Having a mutable reference to the lock guarantees that no other threads have access to the lock.
+    /// Making it safe to get a mutable reference to the lock content.
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

