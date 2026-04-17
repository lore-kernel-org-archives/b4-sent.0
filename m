From: Alvin Sun <alvin.sun@linux.dev>
Date: Fri, 17 Apr 2026 09:05:51 +0800
Subject: [PATCH 1/4] rust: sizes: add SZ_4G constant
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260417-tyr-ioctls-deps-v1-1-41c6e9bb061c@linux.dev>
References: <20260417-tyr-ioctls-deps-v1-0-41c6e9bb061c@linux.dev>
In-Reply-To: <20260417-tyr-ioctls-deps-v1-0-41c6e9bb061c@linux.dev>
To: Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 "Liam R. Howlett" <Liam.Howlett@oracle.com>, 
 Tamir Duberstein <tamird@kernel.org>
Cc: rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-mm@kvack.org, =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>, 
 Alvin Sun <alvin.sun@linux.dev>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776388289; l=622;
 i=alvin.sun@linux.dev; s=20260317; h=from:subject:message-id;
 bh=hv4TGP+tCPibLRF/F0RTc2CpoNa3r8c8YYHZgnw/d40=;
 b=S+iNkF483U9WR+fhQWZU8CgLNpKK5tzKrdQpDfJeKwwAKFnq1eIQG1QE2Vbudm17yD5D1Q1Ah
 LRbBsIrxCZ2AxirhO4muyub2XCtogmNE3/Jmde3gYKeYH9JshdNEVqm
X-Developer-Key: i=alvin.sun@linux.dev; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for alvin.sun@linux.dev/20260317 with auth_id=684
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add SZ_4G constant defined as SZ_2G * 2. This constant will be used by
the Tyr driver for calculating user and kernel VA layout.

Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
---
 rust/kernel/sizes.rs | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/rust/kernel/sizes.rs b/rust/kernel/sizes.rs
index 661e680d93306..872f5bb181ecf 100644
--- a/rust/kernel/sizes.rs
+++ b/rust/kernel/sizes.rs
@@ -48,3 +48,5 @@
 pub const SZ_1G: usize = bindings::SZ_1G as usize;
 /// 0x80000000
 pub const SZ_2G: usize = bindings::SZ_2G as usize;
+/// 0x100000000
+pub const SZ_4G: usize = SZ_2G * 2;

-- 
2.43.0

