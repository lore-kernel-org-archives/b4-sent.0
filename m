From: Younes Akhouayri <git@younes.io>
Date: Sun, 01 Nov 2026 16:47:25 +0100
Subject: [PATCH v2 1/2] rust: str: parse_int: only accept a sign before the
 radix prefix
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261101-b4-parse-int-sign-v2-1-0fd827f52070@younes.io>
References: <20261101-b4-parse-int-sign-v2-0-0fd827f52070@younes.io>
In-Reply-To: <20261101-b4-parse-int-sign-v2-0-0fd827f52070@younes.io>
To: Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Tamir Duberstein <tamird@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Daniel Gomez <da.gomez@kernel.org>
Cc: rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Younes Akhouayri <git@younes.io>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793548044; l=4337;
 i=git@younes.io; s=20261027; h=from:subject:message-id;
 bh=D+H9FI9ogCTq+jwzCZO0KaYdhnIJsuMSbe0CnAgFU7I=;
 b=HjtJgBFDWRWgjnt/fR07zn0bCCT2DVNgadPEMGVBR7mmnpkoUPReCXsOal6rV/6eEhNsGUJbg
 Mb0aGsEshVgAA66pqjAJ8w0XAy+6sPy2cndKHvzZSXzKbtuZzU3D19x
X-Developer-Key: i=git@younes.io; a=ed25519;
 pk=TavwxGPDBjl4XGNQyFLKEW7PKSY4qOWusc7yf6hjV0c=
X-Endpoint-Received: by B4 Relay for git@younes.io/20261027 with auth_id=1332
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

`ParseInt::from_str()` strips an optional `-` and a radix prefix, then
hands the remaining digits to `from_str_radix()` from `core`. That
function accepts a leading `+`, and also `-` for signed types, so a
sign placed after the prefix, or a second sign, is parsed too:

    i32::from_str("0x-5")  == Ok(-5)
    i32::from_str("0x+5")  == Ok(5)
    i32::from_str("-+5")   == Ok(-5)
    i32::from_str("-0x+5") == Ok(-5)

`kstrtol()` rejects all of these with -EINVAL. On the other hand,
`kstrtol()` accepts "+0x5" as 5, but `from_str()` rejects it, because
it does not strip a leading `+` before looking for the prefix. Since
the documentation says that any string parsed by `kstrtol()` is also
parsed by `from_str()`, this is a bug.

Integer module parameters are parsed with `from_str()`, so this is
visible from the kernel command line. Booting with
`rust_minimal.test_parameter=0x-5` makes the `rust_minimal` sample
print `test_parameter: -5`.

Fix it by accepting a single `+` or `-` before the radix prefix only,
and by making `strip_radix()` reject digits that start with a sign.
Add doctests for these cases.

Fixes: 51d9ee90ea90 ("rust: str: add radix prefixed integer parsing functions")
Signed-off-by: Younes Akhouayri <git@younes.io>
---
 rust/kernel/str/parse_int.rs | 26 +++++++++++++++++++++-----
 1 file changed, 21 insertions(+), 5 deletions(-)

diff --git a/rust/kernel/str/parse_int.rs b/rust/kernel/str/parse_int.rs
index 48eb4c202984..66f590251ffc 100644
--- a/rust/kernel/str/parse_int.rs
+++ b/rust/kernel/str/parse_int.rs
@@ -28,8 +28,13 @@ pub trait FromStrRadix: Sized {
 
 /// Extract the radix from an integer literal optionally prefixed with
 /// one of `0x`, `0X`, `0o`, `0O`, `0b`, `0B`, `0`.
-fn strip_radix(src: &BStr) -> (u32, &BStr) {
-    match src.deref() {
+///
+/// Returns [`EINVAL`] if the remaining digits start with a sign. The
+/// caller passes them to the `from_str_radix()` functions of the
+/// primitive integer types in `core`, which accept a leading `+` or `-`
+/// of their own, so a sign here would make `0x-5` or `-+5` parse.
+fn strip_radix(src: &BStr) -> Result<(u32, &BStr)> {
+    let (radix, digits) = match src.deref() {
         [b'0', b'x' | b'X', rest @ ..] => (16, rest.as_ref()),
         [b'0', b'o' | b'O', rest @ ..] => (8, rest.as_ref()),
         [b'0', b'b' | b'B', rest @ ..] => (2, rest.as_ref()),
@@ -38,6 +43,11 @@ fn strip_radix(src: &BStr) -> (u32, &BStr) {
         // not be able to parse `0`.
         [b'0', ..] => (8, src),
         _ => (10, src),
+    };
+
+    match digits.deref() {
+        [b'+' | b'-', ..] => Err(EINVAL),
+        _ => Ok((radix, digits)),
     }
 }
 
@@ -75,13 +85,19 @@ fn strip_radix(src: &BStr) -> (u32, &BStr) {
 /// assert!(i8::from_str(b_str!("-129")).is_err());
 /// assert_eq!(Ok(255u8), u8::from_str(b_str!("255")));
 /// assert!(u8::from_str(b_str!("256")).is_err());
+///
+/// assert_eq!(Ok(0x5i32), i32::from_str(b_str!("+0x5")));
+/// assert!(i32::from_str(b_str!("0x-5")).is_err());
+/// assert!(i32::from_str(b_str!("0x+5")).is_err());
+/// assert!(i32::from_str(b_str!("-+5")).is_err());
+/// assert!(i32::from_str(b_str!("-0x+5")).is_err());
 /// ```
 pub trait ParseInt: private::FromStrRadix + TryFrom<u64> {
     /// Parse a string according to the description in [`Self`].
     fn from_str(src: &BStr) -> Result<Self> {
         match src.deref() {
             [b'-', rest @ ..] => {
-                let (radix, digits) = strip_radix(rest.as_ref());
+                let (radix, digits) = strip_radix(rest.as_ref())?;
                 // 2's complement values range from -2^(b-1) to 2^(b-1)-1.
                 // So if we want to parse negative numbers as positive and
                 // later multiply by -1, we have to parse into a larger
@@ -94,8 +110,8 @@ fn from_str(src: &BStr) -> Result<Self> {
                         .map_err(|_| EINVAL)?;
                 Self::from_u64_negated(val)
             }
-            _ => {
-                let (radix, digits) = strip_radix(src);
+            [b'+', rest @ ..] | rest => {
+                let (radix, digits) = strip_radix(rest.as_ref())?;
                 Self::from_str_radix(digits, radix).map_err(|_| EINVAL)
             }
         }

-- 
2.56.0

