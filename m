From: Maurice Hieronymus <mhi@mailbox.org>
Subject: [PATCH 0/2] rust: clk: Add ExclusiveClk and use it in pwm-th1520
Date: Tue, 26 May 2026 19:04:56 +0200
Message-Id: <20260526-rate-exclusive-get-th1520-v1-0-34cf034e1764@mailbox.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MOwqAMBBF0a3I1A4kQeNnK2IR9KkDopJEEcS9G
 yxPce9DAV4QqM0e8rgkyL4l6DyjYXHbDJYxmYwyVpXGsncRjHtYzyAXeEbkuOjSKK5s4ZqiGaF
 rUOoPj0nu/9317/sBXvSclWsAAAA=
X-Change-ID: 20260526-rate-exclusive-get-th1520-764a949de18e
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Miguel Ojeda <ojeda@kernel.org>, 
 Boqun Feng <boqun@kernel.org>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, Drew Fustini <fustini@kernel.org>, 
 Guo Ren <guoren@kernel.org>, Fu Wei <wefu@redhat.com>, 
 Michal Wilczynski <m.wilczynski@samsung.com>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>
Cc: linux-clk@vger.kernel.org, rust-for-linux@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-riscv@lists.infradead.org, 
 linux-pwm@vger.kernel.org, Maurice Hieronymus <mhi@mailbox.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779815100; l=764;
 i=mhi@mailbox.org; s=20260525; h=from:subject:message-id;
 bh=rw34vtqykP3gLbod3ZqxjK1eri8oVxXKFkcTw3m/x34=;
 b=PL6YfDGWIuf8evRDeF2cmn1l3faTN3bvFDtgClsXkELDWCCjTqreu+xhqpuXNB8YWUsdq/qPW
 fD3wuj/fp7dCDdADJUZhO9wLasJfLgNtJQeyXNQzGz2v/GHT2Tv0wQz
X-Developer-Key: i=mhi@mailbox.org; a=ed25519;
 pk=AHlEkGG3hpXZHntlEzF42Ip/LFyXWOgsNUvaHqAnV80=
X-Endpoint-Received: by B4 Relay for mhi@mailbox.org/20260525 with auth_id=790
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a Rust binding for clk_rate_exclusive_get() / clk_rate_exclusive_put()
and use it in pwm-th1520, which previously carried a TODO noting the
missing binding.

Based on pwm/for-next.

Signed-off-by: Maurice Hieronymus <mhi@mailbox.org>
---
Maurice Hieronymus (2):
      rust: clk: Add ExclusiveClk wrapper for clk_rate_exclusive_get
      pwm: th1520: Lock clock rate with clk_rate_exclusive_get

 drivers/pwm/pwm_th1520.rs |  8 +++---
 rust/kernel/clk.rs        | 65 +++++++++++++++++++++++++++++++++++++++++++++++
 2 files changed, 68 insertions(+), 5 deletions(-)
---
base-commit: 0e5e0db3e954b32a410ab4f74a4faac7a0e8889f
change-id: 20260526-rate-exclusive-get-th1520-764a949de18e

Best regards,
-- 
Maurice Hieronymus <mhi@mailbox.org>

