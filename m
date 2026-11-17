From: Peder Bergan <peder.bergan@gmail.com>
Date: Tue, 17 Nov 2026 10:47:51 +0100
Subject: [PATCH] rust: str: tie Formatter to its backing buffer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-formatter-lifetime-v1-1-9d7f38686552@gmail.com>
X-B4-Tracking: v=1; b=H4sIAMYi/GoC/yWMQQ6CQBAEv0Lm7CSuGlG/Yjws0CtjZCEzgyEh/
 F3QY3W6aiaDCoxuxUyKj5j0eYWwK6huY36CpVmZDvvDOYRQcuq1i+5QfkuCSwc+XY7XgKaMKTW
 0ioMiyfSL3h9/trF6ofattD2qaOBKY67bbRoHc0XsWEdzzpicluULhAGl9psAAAA=
X-Change-ID: 20261117-formatter-lifetime-48391ed7affd
To: Miguel Ojeda <ojeda@kernel.org>
Cc: Boqun Feng <boqun@kernel.org>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Tamir Duberstein <tamird@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>, 
 rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, 
 Georgios Androutsopoulos <georgeandrout13@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794908870; l=2702;
 i=peder.bergan@gmail.com; s=kernel-contributions; h=from:subject:message-id;
 bh=c2EXF63mEwnQnsVVyx1xUR6wHcOb7PHcB7oVHC4kogc=;
 b=cmJf587r8vKEHlsRLXxBys9PRoJzmqc7PY99ABcGPBG30A/U+CR4NFqDkHVTlCpCiZjZyEmEh
 B0zCJRZLbAaAGYDmROGMsitdX3LRLm5XVeeEoCJThHNaAH++9pnec/m
X-Developer-Key: i=peder.bergan@gmail.com; a=ed25519;
 pk=39790pn1YZCulHBoUG1uiQI1Hm01EvhBEa2zVrS/yN0=
X-Endpoint-Received: by B4 Relay for peder.bergan@gmail.com/kernel-contributions with auth_id=1395
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Formatter::new() returns a Formatter whose lifetime is independent of the
borrow of its backing buffer. Safe code can therefore drop the buffer and
then write through the formatter, causing a use-after-free.

Tie the buffer borrow to the formatter's lifetime so that the borrow
checker rejects such callers and prevents overlapping mutable access.
Add a doctest showing formatting into a borrowed buffer.

Fixes: 87482d6d9104 ("rust: str: allow `str::Formatter` to format into `&mut [u8]`.")
Cc: stable@vger.kernel.org
Reported-by: Georgios Androutsopoulos <georgeandrout13@gmail.com>
Closes: https://github.com/Rust-for-Linux/linux/issues/1261
Signed-off-by: Peder Bergan <peder.bergan@gmail.com>
---
I compiled the in-tree callers with Clippy and ran the string tests and
kernel doctests under x86_64 QEMU. Three borrowing probes compiled before
the fix and failed with the expected borrow-checker errors after it.
Rust documentation and formatting checks passed.

OpenAI Codex assisted with coding and testing.
---
 rust/kernel/str.rs | 20 ++++++++++++++++++--
 1 file changed, 18 insertions(+), 2 deletions(-)

diff --git a/rust/kernel/str.rs b/rust/kernel/str.rs
index 644b4279a..6222faacf 100644
--- a/rust/kernel/str.rs
+++ b/rust/kernel/str.rs
@@ -645,7 +645,7 @@ impl fmt::Write for RawFormatter {
 /// Fails if callers attempt to write more than will fit in the buffer.
 pub struct Formatter<'a>(RawFormatter, PhantomData<&'a mut ()>);
 
-impl Formatter<'_> {
+impl<'a> Formatter<'a> {
     /// Creates a new instance of [`Formatter`] with the given buffer.
     ///
     /// # Safety
@@ -658,7 +658,23 @@ impl Formatter<'_> {
     }
 
     /// Create a new [`Self`] instance.
-    pub fn new(buffer: &mut [u8]) -> Self {
+    ///
+    /// The formatter exclusively borrows `buffer` for its lifetime.
+    ///
+    /// # Examples
+    ///
+    /// ```
+    /// use kernel::fmt::Write as _;
+    /// use kernel::str::Formatter;
+    ///
+    /// let mut buffer = [0; 4];
+    /// let mut formatter = Formatter::new(&mut buffer);
+    /// formatter.write_str("test")?;
+    /// assert_eq!(formatter.bytes_written(), 4);
+    /// assert_eq!(&buffer, b"test");
+    /// # Ok::<(), kernel::error::Error>(())
+    /// ```
+    pub fn new(buffer: &'a mut [u8]) -> Self {
         // SAFETY: `buffer` is valid for writes for the entire length for
         // the lifetime of `Self`.
         unsafe { Formatter::from_buffer(buffer.as_mut_ptr(), buffer.len()) }

---
base-commit: aebb7274476403040d582c61478df8f4a7bf9cd3
change-id: 20261117-formatter-lifetime-48391ed7affd

Best regards,
--  
Peder Bergan <peder.bergan@gmail.com>

