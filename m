From: Valentin Obst <kernel@valentinobst.de>
Date: Wed, 31 Jan 2024 21:23:25 +0100
Subject: [PATCH v3 03/12] rust: ioctl: end top-level module docs with full
 stop
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240131-doc-fixes-v3-v3-3-0c8af94ed7de@valentinobst.de>
References: <20240131-doc-fixes-v3-v3-0-0c8af94ed7de@valentinobst.de>
In-Reply-To: <20240131-doc-fixes-v3-v3-0-0c8af94ed7de@valentinobst.de>
To: Miguel Ojeda <ojeda@kernel.org>, Alex Gaynor <alex.gaynor@gmail.com>, 
 Wedson Almeida Filho <wedsonaf@gmail.com>, 
 Boqun Feng <boqun.feng@gmail.com>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <benno.lossin@proton.me>, 
 Andreas Hindborg <a.hindborg@samsung.com>, 
 Alice Ryhl <aliceryhl@google.com>
Cc: rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Valentin Obst <kernel@valentinobst.de>, Trevor Gross <tmgross@umich.edu>, 
 Martin Rodriguez Reboredo <yakoyoku@gmail.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706732646; l=787;
 i=kernel@valentinobst.de; s=20240131; h=from:subject:message-id;
 bh=RnmjgqCkBgtaoPxCHzDBkuKFgg4rjvv/297TJiMhnEQ=;
 b=DFYaExxkBLacWrAXEjYrfqcfudJkoubWg1dEDgUS4NWXXUrugAr3GKNQOtG7EKqVDRcOEdWOY
 oGHG7IZ5INYD7JdP0I4w3Hacu97rtIsCPjclv3/mroltWwWdXZWc1sN
X-Developer-Key: i=kernel@valentinobst.de; a=ed25519;
 pk=3s7U8y0mqkaiurgHSQQTYWOo2tw5HgzCg5vnJVfw37Y=
X-Endpoint-Received: by B4 Relay for kernel@valentinobst.de/20240131 with auth_id=124
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Every other module ends its first line of documentation with a full
stop. Adapt the only outlier.

Signed-off-by: Valentin Obst <kernel@valentinobst.de>
Reviewed-by: Trevor Gross <tmgross@umich.edu>
Reviewed-by: Martin Rodriguez Reboredo <yakoyoku@gmail.com>
Reviewed-by: Alice Ryhl <aliceryhl@google.com>
---
 rust/kernel/ioctl.rs | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/rust/kernel/ioctl.rs b/rust/kernel/ioctl.rs
index 59050e5f5a5a..5987ad6d38a7 100644
--- a/rust/kernel/ioctl.rs
+++ b/rust/kernel/ioctl.rs
@@ -1,6 +1,6 @@
 // SPDX-License-Identifier: GPL-2.0
 
-//! ioctl() number definitions
+//! ioctl() number definitions.
 //!
 //! C header: [`include/asm-generic/ioctl.h`](srctree/include/asm-generic/ioctl.h)
 

-- 
2.43.0

