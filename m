From: Younes Akhouayri <git@younes.io>
Date: Tue, 27 Oct 2026 13:10:03 +0100
Subject: [PATCH 1/2] rust: str: parse_int: only accept a sign before the
 radix prefix
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261027-b4-parse-int-sign-v1-1-7f386318a4b7@younes.io>
References: <20261027-b4-parse-int-sign-v1-0-7f386318a4b7@younes.io>
In-Reply-To: <20261027-b4-parse-int-sign-v1-0-7f386318a4b7@younes.io>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793103002; l=4111;
 i=git@younes.io; s=20261027; h=from:subject:message-id;
 bh=ZIMsYyaNWv66eaanjb2Is4SXAQQRcP2OLUu3EkB/df0=;
 b=mlQf2QJycNef9ASMfrzkl+aJBB+Mrq+9E7pfi2AKiK/7S3w9T/+GIFZWxIdeZ8ElOkectyvvW
 JvzbqAUNjePCSeRUI2WcaXvBI4ECCo+j+JDLP3QPlju07N2lrNntnxt
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

`kstrtoint()` rejects all of these with -EINVAL. On the other hand,
`kstrtoint()` accepts "+0x5" as 5, but `from_str()` rejects it, because
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
 rust/kernel/str/parse_int.rs | 23 ++++++++++++++++++-----
 1 file changed, 18 insertions(+), 5 deletions(-)

diff --git a/rust/kernel/str/parse_int.rs b/rust/kernel/str/parse_int.rs
index 48eb4c202984..07e1fbd7be8f 100644
--- a/rust/kernel/str/parse_int.rs
+++ b/rust/kernel/str/parse_int.rs
@@ -28,8 +28,11 @@ pub trait FromStrRadix: Sized {
 
 /// Extract the radix from an integer literal optionally prefixed with
 /// one of `0x`, `0X`, `0o`, `0O`, `0b`, `0B`, `0`.
-fn strip_radix(src: &BStr) -> (u32, &BStr) {
-    match src.deref() {
+///
+/// Returns [`EINVAL`] if the digits start with a sign, which
+/// `from_str_radix()` would otherwise accept.
+fn strip_radix(src: &BStr) -> Result<(u32, &BStr)> {
+    let (radix, digits) = match src.deref() {
         [b'0', b'x' | b'X', rest @ ..] => (16, rest.as_ref()),
         [b'0', b'o' | b'O', rest @ ..] => (8, rest.as_ref()),
         [b'0', b'b' | b'B', rest @ ..] => (2, rest.as_ref()),
@@ -38,6 +41,11 @@ fn strip_radix(src: &BStr) -> (u32, &BStr) {
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
 
@@ -75,13 +83,18 @@ fn strip_radix(src: &BStr) -> (u32, &BStr) {
 /// assert!(i8::from_str(b_str!("-129")).is_err());
 /// assert_eq!(Ok(255u8), u8::from_str(b_str!("255")));
 /// assert!(u8::from_str(b_str!("256")).is_err());
+///
+/// assert_eq!(Ok(0x5i32), i32::from_str(b_str!("+0x5")));
+/// assert!(i32::from_str(b_str!("0x-5")).is_err());
+/// assert!(i32::from_str(b_str!("0x+5")).is_err());
+/// assert!(i32::from_str(b_str!("-+5")).is_err());
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
@@ -94,8 +107,8 @@ fn from_str(src: &BStr) -> Result<Self> {
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

