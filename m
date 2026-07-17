From: Younes Akhouayri <git@younes.io>
Date: Fri, 17 Jul 2026 15:26:46 +0200
Subject: [PATCH] rust: irq: fix C header path in module docs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260717-docs-irq-rustdoc-header-v1-1-36749192aa04@younes.io>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMyw6CQAyF4VchXdvIJUL0VQyLmeEIdTFoC4aE8
 O7O6PJrev6dDCowuhU7KT5iMseE6lRQmFwcwTIkU13WbdlVHQ9zMBZ9s662JPAEN0C5QttcLx7
 ONaC0fikesv3K9/5vW/0TYcm5/OGdgb26GKZ8mlVGieec5YhtoeP4AqUwLIueAAAA
X-Change-ID: 20260717-docs-irq-rustdoc-header-1e6395beaa3e
To: Danilo Krummrich <dakr@kernel.org>, Alice Ryhl <aliceryhl@google.com>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Trevor Gross <tmgross@umich.edu>, Tamir Duberstein <tamird@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>
Cc: driver-core@lists.linux.dev, rust-for-linux@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Younes Akhouayri <git@younes.io>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784294825; l=1205;
 i=git@younes.io; s=20260712; h=from:subject:message-id;
 bh=DUAXmsk7k/KxOykvnIl3o8UFwBQcn84FmsrWr/BYmZ0=;
 b=b9J58TftG4SmQphTzp8LyXtKcYP/wMDXvQqNnmZYoOiUgUXgzg+IzKDUTQWc0aYp0SqhhJtmE
 hNSDOEWUYCpAa8ay1LKpF2A4P61Fnw7ZkcfSBpRvcnEDC8OT/q033ow
X-Developer-Key: i=git@younes.io; a=ed25519;
 pk=1DRfzPrQ04RQHHgGK28t+vjIAPv5oISPiAdLMU6J5dE=
X-Endpoint-Received: by B4 Relay for git@younes.io/20260712 with auth_id=866
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The IRQ module documentation displays `include/linux/device.h`, while
the link points to `include/linux/interrupt.h`. The module wraps the IRQ
registration interfaces declared in `include/linux/interrupt.h`, so fix
the displayed header path.

Fixes: 1f54d5e5cd2a ("rust: irq: add irq module")
Link: https://github.com/Rust-for-Linux/linux/issues/1246
Signed-off-by: Younes Akhouayri <git@younes.io>
---
 rust/kernel/irq.rs | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/rust/kernel/irq.rs b/rust/kernel/irq.rs
index 20abd4056655..09ef1e7f853c 100644
--- a/rust/kernel/irq.rs
+++ b/rust/kernel/irq.rs
@@ -8,7 +8,7 @@
 //! The current abstractions handle IRQ requests and handlers, i.e.: it allows
 //! drivers to register a handler for a given IRQ line.
 //!
-//! C header: [`include/linux/device.h`](srctree/include/linux/interrupt.h)
+//! C header: [`include/linux/interrupt.h`](srctree/include/linux/interrupt.h)
 
 /// Flags to be used when registering IRQ handlers.
 mod flags;

---
base-commit: 7059bdf4f04a3e14f4fafb3ac35fdca913e3e21a
change-id: 20260717-docs-irq-rustdoc-header-1e6395beaa3e

Best regards,
--  
Younes Akhouayri <git@younes.io>

