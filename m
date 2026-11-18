From: Peder Bergan <peder.bergan@gmail.com>
Date: Wed, 18 Nov 2026 11:40:00 +0100
Subject: [PATCH] rust: pin-init: use precise lifetime capture in list
 examples
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-cleanup-pin-init-precise-capture-v1-1-60f6e06d66f6@gmail.com>
X-B4-Tracking: v=1; b=H4sIAH+A/WoC/yWNywrCQAxFf6VkbbBTtYi/Il1kYmojGod5SKH03
 53qKpzcm5MFkkSVBJdmgSgfTfq2Cm7XAE9kd0G9VYau7Xrn3Bn5KWQlYFBDNc0YorAmQaaQS6y
 zPfCRTj35boSqqfmo8+/FdfhzKv4hnDfv1vBUz30k42lblZByFHrtY0kZTeYM6/oF1uPP9KkAA
 AA=
X-Change-ID: 20261118-cleanup-pin-init-precise-capture-c03c4a56ab2f
To: Benno Lossin <lossin@kernel.org>, Gary Guo <gary@garyguo.net>, 
 Miguel Ojeda <ojeda@kernel.org>
Cc: Boqun Feng <boqun@kernel.org>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Andreas Hindborg <a.hindborg@kernel.org>, Alice Ryhl <aliceryhl@google.com>, 
 Trevor Gross <tmgross@umich.edu>, Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Tamir Duberstein <tamird@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>, 
 rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jesung Yang <y.j3ms.n@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794998399; l=2668;
 i=peder.bergan@gmail.com; s=kernel-contributions; h=from:subject:message-id;
 bh=pZ2OArFfaWdtZNLAKFk6SbDsCLyWp8PYiR1yrw5TjIM=;
 b=Jzwcy6op0gCrX18bd0HgHujuAMD6ODVeD5+qTMw9jMl8qCIlgF0rKTbCjYc2h6H/eyIFCVuMd
 DuAsZWmdZqqDQFXDZEEqumuYvJwDxhZ5ry+UDlh7g3MhN39BRMko3J3
X-Developer-Key: i=peder.bergan@gmail.com; a=ed25519;
 pk=39790pn1YZCulHBoUG1uiQI1Hm01EvhBEa2zVrS/yN0=
X-Endpoint-Received: by B4 Relay for peder.bergan@gmail.com/kernel-contributions with auth_id=1395
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The linked list insertion and mutex wait entry initializers borrow
the list they will link into. Express that dependency with precise
capturing bounds instead of using an outlives bound to capture the
list lifetime.

Precise capturing bounds are available at pin-init's minimum Rust
version of 1.82.

Suggested-by: Jesung Yang <y.j3ms.n@gmail.com>
Link: https://github.com/Rust-for-Linux/linux/issues/1175
Signed-off-by: Peder Bergan <peder.bergan@gmail.com>
---
The two examples passed on Rust 1.82 with std enabled and compiled
with std disabled. The standalone tests and doctests passed on
nightly.

OpenAI Codex assisted with the signature changes, testing and
drafting this commit message.
---
 rust/pin-init/examples/linked_list.rs | 4 ++--
 rust/pin-init/examples/mutex.rs       | 2 +-
 2 files changed, 3 insertions(+), 3 deletions(-)

diff --git a/rust/pin-init/examples/linked_list.rs b/rust/pin-init/examples/linked_list.rs
index 424585fe226d..577106005cbd 100644
--- a/rust/pin-init/examples/linked_list.rs
+++ b/rust/pin-init/examples/linked_list.rs
@@ -39,7 +39,7 @@ pub fn new() -> impl PinInit<Self> {
 
     #[inline]
     #[allow(dead_code)]
-    pub fn insert_next(list: &ListHead) -> impl PinInit<Self> + '_ {
+    pub fn insert_next(list: &ListHead) -> impl PinInit<Self> + use<'_> {
         pin_init!(&this in Self {
             prev: list.next.prev().replace(unsafe { Link::new_unchecked(this)}),
             next: list.next.replace(unsafe { Link::new_unchecked(this)}),
@@ -48,7 +48,7 @@ pub fn insert_next(list: &ListHead) -> impl PinInit<Self> + '_ {
     }
 
     #[inline]
-    pub fn insert_prev(list: &ListHead) -> impl PinInit<Self> + '_ {
+    pub fn insert_prev(list: &ListHead) -> impl PinInit<Self> + use<'_> {
         pin_init!(&this in Self {
             next: list.prev.next().replace(unsafe { Link::new_unchecked(this)}),
             prev: list.prev.replace(unsafe { Link::new_unchecked(this)}),
diff --git a/rust/pin-init/examples/mutex.rs b/rust/pin-init/examples/mutex.rs
index e8d4dbb664fe..81b425cbfea9 100644
--- a/rust/pin-init/examples/mutex.rs
+++ b/rust/pin-init/examples/mutex.rs
@@ -163,7 +163,7 @@ struct WaitEntry {
 
 impl WaitEntry {
     #[inline]
-    fn insert_new(list: &ListHead) -> impl PinInit<Self> + '_ {
+    fn insert_new(list: &ListHead) -> impl PinInit<Self> + use<'_> {
         #[cfg(feature = "std")]
         {
             pin_init!(Self {

---
base-commit: aebb7274476403040d582c61478df8f4a7bf9cd3
change-id: 20261118-cleanup-pin-init-precise-capture-c03c4a56ab2f

Best regards,
--  
Peder Bergan <peder.bergan@gmail.com>

