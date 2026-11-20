From: Peder Bergan <peder.bergan@gmail.com>
Date: Fri, 20 Nov 2026 18:19:17 +0100
Subject: [PATCH v2] rust: bindgen: Preserve sched_statistics alignment
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-fix-schedstats-bindgen-layout-v2-1-1c42e4a996ae@gmail.com>
X-B4-Tracking: v=1; b=H4sIABSBAGsC/42OTQ6CMBSEr2K69mkLosGV9zAs+vOgNdKSvkI0h
 rvb4gVcfpOZL/NhhNEhsevuwyIujlzwGar9jmkr/YDgTGZW8eoshGihdy8gbdFQkolAOW8G9PC
 U7zAn4G3dqPOpPl34hWXHFDEPNv+9+zHN6oE6FWlpKEkIKkqvbYnmiVJEOR7jTAk8vlIpWUcpx
 Pf2chFF9u+hRYAA3rStMVXN+97chlG650GHkXXrun4BQiKm3wEBAAA=
X-Change-ID: 20261119-fix-schedstats-bindgen-layout-0935b6434707
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
 Carlos Llamas <cmllamas@google.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 =?utf-8?q?Arve_Hj=C3=B8nnev=C3=A5g?= <arve@android.com>, 
 Todd Kjos <tkjos@android.com>, Christian Brauner <brauner@kernel.org>, 
 Jules Mercier <jules@les-mercier.fr>, rust-for-linux@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795195162; l=2723;
 i=peder.bergan@gmail.com; s=kernel-contributions; h=from:subject:message-id;
 bh=u4QY0eOrLq5AnKKXDQlNnc7y1G/bsdbLKO4Tsmnc1Rc=;
 b=CGjLrC3xrHMMhwNk+60mTkOfXvVww+NtfWTp4WrSpTz699eWkTcZfvLHqQl0ZqdN5766bwcEE
 9/I4tueXlvnA7tRsCj0He39kTVlIwcEXrORV3Rogf331Je1IwEuSJFa
X-Developer-Key: i=peder.bergan@gmail.com; a=ed25519;
 pk=39790pn1YZCulHBoUG1uiQI1Hm01EvhBEa2zVrS/yN0=
X-Endpoint-Received: by B4 Relay for peder.bergan@gmail.com/kernel-contributions with auth_id=1395
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With CONFIG_SCHEDSTATS disabled, struct sched_statistics is empty but
still cache-line aligned. Bindgen omits the alignment of the empty
type. Bindgen 0.73.2 also stopped forcing padding before over-aligned
fields, so fields following stats can be misplaced in the generated
task_struct. On the reported arm64 build, Rust Binder reads the wrong
pointer via CurrentTask::mm() and rejects mmap() with -EINVAL.

Make sched_statistics opaque so bindgen uses the C size and alignment.
Rust has no callers that access the fields of this type.

Reported-by: Jules Mercier <jules@les-mercier.fr>
Closes: https://github.com/Rust-for-Linux/linux/issues/1269
Link: https://github.com/rust-lang/rust-bindgen/issues/3549
Tested-by: Jules Mercier <jules@les-mercier.fr>
Cc: stable@vger.kernel.org # 6.12.x
Signed-off-by: Peder Bergan <peder.bergan@gmail.com>
---
Changes in v2

- Explain how the bindgen 0.73.2 padding change exposes the missing alignment.
- Link the bindgen bug and request stable backports starting with 6.12.x.
- Credit Jules Mercier's report and OnePlus 6T test, and expand the Binder Cc list.

I kept the opaque rule unconditional as discussed. On bindgen 0.73.1,
I found an offset mismatch at task_struct.se before sched_statistics.

I also checked an arm64 6.12.y build with bindgen 0.73.2 and schedstats
disabled. With the rule applied in the 6.12.y context, the Rust
task_struct.pid offset moved from 1208 to 1216, matching C.

v1 on lore.kernel.org
https://lore.kernel.org/rust-for-linux/20261119-fix-schedstats-bindgen-layout-v1-1-0599dd230ffd@gmail.com/

OpenAI Codex assisted with the bindgen change, validation and drafting.
---
 rust/bindgen_parameters | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/rust/bindgen_parameters b/rust/bindgen_parameters
index 5bab3cf063360..65c308d4b603b 100644
--- a/rust/bindgen_parameters
+++ b/rust/bindgen_parameters
@@ -26,6 +26,12 @@
 # warning. We don't need to peek into it anyway.
 --opaque-type spinlock
 
+# Bindgen omits the alignment of empty structs. Bindgen 0.73.2 also stopped
+# forcing padding before over-aligned fields, so following fields can be
+# misplaced. Making sched_statistics opaque preserves its C alignment.
+# https://github.com/rust-lang/rust-bindgen/issues/3549
+--opaque-type sched_statistics
+
 # enums that appear in indirect function calls should specify a cfi type
 --newtype-enum fwctl_rpc_scope
 --with-attribute-custom-enum=fwctl_rpc_scope='#[cfi_encoding="15fwctl_rpc_scope"]'

---
base-commit: aebb7274476403040d582c61478df8f4a7bf9cd3
change-id: 20261119-fix-schedstats-bindgen-layout-0935b6434707

Best regards,
--  
Peder Bergan <peder.bergan@gmail.com>

