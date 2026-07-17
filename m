From: Younes Akhouayri <git@younes.io>
Date: Fri, 17 Jul 2026 13:44:06 +0200
Subject: [PATCH] rust: print: fix broken `_printk` Rustdoc link
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260717-docs-printk-rustdoc-link-v1-1-892074948f75@younes.io>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CQAyF4auQrm0EVDBexbiYGSpUTCHtYEgId
 3dGl1/T929gpEwGt2IDpQ8bT5JQHQoIg5OekLtkqMu6KduqxW4KhrOyxBF1sZiMb5YRXdOcL76
 +tifvIM1npSevv/T98bct/kUh5l7+8M4IvToJQz5Nyj3LMUdRaI2w719iLLKonwAAAA==
X-Change-ID: 20260717-docs-printk-rustdoc-link-a6645b2873ba
To: Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Tamir Duberstein <tamird@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>
Cc: rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784288662; l=1057;
 i=git@younes.io; s=20260712; h=from:subject:message-id;
 bh=zVBY86ITmj7s9gCecJMwnv88MyaOS9NDh+38YeC1HUQ=;
 b=Y69z8bNr2eF2LQ5NVbtZul9RUSg0T7ydyAYco/TMOtrICmgT07DGC4Gfd4eAJ+TdSx2vR7PTD
 5qeHIf+BhNsDTJz0eqZ5hBobnwy9kPcBuve4Y117NGKyWqVhUV9saRQ
X-Developer-Key: i=git@younes.io; a=ed25519;
 pk=1DRfzPrQ04RQHHgGK28t+vjIAPv5oISPiAdLMU6J5dE=
X-Endpoint-Received: by B4 Relay for git@younes.io/20260712 with auth_id=866
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Rustdoc link for `_printk` points to `include/linux/_printk.h`,
which does not exist. Point it to `include/linux/printk.h`, where
`_printk` is declared.

Fixes: 247b365dc8dc ("rust: add `kernel` crate")
Signed-off-by: Younes Akhouayri <git@younes.io>
---
 rust/kernel/print.rs | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/rust/kernel/print.rs b/rust/kernel/print.rs
index 6fd84389a858..0d62beeedca5 100644
--- a/rust/kernel/print.rs
+++ b/rust/kernel/print.rs
@@ -99,7 +99,7 @@ pub mod format_strings {
 /// The format string must be one of the ones in [`format_strings`], and
 /// the module name must be null-terminated.
 ///
-/// [`_printk`]: srctree/include/linux/_printk.h
+/// [`_printk`]: srctree/include/linux/printk.h
 #[doc(hidden)]
 #[cfg_attr(not(CONFIG_PRINTK), allow(unused_variables))]
 pub unsafe fn call_printk(

---
base-commit: 7059bdf4f04a3e14f4fafb3ac35fdca913e3e21a
change-id: 20260717-docs-printk-rustdoc-link-a6645b2873ba

Best regards,
--  
Younes Akhouayri <git@younes.io>

