From: Peder Bergan <peder.bergan@gmail.com>
Date: Tue, 17 Nov 2026 18:57:07 +0100
Subject: [PATCH v2 2/2] rust: str: add an example for Formatter::new
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-formatter-lifetime-v2-2-e216d86ffb57@gmail.com>
References: <20261117-formatter-lifetime-v2-0-e216d86ffb57@gmail.com>
In-Reply-To: <20261117-formatter-lifetime-v2-0-e216d86ffb57@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794938225; l=1243;
 i=peder.bergan@gmail.com; s=kernel-contributions; h=from:subject:message-id;
 bh=cXnDKX6DUJYzotZgM4eodRj9988SY5vag/57CgAxefA=;
 b=ftlkleDiJFBrpP5Go7Zmk+scHV6bzIGVdtrSzMBuq71SDPvACTVvj4xa0XhOcRCoa6bVKLGMp
 tn8Qq+MxRm8A7huSNZqHvGsypCZTXzVQX9Iuo9O0dTqDGEF8niqOGRZ
X-Developer-Key: i=peder.bergan@gmail.com; a=ed25519;
 pk=39790pn1YZCulHBoUG1uiQI1Hm01EvhBEa2zVrS/yN0=
X-Endpoint-Received: by B4 Relay for peder.bergan@gmail.com/kernel-contributions with auth_id=1395
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the exclusive buffer borrow held by Formatter::new() and show
formatting into a live buffer. Check the number of bytes written and the
resulting buffer contents.

Signed-off-by: Peder Bergan <peder.bergan@gmail.com>
---
 rust/kernel/str.rs | 16 ++++++++++++++++
 1 file changed, 16 insertions(+)

diff --git a/rust/kernel/str.rs b/rust/kernel/str.rs
index e5fe84eeb..6222faacf 100644
--- a/rust/kernel/str.rs
+++ b/rust/kernel/str.rs
@@ -658,6 +658,22 @@ impl<'a> Formatter<'a> {
     }
 
     /// Create a new [`Self`] instance.
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
     pub fn new(buffer: &'a mut [u8]) -> Self {
         // SAFETY: `buffer` is valid for writes for the entire length for
         // the lifetime of `Self`.

-- 
2.56.1

