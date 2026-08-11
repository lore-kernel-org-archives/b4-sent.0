From: Younes Akhouayri <git@younes.io>
Date: Tue, 11 Aug 2026 19:35:49 +0100
Subject: [PATCH] rust: sync: completion: document Send and Sync safety
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260811-docs-completion-send-sync-safety-v1-1-0bc663ae967f@younes.io>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWNQQ6CMBBFr0Jm7USKsVGvYlyU6QA1OiWdYiCEu
 1t0+X5e3l9BOQVWuFUrJP4EDVEKmEMFNDjpGYMvDE3d2PpiDPpIihTf44tzcVFZPOoihOo6zgs
 2V9sZ6605nQlKZkzchfl3cX/8Waf2yZT37m60Thnb5ISGfYop9EGOadKMwnOGbfsCZZU9X6cAA
 AA=
X-Change-ID: 20260811-docs-completion-send-sync-safety-296f16d6135c
To: Boqun Feng <boqun@kernel.org>, Gary Guo <gary@garyguo.net>, 
 Alice Ryhl <aliceryhl@google.com>, Lyude Paul <lyude@redhat.com>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>, 
 Miguel Ojeda <ojeda@kernel.org>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Trevor Gross <tmgross@umich.edu>, Danilo Krummrich <dakr@kernel.org>, 
 Tamir Duberstein <tamird@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>
Cc: linux-kernel@vger.kernel.org, rust-for-linux@vger.kernel.org, 
 Younes Akhouayri <git@younes.io>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786473365; l=1455;
 i=git@younes.io; s=20260712; h=from:subject:message-id;
 bh=lUXX/8VrrDvj2MH58FPRom93+MLZWViupLexp9ZgA1g=;
 b=/TKaSloBlVR3N8B0kkRVoB4Hh/LFDdl6iHWe0C6esiacLthEpsQQfCSyCHDJ2PZwKBu3GZSYb
 D+W50kmgmhhCuR8HviE1KGKQHebeSl94EHUZ7ZkRONSiJAgGhKJzfAc
X-Developer-Key: i=git@younes.io; a=ed25519;
 pk=1DRfzPrQ04RQHHgGK28t+vjIAPv5oISPiAdLMU6J5dE=
X-Endpoint-Received: by B4 Relay for git@younes.io/20260712 with auth_id=866
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The existing safety comments only restate the guarantees provided by
Send and Sync. Document that completions have no task affinity, that
moving an owning pointer preserves pinning, and that the C API serializes
access to the completion state with wait.lock.

Signed-off-by: Younes Akhouayri <git@younes.io>
---
 rust/kernel/sync/completion.rs | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/rust/kernel/sync/completion.rs b/rust/kernel/sync/completion.rs
index 35ff049ff078..b5842f04887b 100644
--- a/rust/kernel/sync/completion.rs
+++ b/rust/kernel/sync/completion.rs
@@ -69,10 +69,12 @@ pub struct Completion {
     inner: Opaque<bindings::completion>,
 }
 
-// SAFETY: `Completion` is safe to be send to any task.
+// SAFETY: `Completion` has no task affinity, and moving an owning pointer to another task preserves
+// the pinning of the underlying `struct completion`.
 unsafe impl Send for Completion {}
 
-// SAFETY: `Completion` is safe to be accessed concurrently.
+// SAFETY: The C completion API protects accesses to `done` and the wait queue with `wait.lock`, so
+// the operations exposed through shared references may be called concurrently.
 unsafe impl Sync for Completion {}
 
 impl Completion {

---
base-commit: 8fe5e5f62bdb9660999449a4b5eaebcc37d7f842
change-id: 20260811-docs-completion-send-sync-safety-296f16d6135c

Best regards,
--  
Younes Akhouayri <git@younes.io>

