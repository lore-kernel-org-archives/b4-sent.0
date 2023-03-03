From: Patrick Blass <patrickblass@mailbox.org>
Date: Fri, 03 Mar 2023 20:06:29 +0100
Subject: [PATCH] rust: str: fix requierments->requirements typo for rust
 str
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230303-str-rs-typo-v1-1-d022b4a57591@mailbox.org>
X-B4-Tracking: v=1; b=H4sIADRFAmQC/x2N0QpAQBBFf0XzbAqbwq/Iw+4azIOlmU0k/27pP
 p1up3ODkjApdNkNQgcrbyFBmWfgFxtmQh4TQ1VUpkhDjYKiGK99Q0el9009utZMkAxnldCJDX7
 5nNVqJPmOXWji88/0w/O8RFEmYnYAAAA=
To: Miguel Ojeda <ojeda@kernel.org>, Alex Gaynor <alex.gaynor@gmail.com>, 
 Wedson Almeida Filho <wedsonaf@gmail.com>, 
 Boqun Feng <boqun.feng@gmail.com>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Morgan Bartlett <mjmouse9999@gmail.com>, 
 Niklas Mohrin <dev@niklasmohrin.de>
Cc: Geoffrey Thomas <geofft@ldpreload.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Viktor Garske <viktor@v-gar.de>, Sven Van Asbroeck <thesven73@gmail.com>, 
 rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Patrick Blass <patrickblass@mailbox.org>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=1205;
 i=patrickblass@mailbox.org; h=from:subject:message-id;
 bh=g3xJefQ8BmKAXAFUnDC8xFZ5SkostIUiVotzVhaztoc=;
 b=owEBbQKS/ZANAwAIAfr4tNPd5QZuAcsmYgBkAkVeU24iFhTfN+ud2zUjZukIEj9jZkHDkPJ0KTfS
 zsYYtjqJAjMEAAEIAB0WIQRyvooYoKyvwaJCarP6+LTT3eUGbgUCZAJFXgAKCRD6+LTT3eUGbpw4EA
 C4KmCm4ce1obC81DpHCncMJR8ODGcnmy/oGrsOnVXZHIShD8Ve3uOtZ+JZFET+8lDz1q5S+Rjlbbgk
 QG9KoTymReH2sNC96yCCy2ZClOPvDAtVvRVuXzIDPGTFHlvqmVPMbfq+nTeynAoTdY2iEZjkdD3fsh
 AzXlMX6c4tToXwQM/VLby4vrVo0wPp9NjPJRPA+ntk1+gtqzHRyeWzbdrFXhqVSXM+iv6xO6H27+XL
 cUgG4gn5B5LT2n7xntqw1nKHTgkE7wXmnOxyPnVFrBZAYw2XcsEEyZEjipB6zqZlbA/xpY/xnuaa06
 R/ipAsUHiZv9POQZ/Kcg8IE/MJWQZ6O7m0ZS2xitvI6Y+tQtOooCjPan4dMQuZcADI4leGNNz1hTNI
 GoO0xuJFGQ/IBcPGRQf04h8QtNpZpqT0dJ/GB7OjdDD53YI4JJCqZmzGqbC/D0Mj/tDhQ6FBJUNq6y
 1E9FOqwNFjyR0iWWz3KPvjyzSntF/S7Qzq+VmQUidg0cBOHZu5WWfJ51mPlMzLMkv796IU1lxFd32n
 dQexjejIHgpQP+qCsbf6wCE5cHUALFDAQZPwMVsvTqwaHs6BrXaSLP0lRGdHIT9lyjQ0w/vVnxh65O
 ykWIfZzDYmX6+z2cyKLv8E+Od+L52A/af90PSeBrtJ6PAJTIy+rCXZ4YvaWw==
X-Developer-Key: i=patrickblass@mailbox.org; a=openpgp;
 fpr=72BE8A18A0ACAFC1A2426AB3FAF8B4D3DDE5066E
X-Endpoint-Received: by B4 Relay for patrickblass@mailbox.org/default with auth_id=36
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix a trivial spelling error in the rust str file.

Fixes: 247b365dc8dc ("rust: add `kernel` crate")
Reported-by: Miguel Ojeda <ojeda@kernel.org>
Link: https://github.com/Rust-for-Linux/linux/issues/978
Signed-off-by: Patrick Blass <patrickblass@mailbox.org>
---
 rust/kernel/str.rs | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/rust/kernel/str.rs b/rust/kernel/str.rs
index b771310fa4a4..cd3d2a6cf1fc 100644
--- a/rust/kernel/str.rs
+++ b/rust/kernel/str.rs
@@ -408,7 +408,7 @@ impl RawFormatter {
     /// If `pos` is less than `end`, then the region between `pos` (inclusive) and `end`
     /// (exclusive) must be valid for writes for the lifetime of the returned [`RawFormatter`].
     pub(crate) unsafe fn from_ptrs(pos: *mut u8, end: *mut u8) -> Self {
-        // INVARIANT: The safety requierments guarantee the type invariants.
+        // INVARIANT: The safety requirements guarantee the type invariants.
         Self {
             beg: pos as _,
             pos: pos as _,

---
base-commit: c9c3395d5e3dcc6daee66c6908354d47bf98cb0c
change-id: 20230303-str-rs-typo-be1cc85db93f

Best regards,
-- 
Patrick Blass <patrickblass@mailbox.org>

