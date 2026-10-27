From: Younes Akhouayri <git@younes.io>
Date: Tue, 27 Oct 2026 13:10:04 +0100
Subject: [PATCH 2/2] rust: str: parse_int: accept a trailing newline like
 kstrtol()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261027-b4-parse-int-sign-v1-2-7f386318a4b7@younes.io>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793103002; l=2519;
 i=git@younes.io; s=20261027; h=from:subject:message-id;
 bh=NMDljLHIBCr2SpOAfotlmJ6JzudvatDgarIHJ0F0q5Y=;
 b=NsX5K2E5gXlHF/QnhEjEST4ehx1nHzafURb/JCD+VMl/i63Qu3CsUzpQc0rNxSVoDpKCYRVbA
 sMRZsNMOTnKAw2lEZp1WTMCHE/eozMyDo1wb/6gPJjVovxrFiJn7mta
X-Developer-Key: i=git@younes.io; a=ed25519;
 pk=TavwxGPDBjl4XGNQyFLKEW7PKSY4qOWusc7yf6hjV0c=
X-Endpoint-Received: by B4 Relay for git@younes.io/20261027 with auth_id=1332
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The documentation of `ParseInt` says that any string parsed by
`kstrtol()` or `kstrtoul()` is also parsed by `from_str()`. However,
those functions accept a single trailing newline, and `from_str()` does
not:

    kstrtoint("5\n", 0, &v) == 0, v == 5
    i32::from_str("5\n")    == Err(EINVAL)

A trailing newline is common when the string comes from user space, for
example when a value is written to a sysfs file with `echo`.

Fix it by removing a single trailing newline before parsing, and add
doctests for it.

Fixes: 51d9ee90ea90 ("rust: str: add radix prefixed integer parsing functions")
Signed-off-by: Younes Akhouayri <git@younes.io>
---
 rust/kernel/str/parse_int.rs | 10 +++++++---
 1 file changed, 7 insertions(+), 3 deletions(-)

diff --git a/rust/kernel/str/parse_int.rs b/rust/kernel/str/parse_int.rs
index 07e1fbd7be8f..ada355306fc5 100644
--- a/rust/kernel/str/parse_int.rs
+++ b/rust/kernel/str/parse_int.rs
@@ -54,8 +54,8 @@ fn strip_radix(src: &BStr) -> Result<(u32, &BStr)> {
 /// Strings beginning with `0x`, `0o`, or `0b` are parsed as hex, octal, or
 /// binary respectively. Strings beginning with `0` otherwise are parsed as
 /// octal. Anything else is parsed as decimal. A leading `+` or `-` is also
-/// permitted. Any string parsed by [`kstrtol()`] or [`kstrtoul()`] will be
-/// successfully parsed.
+/// permitted, as is a single trailing newline. Any string parsed by
+/// [`kstrtol()`] or [`kstrtoul()`] will be successfully parsed.
 ///
 /// [`kstrtol()`]: https://docs.kernel.org/core-api/kernel-api.html#c.kstrtol
 /// [`kstrtoul()`]: https://docs.kernel.org/core-api/kernel-api.html#c.kstrtoul
@@ -88,11 +88,15 @@ fn strip_radix(src: &BStr) -> Result<(u32, &BStr)> {
 /// assert!(i32::from_str(b_str!("0x-5")).is_err());
 /// assert!(i32::from_str(b_str!("0x+5")).is_err());
 /// assert!(i32::from_str(b_str!("-+5")).is_err());
+///
+/// assert_eq!(Ok(5u8), u8::from_str(b_str!("5\n")));
+/// assert!(u8::from_str(b_str!("5\n\n")).is_err());
 /// ```
 pub trait ParseInt: private::FromStrRadix + TryFrom<u64> {
     /// Parse a string according to the description in [`Self`].
     fn from_str(src: &BStr) -> Result<Self> {
-        match src.deref() {
+        let src = src.strip_suffix(b"\n").unwrap_or(src);
+        match src {
             [b'-', rest @ ..] => {
                 let (radix, digits) = strip_radix(rest.as_ref())?;
                 // 2's complement values range from -2^(b-1) to 2^(b-1)-1.

-- 
2.56.0

